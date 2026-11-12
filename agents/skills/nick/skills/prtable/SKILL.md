---
user-invocable: true
description: "Table a set of PRs grouped by stack in merge order: summary, impact, safe to merge (no regressions), QA'd, and lines of code. Takes PR numbers, an issue, or a branch stack. Read-only. Flags: `--stack <branch>`, `--repo <owner/name>`, `--copy`."
---

# prtable

One table per stack that answers "what is each of these PRs, who does it reach, can it merge, was it QA'd, how big is it". Read-only: never comment, merge, push, or edit a PR.

## 1. Resolve the PR set

`$ARGUMENTS` picks it. First match wins:

- **PR numbers or URLs** → exactly those.
- **An issue** (`#N`, `N` that `gh issue view` resolves, or an issue URL) → its open linked PRs: the issue's timeline cross-references (`gh api graphql` on `timelineItems(itemTypes:[CROSS_REFERENCED_EVENT,CONNECTED_EVENT])`) plus `gh pr list --state open --search "N in:body"`. If `.ignore/investigations/issue-N.md` exists, add the PRs its body names.
- **`--stack <branch>`** → the PR for that branch, every PR below it (follow `baseRefName` until the default branch), and every PR above it (`gh pr list --base <head>` repeatedly).
- **Anaphoric** ("the PRs", "these", "both stacks") → the PRs opened, pushed, or discussed in this conversation, including prerequisites named alongside them. If the conversation has none, ask which PRs, don't guess.

Print the resolved list with a count in one line before fetching.

## 2. Fetch, in parallel

Per PR: `gh pr view <n> --json number,url,title,body,state,isDraft,mergeable,mergeStateStatus,baseRefName,headRefName,headRefOid,additions,deletions,files,reviewDecision`. Then:

- `mergeable` is `UNKNOWN` → query once more. Still unknown → `git fetch` both refs and run `git merge-tree --write-tree --name-only origin/<base> origin/<head>`; a `CONFLICT` line means conflicting. Name the file and the develop commit that caused it (`git log <merge-base>..origin/<base> -- <file>`).
- `gh pr checks <n> --json name,state`: drop `CANCELLED`, count `FAILURE`. Only report CI when something is red.

## 3. Group and order

A PR whose base is another listed PR's head stacks on it. One table per stack, rows bottom to top (merge order). Unrelated PRs share one table. Give each table a short heading naming what the stack does.

## 4. Columns

| Column | Rule |
|---|---|
| PR | `[#N](url)` |
| Summary | One clause, 12 words max, from the PR's What?. Plain words. |
| Impact | Who or what it reaches: orgs, flag, config key, BP or surface. "None by itself" for flag-only or inert PRs. Derive from the diff (flags read, config read, paths), not the title. |
| Safe to merge (no regressions)? | **Yes**, **Yes, with a caveat**, or **No, not yet**, plus one reason. "No" for a conflict, red CI, or an unmerged parent it depends on. "Caveat" for an unflagged behavior change to existing orgs, or a config-driven failure mode. If this conversation or the issue checkpoint already gave a Merge verdict and the head SHA hasn't moved, carry it forward by name. |
| QA'd? | **Yes** only when the body's "QA Steps Taken" block sits outside `<!-- -->`, or QA ran in this session with evidence. Add the date if known, and "re-check" if the PR was rebased or conflicted since. Otherwise **No**, with why in parens: steps still commented out, nothing to QA, no behavior change. Never infer Yes from passing tests. |
| LoC | `+A / −D`, then test lines in parens: the sum of additions in files matching `.test.` or `.spec.`. Name generated files or lockfiles if they dominate. |

## 5. After the tables

- One line saying what the safety calls rest on: a review score, today's conflict check, or notes. Say which rows were derived fresh and which were carried forward.
- If a PR needs a rebase or an unmerged parent, say so in one line with the order.
- Close with who has the ball and one next action ("Next: you — say 'rebase' and I'll…").

## `--copy`

Also write a paste-ready version to the scratchpad, `pbcopy` it, and show it in a fenced block. Slack doesn't render tables, so the paste version is one line per PR: `#N <summary> · <impact> · safe: <verdict> · QA: <yes/no> · +A/−D`. Keep the `|` table in the terminal.

## Voice

The Voice rules in `~/.claude/CLAUDE.md` apply to every cell. No filler, no em-dash pileups, no restating the column header in the cell.
