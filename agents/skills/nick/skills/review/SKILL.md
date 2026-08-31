---
user-invocable: true
description: "Adversarial multi-agent code review of a branch or PR. Deep mode (default) fans out independent lenses, verifies each finding, and triages existing PR comments. Light mode is a fast single-pass read. Report stays in the terminal. Flags: `--force`, `--light`/`--quick`, `--reply`/`--resolve`."
---

# Code Review

Review a branch's changes or a specific PR. Two modes:

- **deep** (default) — independent agents attack the diff through different lenses, verifiers confirm/refute each finding, existing PR comments get triaged, and a consolidation agent converges one report.
- **light** — fast single-pass read of the diff. No fan-out, no verification agents, no comment triage.

Every review is **checkpointed** to `.ignore/reviews/<slug>.md` so re-runs are cheap — §0 has the path table.

> The first full review must be **immaculate** — every later run builds on it, so don't cut corners.

> **Prose for humans** (report, summaries, posted text) gets a de-slop pass per the Voice rules in `~/.claude/CLAUDE.md`. Never change a finding, severity, `file:line`, or verdict.

## Inputs

Parse `args` for:
- **Target** — one or more PR refs (`#107704`, `107704`, or a GitHub URL). If none, review the current branch. **Multiple targets** (`#117138 and #117140`, `both PRs`, a list) are reviewed one at a time, each with its own slug, checkpoint, and full §6 report — never merged into one report, never silently narrowed to the first. `both PRs` resolves to the PRs for the branches this session has touched; if that's ambiguous, name the candidates and ask before spending agent time.
- **Mode** — `light` (aliases `--light`, `--quick`) selects light mode; anything else is deep.
- **`--force`** (alias `--fresh`) — ignore any checkpoint and run a full review from scratch, then overwrite it.
- **`--reply`** / **`--resolve`** — *automated reviewers only.* Reply to / resolve the bot threads (CodeRabbit, Lucille, etc.) triaged in §4. Never on human comments, never on your own initiative — the flag (or an explicit ask) is required. Combine to reply then resolve.

Examples:
- `/nick:review` → cached / incremental / full review of the current branch (per checkpoint)
- `/nick:review #107704` → same, for PR 107704
- `/nick:review light` → light-mode review of the current branch
- `/nick:review --force` → full deep review, ignoring any checkpoint
- `/nick:review #107704 --reply --resolve` → deep review, then reply to and resolve the bot threads; the report still stays in the terminal

---

## 0. Checkpoint — resolve & short-circuit

Do this **first**, before spending any agent time. The checkpoint lives at `.ignore/reviews/<slug>.md`.

**Resolve the slug** — must be **deterministic**: the same target maps to the same slug every run. Each kind gets a reserved prefix:
- PR target → `pr-<number>` (e.g. `pr-107704`)
- Named branch → `branch-<sanitized>` (`/`→`-`, non-`[A-Za-z0-9._-]` stripped; `feat/email-notifs` → `branch-feat-email-notifs`). Empty `<sanitized>` → `branch-<short-head-sha>`. Branches that sanitize alike still collide — the target guard below is the backstop.
- Detached HEAD / generic branch (`main`, `develop`) with no PR → `detached-<short-head-sha>`. New commits yield a new slug, so these get CACHED or FULL, never INCREMENTAL. Never use a model-written title.

**Cross-repo target.** If the target is a GitHub URL for another repo, parse its `owner/repo` (and PR number) and `export GH_REPO=<owner>/<repo>` for the whole run — every `gh` call in the run then targets that repo instead of the current directory's. Also pass the GraphQL `owner`/`repo` vars explicitly. (`gh api` has no `--repo` flag, so `GH_REPO` is the portable way.)

**Current head SHA:** PR → `gh pr view <number> --json headRefOid -q .headRefOid`; branch → `git rev-parse HEAD`.

**Pick the path:**
1. **`--force`** → **FULL** review. Skip the rest of §0.
2. **No checkpoint file** → **FULL** review (first time).
3. **Checkpoint exists** — read its frontmatter (`target`, `sha`, `base`, `base_sha`, `mode`, `verdict`, `date`, `last_activity`). Throughout, **"mode" means the mode requested *this* invocation**, not the stored `mode`.
   Three guards run before any SHA comparison. If any trips → **FULL**, skip the rest of step 3.
   - **Target guard** — the stored `target` (§7) isn't the target you're reviewing now (slug collision, possibly on shared history so the SHA is even reachable). Never serve or build on another target's report.
   - **Depth escalation** — invocation is **deep** but checkpoint `mode` is `light`. A deep request must never be served from a single-pass report.
   - **Base guard** — recompute the base–HEAD merge-base (branch → `git merge-base <base> HEAD`; PR → the compare API's `merge_base_commit.sha`) and compare it to stored `base_sha`. Absent (old checkpoint) or moved (retarget / rebase / force-push) → FULL, note base drift: a changed base means the whole diff is unreviewed, and a `checkpoint_sha..HEAD` delta wouldn't show it. A plain fast-forward of the base leaves the merge-base unchanged, so this only fires on retarget/rewrite.

   Then compare SHAs:
   - **head SHA == checkpoint `sha`** → the code is unchanged, but PR activity may not be — check the PR's current state before caching:
     - **light mode, or no PR** → **CACHED**. Emit the stored report verbatim, prefixed with:
       `> Cached review — unchanged since <date> (SHA <short-sha>). Re-run with \`--force\` for a fresh review.`
       Then **stop** — no agents, no diffing beyond the SHA compare.
     - **deep mode with a PR** → fetch the PR's current comments/threads (the §1 queries). Let `newest_seen` = the newest timestamp among **all** of them (any author, resolved or not). Then compare the rest against `last_activity`, **excluding this skill's own replies** — identified *only* by the `<!-- review-skill:reply -->` sentinel §8 stamps in, never by author (the gh user may be the PR author self-reviewing):
       - **no new comments** → **CACHED**, as above, but rewrite `last_activity` to `newest_seen` if it advanced (own replies count toward `newest_seen`), so repeat serves stay idempotent.
       - **new comments since the checkpoint** (any author — inline, thread, or issue-level) → **COMMENT-DELTA**. Skip the review agents (§3); re-triage the new/updated comments (§4), reconcile them into the stored report (a new comment can raise an issue, resolve one, or change the verdict), emit it, then rewrite the checkpoint (§7, setting `last_activity` = `newest_seen`). Announce: `Cached code unchanged, but N new PR comment(s) since <date> — re-triaging comments only.`
   - **head SHA != checkpoint `sha`**, and the checkpoint `sha` is still reachable from head → **INCREMENTAL**. Reachability: branch → `git merge-base --is-ancestor <checkpoint_sha> HEAD`; PR → `gh api repos/{owner}/{repo}/compare/<checkpoint_sha>...<head_sha>` returns `status: ahead` (a rolled-back head reads as `behind`/`diverged` — not an ancestor → FULL, matching the branch check). Proceed to §1 in incremental posture.
   - **checkpoint `sha` unreachable** (force-push / rebase dropped it, or the compare diverged) → **FULL** review; note it in the report changelog.

**`--reply`/`--resolve` are never silently dropped.** They act on live threads, not the stored report. Whenever either (or an explicit ask) is present on a PR — including a CACHED serve, light mode (§2), and an empty diff (§1) — still run the §1 thread fetch + §4 triage + §8 against freshly-fetched threads, which carry the node `id`s §8 needs. Only §3–§5 stay skipped. Never improvise a resolve from the stored report — §6 records `file:line`, not a durable thread id.

Announce the path in one line (e.g. `Incremental review: 3 new commits since 2026-07-01 checkpoint.`).

---

## 1. Gather context (parallel)

First, **resolve the base branch** for a non-PR review (a PR carries its own `baseRefName`): `develop`→`main`→`master`→remote default (`git symbolic-ref --short refs/remotes/origin/HEAD`, stripped of `origin/`); first that exists **and isn't the branch under review** wins. **Never use the branch's own `@{u}`** — on a pushed feature branch `git diff @{u}...HEAD` sees only unpushed commits, so a synced branch reads empty → false APPROVE. **If none resolve, stop and ask — never proceed with an empty base**, which trips the empty-diff guard into a false APPROVE on unreviewed code. Record the base ref as `base` and the base–HEAD merge-base (`git merge-base <base> HEAD`; PR → the compare API's `merge_base_commit.sha`) as `base_sha` — the three-dot diff's real start (§0's base guard). Surface the base so the user can override, and use `<base>` everywhere below — never hard-code `develop`/`main`.

Run these together:
- **Diff** — PR: `gh pr diff <number>`; branch: `git diff <base>...HEAD`.
- **Delta diff** (INCREMENTAL only) — the changes since the checkpoint, which is all the new work you actually review:
  - Branch: `git diff <checkpoint_sha>..HEAD`
  - PR: `gh api repos/{owner}/{repo}/compare/<checkpoint_sha>...<head_sha> --jq '.files[].filename'` for the changed-file set, plus `gh pr diff <number>` for full context.
- **Commits** — PR: `gh pr view <number> --json commits`; branch: `git log --oneline <base>..HEAD` (INCREMENTAL: also `git log --oneline <checkpoint_sha>..HEAD`).
- **PR metadata** (if a PR exists): `gh pr view <number> --json number,title,url,body,headRefName,baseRefName`.
- **Project conventions**: locate all `CLAUDE.md` and `AGENTS.md` files in the repo.
- **Prior checkpoint report** (INCREMENTAL only): read `.ignore/reviews/<slug>.md` in full — its findings and comment dispositions are the baseline you carry forward.

**Deep mode + PR only — existing review comments.** Pull every existing comment/thread so it can be triaged in §4. Generalize across *all* reviewers (humans and bots alike — CodeRabbit, Lucille, etc. are just examples; don't special-case them):

```bash
# Issue-level + review summaries
gh pr view <number> --json reviews,comments

# Inline review comments
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate

# Unresolved review threads (resolution state requires GraphQL)
# PAGINATE to exhaustion: --paginate walks only the OUTER reviewThreads list.
# A thread with >100 comments is NOT auto-paged — see the follow-up rule below.
gh api graphql --paginate -f query='
query($owner:String!,$repo:String!,$pr:Int!,$endCursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100, after:$endCursor){
        pageInfo{ hasNextPage endCursor }
        nodes{
          id isResolved isOutdated path line
          comments(first:100){
            pageInfo{ hasNextPage endCursor }
            nodes{ id author{login} body }
          }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=<number>
```

For any thread whose `comments.pageInfo.hasNextPage` is true, run a follow-up query keyed on that thread `id` to fetch the remaining comments **before** §4 classifies it — never mark a thread bot-only on a partial comment list. And ensure `--paginate` walked the whole thread list; never cap at 100.

### Incremental posture

When §0 selected INCREMENTAL, the rule for §2–§5 is: **review the delta, not the whole diff again.**
- Only look for **new** issues inside the delta hunks. Don't re-scan or re-nitpick untouched code that was already reviewed.
- **Carry forward** every prior finding whose code the delta didn't touch, verbatim (re-anchor `file:line` if lines shifted).
- For prior findings whose code the delta **did** touch: re-check them — mark **resolved** (drop, note in the changelog) if fixed, else keep.
- Carry prior comment dispositions (§4) forward unchanged unless the delta touched the relevant code.
- Scope agent work to the delta files. If the delta is trivial (comment/whitespace/version bump, no behavior change), reconcile directly without fanning out agents.

**Empty-diff guard (all modes).** Before any fan-out, check the resolved diff. If it's empty or purely whitespace/comment (a net-zero revert, a branch with no commits ahead of base, or a detached HEAD sitting at base), skip §2–§5 entirely, emit a `No reviewable changes` report with an APPROVE verdict, and write the checkpoint. This also covers FULL runs (first review or `--force`), not just the trivial-delta case above. **Exception:** `--reply`/`--resolve` still run (§0); the guard applies to the review itself.

---

## 2. Light mode

If light mode is selected, do this and **stop** — skip §3–§5:
1. Read the diff and project conventions directly, or delegate one pass to `oh-my-claudecode:code-reviewer` (model: `sonnet`). In INCREMENTAL posture, read the **delta diff** and reconcile against the prior report.
2. Surface only concrete, high-confidence issues. Don't pad with nitpicks.
3. Emit the report (§6, existing-comment section omitted), then write the checkpoint (§7).

`--reply`/`--resolve` still run in light mode (§0): the §1 thread fetch + §4 triage + §8, nothing else.

---

## 3. Deep mode — adversarial review + verification

### 3a. Spawn review agents (parallel)

Launch **4 independent agents**. Each gets the full diff + project conventions (INCREMENTAL: the **delta diff** + the prior report), works in isolation, and reviews from an **adversarial** stance — assume the change is broken and try to prove it. In INCREMENTAL posture, tell every agent explicitly: **only report issues introduced or exposed by the delta hunks; never flag pre-existing untouched code.**

1. **Correctness & Logic** (`oh-my-claudecode:code-reviewer`, `sonnet`) — logic errors, off-by-one, null/undefined paths, race conditions, state corruption; missing error handling on unhappy paths; spec compliance (does the diff actually solve the stated problem?); type safety (narrowing gaps, unsafe casts); test adequacy for behavioral changes (is there a test that would fail without this diff, or does it pass either way?).
2. **Security & Trust Boundaries** (`oh-my-claudecode:security-reviewer`, `sonnet`) — OWASP Top 10 (injection, XSS, CSRF, broken authn/authz); hardcoded secrets, leaked credentials, permissive configs; trust-boundary violations (user input reaching privileged ops); dependency concerns (new deps, known CVEs).
3. **Edge Cases & Failure Modes** (`oh-my-claudecode:code-reviewer`, `sonnet`) — adversarial inputs (empty, huge, malformed, concurrent, boundary); resource exhaustion, partial failures, retries/idempotency; behavior when an external call times out or returns garbage.
4. **Architecture, Contracts & Maintainability** (`oh-my-claudecode:architect`, `sonnet`) — API contract changes and backward compatibility; abstraction fitness (right layer?); performance (algorithmic complexity, N+1, memory); convention compliance, anti-patterns, dead code, naming; **scope** — anything the stated problem doesn't require (speculative abstractions, unrelated refactors, unused params/exports, drive-by edits), and whether a smaller or more reusable change would do.

Each agent MUST output:

```
## [Lens Name] Review

### Issues
- **[CRITICAL|HIGH|MEDIUM|LOW]** `file:line` — Description
  Evidence: why this is a real problem (code path / input that triggers it)
  Suggestion: how to fix

### Positive Observations
- What's done well

### Verdict: APPROVE | CONCERNS | REQUEST_CHANGES
```

### 3b. Verify findings (along the way)

**Stop each lens the moment its report block arrives.** Call `TaskStop` on it right then — don't wait for the slowest to finish, and never spend a turn narrating an idle or duplicate agent message. A lens that has delivered its findings has nothing left to add; a fan-out left running is what ends up killed by hand, and a killed fan-out costs a `resume` round to recover. If a lens goes idle *without* a report, ask it once for its output, then stop it and cover that lens yourself.

As each lens reports, verify its non-trivial findings before they reach the report. For each CRITICAL/HIGH (and any disputed MEDIUM), spawn a verifier (`oh-my-claudecode:verifier`, `sonnet`) prompted **adversarially — try to refute the finding**:
- Confirm the triggering code path actually exists in the diff and is reachable.
- Default to `refuted` when the evidence is hand-wavy or the path can't be reproduced.
- Output: `{ finding, verdict: CONFIRMED | REFUTED | UNCERTAIN, reasoning }`.

Drop REFUTED findings. Keep CONFIRMED and UNCERTAIN (flag UNCERTAIN as such).

---

## 4. Deep mode — triage existing review comments

Hand the §1 comments/threads to a triage agent (`oh-my-claudecode:code-reviewer`, `sonnet`). For each **unresolved** comment or thread (any author), decide and record:
- **Disposition**: WORTH_ADDRESSING | NOT_WORTH_ADDRESSING | ALREADY_HANDLED | NEEDS_DISCUSSION
- **Reasoning** (1–2 sentences): cross-reference the current diff — the comment may already be fixed, a false positive, or a nit the project doesn't care about.
- **Thread ownership** (needed by §8): the thread node `id`, and whether it is **bot-only** (every comment authored by a bot) or **human-touched** (any comment by a human). A thread opened by a bot but replied to by a human is **human-touched** — §8 must never auto-resolve or auto-reply to it.

Don't auto-trust bot comments; assess them on merit like any other. In INCREMENTAL posture, only (re-)triage comments that are new or whose referenced code the delta touched; carry the rest forward.

---

## 5. Deep mode — consolidate

Hand all verified findings + comment dispositions (INCREMENTAL: **plus the carried-forward prior findings**) to a consolidation agent (`oh-my-claudecode:critic`, `opus`):
1. **Deduplicate** — merge findings hitting the same location or root cause (including a carried-forward finding a new agent re-flagged).
2. **Rank by severity** — CRITICAL > HIGH > MEDIUM > LOW.
3. **Confidence filter** — drop LOW items flagged by only one agent.
4. **Resolve conflicts** — if agents disagree, present both sides and make the call.
5. **Triage each finding by action** — tag every survivor `FIX NOW` (blocks this PR), `DEFER` (real, fine as a follow-up), or `IGNORE` (noise, wrong, or not worth the churn). Severity is how bad it is; this is whether Nick should act before merging, and the two come apart constantly. A finding nobody would act on gets cut, not listed. Answer this unasked — "any of these worth fixing, or okay to defer?" is not a question the report should leave open.
6. **Fold in comment triage** — surface WORTH_ADDRESSING (and NEEDS_DISCUSSION) items alongside the agents' findings.
7. **Reconcile with the checkpoint** (INCREMENTAL) — carry untouched prior findings forward, mark delta-fixed ones resolved, add only genuinely new delta findings. Produce a short changelog: `N new · M resolved · K carried forward`.

---

## 6. Final report

```markdown
## Code Review — [PR #N or branch name] (deep | light · full | incremental)

**PR:** #number (if exists)
**Reviewed SHA:** <short-sha> · **Base:** <base-ref>
**Commits reviewed:** N · **Files changed:** N
<!-- INCREMENTAL only: -->
**Delta since checkpoint (<prev-date>, <prev-short-sha>):** N new · M resolved · K carried forward

### Worth acting on
The edits themselves, not a restatement of the findings. One instruction per item carrying the literal value, path, or diff line to apply — not a bare `file:line`, not "consider". Mark each **required** or **optional**; if order matters (recompute-after-edit, parent-before-child) say so in one line. Close with a single offer: `Want me to apply <the required one>, or all N?` If none: `Nothing blocking — the rest is DEFER/IGNORE.`

### Critical / Must Fix
- [ ] `file:line` — issue — **FIX NOW** (Source: Agent 1, Agent 3 · Verified)

### High / Should Fix
- [ ] `file:line` — issue — **DEFER** (Source: Agent 2 · Verified)

### Medium / Consider
- [ ] `file:line` — issue — **DEFER**

### Low / Nitpicks
- `file:line` — observation — **DEFER**

`IGNORE` findings are never printed. Close the section with one line: `N findings dropped as IGNORE.`

### Resolved Since Last Review  (incremental only)
- ~~`file:line` — issue~~ — fixed by <commit/change>

### Existing Review Comments  (deep mode, PR only)
- **WORTH_ADDRESSING** `file:line` (@author) — comment summary → why it matters
- **NOT_WORTH_ADDRESSING** `file:line` (@author) — comment summary → why it's safe to skip
- **ALREADY_HANDLED** `file:line` (@author) — addressed by <commit/change>
- **NEEDS_DISCUSSION** `file:line` (@author) — comment summary → the open question

### What's Done Well
- Positive observations agreed on by 2+ agents

### Comment on this PR?
One line, unhedged: `Approve — nothing worth a comment.` or `Comment on N: <file:line>, <file:line>.`

For each one listed, draft the comment text — short, ready to paste, no preamble. Fold findings that resolve to the same thread into one comment. Only list something here you'd defend if asked "is that actually important?" A nit you'd shrug at is an `IGNORE`, and IGNOREs don't get printed.

### Merge readiness
**SAFE TO MERGE** | **SAFE WITH CAVEATS** | **NOT SAFE**
- Behavior this diff can change: <surfaces, or "nothing outside the new code path">
- Existing flows checked and unaffected: <flow — how you checked>
- Not checked: <gaps, or "nothing material">
- Solves the stated issue: yes / partially / no — name the issue and what's left over

### Verdict
**APPROVE** | **CONCERNS** | **REQUEST_CHANGES**
Rationale: 1–2 sentences.
Agent breakdown: Agent 1 (APPROVE), Agent 2 (CONCERNS), …
```

**Verdict rules:** any CRITICAL → **REQUEST_CHANGES**; 2+ HIGH → **REQUEST_CHANGES**; 1 HIGH or 3+ MEDIUM → **CONCERNS**; otherwise → **APPROVE**.

**Multi-target runs open with a verdict table**, before the first report — one row per PR: `| PR | Verdict | Merge readiness |`. Then the full per-PR reports in the order given, and one offer per PR at the close, each with a literal selector the user can type back (`#117138: apply`, `#117140: none`). "Are they all safe to merge?" must be answerable from the table alone.

**Merge readiness is never omitted** — deep or light, cached or fresh. "Is this regression-free and safe to merge?" is the question the review exists to answer, so answer it unasked; `APPROVE` alone reads as a code-quality verdict, not a merge decision. Name what you did *not* check rather than letting silence imply full coverage — an honest SAFE WITH CAVEATS beats a bare APPROVE. In light mode (`--quick`), emit it marked `unverified — light pass`.

---

## 7. Write the checkpoint (always, except a pure CACHED serve — which at most rewrites `last_activity`)

After producing the report — FULL and INCREMENTAL, deep and light — persist it so the next `/nick:review` is cheap.

1. `mkdir -p .ignore/reviews`, and make sure `.ignore/` is git-ignored (add to `.gitignore` or `.git/info/exclude` if not) so review artifacts never get committed.
2. Write `.ignore/reviews/<slug>.md` (overwriting any prior checkpoint) with frontmatter + the full §6 report as the body:

```markdown
---
target: "PR #107704"        # or "branch: feat/email-notifs"
slug: pr-107704
sha: <full 40-char reviewed head SHA>
base: develop               # base ref the diff was taken against
base_sha: <full base–HEAD merge-base SHA>   # required — §0's base guard compares against this
mode: deep                  # deep | light
verdict: CONCERNS
date: 2026-07-06            # today's date
last_activity: 2026-07-06T14:22:00Z   # §0's `newest_seen` — fetch-time high-water (deep + PR only; omit if no PR)
---

<the full report from §6>
```

`sha` must be the exact head SHA you reviewed — it's the CACHED-vs-INCREMENTAL key. Use today's date. Set `last_activity` = the §0 `newest_seen` and never advance it past the fetch — a reply you post afterward is excluded by the §8 sentinel, not by this watermark. Omit when there's no PR. A light run must not overwrite a deep checkpoint — if the stored `mode` is deep and this run is light, leave the checkpoint alone.

---

## 8. Deliver results (terminal by default — never post to the issue/PR unprompted)

**Hard default: display the report in the terminal only.** Don't post it as an issue/PR comment, and don't offer or ask. The checkpoint (§7) is all this skill writes by default. Post **only** when the user explicitly asks — and then **never interpolate the report into a shell command**: report bodies contain arbitrary code (a lone `EOF`, backticks, `$(…)`), so a heredoc or `--body "$(…)"` can truncate or execute it. Pass the body by file or stdin: `gh pr comment <number> --body-file <path>` (or `--body-file -`). Same rule for every write below. Prefix the posted report with the `<!-- review-skill:reply -->` sentinel so §0 excludes it next run.

**Exception — automated reviewers only** (CodeRabbit, Lucille, etc.), gated on `--reply`/`--resolve` or an explicit ask — never on your own initiative. Both actions apply **only to threads §4 marked bot-only**; a **human-touched** thread (any human comment, even on a bot-opened thread) is never auto-replied or auto-resolved — surface it in the report for the human instead:
- `--reply` → reply on the bot-only threads from §4 (answer the bot; note what was addressed or skipped). Post **into the specific thread by its node/comment `id`** via the thread-reply API (`gh api .../pulls/<n>/comments/<comment_id>/replies` or `addPullRequestReviewThreadReply`) — never by `path`/`line`, never a top-level `gh pr comment` (that sprays the PR). Pass the reply body injection-safely (it echoes bot text): `gh api … -F body=@<file>` (or `--input`/stdin), never `-f body="$(…)"`. Start every reply body with the `<!-- review-skill:reply -->` sentinel.
- `--resolve` → resolve the bot-only threads that are addressed or triaged NOT_WORTH_ADDRESSING / ALREADY_HANDLED, via the GraphQL `resolveReviewThread` mutation. Resolve **strictly by the thread node `id`** recorded in §4 (from the §1 `reviewThreads` query) — never match on `path`/`line`, which can hit the wrong thread when two share a location.
- With neither flag nor an explicit ask, leave every thread untouched — triage them in the report and stop there.

Posting/replying/resolving is independent of the checkpoint — §7 is written locally regardless.

---

## Notes

- Read-only on the codebase — this skill never modifies source; the only thing it writes is the checkpoint under `.ignore/reviews/`.
- Use **light** for small/quick changes, **deep** for anything risky, large, or security/architecture-touching. Scale verifier depth to the stakes.
