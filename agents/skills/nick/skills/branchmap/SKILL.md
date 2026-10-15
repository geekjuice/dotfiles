---
user-invocable: true
description: "Map every local branch to its worktree, Conductor workspace, PR and a deterministic cleanup verdict by running the `branch-map` CLI. Use for 'what branches do I have', 'anything to clean up', 'which worktree is X on', or a bare /nick:branchmap. Read-only; hands remove:* rows to /nick:cleanup."
---

# branchmap

Runs `branch-map` (`~/.dotfiles/bin/branch-map`, python3, no deps) and reports. The tool is the
source of truth; do not re-derive its facts by hand.

## 1. Run

- Bare invoke or "anything to clean up": `branch-map --candidates` from inside the repo.
- "Show everything" / "which worktree is X on": `branch-map` (full table) or `branch-map --json`.
- `--no-status` when the user wants it fast; `--refresh` when a PR just merged and the 15-minute
  PR cache may be stale. Another repo: `--repo <path>`.

## 2. Read the verdicts (first matching rule wins)

| Verdict | Meaning | What to say |
|---|---|---|
| `remove:merged` / `remove:closed` | PR done, nothing unpushed, worktree clean | removable now; offer `/nick:cleanup <branch>` |
| `remove:no-commits` | no PR, zero commits beyond base, clean | removable now |
| `review:merged-wip` / `review:closed-wip` | PR done but local changes or unpushed commits remain | list what remains; user decides |
| `review:no-pr` | commits beyond base, no PR | in-progress or forgotten; never remove unasked |
| `keep:open` / `keep:open-stale` | open PR (stale = no activity for 60 days) | keep; mention stale ones in one line |
| `conductor:*` | a Conductor workspace | NEVER a removal target; "archive it in Conductor" |
| `main` | the main checkout | ignore |

Columns: `vs base` = commits ahead/behind `origin/HEAD`; `UPSTREAM` = `sync`, `gone`, `none` or
git's ahead/behind text; `DIRTY` = modified/untracked counts; `CTX` = files under `.context/`,
`.omc/{plans,research,autopilot}`, `.ignore/` (working context git status never shows);
`LAST` = last commit date.

## 3. Report

Lead with the count per verdict group, then the `remove:*` rows as a short table, then
`review:*` rows with one line each on why they are not removable. Keep and conductor rows are a
single sentence unless asked. Close with the one next action (usually `/nick:cleanup <branch>...`
for the remove rows, or nothing to clean).

## Never

- Never remove anything from this skill; it is read-only. Removal goes through `/nick:cleanup`.
- Never treat a `conductor:*` row as removable, whatever the PR state says.
