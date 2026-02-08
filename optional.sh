#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"

trap "exit" INT

if [[ $(uname -s) != "Darwin" ]]; then
  echo "Script meant for MacOS. Exiting..."
  exit 1
fi

echo "Installing optional cask packages..."
brew install --cask \
  alfred \
  bartender \
  beekeeper-studio \
  boop \
  charles \
  claude-code \
  dash \
  discord \
  emacs \
  firefox \
  folx \
  ghostty \
  http-toolkit \
  insomnia \
  mongodb-compass \
  numi \
  openemu \
  shottr \
  virtualbox \
  zed \

echo "Installing optional homebrew packages..."
brew install \
  bottom \
  croc \
  entr \
  golang \
  hyperfine \
  icloudpd \
  imagemagick \
  lnav \
  moreutils \
  navi \
  ncdu \
  neofetch \
  nginx \
  pastel \
  pipx \
  scc \
  sd \
  shortcat \
  starship \
  stow \
  tlrc \
  worktrunk \
  xplr \

echo "Installing optional custom homebrew packages..."
brew install \
  cjbassi/gotop/gotop \
  cloudflare/cloudflare/cloudflared \
  jesseduffield/horcrux/horcrux \
  jesseduffield/lazydocker/lazydocker \
  jesseduffield/lazynpm/lazynpm \
  mongodb/brew/mongodb-community \
  TomAnthony/brews/itermocil \
  xwmx/taps/nb \

echo "Installing embark iterm theme..."
curl -OSL https://raw.githubusercontent.com/embark-theme/iterm/master/colors/Embark.itermcolors
open Embark.itermcolors
rm -rf Embark.itermcolors

echo "Installing rust toolchain installer..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "Installing pipx packages..."
pipx ensurepath
pipx install terminaltexteffects

echo "Optional manual installs..."
echo "  - Affinity Designer- https://affinity.serif.com/en-us/designer/"

echo "All done!"
