---
user-invocable: true
description: Adversarial multi-agent code review (deep or light) with verification, existing-comment triage, convergence, and a persisted checkpoint that makes re-runs cheap (cached / incremental / forced)
---

# Code Review

Review a branch's changes or a specific PR. Two modes:

- **deep** (default) — multi-agent adversarial deep-dive. Independent review agents attack the diff through different lenses, verification agents confirm/refute each finding along the way, existing review comments on the PR are triaged, and a consolidation agent converges everything into one report.
- **light** — fast single-pass review. No agent fan-out, no verification agents, no comment triage. Just a focused read of the diff.

Every review is **checkpointed** to `.ignore/reviews/<slug>.md` with the reviewed SHA and date. Because you call `/review` often and a fresh deep review is expensive, re-runs are cheap by default: if nothing changed since the checkpoint you get the cached report back; if only some commits landed you get an **incremental** review of just the delta, reconciled against the prior findings. A cache hit still **always re-checks the PR for new comments** — if reviewers (human or bot) commented since the checkpoint, those are re-triaged and folded in even when the code is unchanged. `--force` throws the checkpoint away and reviews from scratch.

> The first full review must be **immaculate and stable** — thorough enough that follow-ups only need to look at the delta. Do not cut corners on the initial pass; every later re-run trusts it.

## Inputs

Parse `args` for:

- **Target** — a PR reference (`#107704`, `107704`, or a GitHub URL). If none, review the current branch.
- **Mode** — `light` (or `--light`, `--quick`) selects light mode. Anything else (including no flag) is deep mode.
- **`--force`** (or `--fresh`) — ignore any existing checkpoint and run a full review from scratch, then overwrite the checkpoint.

Examples:
- `/review` → cached / incremental / full review of current branch (depending on checkpoint)
- `/review #107704` → same, for PR 107704
- `/review light` → light-mode review of current branch
- `/review --force` → full deep review, ignoring any checkpoint
- `/review light #107704 --force` → full light review of PR 107704, ignoring any checkpoint

---

## 0. Checkpoint — resolve & short-circuit

Do this **first**, before spending any agent time.

**Resolve the slug and path.** The checkpoint lives at `.ignore/reviews/<slug>.md`:
- PR target → `pr-<number>` (e.g. `pr-107704`)
- Current branch → the branch name with `/`→`-` and any non `[A-Za-z0-9._-]` stripped (e.g. `feat/email-notifs` → `feat-email-notifs`)
- Detached HEAD / generic branch (`main`, `develop`) with no PR → a short kebab title summarizing the change (e.g. `refactor-auth-session`)

**Determine the current head SHA:**
- PR: `gh pr view <number> --json headRefOid -q .headRefOid`
- Branch: `git rev-parse HEAD`

**Pick the path:**

1. **`--force` given** → **FULL** review. Skip the rest of §0.
2. **No checkpoint file exists** → **FULL** review (first time).
3. **Checkpoint exists** — read its frontmatter (`sha`, `base`, `mode`, `date`, `last_activity`):
   - **Current head SHA == checkpoint `sha`** → the code is unchanged, but **PR activity may not be** — so always check the PR's current state before caching (never serve a stale report without first re-checking the latest PR):
     - **Light mode, or no PR** → **CACHED**. Emit the stored report verbatim, prefixed with:
       `> Cached review — unchanged since <date> (SHA <short-sha>). Re-run with \`--force\` for a fresh review.`
       Then **stop**. No agents, no diffing beyond the SHA compare — the common-case free path.
     - **Deep mode with a PR** → fetch the PR's current comments/threads (the §1 deep-mode queries) and compare against the checkpoint's `last_activity`:
       - **No new comments** → **CACHED**, exactly as above.
       - **New comments since the checkpoint** (any author — human or bot; new review comments, threads, or issue-level comments) → **COMMENT-DELTA**. The code didn't change, so skip the review agents (§3), but **re-triage the new/updated comments** (§4) and reconcile them into the stored report — a new comment may raise a real issue, resolve an open one, or change the verdict — then rewrite the checkpoint (§7, refreshing `last_activity`). Announce: `Cached code unchanged, but N new PR comment(s) since <date> — re-triaging comments only.` Do **not** re-review the unchanged code.
   - **Current head SHA != checkpoint `sha`** → **INCREMENTAL**, *if* the checkpoint `sha` is still reachable from the current head (verify: `git merge-base --is-ancestor <checkpoint_sha> HEAD` for a branch; for a PR, `gh api repos/{owner}/{repo}/compare/<checkpoint_sha>...<head_sha>` succeeding with `status` != `diverged`). Proceed to §1 in **incremental** posture.
   - **Checkpoint `sha` is unreachable** (force-push / rebase dropped the commit, or the compare diverged) → **FULL** review — the prior baseline no longer exists, so a clean pass is safer. Note this in the report changelog.

Announce which path you took in one line (e.g. `Incremental review: 3 new commits since 2026-07-01 checkpoint.`).

---

## 1. Gather context (parallel)

Run these together:

- **Diff**
  - PR target: `gh pr diff <number>`
  - Current branch: `git diff develop...HEAD` (fall back to `main...HEAD` if no `develop`)
- **Delta diff** (INCREMENTAL only) — the changes *since the checkpoint*, which is all the new work you actually need to review:
  - Branch: `git diff <checkpoint_sha>..HEAD`
  - PR: `gh api repos/{owner}/{repo}/compare/<checkpoint_sha>...<head_sha> --jq '.files[].filename'` for the changed-file set, plus `gh pr diff <number>` for full context on those files
- **Commits**
  - PR target: `gh pr view <number> --json commits`
  - Current branch: `git log --oneline develop..HEAD` (INCREMENTAL: also `git log --oneline <checkpoint_sha>..HEAD` for just the new commits)
- **PR metadata** (if a PR exists): `gh pr view <number> --json number,title,url,body,headRefName,baseRefName`
- **Project conventions**: locate all `CLAUDE.md` and `AGENTS.md` files in the repo
- **Prior checkpoint report** (INCREMENTAL only): read `.ignore/reviews/<slug>.md` in full — its findings and comment dispositions are the baseline you carry forward.

**Deep mode only — existing review comments.** Pull every existing review comment and thread on the PR so it can be triaged later (see §4). Generalize across *all* reviewers — humans and bots alike (CodeRabbit, Lucille, etc. are just examples; do not special-case them):

```bash
# Issue-level + review summaries
gh pr view <number> --json reviews,comments

# Inline review comments
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate

# Unresolved review threads (resolution state requires GraphQL)
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          isResolved isOutdated path line
          comments(first:20){ nodes{ author{login} body } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=<number>
```

Skip this step in light mode and when there is no PR.

### Incremental posture

When §0 selected INCREMENTAL, the guiding rule for §2–§5 is: **review the delta, not the whole diff again.** Concretely:

- Only look for **new** issues inside the delta hunks (the code that changed since the checkpoint). Do **not** re-open, re-scan, or re-nitpick code that was already reviewed and is untouched — that is what produces surprise findings on a re-run and is exactly what the checkpoint exists to prevent.
- **Carry forward** every prior finding whose code the delta did not touch, verbatim (re-anchor its `file:line` if lines shifted).
- For prior findings whose code the delta **did** touch: re-check them — mark **resolved** (drop from the active list, note in the changelog) if the change fixed them, otherwise keep them.
- Carry forward prior comment dispositions (§4) unchanged unless the delta touched the relevant code.
- Scope agent work to the delta files only. If the delta is trivial (e.g. a comment/whitespace/version bump with no behavioral change), you may reconcile directly without fanning out agents.

---

## 2. Light mode

If light mode is selected, do this and **stop** — skip §3–§5:

1. Read the diff and project conventions directly (no agents), or delegate a single pass to `oh-my-claudecode:code-reviewer` (model: `sonnet`). In INCREMENTAL posture, read the **delta diff** and reconcile against the prior report instead of re-reviewing everything.
2. Surface only concrete, high-confidence issues. Don't pad with nitpicks.
3. Emit the report (§6) with the existing-comment section omitted, then write the checkpoint (§7).

---

## 3. Deep mode — adversarial review + verification

### 3a. Spawn review agents (parallel)

Launch **4 independent agents**. Each gets the full diff + project conventions (INCREMENTAL: the **delta diff** + the prior report), works in isolation, and reviews from an **adversarial** stance: assume the change is broken and try to prove it.

**Agent 1 — Correctness & Logic** (`oh-my-claudecode:code-reviewer`, model: `sonnet`)
- Logic errors, off-by-one, null/undefined paths, race conditions, state corruption
- Missing error handling on unhappy paths
- Spec compliance: does the diff actually solve the stated problem?
- Type safety (narrowing gaps, unsafe casts)

**Agent 2 — Security & Trust Boundaries** (`oh-my-claudecode:security-reviewer`, model: `sonnet`)
- OWASP Top 10: injection, XSS, CSRF, broken auth/authz
- Hardcoded secrets, leaked credentials, overly permissive configs
- Trust-boundary violations (user input reaching privileged operations)
- Dependency concerns (new deps, known CVEs)

**Agent 3 — Edge Cases & Failure Modes** (`oh-my-claudecode:code-reviewer`, model: `sonnet`)
- Adversarial inputs: empty, huge, malformed, concurrent, boundary values
- Resource exhaustion, partial failures, retries/idempotency
- What happens when an external call times out or returns garbage?

**Agent 4 — Architecture, Contracts & Maintainability** (`oh-my-claudecode:architect`, model: `sonnet`)
- API contract changes and backward compatibility
- Abstraction fitness: is the change at the right layer?
- Performance (algorithmic complexity, N+1 queries, memory)
- Convention compliance, anti-patterns, dead code, naming

In INCREMENTAL posture, tell every agent explicitly: **only report issues introduced or exposed by the delta hunks; do not flag pre-existing untouched code.**

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

As each lens reports, verify its non-trivial findings before they reach the report. For each CRITICAL/HIGH (and any disputed MEDIUM), spawn a verification agent (`oh-my-claudecode:verifier`, model: `sonnet`) prompted **adversarially — try to refute the finding**:

- Confirm the triggering code path actually exists in the diff and is reachable
- Default to `refuted` when the evidence is hand-wavy or the path can't be reproduced
- Output: `{ finding, verdict: CONFIRMED | REFUTED | UNCERTAIN, reasoning }`

Drop REFUTED findings. Keep CONFIRMED and UNCERTAIN (flag UNCERTAIN as such). This kills plausible-but-wrong findings before they waste the reader's time — and keeps the checkpoint clean so future re-runs don't resurface noise.

---

## 4. Deep mode — triage existing review comments

Hand the existing comments/threads from §1 to a triage agent (`oh-my-claudecode:code-reviewer`, model: `sonnet`). For each **unresolved** comment or thread (any author — human or bot), decide and record:

- **Disposition**: WORTH_ADDRESSING | NOT_WORTH_ADDRESSING | ALREADY_HANDLED | NEEDS_DISCUSSION
- **Reasoning**: 1–2 sentences. Cross-reference the current diff — the comment may already be fixed, may be a false positive, or may be a stylistic nit the project doesn't care about.

Don't auto-trust bot comments; assess them on merits like any other. In INCREMENTAL posture, only (re-)triage comments that are new or whose referenced code the delta touched; carry the rest forward from the prior report.

---

## 5. Deep mode — consolidate (agents converge at the end)

Hand all verified findings + comment dispositions (INCREMENTAL: **plus the carried-forward prior findings**) to a consolidation agent (`oh-my-claudecode:critic`, model: `opus`) to converge:

1. **Deduplicate** — merge findings that hit the same location or root cause (including a carried-forward finding that a new agent re-flagged)
2. **Rank by severity** — CRITICAL > HIGH > MEDIUM > LOW
3. **Confidence filter** — drop LOW-severity items only one agent flagged
4. **Resolve conflicts** — if agents disagree, present both sides and make a final call
5. **Fold in comment triage** — surface WORTH_ADDRESSING items alongside the agents' own findings
6. **Reconcile with the checkpoint** (INCREMENTAL) — carry forward untouched prior findings, mark delta-fixed ones as resolved, add only genuinely new delta findings. Do not re-derive findings on unchanged code. Produce a short changelog: `N new · M resolved · K carried forward`.

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

### What's Done Well
- Positive observations agreed on by 2+ agents

### Verdict
**APPROVE** | **CONCERNS** | **REQUEST_CHANGES**
Rationale: 1–2 sentences.
Agent breakdown: Agent 1 (APPROVE), Agent 2 (CONCERNS), …
```

## Verdict Rules

- Any CRITICAL issue → **REQUEST_CHANGES**
- 2+ HIGH issues → **REQUEST_CHANGES**
- 1 HIGH or 3+ MEDIUM → **CONCERNS**
- Otherwise → **APPROVE**

### De-slop the prose before you emit it

Do a quick cleanup pass over the report's wording before you show it (§6), store it (§7), or post it (§8), per the Voice rules in `~/.claude/CLAUDE.md`: cut wordiness and filler, break up em-dash and semicolon pileups, and warm up robotic, overly matter-of-fact phrasing. Keep every finding, severity, `file:line`, and verdict exactly as written. This pass touches tone and length, never facts.

---

## 7. Write the checkpoint (always, except on the CACHED short-circuit)

After producing the report — for FULL and INCREMENTAL paths, both deep and light — persist it so the next `/review` is cheap.

1. `mkdir -p .ignore/reviews` (and make sure `.ignore/` is git-ignored: if it isn't already covered, add `.ignore/` to `.gitignore` or `.git/info/exclude` so review artifacts never get committed).
2. Write `.ignore/reviews/<slug>.md` (overwriting any prior checkpoint) with frontmatter + the full §6 report as the body:

```markdown
---
target: "PR #107704"        # or "branch: feat/email-notifs"
slug: pr-107704
sha: <full 40-char reviewed head SHA>
base: develop               # base ref the diff was taken against
base_sha: <full base SHA>   # optional; helps detect base movement on re-run
mode: deep                  # deep | light
verdict: CONCERNS
date: 2026-07-06            # today's date
last_activity: 2026-07-06T14:22:00Z   # newest PR comment/review/thread timestamp triaged (deep + PR only); omit when there's no PR or no comments. A future cache hit compares against it to detect new comments on unchanged code.
---

<the full report from §6>
```

The `sha` is what a future run compares against to decide CACHED vs INCREMENTAL, so it must be the exact head SHA you reviewed. Use the current date for `date`. Set `last_activity` to the newest timestamp among the PR comments/reviews/threads you triaged — a future cache hit compares against it to catch new comments on unchanged code (omit it when there's no PR).

---

## 8. Post results (conditional)

- If a PR exists and the user confirms, post the report as a PR comment via `gh pr comment <number> --body "$(cat <<'EOF' … EOF)"`
- Otherwise display the report in the terminal only
- Posting to the PR is independent of the checkpoint — the checkpoint (§7) is always written locally regardless.

## Notes

- Read-only on the codebase — this skill never modifies source, only reports findings. The one thing it writes is the checkpoint under `.ignore/reviews/`.
- **Cheap re-runs by design:** unchanged code + no new comments → cached report (no agents); unchanged code + new PR comments → comment-only re-triage; a few new commits → incremental review of just the delta; `--force` → full fresh review. A cache hit never skips the new-comment check — the latest PR state is always consulted. This is deliberate — a full deep review is expensive and you re-run often.
- Because later runs trust the checkpoint, the first full review must be **thorough and stable**: verify findings, drop the plausible-but-wrong ones, and don't leave nits that will re-surface as churn.
- Use **light** for small/quick changes; **deep** for anything risky, large, or security/architecture-touching.
- **Human, concise prose:** before emitting, storing, or posting the report, de-slop its wording per the Voice rules in `~/.claude/CLAUDE.md`. Trim filler, avoid em-dash and semicolon pileups, keep the tone plainspoken. Facts, findings, and verdicts stay exact.
