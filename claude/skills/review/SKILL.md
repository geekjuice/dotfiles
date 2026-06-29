---
user-invocable: true
description: Adversarial multi-agent code review (deep or light) with verification, existing-comment triage, and convergence
---

# Code Review

Review a branch's changes or a specific PR. Two modes:

- **deep** (default) — multi-agent adversarial deep-dive. Independent review agents attack the diff through different lenses, verification agents confirm/refute each finding along the way, existing review comments on the PR are triaged, and a consolidation agent converges everything into one report.
- **light** — fast single-pass review. No agent fan-out, no verification agents, no comment triage. Just a focused read of the diff.

## Inputs

Parse `args` for:

- **Target** — a PR reference (`#107704`, `107704`, or a GitHub URL). If none, review the current branch.
- **Mode** — `light` (or `--light`, `--quick`) selects light mode. Anything else (including no flag) is deep mode.

Examples:
- `/review` → deep review of current branch
- `/review #107704` → deep review of PR 107704
- `/review light` → light review of current branch
- `/review light #107704` → light review of PR 107704

---

## 1. Gather context (parallel)

Run these together:

- **Diff**
  - PR target: `gh pr diff <number>`
  - Current branch: `git diff develop...HEAD` (fall back to `main...HEAD` if no `develop`)
- **Commits**
  - PR target: `gh pr view <number> --json commits`
  - Current branch: `git log --oneline develop..HEAD`
- **PR metadata** (if a PR exists): `gh pr view <number> --json number,title,url,body,headRefName,baseRefName`
- **Project conventions**: locate all `CLAUDE.md` and `AGENTS.md` files in the repo

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

---

## 2. Light mode

If light mode is selected, do this and **stop** — skip §3–§4:

1. Read the diff and project conventions directly (no agents), or delegate a single pass to `oh-my-claudecode:code-reviewer` (model: `sonnet`).
2. Surface only concrete, high-confidence issues. Don't pad with nitpicks.
3. Emit the report (§5) with the existing-comment section omitted.

---

## 3. Deep mode — adversarial review + verification

### 3a. Spawn review agents (parallel)

Launch **4 independent agents**. Each gets the full diff + project conventions, works in isolation, and reviews from an **adversarial** stance: assume the change is broken and try to prove it.

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

Drop REFUTED findings. Keep CONFIRMED and UNCERTAIN (flag UNCERTAIN as such). This kills plausible-but-wrong findings before they waste the reader's time.

---

## 4. Deep mode — triage existing review comments

Hand the existing comments/threads from §1 to a triage agent (`oh-my-claudecode:code-reviewer`, model: `sonnet`). For each **unresolved** comment or thread (any author — human or bot), decide and record:

- **Disposition**: WORTH_ADDRESSING | NOT_WORTH_ADDRESSING | ALREADY_HANDLED | NEEDS_DISCUSSION
- **Reasoning**: 1–2 sentences. Cross-reference the current diff — the comment may already be fixed, may be a false positive, or may be a stylistic nit the project doesn't care about.

Don't auto-trust bot comments; assess them on merits like any other.

---

## 5. Deep mode — consolidate (agents converge at the end)

Hand all verified findings + comment dispositions to a consolidation agent (`oh-my-claudecode:critic`, model: `opus`) to converge:

1. **Deduplicate** — merge findings that hit the same location or root cause
2. **Rank by severity** — CRITICAL > HIGH > MEDIUM > LOW
3. **Confidence filter** — drop LOW-severity items only one agent flagged
4. **Resolve conflicts** — if agents disagree, present both sides and make a final call
5. **Fold in comment triage** — surface WORTH_ADDRESSING items alongside the agents' own findings

---

## 6. Final report

```markdown
## Code Review — [PR #N or branch name] (deep | light)

**PR:** #number (if exists)
**Commits reviewed:** N · **Files changed:** N

### Critical / Must Fix
- [ ] `file:line` — issue (Source: Agent 1, Agent 3 · Verified)

### High / Should Fix
- [ ] `file:line` — issue (Source: Agent 2 · Verified)

### Medium / Consider
- [ ] `file:line` — issue

### Low / Nitpicks
- `file:line` — observation

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

## 7. Post results (conditional)

- If a PR exists and the user confirms, post the report as a PR comment via `gh pr comment <number> --body "$(cat <<'EOF' … EOF)"`
- Otherwise display the report in the terminal only

## Notes

- Read-only — this skill never modifies code, only reports findings
- Re-run safe — produces a fresh review each time
- Use **light** for small/quick changes; **deep** for anything risky, large, or security/architecture-touching
