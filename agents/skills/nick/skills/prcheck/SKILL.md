---
user-invocable: true
description: "Triage open PRs by what actually blocks each one from merging — real gate discovery, auto-approval-bot awareness, stack-dependency detection. Defaults to your own PRs from the last two weeks. Read-only. Flags: `--all`, `--author <login>`, `--days N`, `--since <date>`, `--repo <owner/name>`, `--base <branch>`, `--deep`, `--quick`, `--artifact`, `--json`."
---

# prcheck

Answer "what can I merge, and what's holding up the rest" for a set of open PRs — grounded in the repo's **actual** merge gates, not assumed ones.

`$ARGUMENTS` selects the PR set and the depth. Default is **your own** open PRs from the last 14 days. The deliverable is a per-PR next action, not a status dump: every PR lands in exactly one bucket named for the thing that must happen next.

The expensive half of this workflow is judgment on the mergeable-looking PRs. The cheap half — classifying every PR mechanically — covers most of the ground. Do the cheap half first, always; spend agents only on what survives it.

---

## 1. Inputs

**Scope** (mutually exclusive; default is `--author @me`):
- *neither* → **default**: your own PRs. Resolve your login once with `gh api user --jq '.login'`.
- `--all` (alias `--everyone`) — every open PR in range, all authors.
- `--author <login>` — one author. `@me` is accepted and resolves as above. An empty value means the flag was omitted.

**Time range** (mutually exclusive; default `--days 14`):
- `--days N` — opened within the last N days. N must be a positive integer; reject anything else.
- `--since <date>` — opened on or after an ISO date (`YYYY-MM-DD`). Wins over `--days` if both are given; say so in one line.
- `--all-time` — no date filter. Warn before running if the repo has >500 open PRs.

**Target**:
- `--repo <owner/name>` — default is the current repo (`gh repo view --json nameWithOwner`). Reject a value without exactly one `/`.
- `--base <branch>` — the branch whose gates define "mergeable". Default: the repo's default branch (`gh repo view --json defaultBranchRef`). This is the branch §2 reads rules from, and PRs targeting a *different* base are classified as stacked (§4).

**Depth** (mutually exclusive; default is `--deep` when the mergeable set is ≤80 PRs, else `--quick`):
- `--deep` — run §5's judgment pass (post-approval diffs, human review threads, blocker next-steps).
- `--quick` — mechanical only (§2–§4). Fast, no subagents, still correct about what's blocked.

**Output** (compose freely):
- `--artifact` (alias `--web`) — also publish a filterable board. Default is terminal-only.
- `--json <path>` — write the enriched per-PR records for later reuse.

Examples:
- `/nick:prcheck` → your PRs, last 14 days, deep.
- `/nick:prcheck --all --days 7 --artifact` → whole repo, last week, with a published board.
- `/nick:prcheck --author esjee --quick` → one teammate, mechanical only.

**Shell safety.** `<login>`, `<owner/name>`, `<branch>`, and `<date>` reach `gh`/`git`. Pass each as a standalone argv argument, never string-formatted into a command. Reject any value containing a quote, `` ` ``, `$`, `\`, `;`, `|`, `&`, `<`, `>`, `(`, `)`, `{`, `}`, a newline, or a control character, and reject any value beginning with `-` (option injection).

---

## 2. Discover the real gates — never assume them

**This step is not optional and its result is not guessable.** Branch protection and rulesets are *separate* systems and both apply. Reading only one gives a wrong answer.

```bash
gh api repos/<owner>/<repo>/branches/<base>/protection \
  --jq '{checks: .required_status_checks.contexts, strict: .required_status_checks.strict,
         reviews: .required_pull_request_reviews.required_approving_review_count}'
gh api repos/<owner>/<repo>/rulesets --jq '.[] | select(.enforcement=="active") | {id, name}'
# then, per active ruleset id:
gh api repos/<owner>/<repo>/rulesets/<id> --jq '.rules'
```

Union the required checks from **both**. Record from the rulesets' `pull_request` rule:
- `required_approving_review_count`
- `dismiss_stale_reviews_on_push` — if **false**, an approval older than the head commit still counts. Do not treat "approval predates head" as a blocker.
- `required_review_thread_resolution` — if **false**, unresolved threads do **not** block merging. They are advisory only.
- `allowed_merge_methods`

State the discovered gates in one line before classifying. If a ruleset is `"enforcement": "disabled"`, ignore its rules but note it exists.

> Real example of why: on `ashbyhq/Ashby`, branch protection lists only `Danger`. The `ci-gate` check — equally blocking — comes from a separate active ruleset. Reading protection alone under-reports the gates.

---

## 3. Fetch (the naive call fails at scale)

`gh pr list --limit 1000` with `statusCheckRollup` returns **502**, and paginated GraphQL over ~300 PRs returns **504**. `statusCheckRollup` alone is ~30 KB per PR. Don't fight it — split the work:

```bash
# 1. Enumerate (paginates internally, cheap)
gh search prs --repo <owner/name> --state open --created '>=<date>' \
  --limit 500 --json number,title,author,createdAt,updatedAt,isDraft,labels > search.json

# 2. Hydrate in parallel, one PR per call, resumable
#    fetch_one.sh: skip if output already exists, delete partial output on failure
jq -r '.[].number' search.json | xargs -P 10 -n 1 ./fetch_one.sh
```

Per PR, request: `number,title,author,createdAt,updatedAt,isDraft,mergeable,mergeStateStatus,reviewDecision,headRefName,baseRefName,labels,additions,deletions,changedFiles,reviews,statusCheckRollup`.

Make the per-PR script **idempotent** (`[[ -s "$out" ]] && exit 0`) so a partial run resumes for free. Add `--author <login>` to the search when scoped.

---

## 4. Classify mechanically — first match wins

Order matters: each PR gets the **one** gate it must clear next, so the bucket is an instruction.

1. **Hard block label** (`do not merge`, `dnm`, `blocked`) → `BLOCKED_LABEL`.
2. **Stacked** — `baseRefName` matches another *open* PR's `headRefName` → `STACKED`. Build the `headRef → number` map from the fetched set first; without it these masquerade as ready or awaiting-review. Follow parents transitively to find the **root**.
3. **`mergeable == "CONFLICTING"`** or `mergeStateStatus == "DIRTY"` → `CONFLICTS`.
4. **`reviewDecision == "CHANGES_REQUESTED"`** → `CHANGES_REQUESTED`.
5. **A §2-required check failing** (or a merge-blocking workflow check like `do-not-merge`/`qa-failed`) → `CI_RED`.
6. **A §2-required check still running** → `CI_PENDING`.
7. **Not approved** → `NEEDS_REVIEW`.
8. **A non-required check failing** → `READY_WITH_NOISE` — mergeable; name the check.
9. **`mergeStateStatus == "BLOCKED"`** with no cause found above → `BLOCKED_OTHER`. Investigate; don't report it as ready.
10. Otherwise → `READY`.

**Draft is a tag, not a bucket.** `isDraft` never changes which bucket a PR lands in — classify it on its gates like any other open PR, and mark it `[draft]` next to the title in the report. Draft state is a one-click author decision, and hiding those PRs in a bucket of their own buries the ones that are already green. The only adjustment: a draft in `READY` needs "Ready for review" clicked before the merge button works, so say that where you name its next action.

**Leverage.** For every `STACKED` root, count its transitive dependents. A root with 3+ dependents that is merely `NEEDS_REVIEW` is the highest-value review in the set — reviewing one releases the chain. Surface these explicitly.

---

## 5. Judgment pass (`--deep`)

Only the mergeable-looking set (`READY`, `READY_WITH_NOISE`, `BLOCKED_OTHER`) plus the blocked buckets need this. Batch 6–8 PRs per subagent; a fan-out of ~11 agents covers ~60 PRs. Run the three lanes concurrently.

### 5a. Identify auto-approval bots first — this reframes everything else

**Do this before drawing any conclusion from `reviewDecision: APPROVED`.** Many orgs auto-approve low-risk PRs, and GitHub reports that identically to a human review.

```bash
gh api graphql -F number=<N> -f query='query($number:Int!){repository(owner:"<o>",name:"<r>"){
  pullRequest(number:$number){reviews(last:40){nodes{state submittedAt author{login} body}}}}}'
```

A bot approval is usually an **empty body** from a `*-automation` / `*[bot]` account across unrelated PR types. When you find one, **read the workflow that produces it** (`grep -rl <bot-login> .github/workflows/`, then follow the action it calls — often an external repo readable via `gh api repos/<org>/<repo>/contents/<path> --jq '.content' | base64 -d`).

You are answering two questions:
1. **What makes a PR eligible?** (author allowlist, path rules, keyword rules, branch pairs)
2. **Does it re-evaluate and dismiss on push?**

If it **dismisses on push**, then a bot approval older than the head commit means the rules *still passed at the last push*. It is **not stale**, and counting it as such produces mostly false positives.

The real exposure is different, and worth reporting on its own: eligibility rules read **paths and words, not logic**. A PR can be rewritten top to bottom, stay eligible, and merge with **no human having read the final diff**. Cross-tabulate "substantively rewritten after approval" against "no human ever approved" — that intersection is the finding.

> On `ashbyhq/Ashby` this is `ashby-automation` running `optional_human_review`: eligible when the author is on an allowlist **and** the diff avoids sensitive paths (GraphQL, migrations, models), sensitive words, and restricted branch pairs. It re-runs on every push and dismisses its own approval when a PR stops qualifying. Applying the naive stale-approval rule here gave 34 false positives against 2 real ones.

### 5b. Post-approval drift

For each PR whose head moved after its latest approval, have an agent diff approval-time against head and rule **trivial** (merge from base, lint/format, comment or test-only) vs **substantive** (production logic, new files, behavior change, migration, flag change). Require concrete evidence — commit subjects and file paths.

Watch for a **force-push that orphans the approved commit**: if the approved SHA is no longer an ancestor of head, no reviewed state exists at all. Flag those hardest. Also flag approvals landing seconds after a force-push — that's the bot, and it means nobody looked.

### 5c. Review threads

Fetch `reviewThreads` and drop `isResolved` and `isOutdated` ones. **Filter bot authors before counting** — expect the large majority to be bots (`coderabbitai`, `*-lucille-bot`, `github-actions`, `*[bot]`). Typical split is ~85–90% bot noise. Judge only human threads: *blocking* (a change or concern with no resolving reply) vs *non-blocking* (nit, praise, answered question, or the author's own annotation). Author self-annotations are common and are never blocking.

If §2 found `required_review_thread_resolution: false`, say plainly that none of these block the merge button.

### 5d. Blockers

For each blocked PR, get the **specific** failing check by name (`gh pr checks <N>`) and a concrete next step with an owner (author / reviewer / ci-or-infra) and rough effort. When only the check name is visible, report the check name and mark effort unclear — never invent a root cause.

---

## 6. Report

Lead with the count that answers the question, then the buckets as actions. For a **self-scoped** run (the default), name buckets as verbs — *Merge now*, *Check then merge*, *Chase a reviewer*, *Fix CI*, *Resolve conflicts*, *Waiting on parent* — and order them by proximity to landing. For `--all`, keep state names and add the leverage list from §4.

Tag drafts inline (`#412 [draft] Fix login redirect`) wherever they appear. Never split them into their own section.

Always state:
- The gates discovered in §2, in one line.
- Whether approvals are human or bot, and what the bot policy actually means.
- For anything called ready: what you verified, not just that it's green.

Call out separately, because these are the findings a status dump hides:
- Drafts that landed in `READY` — green, approved, one click from merging. Usually the cheapest wins on the list.
- Stack roots gating 3+ dependents.
- Substantively-rewritten-after-bot-approval PRs.

Flag confidence honestly: gate data and bot policy are verified from source; agent readings of review text and CI output are not independently confirmed. Say which is which. Follow the Voice rules in `~/.claude/CLAUDE.md`.

---

## 7. Artifact (`--artifact`)

Only when `--artifact` (or `--web`) is passed. Without the flag there is no page, and the terminal report is the whole deliverable.

Build it **after** §6's report is written, from the same records. It never shows a PR the report doesn't, and never a verdict the report doesn't. Load the `artifact-design` skill before writing the file.

**Fixed identity.** These three keep the URL and the browser tab stable across reruns, so publishing again updates the same board instead of minting a new one:

| | Value |
|---|---|
| File path | `<scratchpad>/prcheck-<owner>-<repo>.html` |
| `<title>` | `prcheck — <owner>/<repo>` |
| `favicon` | `🚦` |

Same repo → same path → same URL. Never date-stamp the filename.

**One table, one row per PR**, in §6's bucket order, and by number ascending inside a bucket. Columns, left to right:

1. **PR** — `#412`, linked.
2. **Title** — with `[draft]` inline. Draft is never its own column, section, or filter-by-exclusion.
3. **Bucket** — as the §6 verb (*Merge now*, *Chase a reviewer*, …), not the raw §4 constant.
4. **Next action** — the specific one from §5d: the failing check by name, the reviewer to chase, the parent to wait on.
5. **Author**
6. **Approval** — `human`, `bot`, `bot (rewritten since)`, or `none`, per §5a.
7. **Idle** — days, clamped at 0.
8. **Size** — `+adds / -dels` across `changedFiles`.

**Filters** are chips above the table, client-side, and combinable: one per bucket, plus `draft`, `bot-approved`, and one per author. Every chip carries its count. A chip that would match nothing renders disabled rather than hidden — a zero is information.

**Mark what isn't verified.** Gates, buckets, and bot policy come from the API; §5b and §5c readings do not. Give agent judgments a visually distinct style and a legend that says so, matching §6's confidence rule.

Publish once, complete. Print the URL as the last line of the report, after the terminal output and never in place of it.

Empty set → no page. Say so in one line instead.

---

## 8. Pitfalls

- **zsh `noclobber`** — plain `>` fails with `file exists`. Use `>|` for overwrites and `2>|` for stderr in every generated script.
- **Foreground `sleep` is blocked** by the harness. To wait on background work, use `run_in_background` with an `until` loop, and grep the workflow journal for `"type":"result"` — **not** `"completed"`.
- **Don't poll a running fan-out turn after turn.** Each poll re-reads the whole context from cache; a handful of `grep` turns is pure waste. Arm one waiter and stop.
- **Negative "idle days"** mean the PR was updated after your reference timestamp. Clamp to 0.
- **`reviewDecision: APPROVED` is not "a person approved."** See §5a.
- **`mergeStateStatus: BLOCKED` with everything green** usually means an unmet gate you didn't discover in §2. Go back and re-read the rulesets.
- **Drafts return `mergeStateStatus: "DRAFT"`**, which masks the `BLOCKED` that rule 9 keys off. Classify a draft on its checks and `reviewDecision` alone; don't read the missing `BLOCKED` as proof nothing is wrong.
- **A `stacked` label can be stale** — trust the `baseRefName` → open-PR map, not the label.
- **Don't publish a half-built artifact.** §7 runs after the report is complete, not alongside it. Redeploying the same file path keeps the URL.

---

## 9. Success criteria

- Every PR in range lands in exactly one bucket, and the buckets sum to the fetched count.
- The required checks came from **both** branch protection and active rulesets.
- Any auto-approval bot in the set was identified and its dismissal semantics read from its workflow before approvals were interpreted.
- Stacked PRs are attributed to their parent, not reported as independently ready.
- Every "ready" claim names what was verified; every blocked PR names its check and next step.
- With `--artifact`: the board carries every row the report does, at §7's fixed path, and its URL is the last line of the output. Without it: no page.
