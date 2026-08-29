# Nix Configuration

This repo uses [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager) to declaratively manage macOS environments. It replaces `install.sh` (package installation) and `symlink.sh` (dotfile linking) with a single reproducible configuration.

## Prerequisites

1. **Homebrew** — must be installed first (nix-darwin manages casks through it, but does not install Homebrew itself):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Nix** — install via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (recommended over the official installer):

   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh
   ```

3. **Clone this repo** to `~/.dotfiles` (the zshrc and nix config both expect this path):

   ```sh
   git clone https://github.com/geekjuice/dotfiles.git ~/.dotfiles
   ```

## Quick Start

```sh
cd ~/.dotfiles
darwin-rebuild switch --flake .#nick
```

That's it. This single command will:

- Install all CLI tools via nix
- Install all GUI apps via Homebrew casks
- Symlink all dotfiles to their expected locations
- Bootstrap TPM (tmux plugin manager) and install tmux plugins
- Generate local SSL certificates via mkcert (if not already present)

Open a new terminal session afterward for all shell changes to take effect.

Neovim plugins are managed by lazy.nvim and self-bootstrap on first launch. Zim (zsh framework) also self-installs on first shell session.

## What Gets Installed

### CLI Packages (via nix)

Managed in `nix/home.nix`. Installed into the nix profile — no Homebrew needed for these.

| Category | Packages |
|----------|----------|
| Shells | zsh, bash |
| Version management | mise |
| File & directory | eza, fd, yazi, zoxide |
| Editors | vim, neovim |
| Git | git, gh, git-delta, lazygit |
| Terminal multiplexer | tmux, tmuxp |
| Search | ripgrep, fzf |
| Data & JSON | bat, jq, jnv, fx |
| System & utilities | htop, watch, viddy, rsync, coreutils, gnused, dust, icloudpd |
| Diff & color | difftastic, pastel |
| Security | mkcert |
| Dev tools | direnv, worktrunk, stylua |

### GUI Apps (via Homebrew casks)

Managed in `nix/darwin.nix`. nix-darwin runs `brew bundle` under the hood.

arc, bitwarden, claude-code, cleanshot, clop, conductor, discord, docker-desktop, figma, font-hack-nerd-font, ghostty, google-chrome, hammerspoon, httpie-desktop, iterm2, jordanbaird-ice, meetingbar, proxyman, raycast, slack, spotify, syncthing-app, tailscale-app, temurin, visual-studio-code

### Homebrew Formulae

Only packages that require Homebrew-specific paths stay as brews:

- `pam-reattach` — needs `/opt/homebrew/lib/pam/` for sudo Touch ID support

## What Gets Symlinked

Managed in `nix/home.nix` via `home.file`. All symlinks point directly at repo files, so edits are live without rebuilding.

| Category | Targets |
|----------|---------|
| Home dotfiles | `.zshrc`, `.zimrc`, `.editorconfig`, `.gitconfig`, `.gitignore`, `.tmux.conf`, `.tmuxline.conf`, `.inputrc`, `.npmrc`, `.psqlrc`, `.ripgreprc`, `.tool-versions`, `.hushlogin`, `.default-npm-packages` |
| Directories | `.localssl/`, `.hammerspoon/`, `.githooks/`, `.agents/`, `.tmuxp/` |
| XDG config | `nvim/`, `yazi/`, `direnv/direnv.toml`, `worktrunk/config.toml`, `dex/dex.toml` |
| macOS App Support | `lazygit/config.yml`, `com.mitchellh.ghostty/config` |
| Claude | `CLAUDE.md`, `keybindings.json`, `settings.json`, `skills/pr` |

## Automatic Setup

The following are handled by `home.activation` scripts in `nix/home.nix`. They run during every `darwin-rebuild switch` and are idempotent (skip if already done).

- **TPM** — clones tmux plugin manager to `~/.tmux/plugins/tpm` if missing, then installs plugins
- **mkcert** — runs `mkcert -install` and generates `localhost.pem`/`localhost.key` if the cert files don't exist

### Self-Bootstrapping Tools

These tools manage their own setup automatically — no activation scripts needed:

- **lazy.nvim** — neovim plugin manager, bootstraps from `nvim/init.lua` on first launch
- **zim** — zsh framework, bootstraps from `zshrc` on first shell session

## Day-to-Day Usage

### Rebuild after config changes

```sh
darwin-rebuild switch --flake ~/.dotfiles#nick
```

Run this after editing any file in `nix/`. Dotfile content changes (e.g., editing `zshrc`, `nvim/`) do **not** require a rebuild since they're symlinked directly.

### Add a new CLI package

Edit `nix/home.nix` and add to `home.packages`:

```nix
home.packages = with pkgs; [
  # ...existing packages...
  newpackage
];
```

Then rebuild.

### Add a new GUI app (cask)

Edit `nix/darwin.nix` and add to `homebrew.casks`:

```nix
casks = [
  # ...existing casks...
  "new-cask"
];
```

Then rebuild. Note: `cleanup = "zap"` means any cask installed via Homebrew but **not** listed here will be removed on rebuild.

### Update all nix inputs

```sh
cd ~/.dotfiles
nix flake update
darwin-rebuild switch --flake .#nick
```

This pulls the latest nixpkgs, nix-darwin, and home-manager.

### Garbage collection

```sh
# Remove old generations and unreferenced store paths
nix-collect-garbage -d
```

## File Structure

```
dotfiles/
  flake.nix          # Flake entry point — inputs (nixpkgs, nix-darwin, home-manager)
                     # and the darwinConfigurations."nick" definition
  nix/
    darwin.nix       # System-level: Homebrew casks/brews, nix settings, shell, user
    home.nix         # User-level: CLI packages, dotfile symlinks, activation scripts
```

## Post-Install (Manual)

These steps can't be automated via nix:

### Touch ID for sudo

```sh
sudo vim /etc/pam.d/sudo_local
```

Add these lines at the top:

```
auth optional /opt/homebrew/lib/pam/pam_reattach.so
auth sufficient pam_tid.so
```

### iTerm2 session persistence

Set `Prefs > Advanced > Allow sessions to survive logging out and back in` to **No**.

### Nord iTerm2 theme

One-time import:

```sh
curl -OL https://raw.githubusercontent.com/arcticicestudio/nord-iterm2/master/src/xml/Nord.itermcolors
open Nord.itermcolors
rm Nord.itermcolors
```

## Troubleshooting

### `darwin-rebuild: command not found`

After installing nix, open a new terminal or run:

```sh
source /etc/zshrc
```

### Homebrew not found during rebuild

nix-darwin expects Homebrew at `/opt/homebrew/bin/brew` (Apple Silicon) or `/usr/local/bin/brew` (Intel). Ensure Homebrew is installed before running `darwin-rebuild switch`.

### PATH conflicts between nix and Homebrew

Nix packages take precedence when nix paths appear earlier in `$PATH`. If you need the Homebrew version of a tool, either remove it from `home.packages` or adjust PATH ordering in `zshrc`.

### Homebrew cask removed unexpectedly

The `cleanup = "zap"` setting removes any Homebrew-managed formula or cask not declared in `darwin.nix`. To keep manually-installed casks alongside the nix config, change to `cleanup = "none"` in `nix/darwin.nix`.

### Symlink conflicts

If `darwin-rebuild switch` fails with "existing file" errors, the target file already exists and isn't a symlink. Back it up and remove it:

```sh
mv ~/.zshrc ~/.zshrc.bak
darwin-rebuild switch --flake ~/.dotfiles#nick
```
