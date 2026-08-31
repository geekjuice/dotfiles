---
user-invocable: true
description: "DRAFT — Walk manual QA for a PR or stack: restack on latest base, spotlight, seed local data, hand over steps one at a time, then uncomment each PR's QA block as it passes. Use for 'start QA', 'QA this', 'restack then QA', 'give me step by step QA'."
---

# qa

The chain you type by hand: restack on latest develop, spotlight, generate data as needed, step-by-step QA per PR, then show the QA sections on the PRs.

## 1. Target

The PR or stack named in the args, else the current branch's PR (and its stack, if
`gh pr list --base <branch>` finds children). Print the PR URLs.

## 2. Restack

Run the `/nick:restack` flow on the target (whole stack if there is one). If it stops on a
conflict or a refused push, QA waits.

## 3. Pick the unit

Say it in one line: per PR when each PR's body has its own QA block, otherwise the top PR of the
stack covers all. Order bottom-up.

## 4. For each unit

1. `spotlight start <branch>` (or `spotlight refresh` if already spotlit on it). Tell Nick
   whether the dev server should hot-reload or needs a restart.
2. Seed what the steps need: local DB rows (SQL printed with `-- DB: <name>, port <n>`), a
   feature-flag flip (flag caches ~60s), a stubbed external call. Run what you can yourself;
   print what Nick has to run.
3. Hand over one step with its **Expect:** line. Stop and wait for the result. Quote UI labels
   as the frontend source has them.
4. A failed step: diagnose, fix in the worktree, `spotlight refresh`, and re-hand the same step
   in full.
5. When every step in the unit passed, uncomment that PR's QA block per the `/nick:pr` QA rule:
   pull the body, write the steps actually run, drop givens, `gh pr edit --body-file`.

## 5. Close

`spotlight stop`. Print a table: PR URL, QA'd | skipped (why), QA block uncommented yes/no.
End with the next action, usually "Waiting on you: merge <URL>".
