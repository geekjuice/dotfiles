---
user-invocable: true
description: "Adversarial multi-agent code review of a branch or PR. Deep mode (default) fans out independent lenses that attack the diff, verifies each finding, triages existing PR comments, and converges one report; light mode is a fast single-pass read. Checkpoints each run to `.ignore/reviews/<slug>.md` so re-runs are cheap: unchanged → cached; new commits → incremental review of just the delta; new PR comments only → comment re-triage; `--force` → fresh. Report stays in the terminal — never posts to the PR unless explicitly asked (bot threads only, via `--reply`/`--resolve`)."
---

# Code Review

Review a branch's changes or a specific PR. Two modes:

- **deep** (default) — multi-agent adversarial deep-dive. Independent agents attack the diff through different lenses, verification agents confirm/refute each finding along the way, existing PR comments are triaged, and a consolidation agent converges everything into one report.
- **light** — fast single-pass read of the diff. No fan-out, no verification agents, no comment triage.

Every review is **checkpointed** to `.ignore/reviews/<slug>.md` with the reviewed SHA and date. You call `/nick:review` often and a fresh deep review is expensive, so re-runs are cheap by design — §0 has the full path table. In **deep mode on a PR**, a cache hit re-checks the PR for new comments before serving, so a stale report is never served blind. (Light mode and no-PR targets have no comments to re-check and cache directly.)

> The first full review must be **immaculate and stable** — thorough enough that follow-ups only touch the delta. Every later re-run trusts it, so don't cut corners on the initial pass.

> **Prose for humans** (the report, summaries, any posted text) gets a de-slop pass per the Voice rules in `~/.claude/CLAUDE.md`: trim filler, break up em-dash/semicolon pileups, warm up robotic phrasing. Never change a finding, severity, `file:line`, or verdict.

## Inputs

Parse `args` for:
- **Target** — a PR ref (`#107704`, `107704`, or a GitHub URL). If none, review the current branch.
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

**Resolve the slug** (must be **deterministic** — the same target maps to the same slug every run, or the checkpoint is never found and every run degrades to FULL). Every kind gets a reserved prefix so the kinds can't collide:
- PR target → `pr-<number>` (e.g. `pr-107704`)
- Named branch → `branch-<sanitized>` (branch name, `/`→`-`, non-`[A-Za-z0-9._-]` stripped; e.g. `feat/email-notifs` → `branch-feat-email-notifs`). The `branch-` prefix stops a branch named `pr-123` colliding with PR #123; empty `<sanitized>` → `branch-<short-head-sha>`. Branches that sanitize alike (`feat/x`, `feat-x`) still collide — the §0 target guard is the backstop.
- Detached HEAD / generic branch (`main`, `develop`) with no PR → `detached-<short-head-sha>`. CACHED still works on an unchanged tree; new commits yield a new slug and a fresh FULL review (INCREMENTAL doesn't apply to these anchorless targets — rare, fine). Never use a model-written title.

**Cross-repo target.** If the target is a GitHub URL for another repo, parse its `owner/repo` (and PR number) and `export GH_REPO=<owner>/<repo>` for the whole run — every `gh` call (the head-SHA fetch below, `gh api`, `gh pr view`, the §8 reply/resolve calls) then targets that repo instead of the current directory's; also pass the GraphQL `owner`/`repo` vars explicitly. (`gh api` has no `--repo` flag; `GH_REPO` is the portable way that covers `gh pr *` and REST `gh api` alike.)

**Current head SHA:** PR → `gh pr view <number> --json headRefOid -q .headRefOid`; branch → `git rev-parse HEAD`.

**Pick the path:**
1. **`--force`** → **FULL** review. Skip the rest of §0.
2. **No checkpoint file** → **FULL** review (first time).
3. **Checkpoint exists** — read its frontmatter (`target`, `sha`, `base`, `base_sha`, `mode`, `verdict`, `date`, `last_activity`). Throughout, **"mode" means the mode requested *this* invocation**, not the stored `mode`.
   - **Target guard (applies to every branch below, before any SHA/reachability check)** — if the stored `target` (§7) isn't the target you're reviewing now (a slug collision — two branches that sanitize alike, possibly on shared history so the SHA is even reachable) → **cache miss**, run **FULL**. Never serve or incrementally build on another target's report.
   - **Depth escalation** — invocation is **deep** but checkpoint `mode` is `light` → treat as a **cache miss** (the stored report is a shallow single-pass; a deep request must not be served from it) and run **FULL**, regardless of SHA. Skip the rest of step 3.
   - **head SHA == checkpoint `sha`** (no depth escalation or target mismatch) → head unchanged, but **base drift** can still invalidate it. Recompute the current base–HEAD merge-base (branch → `git merge-base <base> HEAD`; PR → the compare API's `merge_base_commit.sha`) and compare it against stored `base_sha`. If absent (old checkpoint) or moved (retarget / rebase / force-push that moved the merge-base) → **cache miss → FULL** (the head is unchanged, so a `checkpoint_sha..HEAD` delta would be empty — the changed *base* means the whole diff must be re-reviewed), note base drift. (A plain fast-forward of the base leaves the merge-base unchanged, so this only fires on retarget/rewrite.)

     Otherwise the code is genuinely unchanged, but PR activity may not be — check the PR's current state before caching:
     - **light mode, or no PR** → **CACHED**. Emit the stored report verbatim, prefixed with:
       `> Cached review — unchanged since <date> (SHA <short-sha>). Re-run with \`--force\` for a fresh review.`
       Then **stop** — no agents, no diffing beyond the SHA compare.
     - **deep mode with a PR** → fetch the PR's current comments/threads (the §1 queries). Let `newest_seen` = the newest timestamp among **all** comments/reviews/threads returned (any author, resolved or not) — §7 stores it as `last_activity`, so the check stays idempotent. Then, **excluding this skill's own replies** (identified *only* by the sentinel `<!-- review-skill:reply -->` that §8 stamps in, never by author — the gh user may be the PR author self-reviewing), compare the rest against `last_activity`:
       - **no new comments** → **CACHED**, as above (still rewrite `last_activity` to `newest_seen` if it advanced — e.g. absorbing this skill's own reply, which is excluded from the new-comment check but counts toward `newest_seen` — so the CACHED serve stays idempotent).
       - **new comments since the checkpoint** (any author — review comments, threads, or issue-level) → **COMMENT-DELTA**. Code is unchanged, so skip the review agents (§3), but **re-triage the new/updated comments** (§4), reconcile them into the stored report (a new comment may raise a real issue, resolve an open one, or change the verdict), then rewrite the checkpoint (§7, setting `last_activity` = `newest_seen`). Announce: `Cached code unchanged, but N new PR comment(s) since <date> — re-triaging comments only.`
   - **head SHA != checkpoint `sha`**, and the checkpoint `sha` is still reachable from head → **INCREMENTAL**. Reachability: branch → `git merge-base --is-ancestor <checkpoint_sha> HEAD`; PR → `gh api repos/{owner}/{repo}/compare/<checkpoint_sha>...<head_sha>` returns `status: ahead` (a rolled-back head reads as `behind`/`diverged` — not an ancestor → FULL, matching the branch check). Proceed to §1 in incremental posture.
   - **checkpoint `sha` unreachable** (force-push / rebase dropped it, or the compare diverged) → **FULL** review; note it in the report changelog.

**`--reply`/`--resolve` override the cache short-circuit.** They act on live threads, not the stored report, so a cache hit (with either flag or an explicit ask) must still run §4 triage + §8 against freshly-fetched threads (which carry the node `id`s §8 needs) before serving the cached report; §3 stays skipped. Never improvise a resolve from the stored report — §6 records `file:line`, not a durable thread id.

Announce the path in one line (e.g. `Incremental review: 3 new commits since 2026-07-01 checkpoint.`).

---

## 1. Gather context (parallel)

First, **resolve the base branch** for a non-PR review (a PR carries its own `baseRefName`): `develop`→`main`→`master`→remote default (`git symbolic-ref --short refs/remotes/origin/HEAD`, stripped of `origin/`); first that exists wins. **Don't use the branch's own `@{u}` tracking ref** — for a pushed feature branch it resolves to that branch's remote counterpart, so `git diff @{u}...HEAD` sees only unpushed commits (empty on a synced branch → false APPROVE). **If none resolve, stop and ask for the base — never proceed empty**: an empty base makes `git diff <base>...HEAD` empty, tripping the empty-diff guard into a false APPROVE on unreviewed code. Record the base ref as `base` and the base–HEAD merge-base (`git merge-base <base> HEAD`; PR → the compare API's `merge_base_commit.sha`) as `base_sha` — the three-dot diff's real start, so a plain fast-forward of the base doesn't read as drift (§0). Surface the base so the user can override, and use `<base>` everywhere below — never hard-code `develop`/`main`.

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
# PAGINATE: a PR can have >100 threads. --paginate walks the OUTER reviewThreads
# list to exhaustion (it follows the top-level pageInfo.hasNextPage only). A
# thread with >100 comments is NOT auto-paged here — its comments.pageInfo below
# flags that, and you must run a per-thread follow-up query for the rest (see
# below) BEFORE §4 classifies it. Missing a comment is a safety bug: §4 decides
# bot-only vs human-touched from these comments, so an unseen human reply would
# let §8 auto-resolve a human's thread.
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
- Only look for **new** issues inside the delta hunks. Don't re-open, re-scan, or re-nitpick untouched code that was already reviewed — that surprise churn is exactly what the checkpoint prevents.
- **Carry forward** every prior finding whose code the delta didn't touch, verbatim (re-anchor `file:line` if lines shifted).
- For prior findings whose code the delta **did** touch: re-check them — mark **resolved** (drop, note in the changelog) if fixed, else keep.
- Carry prior comment dispositions (§4) forward unchanged unless the delta touched the relevant code.
- Scope agent work to the delta files. If the delta is trivial (comment/whitespace/version bump, no behavior change), reconcile directly without fanning out agents.

**Empty-diff guard (all modes).** Before any fan-out, check the resolved diff. If it's empty or purely whitespace/comment (a net-zero revert, a branch with no commits ahead of base, or a detached HEAD sitting at base), skip §2–§5 entirely, emit a `No reviewable changes` report with an APPROVE verdict, and write the checkpoint. This also covers FULL runs (first review or `--force`), not just the trivial-delta case above. **Exception:** if `--reply`/`--resolve` (or an explicit ask) is present on a PR, still run the §1 thread fetch + §4 triage + §8 first (as in the cache-hit override) so the flags aren't silently dropped — then apply the guard to the review itself.

---

## 2. Light mode

If light mode is selected, do this and **stop** — skip §3–§5:
1. Read the diff and project conventions directly, or delegate one pass to `oh-my-claudecode:code-reviewer` (model: `sonnet`). In INCREMENTAL posture, read the **delta diff** and reconcile against the prior report.
2. Surface only concrete, high-confidence issues. Don't pad with nitpicks.
3. Emit the report (§6, existing-comment section omitted), then write the checkpoint (§7).

**If `--reply`/`--resolve` (or an explicit ask) is present on a PR**, light mode must not silently drop them: run the §1 comment/thread fetch + §4 triage (the only steps that produce the bot-only classification and node `id`s §8 needs) and then §8, even though the rest of §3–§5 stays skipped.

---

## 3. Deep mode — adversarial review + verification

### 3a. Spawn review agents (parallel)

Launch **4 independent agents**. Each gets the full diff + project conventions (INCREMENTAL: the **delta diff** + the prior report), works in isolation, and reviews from an **adversarial** stance — assume the change is broken and try to prove it. In INCREMENTAL posture, tell every agent explicitly: **only report issues introduced or exposed by the delta hunks; never flag pre-existing untouched code.**

1. **Correctness & Logic** (`oh-my-claudecode:code-reviewer`, `sonnet`) — logic errors, off-by-one, null/undefined paths, race conditions, state corruption; missing error handling on unhappy paths; spec compliance (does the diff actually solve the stated problem?); type safety (narrowing gaps, unsafe casts).
2. **Security & Trust Boundaries** (`oh-my-claudecode:security-reviewer`, `sonnet`) — OWASP Top 10 (injection, XSS, CSRF, broken authn/authz); hardcoded secrets, leaked credentials, permissive configs; trust-boundary violations (user input reaching privileged ops); dependency concerns (new deps, known CVEs).
3. **Edge Cases & Failure Modes** (`oh-my-claudecode:code-reviewer`, `sonnet`) — adversarial inputs (empty, huge, malformed, concurrent, boundary); resource exhaustion, partial failures, retries/idempotency; behavior when an external call times out or returns garbage.
4. **Architecture, Contracts & Maintainability** (`oh-my-claudecode:architect`, `sonnet`) — API contract changes and backward compatibility; abstraction fitness (right layer?); performance (algorithmic complexity, N+1, memory); convention compliance, anti-patterns, dead code, naming.

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

As each lens reports, verify its non-trivial findings before they reach the report. For each CRITICAL/HIGH (and any disputed MEDIUM), spawn a verifier (`oh-my-claudecode:verifier`, `sonnet`) prompted **adversarially — try to refute the finding**:
- Confirm the triggering code path actually exists in the diff and is reachable.
- Default to `refuted` when the evidence is hand-wavy or the path can't be reproduced.
- Output: `{ finding, verdict: CONFIRMED | REFUTED | UNCERTAIN, reasoning }`.

Drop REFUTED findings. Keep CONFIRMED and UNCERTAIN (flag UNCERTAIN as such). This kills plausible-but-wrong findings before they waste the reader's time and keeps the checkpoint clean.

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
3. **Confidence filter** — drop LOW items only one agent flagged.
4. **Resolve conflicts** — if agents disagree, present both sides and make the call.
5. **Fold in comment triage** — surface WORTH_ADDRESSING (and NEEDS_DISCUSSION) items alongside the agents' findings.
6. **Reconcile with the checkpoint** (INCREMENTAL) — carry untouched prior findings forward, mark delta-fixed ones resolved, add only genuinely new delta findings. Produce a short changelog: `N new · M resolved · K carried forward`.

---

## 6. Final report

```markdown
## Code Review — [PR #N or branch name] (deep | light · full | incremental)

**PR:** #number (if exists)
**Reviewed SHA:** <short-sha> · **Base:** <base-ref>
**Commits reviewed:** N · **Files changed:** N
<!-- INCREMENTAL only: -->
**Delta since checkpoint (<prev-date>, <prev-short-sha>):** N new · M resolved · K carried forward

### Critical / Must Fix
- [ ] `file:line` — issue (Source: Agent 1, Agent 3 · Verified)

### High / Should Fix
- [ ] `file:line` — issue (Source: Agent 2 · Verified)

### Medium / Consider
- [ ] `file:line` — issue

### Low / Nitpicks
- `file:line` — observation

### Resolved Since Last Review  (incremental only)
- ~~`file:line` — issue~~ — fixed by <commit/change>

### Existing Review Comments  (deep mode, PR only)
- **WORTH_ADDRESSING** `file:line` (@author) — comment summary → why it matters
- **NOT_WORTH_ADDRESSING** `file:line` (@author) — comment summary → why it's safe to skip
- **ALREADY_HANDLED** `file:line` (@author) — addressed by <commit/change>
- **NEEDS_DISCUSSION** `file:line` (@author) — comment summary → the open question

### What's Done Well
- Positive observations agreed on by 2+ agents

### Verdict
**APPROVE** | **CONCERNS** | **REQUEST_CHANGES**
Rationale: 1–2 sentences.
Agent breakdown: Agent 1 (APPROVE), Agent 2 (CONCERNS), …
```

**Verdict rules:** any CRITICAL → **REQUEST_CHANGES**; 2+ HIGH → **REQUEST_CHANGES**; 1 HIGH or 3+ MEDIUM → **CONCERNS**; otherwise → **APPROVE**.

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
base_sha: <full base–HEAD merge-base SHA>   # required — the three-dot diff's start; §0 recomputes the merge-base and compares to detect base drift (retarget/rebase) at an unchanged head, immune to a plain base fast-forward
mode: deep                  # deep | light
verdict: CONCERNS
date: 2026-07-06            # today's date
last_activity: 2026-07-06T14:22:00Z   # newest timestamp among all PR comments/reviews/threads seen at §1 fetch time (any author) — the §0 `newest_seen`. Own replies are excluded by the §8 sentinel, NOT by this watermark, so it stays at the fetch high-water and a human comment posted after the fetch is still seen next run (deep + PR only; omit when there's no PR or no comments)
---

<the full report from §6>
```

`sha` must be the exact head SHA you reviewed — it's the CACHED-vs-INCREMENTAL key. Use today's date. Set `last_activity` = the §0 `newest_seen` (fetch-time high-water; see the field comment above) — never advance it past the fetch to cover a reply you post afterward, or a human comment created in that window is skipped next run. Omit when there's no PR.

---

## 8. Deliver results (terminal by default — never post to the issue/PR unprompted)

**Hard default: display the report in the terminal only.** Don't post it as an issue/PR comment, and don't offer or ask. The checkpoint (§7) is all this skill writes by default. Post **only** when the user explicitly asks (e.g. "post this to the PR") — and then **never interpolate the report into a shell command**: report bodies quote arbitrary code (a lone `EOF`, backticks, `$(…)`), so a heredoc or `--body "$(…)"` can truncate or execute injected shell. Pass the body by file or stdin: `gh pr comment <number> --body-file <path>` (or `--body-file -`). Same rule for every `--reply`/`--resolve` write below. Prefix the posted report with the `<!-- review-skill:reply -->` sentinel too, so §0 excludes this skill's own comment from the next run's new-comment check.

**Exception — automated reviewers only** (CodeRabbit, Lucille, etc.), gated on `--reply`/`--resolve` or an explicit ask — never on your own initiative. Both actions apply **only to threads §4 marked bot-only**; a **human-touched** thread (any human comment, even on a bot-opened thread) is never auto-replied or auto-resolved — surface it in the report for the human instead:
- `--reply` → reply on the bot-only threads from §4 (answer the bot; note what was addressed or skipped). Post **into the specific thread by its node/comment `id`** via the thread-reply API (`gh api .../pulls/<n>/comments/<comment_id>/replies` or `addPullRequestReviewThreadReply`) — never by `path`/`line`, never a top-level `gh pr comment` (that sprays the PR). Pass the reply body injection-safely (it echoes bot text): `gh api … -F body=@<file>` (or `--input`/stdin), never `-f body="$(…)"`. Start every reply body with the sentinel `<!-- review-skill:reply -->` — §0 excludes your own replies by this sentinel, not by timestamp, so `last_activity` stays at the fetch-time high-water (don't bump it to cover the reply, or a human comment posted after your fetch is skipped next run).
- `--resolve` → resolve the bot-only threads that are addressed or triaged NOT_WORTH_ADDRESSING / ALREADY_HANDLED, via the GraphQL `resolveReviewThread` mutation. Resolve **strictly by the thread node `id`** recorded in §4 (from the §1 `reviewThreads` query) — never match on `path`/`line`, which can hit the wrong thread when two share a location.
- With neither flag nor an explicit ask, leave every thread untouched — triage them in the report and stop there.

Posting/replying/resolving is independent of the checkpoint — §7 is written locally regardless.

---

## Notes

- Read-only on the codebase — this skill never modifies source; the only thing it writes is the checkpoint under `.ignore/reviews/`.
- Use **light** for small/quick changes, **deep** for anything risky, large, or security/architecture-touching. Scale verifier depth to the stakes.
