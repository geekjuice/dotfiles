---
user-invocable: true
description: "DRAFT — Tear down after a PR merges or closes: stop spotlight, remove the worktree, delete the local and remote branch. Use for 'merged', 'clean up', 'remove the branch/worktree'. `/nick:cleanup <pr|branch>...` for named targets; bare invoke sweeps every worktree whose PR is merged or closed."
---

# cleanup

The teardown you type by hand after every merge: "merged. stop spotlight, delete local branch and worktree."

## 1. Resolve targets

- Args given: each is a PR number, URL, or branch. Resolve to `{pr, branch, state}` with
  `gh pr view <ref> --json number,headRefName,state,url`.
- Bare invoke: run `branch-map --candidates --json` (see /nick:branchmap) and take its rows. Print a table:
  verdict, branch, worktree, PR URL. Then one AskUserQuestion to confirm removing the `remove:*` rows.
  `review:*` rows are listed with their reason, never removed. `conductor:*` rows never appear as
  candidates; if the user names one, say "archive it in Conductor".

## 2. Guards (per target, before touching anything)

- PR is OPEN: stop and ask. "Close the PR and remove it" in the request counts as a yes for
  `gh pr close <n>` first.
- Worktree has uncommitted changes (`git -C <path> status --porcelain`) or commits not on the
  remote (`git -C <path> log @{upstream}..` non-empty, or no upstream): refuse for that target and
  print what would be lost. Never pass `--force`.
- Path is under `~/conductor/workspaces/`: refuse. It is a Conductor workspace; `wt remove` deletes its
  `.context/` (pasted attachments, todos, plan docs) that only the app's Archive moves to
  `~/conductor/archived-contexts/<repo>/`. Say "archive it in Conductor" and move on. A branch with zero commits
  beyond develop is NOT proof the workspace is empty.
- `git -C <path> status --porcelain --ignored` lists anything under `.context/`, `.omc/plans`, `.omc/research`,
  `.omc/autopilot` or `.ignore/` beyond an empty `todos.md`: refuse and print the list.

## 3. Tear down, in order

1. `spotlight status`: if it names this branch's worktree, `spotlight stop`.
2. `wt remove -D <branch>`. `-D` is needed because squash merges don't read as merged to git;
   the PR state from step 1 is the proof. This deletes the worktree and the local branch.
3. Remote: `git ls-remote --heads origin <branch>`. If it still lists it,
   `git push origin --delete <branch>`.
4. `git worktree prune`.

## 4. Report

One line per target: `✓ <branch> (<PR URL>, merged): spotlight stopped · worktree removed · local ✓ · remote ✓|already gone`.
Refused targets are listed with the reason. Close with what's left, or `Nothing left to clean.`
