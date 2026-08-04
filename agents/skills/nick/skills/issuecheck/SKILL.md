---
user-invocable: true
description: "Triage open issues by what actually blocks each one from being done — real label-taxonomy discovery, linked-PR awareness, dependency-chain detection. Defaults to issues assigned to you in the current repo, last 30 days. Also takes an explicit list of issue numbers or URLs. Read-only. Flags: `--all-repos`, `--assignee <login>`, `--author <login>`, `--unassigned`, `--days N`, `--since <date>`, `--all-time`, `--repo <owner/name>`, `--label <name>`, `--milestone <name>`, `--deep`, `--quick`, `--artifact`, `--json`."
---

# issuecheck

Answer "what can I actually pick up, and what's holding up the rest" for a set of open issues — grounded in the repo's **real** triage vocabulary, not assumed label names.

`$ARGUMENTS` selects the issue set and the depth. Default is **issues assigned to you** in the current repo, active in the last 30 days. The deliverable is a per-issue next action, not a status dump: every issue lands in exactly one bucket named for the thing that must happen next.

The expensive half of this workflow is judgment on the ones that look ready. The cheap half — classifying every issue mechanically — covers most of the ground. Do the cheap half first, always; spend agents only on what survives it.

Sibling skill: `/nick:prcheck` does this for pull requests. Where an issue's next action is a PR, hand off rather than duplicating that analysis.

---

## 1. Inputs

### Explicit targets (short-circuits every selector below)

Any positional token that names an issue switches the run to **target mode**: triage exactly those, in the order given, ignoring scope and time flags. Say in one line that the selectors were ignored.

Accepted forms, space- or comma-separated: `#412`, `412`, `owner/name#412`, and full issue URLs (`https://github.com/<o>/<r>/issues/412`). A URL or `owner/name#N` carries its own repo, so one list may span repos. Each number must be a positive integer.

- A target that resolves to a **pull request** instead of an issue → say so, skip it, and point at `/nick:prcheck`. GitHub shares one number space between the two.
- A target that is **closed** → still report it, in the `CLOSED` bucket, with how it closed (completed vs not planned). You asked about it for a reason.
- A target that doesn't exist or is in a repo you can't read → name it and continue with the rest. One bad number never aborts the run.

### Selectors (target mode off)

**Who** (mutually exclusive; default `--assignee @me`):
- *neither* → **default**: assigned to you. Resolve your login once with `gh api user --jq '.login'`.
- `--assignee <login>` — one assignee. `@me` accepted and resolves as above.
- `--author <login>` — issues *filed by* that login, regardless of assignee.
- `--unassigned` — open issues with no assignee. Pairs well with `--label`.

**Where** (default: current repo):
- `--repo <owner/name>` — a specific repo. Default is the current repo (`gh repo view --json nameWithOwner`). Reject a value without exactly one `/`.
- `--all-repos` (alias `--everywhere`) — every repo you can see, via `gh search issues`. Group the report by repo. Note the tradeoff in one line: the §5a relevance check reads code, so it only runs for the repo you're standing in.
- If you're not in a git repo and neither flag is given, say so and run as `--all-repos`.

**When** (mutually exclusive; default `--days 30`):
- `--days N` — **updated** within the last N days. N must be a positive integer; reject anything else.
- `--since <date>` — updated on or after an ISO date (`YYYY-MM-DD`). Wins over `--days` if both are given; say so in one line.
- `--all-time` — no date filter.

Filter on `updated`, not `created` — a two-year-old issue you're actively working is in scope, and a two-year-old issue nobody has touched is not. Bot activity inflates `updatedAt` (§8), so this filter runs wide on purpose; §4 sorts it out and the report shows **human** idle days.

Always print the count you excluded: `12 assigned issues older than 30 days not shown — --all-time to include.` A hidden queue is the thing this skill exists to prevent.

**Narrowing** (compose freely with the above):
- `--label <name>` — repeatable; AND semantics. Pass the raw label name as its own argv argument, spaces and all.
- `--milestone <name>` — one milestone.

**Depth** (mutually exclusive; default `--deep` when the set is ≤60 issues, else `--quick`):
- `--deep` — run §5's judgment pass (still-reproduces check, scoping gaps, who holds the ball, effort read).
- `--quick` — mechanical only (§2–§4). Fast, no subagents, still correct about what's blocked.

**Output** (compose freely):
- `--artifact` (alias `--web`) — also publish a filterable board. Default is terminal-only.
- `--json <path>` — write the enriched per-issue records for later reuse.

Examples:
- `/nick:issuecheck` → your open issues in this repo, active in the last 30 days, deep.
- `/nick:issuecheck 412 588 https://github.com/o/r/issues/33` → just those three, any assignee, any age.
- `/nick:issuecheck --all-repos --all-time --quick` → your whole assigned queue everywhere, mechanical.
- `/nick:issuecheck --unassigned --label p0 --days 7` → unclaimed urgent work from this week.
- `/nick:issuecheck --all-repos --days 7 --artifact` → your queue everywhere this week, with a published board.

**Shell safety.** `<login>`, `<owner/name>`, `<name>`, `<date>`, and every issue number reach `gh`/`git`. Pass each as a standalone argv argument, never string-formatted into a command. Reject any value containing a quote, `` ` ``, `$`, `\`, `;`, `|`, `&`, `<`, `>`, `(`, `)`, `{`, `}`, a newline, or a control character, and reject any value beginning with `-` (option injection). Issue numbers must match `^[0-9]+$` before they reach a command line — a URL-derived number included.

---

## 2. Discover the real triage vocabulary — never assume it

**This step is not optional and its result is not guessable.** Every repo invents its own label names for the same handful of states. `blocked` may be `on-hold`, `needs-info` may be `awaiting-response` or `status: reporter`. Hardcoding names silently mis-buckets everything.

```bash
gh label list --repo <owner/name> --limit 300 --json name,description,color
gh api repos/<o>/<r>/milestones --jq '.[] | {title, due_on, open_issues}'
```

Read the real list and map names onto **roles**. The role is what §4 keys off; the name is repo-local trivia:

| Role | Names that usually carry it |
|---|---|
| `blocked` | `blocked`, `on hold`, `do not work`, `dnw`, `parked` |
| `needs-info` | `needs info`, `needs repro`, `awaiting response`, `question`, `more-information-needed` |
| `needs-decision` | `needs design`, `needs product`, `discussion`, `rfc`, `proposal` |
| `priority` | `p0`–`p3`, `sev1`–`sev3`, `urgent`, `critical` |
| `triage-state` | `needs triage`, `untriaged`, `ready`, `accepted` |
| `wontfix-ish` | `wontfix`, `invalid`, `duplicate`, `stale` |

Use the label **description** as much as the name — it usually states the intent outright. Match case-insensitively and ignore separators (`needs-info`, `needs_info`, `needs info`, `status: needs info` are one role).

State the mapping in one line before classifying, and **name the roles that found no label**: `no blocked-role label in this repo — rule 5 will never fire.` A role with no label is not the same as a role with nothing in it, and only one of those is worth the user knowing.

If the repo uses **issue types** (the `issueType` field from §3, no extra call) or **projects** (`gh project list --owner <o>`), read those too and treat their status field the same way — a project column named `Blocked` carries the `blocked` role as much as a label does. Both surfaces are newer than labels and may come back empty or unsupported; degrade quietly and note it once.

---

## 3. Fetch

**One call gets nearly everything. Don't hand-roll GraphQL for it.** `gh issue list --json` exposes linked PRs and dependencies as first-class fields — the two things that decide the top four buckets:

```bash
gh issue list --repo <owner/name> --state open --assignee <login> --limit 300 \
  --search 'updated:>=<date>' \
  --json number,title,author,assignees,createdAt,updatedAt,labels,milestone,state,stateReason,url,issueType,closedByPullRequestsReferences,blockedBy,blocking,parent,subIssues,subIssuesSummary
```

Keep the `--json` value on **one line**. A `\`-continuation inside the comma list works only if the next line starts at column 0; any indentation injects a space and the call fails. `--assignee`, `--label`, `--milestone`, and `--search` all compose in a single call.

- `closedByPullRequestsReferences` → rules 2 and 3. **It returns `number`, `url`, and `repository` — no `state` and no `isDraft`.** Merged-vs-open needs a second call; see below.
- `blockedBy` / `blocking` → rule 4 and the leverage count, straight from GitHub's dependency graph. Both come back as `{nodes, totalCount}`; key on `totalCount`, and if the nodes don't carry a state, resolve their numbers like the PRs below.
- `parent` / `subIssues` / `subIssuesSummary` → the rest of rule 4. Summary is `{completed, total, percentCompleted}`.
- `stateReason` → `completed` vs `not planned` for rule 1. It is `""` on open issues, not null.
- `issueType` → null when the repo doesn't use types. Not an error.

**Resolve the referenced PRs in one batch.** Collect every number from every issue's `closedByPullRequestsReferences`, **dedupe across the whole set** (one PR routinely closes several issues), then hydrate each once, in parallel:

```bash
gh pr view <N> --repo <owner/name> --json number,state,isDraft,title,url,mergedAt
```

`state` is `MERGED` / `OPEN` / `CLOSED`. A `CLOSED`-unmerged PR is *not* rule 2 or 3 — the work was abandoned, so the issue falls through to whatever else applies, and the report should say a PR was attempted and dropped.

Verify these fields against `gh issue list --json` (with no value, it prints the supported list) before relying on them. They need **gh ≥ 2.97** and a host that supports issue dependencies and sub-issues; GHES lags. If a field isn't there, drop it from the query — a `--json` call naming one unknown field fails entirely and takes the whole run with it.

**Only when a field is genuinely unavailable**, fall back per signal and say so in the report, since the fallbacks are noisier: linked PRs → timeline cross-references → scanning body and comments for `#\d+`; dependencies → `- [ ] #123` task-list rows and `blocked by #123` prose. Resolve every number found to its current state — an unresolved `#123` is a mention, not a dependency.

`--all-repos` uses search, which spans repos and excludes PRs by default (don't pass `--include-prs`). It carries none of the rich fields above, so hydrate the survivors of §4 individually:

```bash
gh search issues --assignee <login> --state open --updated '>=<date>' \
  --limit 300 --json number,title,repository,author,createdAt,updatedAt,labels,url,isPullRequest
```

**Enumerate without `body` and `comments`.** Both are available on `gh issue list` and both are heavy across a few hundred issues. Fetch them only for the issues §4 sends to a judgment lane, one issue per call, in parallel. Make the per-issue script idempotent (`[[ -s "$out" ]] && exit 0`) so a partial run resumes for free.

---

## 4. Classify mechanically — first match wins

Order matters: each issue gets the **one** thing that must happen next, so the bucket is an instruction.

1. **Closed** (target mode only) → `CLOSED`. Report `completed` vs `not planned`; they mean opposite things.
2. **A merged PR references it, issue still open** → `LIKELY_DONE`. The work shipped and nobody closed the issue. Verify and close.
3. **An open PR references it** → `IN_REVIEW`. The code exists. Chase the review, don't rewrite it. Tag `[draft PR]` if the PR is a draft — draft state doesn't change the bucket, same as in `/nick:prcheck`.
4. **An open dependency** — `blockedBy.totalCount > 0` with at least one blocker still open, an open `parent`, or an open entry in `subIssues` → `BLOCKED_BY_ISSUE`. Name the blocker. Follow `blockedBy` transitively to the **root**. A `blockedBy` whose blockers all closed is not blocked; that's a stale-graph finding worth reporting.
5. **A `blocked`-role label or project status** (§2) → `BLOCKED_LABEL`.
6. **A `needs-info`-role label**, or the newest human comment is a question from someone other than the reporter with no reply since → `WAITING_ON_REPORTER`. Not your move.
7. **A `needs-decision`-role label** → `NEEDS_DECISION`. Name who decides if the thread says.
8. **A branch exists referencing the number with commits, but no PR** → `WIP_NO_PR`. Started and dropped. Current repo only — `git branch -a --list '*<number>*'`. Say how stale the branch is.
9. **No repro steps and no acceptance criteria** in body or comments → `NEEDS_SCOPING`. Nobody can start this, including you.
10. Otherwise → `READY`. Nothing is blocking it; pick it up.

**Why linkage outranks labels.** Rules 2–4 read *evidence of state* (a PR merged, a dependency is open); rules 5–7 read *someone's assertion about state*, which goes stale the moment the situation changes. A `blocked` label on an issue whose blocker merged last month is wrong, and the merged PR proves it. Trust the link over the label, and say when they disagree — that disagreement is itself a finding.

**Leverage.** For every `BLOCKED_BY_ISSUE` root, count its transitive dependents. A root with 3+ dependents that is itself `READY` and **unassigned** is the highest-value pickup in the set: doing one issue releases the chain. Surface these explicitly, even when they're outside the selector (a blocker assigned to someone else still gates your work — name it and who owns it).

---

## 5. Judgment pass (`--deep`)

Only `READY`, `NEEDS_SCOPING`, `LIKELY_DONE`, and `WIP_NO_PR` need the full pass; the blocked buckets need 5c only. Batch 6–8 issues per subagent and run the lanes concurrently.

### 5a. Is it still real? — do this before calling anything ready

**Issues rot.** The single most expensive outcome of this skill is sending someone to work an issue that the code fixed eight months ago. For each `READY` and `LIKELY_DONE` issue, have an agent locate the code the issue describes and rule:

- **reproduces** — the described path still behaves as reported. Cite `file:line`.
- **likely fixed** — the path changed in a way that addresses it. Cite the commit or `file:line`, and say what would confirm it.
- **can't tell** — the issue is too vague to locate, or the area was rewritten. This is a legitimate verdict; say it plainly.

**Never rule "fixed" without a citation.** A guess here closes real bugs. When the verdict is `likely fixed`, the report says *verify and close*, never *closed*. Only runs for the repo you're in; for `--all-repos` say the check was skipped rather than implying it passed.

### 5b. Is it actually scoped?

For `NEEDS_SCOPING` and `READY`, check whether a competent stranger could start: reproduction steps or a concrete trigger, expected vs actual, and some notion of done. Output the **specific missing question**, ready to paste — `what browser and what did you expect instead?` beats *needs more detail*.

### 5c. Who holds the ball?

Fetch comments and **filter bots before counting** (`github-actions`, `*[bot]`, `*-automation`, stale-bots, linkers). Expect most of the volume to be bots. From the human comments only, determine the ball-holder: **you** (a question you never answered), **the reporter** (info requested, never supplied), or **a third party** (name them). Compute **human idle days** — time since the last non-bot comment — and use that everywhere the report shows staleness. Clamp negatives to 0.

An issue whose last human word was a question to the reporter 60 days ago is not stale-and-neglected; it's answered and closeable. Say which it is.

### 5d. Effort read

For each `READY` issue: rough size (one-line / an afternoon / needs a plan) and the **first file to open**. Low confidence is fine — say so — but the first file is what turns triage into work actually starting.

---

## 6. Report

Lead with the count that answers the question, then the buckets as actions, ordered by proximity to done: *Close it* · *Chase a review* · *Pick this up* · *Finish the branch* · *Ask the reporter* · *Get a decision* · *Unblock the parent* · *Scope it*. For `--all-repos`, group by repo and keep this order inside each group.

Tag inline, never as separate sections: `#412 [p0] [draft PR] [idle 94d] Fix login redirect`.

Always state:
- The label→role mapping from §2, in one line, including roles with no label.
- How linked PRs were resolved (GraphQL field, timeline, or comment scan) when it wasn't the first method.
- For anything called ready: that §5a says it still reproduces, and the `file:line` that says so.

Call out separately, because these are the findings a status dump hides:
- `LIKELY_DONE` — shipped work still holding an open issue. Usually the cheapest wins on the list.
- Stack roots gating 3+ issues, especially unassigned ones.
- Issues where the label and the linkage disagree (§4).
- Anything idle >90 human-days that is nonetheless `READY` — either it doesn't matter or it's been forgotten, and both deserve a decision.

End with the handoff, so triage turns into work in one keystroke: `/nick:investifix #412` for a `READY` issue, `/nick:prcheck` when `IN_REVIEW` dominates the list. Suggest; never run them.

Flag confidence honestly: label mapping, linked PRs, and dependency state are verified from the API; agent readings of code relevance, scoping, and effort are not independently confirmed. Say which is which. Follow the Voice rules in `~/.claude/CLAUDE.md`.

---

## 7. Artifact (`--artifact`)

Only when `--artifact` (or `--web`) is passed. Without the flag there is no page, and the terminal report is the whole deliverable.

Build it **after** §6's report is written, from the same records. It never shows an issue the report doesn't, and never a verdict the report doesn't. Load the `artifact-design` skill before writing the file.

**Fixed identity.** These three keep the URL and the browser tab stable across reruns, so publishing again updates the same board instead of minting a new one:

| | Value |
|---|---|
| File path | `<scratchpad>/issuecheck-<owner>-<repo>.html`, or `<scratchpad>/issuecheck-<login>-all-repos.html` under `--all-repos` |
| `<title>` | `issuecheck — <owner>/<repo>`, or `issuecheck — all repos` |
| `favicon` | `🧭` |

Same scope → same path → same URL. Never date-stamp the filename.

**One table, one row per issue**, in §6's bucket order, and by number ascending inside a bucket. Under `--all-repos`, add a leading **Repo** column and group by repo first, keeping bucket order within each group. Columns:

1. **Issue** — `#412`, linked.
2. **Title** — with `[draft PR]` inline where rule 3 applied.
3. **Bucket** — as the §6 verb (*Close it*, *Pick this up*, …), not the raw §4 constant.
4. **Next action** — the specific one: the PR to chase, the blocker to unblock, §5b's paste-ready question, or §5d's first file to open.
5. **Blocked by** — rule 4's transitive **root**, linked. Empty when nothing blocks it.
6. **Assignee** — `—` when unassigned.
7. **Labels** — each with its §2 role as a suffix or tooltip, since the names are repo-local trivia and the role is the part that means something.
8. **Idle** — **human** idle days from §5c, clamped at 0. Never `updatedAt`.
9. **Effort** — §5d's read. Empty when the pass didn't run; never guessed to fill the column.

**Filters** are chips above the table, client-side, and combinable: one per bucket, plus `unassigned`, plus `leverage` (§4 roots gating 3+ dependents), plus one per repo under `--all-repos`. Every chip carries its count. A chip that would match nothing renders disabled rather than hidden — a zero is information.

**Mark what isn't verified.** Label roles, linked PRs, and dependency state come from the API; §5a relevance, §5b scoping, and §5d effort do not. Give agent judgments a visually distinct style and a legend that says so, matching §6's confidence rule.

Two things from the terminal report belong on the page as well: the §2 label→role mapping including the roles with no label, and §1's excluded-by-date count. A board that hides the rest of the queue is the exact failure this skill exists to prevent.

Publish once, complete. Print the URL as the last line of the report, after the terminal output and never in place of it.

Empty set → no page. Say so in one line instead.

---

## 8. Pitfalls

- **`updatedAt` is not activity.** Stale-bots, label edits, and project moves all bump it. An issue "updated 2 days ago" can be untouched by a human for a year. Filter on `updatedAt` (§1) but *display* human idle days from §5c, and never call an issue active on `updatedAt` alone.
- **Issues and PRs share one number space.** `#412` may be a PR. In target mode, probe and redirect (§1); never report a PR as an issue.
- **`--assignee` misses work that's really yours** — team-assigned issues, ones where you're only mentioned, and ones assigned to a bot on your behalf. State this scope limit in the report rather than implying the queue is complete.
- **`needs-info` labels go stale silently.** Check whether the reporter replied *after* the label was applied. If they did, the label is wrong and the ball is back with you — that's a `READY`, not a `WAITING_ON_REPORTER`.
- **Closed ≠ done.** `not planned` means someone rejected it. Never fold it in with `completed`.
- **A `blocked` label outlives its blocker.** Trust the dependency's actual state (§4).
- **Don't rule "fixed" from the issue text.** §5a requires a citation from the current tree. No citation, no verdict.
- **zsh `noclobber`** — plain `>` fails with `file exists`. Use `>|` for overwrites and `2>|` for stderr in every generated script.
- **Foreground `sleep` is blocked** by the harness. To wait on background work, use `run_in_background` with an `until` loop, and grep the workflow journal for `"type":"result"` — **not** `"completed"`.
- **Don't poll a running fan-out turn after turn.** Each poll re-reads the whole context from cache. Arm one waiter and stop.
- **Don't publish a half-built artifact.** §7 runs after the report is complete, not alongside it. Redeploying the same file path keeps the URL.

---

## 9. Success criteria

- Every issue in range lands in exactly one bucket, and the buckets sum to the fetched count.
- Label roles came from the repo's **actual** label list, and roles with no matching label were named as such.
- Linked PRs were resolved before any issue was called ready or blocked, and the method was stated when it wasn't the primary one.
- Dependency chains are attributed to their root, not reported as independently ready.
- Nothing is called ready without a §5a verdict, and nothing is called fixed without a citation.
- The excluded-by-date count was printed, so the hidden part of the queue is visible.
- With `--artifact`: the board carries every row the report does, at §7's fixed path, and its URL is the last line of the output. Without it: no page.
