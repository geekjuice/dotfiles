{ pkgs, ... }:

let
  dotfilesDir = "/Users/nick/.dotfiles";
in
{
  home.stateVersion = "24.05";

  # ──────────────────────────────────────────────
  # CLI Packages (replaces `brew install` from Brewfile)
  # ──────────────────────────────────────────────
  home.packages = with pkgs; [
    # shells
    zsh
    bash

    # version management
    mise

    # file & directory
    eza
    fd
    yazi
    zoxide

    # editors
    vim
    neovim

    # git
    git
    gh
    git-delta
    lazygit

    # terminal multiplexer
    tmux
    tmuxp

    # search
    ripgrep
    fzf

    # data & json
    bat
    jq
    jnv
    fx

    # system & utilities
    htop
    watch
    viddy
    rsync
    coreutils
    gnused
    dust
    icloudpd

    # diff & color
    difftastic
    pastel

    # security
    mkcert

    # dev tools
    direnv
    worktrunk
    stylua
  ];

  # ──────────────────────────────────────────────
  # Dotfile symlinks (replaces symlink.sh)
  #
  # Using absolute paths so nix creates symlinks pointing directly
  # at the repo files — edits are live without rebuilding.
  # ──────────────────────────────────────────────
  home.file = {
    # ── Home dotfiles ──
    ".editorconfig".source        = "${dotfilesDir}/editorconfig";
    ".gitconfig".source           = "${dotfilesDir}/gitconfig";
    ".gitignore".source           = "${dotfilesDir}/gitignore";
    ".githooks".source            = "${dotfilesDir}/githooks";
    ".hammerspoon".source         = "${dotfilesDir}/hammerspoon";
    ".hushlogin".source           = "${dotfilesDir}/hushlogin";
    ".inputrc".source             = "${dotfilesDir}/inputrc";
    ".npmrc".source               = "${dotfilesDir}/npmrc";
    ".psqlrc".source              = "${dotfilesDir}/psqlrc";
    ".ripgreprc".source           = "${dotfilesDir}/ripgreprc";
    ".tmux.conf".source           = "${dotfilesDir}/tmux.conf";
    ".tmuxline.conf".source       = "${dotfilesDir}/tmuxline.conf";
    ".tool-versions".source       = "${dotfilesDir}/tool-versions";
    ".zshrc".source               = "${dotfilesDir}/zshrc";
    ".zimrc".source               = "${dotfilesDir}/zimrc";

    # ── Directories ──
    ".localssl".source            = "${dotfilesDir}/localssl";
    ".agents".source              = "${dotfilesDir}/agents";
    ".tmuxp".source               = "${dotfilesDir}/tmuxp";

    # ── npm ──
    ".default-npm-packages".source = "${dotfilesDir}/default-npm-packages";

    # ── XDG config ──
    ".config/direnv/direnv.toml".source    = "${dotfilesDir}/direnv.toml";
    ".config/yazi".source                  = "${dotfilesDir}/yazi";
    ".config/nvim".source                  = "${dotfilesDir}/nvim";
    ".config/worktrunk/config.toml".source = "${dotfilesDir}/worktrunk.toml";
    ".config/dex/dex.toml".source          = "${dotfilesDir}/dex.toml";

    # ── macOS Application Support ──
    "Library/Application Support/lazygit/config.yml".source        = "${dotfilesDir}/lazygit.yml";
    "Library/Application Support/com.mitchellh.ghostty/config".source = "${dotfilesDir}/ghostty";

    # ── Claude ──
    ".claude/CLAUDE.md".source         = "${dotfilesDir}/claude/CLAUDE.md";
    ".claude/keybindings.json".source  = "${dotfilesDir}/claude/keybindings.json";
    ".claude/settings.json".source     = "${dotfilesDir}/claude/settings.json";
    ".claude/skills/pr".source         = "${dotfilesDir}/claude/skills/pr";
  };

  # ──────────────────────────────────────────────
  # Activation scripts (replaces one-time install steps)
  #
  # These are idempotent — safe to re-run on every switch.
  # ──────────────────────────────────────────────
  home.activation = {
    # TPM + tmux plugins
    installTpm = ''
      TPM_DIR="$HOME/.tmux/plugins/tpm"
      if [ ! -d "$TPM_DIR" ]; then
        ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
      fi
      if [ -x "$TPM_DIR/bin/install_plugins" ]; then
        "$TPM_DIR/bin/install_plugins" || true
      fi
    '';

    # mkcert local SSL certificates
    installLocalSsl = ''
      CERT_FILE="${dotfilesDir}/localssl/localhost.pem"
      KEY_FILE="${dotfilesDir}/localssl/localhost.key"
      if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        ${pkgs.mkcert}/bin/mkcert -install 2>/dev/null || true
        ${pkgs.mkcert}/bin/mkcert \
          -cert-file "$CERT_FILE" \
          -key-file "$KEY_FILE" \
          localhost
      fi
    '';
  };

  # ──────────────────────────────────────────────
  # Let home-manager manage itself
  # ──────────────────────────────────────────────
  programs.home-manager.enable = true;
}
