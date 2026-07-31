---
user-invocable: true
description: "Mirror a git worktree's state into the main worktree, so the dev server, editor and build cache already running there see an agent's changes without a branch switch. Subcommands: start, refresh, status, stop. One-way and non-destructive."
---

# Spotlight

Put what a worktree currently looks like into the main worktree, so the things
that only run there (dev server on a fixed port, editor window, warm build
cache, hard-coded paths) exercise an agent's changes without a branch switch.

All the work is done by the `spotlight` CLI (`~/.dotfiles/bin/spotlight`, on
PATH). **Always drive it through that command.** Never hand-roll the git: the
CLI is what knows how to put the main worktree back, and improvised
`checkout`/`stash`/`rsync` will lose someone's work.

## Inputs

Map what the user said onto one subcommand:

| They said | Run |
|---|---|
| "spotlight this", "spotlight my worktree", "run this in main" | `spotlight start` (from the worktree) |
| "spotlight `<branch>`", "put fix/login in main" | `spotlight start <branch>` |
| "keep it in sync", "watch it", "auto-refresh" | `spotlight start --watch` (if already spotlit, `stop` then `start --watch`) |
| "refresh", "update it", "push my latest over", "re-sync" | `spotlight refresh` |
| "what's spotlit?", "is it still current?" | `spotlight status` |
| "stop", "undo it", "give me my repo back" | `spotlight stop` |
| bare `/nick:spotlight` with no context | `spotlight status`, then offer the obvious next step |

Flags worth knowing: `--watch[=sec]` (poll and re-sync, default 3s),
`--branch[=name]` (leave the main worktree on a named branch instead of detached
HEAD, for tooling that reads the branch name), `--to <path>` (a target other
than the main worktree), `--no-stash` (refuse rather than stash a dirty main
worktree), `--force` (see the rules below).

`start` accepts a worktree path, a branch name, or a unique substring of either.

## The model to explain, if asked

- A checkpoint commit is built from a **scratch index**, so the worktree's HEAD,
  index, stash and files are never touched. Untracked-but-not-ignored files are
  included; the agent doesn't have to commit anything first.
- That commit is checked out in the main worktree (detached by default). The
  main worktree ends up byte-identical to the worktree for everything git tracks.
- **Ignored files are never synced.** `node_modules`, `.env`, `dist` and friends
  stay exactly as the main worktree has them, which is what makes the running
  dev server survive the swap.
- **One-way.** Edits made in the main worktree while spotlit do not travel back.
- Nothing is deleted. Uncommitted work in the main worktree is parked in a
  labelled `git stash` entry and restored by `stop`.

## Rules

1. **Edit in the worktree, never in the spotlit main worktree.** Make the change
   in the source worktree (`spotlight status` prints its path), then run
   `spotlight refresh`. Edits made in the main checkout aren't on the branch, and
   the next refresh parks them in a stash.
2. **Don't commit from the main worktree while spotlit.** It's on a detached
   checkpoint commit. Commit in the worktree.
3. **`--force` is the user's call, not yours.** Every `--force` path moves work
   the user did by hand (parks it in a stash, or takes the checkout back off
   whatever they switched to). Say what it will do and get a yes first. The
   refusal messages are there to be read out, not routed around.
4. **`stop` when the testing is done.** A spotlit repo is a surprising thing to
   walk up to later. If you started it, offer to stop it.
5. Report the actual command output. If it refuses, relay why and the suggested
   fix rather than trying something else.

## After running

Say which worktree is spotlit onto which path, and how to undo it. On `start`,
mention whether uncommitted work got parked. If the user has a dev server up,
point out that it should have hot-reloaded.

## When it refuses

| Message | What to do |
|---|---|
| unfinished `rebase-merge` / `MERGE_HEAD` etc. | Finish or abort it in the named worktree (`git rebase --continue`, `git merge --abort`), then retry. |
| "already spotlit onto …" | `spotlight stop` first, or `start <target> --force` to switch. Ask which. |
| "local edits that a refresh would overwrite" | Those edits exist only in the main worktree. Offer: move them into the worktree yourself, or `refresh --force` to park them in a stash. |
| "moved off the spotlight commit" | Someone checked something else out. `stop` cleans up state without disturbing it; `--force` takes it back. Ask. |
| "the main worktree is not something you can spotlight onto itself" | You're in the main checkout. Name the worktree: `spotlight start <branch>`. |
| bare repo, no main worktree | Pass `--to <path>` to pick a target checkout. |
| stash restore failed on `stop` | The work is still in the stash. Give the exact `git -C <main> stash pop <ref>` from the output. |

## Not doing

- Syncing back the other way. If work happened in the main worktree by mistake,
  move it across by hand (`git -C <main> diff > /tmp/p && git -C <wt> apply /tmp/p`).
- Promoting a spotlight into real changes on the main branch. `stop` restores;
  it never keeps. To keep the work, merge or cherry-pick the branch normally.
- Submodules and git-lfs pointers get whatever a plain checkout gives them.
