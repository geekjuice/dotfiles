---
user-invocable: true
description: "DRAFT — QA a PR or stack: restack on latest base, spotlight, seed local data, run each step yourself (Playwright MCP, CLI, SQL) and hand Nick only the steps that need a human, then uncomment each PR's QA block as it passes. Use for 'start QA', 'QA this', 'restack then QA', 'automated QA'. Flags: `--manual` (hand every step over one at a time)."
---

# qa

The chain you type by hand: restack on latest develop, spotlight, generate data as needed, QA per PR (automated by default), then show the QA sections on the PRs.

## 1. Target

The PR or stack named in the args, else the current branch's PR (and its stack, if
`gh pr list --base <branch>` finds children). Print the PR URLs. Then the mode in one line:
`QA: automated (Playwright + CLI); will stop at any step that needs you` or `QA: manual (--manual)`.

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
3. Run the step yourself first: Playwright MCP against the spotlit dev server for UI, the CLI or
   ops tool for commands, SQL for data. Keep the evidence (screenshot, output, row count) against
   the step's **Expect:** line and mark it `passed (automated)`. Hand Nick only a step that needs a
   human: a login or 2FA he holds, an external approval, a visual judgment. Say how many of those
   there are before the first one. Each goes over as `**Step N of M.**` with its **Expect:** line,
   opened by the previous result (`Step N-1 passed.`) and closed with
   `Waiting on you: "pass", or what you see.` Stop and wait. Quote UI labels as the frontend
   source has them. With `--manual`, every step goes over this way.
4. A failed step: diagnose, fix in the worktree, `spotlight refresh`, and re-hand the same step
   in full.
5. When every step in the unit passed, uncomment that PR's QA block per the `/nick:pr` QA rule:
   pull the body, write the steps actually run, drop givens, `gh pr edit --body-file`.
6. If the unit's PR qualifies under the `/nick:pr` Screenshots rule, take the before/after shots
   while the app is already spotlit and hand them to the step-5 body refresh.

## 5. Close

`spotlight stop`. Print a table: PR URL, QA'd | skipped (why), QA block uncommented yes/no.
End with the next action, usually "Waiting on you: merge <URL>".
