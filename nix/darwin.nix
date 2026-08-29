{ pkgs, ... }:

{
  # ──────────────────────────────────────────────
  # Homebrew (nix-darwin manages the bundle declaratively)
  # NOTE: Homebrew itself must be pre-installed
  # ──────────────────────────────────────────────
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # remove formulae/casks not declared here
    };
    casks = [
      "arc"
      "bitwarden"
      "claude-code"
      "cleanshot"
      "clop"
      "conductor"
      "discord"
      "docker-desktop"
      "figma"
      "font-hack-nerd-font"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "httpie-desktop"
      "iterm2"
      "jordanbaird-ice"
      "meetingbar"
      "proxyman"
      "raycast"
      "slack"
      "spotify"
      "syncthing-app"
      "tailscale-app"
      "temurin"
      "visual-studio-code"
    ];
    # Packages that must come from Homebrew (no nix equivalent or path-dependent)
    brews = [
      "pam-reattach" # needs /opt/homebrew/lib/pam/ path for sudo Touch ID
    ];
  };

  # ──────────────────────────────────────────────
  # Nix
  # ──────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ──────────────────────────────────────────────
  # System
  # ──────────────────────────────────────────────
  programs.zsh.enable = true;
  system.stateVersion = 5;

  users.users.nick = {
    name = "nick";
    home = "/Users/nick";
  };
}
