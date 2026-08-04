---
user-invocable: true
description: Rebase the current branch onto the latest base (develop/main/master, whichever this repo uses), resolve conflicts, and optionally restack a stack of PRs and force-push. Use for "rebase with latest develop", "rebase on main", "restack", "rebase #N and repush".
---

# Restack

Rebase onto the latest base and resolve the conflicts. Two shapes:

- **Single branch** (default) — the current branch onto the latest base. No PR needed.
- **Stack** — two or more PRs/branches, rebased parent-before-child and force-pushed.

`$ARGUMENTS` is zero or more PR numbers or branch names **in stack order, oldest first**
(`#112692 #112362`, `6,9,11,12`, `fix/login-redirect`). No arguments means the current branch only.

## 1. Resolve the base

Never assume `develop` or `main`. First hit wins:

```bash
BASE=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null)          # open PR for this branch
[ -z "$BASE" ] && BASE=$(git symbolic-ref -q --short refs/remotes/origin/HEAD | sed 's#^origin/##')
[ -z "$BASE" ] && BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
```

Then sanity-check it against what the repo actually branches from:
`git ls-remote --heads origin develop main master`. If `origin/develop` exists and the resolved
base is something else, that is a genuine choice — ask which one, don't guess. Gitflow repos often
report `main` as the default while every feature branch lives on `develop`.

Empty `BASE`, or no `origin` remote at all → stop and ask. A wrong base rebases onto nothing.

If `$ARGUMENTS` is empty and the current branch **is** `$BASE`, there is nothing to
restack. Stop and ask for a target in one line — a branch name or a PR number. Do not
enumerate open PRs to guess one: the list is long, the guess is wrong, and the user
already knows which branch they meant.

Say the base you resolved, and how, before touching anything.

## 2. Fetch and take a safety line

```bash
git fetch origin --prune
git rev-parse HEAD                     # note it; this is the pre-rebase escape hatch
git rev-list --count origin/$BASE..HEAD   # commits about to be replayed
```

Dirty tree → `git stash push -u -m restack` first, restore at the end, and say you did.

If `git merge-base --is-ancestor origin/$BASE HEAD` succeeds, the branch is already on the latest
base. Say so and stop. Nothing to do is a valid outcome.

## 3. Rebase

Single branch: `git rebase origin/$BASE`.

Stack: read the real parent chain first — `gh pr view <n> --json number,baseRefName,headRefName,state,mergedAt`
for each target. The argument order is a hint, the PR metadata is the truth. If a target's base PR is
already merged, retarget it at the root base first (`gh pr edit <n> --base "$BASE"`) and say so;
rebasing onto a merged branch replays commits that are already upstream and manufactures conflicts.
Then, parent before child: `git rebase --onto <new-base> <old-base> <branch>`.

**Never `git rebase --skip`** — a skipped commit silently drops work. If things go sideways,
`git rebase --abort` returns to the SHA from step 2.

## 4. Conflicts

During a rebase the sides are inverted: `--ours` is the base you're landing on, `--theirs` is your
own commit. Check which is which before reaching for either.

**Resolve it yourself** when the resolution is mechanical and checkable:

- Both sides added independent entries (imports, exports, cases, list items) → keep both, in the
  file's existing order.
- Lockfiles and generated output → regenerate from the post-rebase source (`pnpm install --lockfile-only`,
  the codegen command, whatever the repo uses). Never hand-merge a lockfile.
- Upstream moved or deleted a file you only reformatted → take upstream.
- Both sides made the same change → take either, and say so.

**Ask** when the choice is real, meaning any of:

- Both sides changed the same logic in incompatible ways.
- Upstream deleted, renamed, or changed the signature of something your commits call.
- The merge is textually clean but the result is probably wrong (moved constant, renamed helper,
  changed default).

Use `AskUserQuestion`, one question per conflict, up to 4 per call. Put the actual hunk — both sides,
trimmed to the relevant lines — in the question text so it can be decided without opening the file.
Options: take mine, take upstream, combine (describe how). Leave the tree mid-rebase while asking.
Do not `--abort` to ask a question, and do not guess and push.

Stage by name (`git add <file>`), then `git rebase --continue`. Never `git add .`.

State each resolution in one line: which file, which side won, why.

## 5. Check it still builds

After the last conflict, run the repo's fast check over what you touched — typecheck the changed
files, run the test file next to them. A rebase that compiles is the only evidence the resolutions
held. Report the result either way; don't skip this because the conflicts looked trivial.

## 6. Push

`--force-with-lease`, never bare `--force`. A rejected lease means someone else moved the branch:
stop and report.

If the branch has no upstream (`git rev-parse --abbrev-ref @{upstream}` fails), it's local-only.
Stop after the rebase and say so rather than creating a remote branch.

For a stack, verify each push didn't absorb its parent: `gh pr diff <n> --name-only`. A PR whose
file list suddenly includes its parent's files was rebased onto the wrong point. Catching it here is
the difference between one bad branch and a bad stack.

## 7. Report

Single branch: base, commits replayed, conflicts and how each was resolved, new SHA, push status.
Stack: a table — PR, old base, new base, conflicts resolved, pushed SHA.

## Rules

- Never amend commit messages during a restack. A restack moves commits; it doesn't rewrite them.
- Never add an issue or PR number to a commit subject or body (see CLAUDE.md Git rules).
- Never `git add .` or `git add -A` while resolving — name the conflicted files.
- Restore the stash at the end if you took one, and say whether it applied cleanly.
- Re-running `/nick:pr <n>` afterwards is a separate step; this skill does not touch PR bodies.
