---
user-invocable: true
description: DRAFT — Rebase a branch or a stack of PRs onto the latest base, resolve conflicts, restack dependents, and force-push. Use for "rebase with latest develop", "restack", "rebase #N and repush".
---

# Restack

Rebase one branch or a stack of PRs onto the latest base, resolving conflicts along the way, then force-push each.

`$ARGUMENTS` is zero or more PR numbers or branch names **in stack order, oldest first** (`#112692 #112362`, `6,9,11,12`, `fix/login-redirect`). No arguments means the current branch only.

> DRAFT: written from 13 sessions of hand-driving this sequence. Unrefined — expect to correct it in use.

## Steps

1. **Resolve the root base.** Never assume `develop` or `main`:

   ```bash
   BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null) \
     || BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
   ```

   Empty `BASE` → stop and ask. A wrong base silently rebases onto nothing.

2. **Fetch, then read the stack.** `git fetch origin`. For each target in order:
   `gh pr view <n> --json number,baseRefName,headRefName,state,mergedAt`. Build the real
   parent chain from `baseRefName` rather than trusting the order given — the argument
   order is a hint, the PR metadata is the truth. Say what you found before touching anything.

3. **Retarget orphans.** If a target's base PR is already merged, point it at the root base
   first (`gh pr edit <n> --base "$BASE"`) and say so. Rebasing onto a merged branch replays
   commits that are already upstream and manufactures conflicts.

4. **Rebase oldest-first.** For each target, in parent-before-child order:
   `git rebase --onto <new-base> <old-base> <branch>`. On a conflict, resolve it and state
   each resolution in one line — which file, which side won, why. **Never `git rebase --skip`**;
   a skipped commit silently drops work. If a conflict isn't clearly resolvable, stop the whole
   restack with the tree mid-rebase and ask, rather than guessing and pushing.

5. **Push with `--force-with-lease`.** Never bare `--force`. A rejected lease means someone
   else moved the branch — stop and report, don't retry with `--force`.

6. **Verify each push didn't absorb its parent.** `gh pr diff <n> --name-only` after each one.
   A PR whose file list suddenly includes its parent's files was rebased onto the wrong point.
   Catching this here is the difference between one bad branch and a bad stack.

7. **Report a table:** PR, old base, new base, conflicts resolved, pushed SHA.

## Rules

- Never amend commit messages during a restack. A restack moves commits; it doesn't rewrite them.
- Never add an issue or PR number to a commit subject or body (see CLAUDE.md Git rules).
- Never `git add .` or `git add -A` while resolving — name the conflicted files.
- If the working tree is dirty when you start, stash first and restore at the end, or ask.
- Re-running `/nick:pr <n>` afterwards is a separate step; this skill does not touch PR bodies.
