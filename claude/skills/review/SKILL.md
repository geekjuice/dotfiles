---
user-invocable: true
description: Multi-agent parallel code review with convergence
---

# Code Review

Run independent parallel review agents against the current branch's changes, then converge findings into a single actionable report.

## Steps

### 1. Gather context (parallel)

Run all of these in parallel:

- `git diff develop...HEAD` (or `main...HEAD` if no `develop`) — full diff
- `git log --oneline develop..HEAD` — commit list
- `gh pr view --json number,title,url,body` — existing PR metadata (if any)
- Find all `CLAUDE.md` and `AGENTS.md` files in the repo for project conventions

### 2. Spawn review agents (parallel)

Launch **4 independent agents** — each receives the full diff and project conventions but reviews through a different lens. Each agent works in isolation with no visibility into the others' findings.

**Agent 1 — Correctness** (`oh-my-claudecode:code-reviewer`, model: `sonnet`)
- Logic errors, off-by-one, null/undefined paths, race conditions
- Missing error handling on unhappy paths
- Spec compliance: does the diff solve the stated problem?
- Type safety issues (narrowing gaps, unsafe casts)

**Agent 2 — Security & Trust Boundaries** (`oh-my-claudecode:security-reviewer`, model: `sonnet`)
- OWASP Top 10: injection, XSS, CSRF, broken auth/authz
- Hardcoded secrets, leaked credentials, overly permissive configs
- Trust boundary violations (user input flowing to privileged operations)
- Dependency concerns (new deps, known CVEs)

**Agent 3 — Maintainability & Conventions** (`oh-my-claudecode:code-reviewer`, model: `haiku`)
- Project convention compliance (from CLAUDE.md / AGENTS.md)
- Anti-patterns: God objects, feature envy, shotgun surgery, magic numbers
- Naming, structure, readability
- Dead code, unused imports, leftover debug statements

**Agent 4 — Architecture & Edge Cases** (`oh-my-claudecode:architect`, model: `sonnet`)
- API contract changes and backward compatibility
- Missing edge cases and boundary conditions
- Performance implications (algorithmic complexity, N+1 queries, memory)
- Abstraction fitness: is the change at the right layer?

Each agent MUST output findings in this format:

```
## [Lens Name] Review

### Issues

- **[CRITICAL|HIGH|MEDIUM|LOW]** `file:line` — Description
  Suggestion: how to fix

### Positive Observations
- What's done well

### Verdict: APPROVE | CONCERNS | REQUEST_CHANGES
```

### 3. Converge findings

After all agents complete, synthesize their outputs:

1. **Deduplicate** — merge findings that reference the same code location or root cause
2. **Rank by severity** — CRITICAL > HIGH > MEDIUM > LOW
3. **Confidence filter** — drop LOW-severity items that only one agent flagged (noise reduction)
4. **Resolve conflicts** — if agents disagree (e.g., one approves, one requests changes), explain both perspectives and make a final call

### 4. Produce final report

Output a single converged report:

```markdown
## Code Review — [branch name]

**PR:** #number (if exists)
**Commits reviewed:** N
**Files changed:** N

### Critical / Must Fix
- [ ] `file:line` — issue (Source: Agent 1, Agent 3)

### High / Should Fix
- [ ] `file:line` — issue (Source: Agent 2)

### Medium / Consider
- [ ] `file:line` — issue

### Low / Nitpicks
- `file:line` — observation

### What's Done Well
- Positive observations agreed on by 2+ agents

### Verdict

**APPROVE** | **CONCERNS** | **REQUEST_CHANGES**

Rationale: 1-2 sentences explaining the final call.
Agent breakdown: Agent 1 (APPROVE), Agent 2 (CONCERNS), ...
```

### 5. Post results (conditional)

- If a PR exists and the user confirms, post the report as a PR comment via `gh pr comment --body "$(cat <<'EOF' ... EOF)"`
- Otherwise, display the report in the terminal only

## Verdict Rules

- Any CRITICAL issue -> **REQUEST_CHANGES**
- 2+ HIGH issues -> **REQUEST_CHANGES**
- 1 HIGH or 3+ MEDIUM -> **CONCERNS**
- Otherwise -> **APPROVE**

## Notes

- This skill is read-only — it never modifies code, only reports findings
- For quick reviews of small changes, agents 3 and 4 can be skipped by passing `--quick`
- Re-run safe: running multiple times on the same branch produces a fresh review each time
