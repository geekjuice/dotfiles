---
user-invocable: true
description: "Bring Claude Code sessions back into their tmux panes after a reboot or tmux crash. Use for 'resume my sessions', 'restore my claude sessions', 'bring my tmux sessions back', or a bare /nick:revive. Also takes a manual snapshot."
---

# Revive

tmux-resurrect restores panes, not the programs in them. The `revive` CLI
(`~/.dotfiles/bin/revive`, on PATH) remembers which Claude session ran in which
pane and types the matching `claude --resume` back in. **Always drive it
through that command.** It knows the traps: the launch dir can differ from the
pane's cwd, `--resume` only finds a transcript from its launch dir, and tmux
resolves a missing pane to some other pane.

Snapshots are automatic. The tmux-resurrect post-save hook runs
`revive snapshot` on every continuum save (every 15 min). `restore` reads the
newest snapshot taken **before this boot**, so saves made after the reboot
can't shadow the sessions that were lost.

## Inputs

| They said | Run |
|---|---|
| "resume/restore/revive my sessions", bare `/nick:revive` | `revive restore --dry-run`, then `revive restore` |
| "snapshot my sessions", "save them before I reboot" | `revive snapshot` |
| "use an older snapshot" | `ls ~/.local/state/revive`, then `revive restore --from <file>` |

## Steps

1. Run `revive restore --dry-run` and show the output as a table: pane,
   session name, and either "resume" or the skip reason.
2. If the user already asked to restore, go straight to step 3. For a bare
   `/nick:revive`, ask first.
3. Run `revive restore`. Wait a few seconds, then run
   `tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'`
   and confirm each resumed pane shows `claude`.

## Skips to relay, not route around

| Output | What it means |
|---|---|
| `was suspended` | Two sessions shared that pane and this one was behind `^Z`. Ask before reviving it; offer a new pane. |
| `pane missing` | resurrect didn't bring the pane back. Offer to create it and rerun, or give the printed command. |
| `pane busy (<cmd>)` | Something else runs there. Don't interrupt it. Give the printed command. |
| `this pane` | That's the session running the skill. Nothing to do. |
| `already running` | Live somewhere already. Nothing to do. |
| `no transcript` | The session file is gone. It can't be resumed. |

Panes that ran something other than Claude (dev servers, `node`) are not in the
snapshot. Say they came back as bare shells.
