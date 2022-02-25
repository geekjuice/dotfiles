#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"

trap "exit" INT

if [[ $(uname -s) != "Darwin" ]]; then
  echo "Script meant for MacOS. Exiting..."
  exit 1
fi

echo "Installing optional cask packages..."
brew install --cask \
  arc \
  beekeeper-studio \
  discord \
  docker \
  emacs \
  figma \
  firefox \
  insomnia \
  mongodb-compass \
  numi \
  openemu \
  virtualbox \
  visual-studio-code \

echo "Installing optional homebrew packages..."
brew install \
  bottom \
  croc \
  entr \
  exa \
  git-delta \
  golang \
  hyperfine \
  imagemagick \
  moreutils \
  navi \
  ncdu \
  neofetch \
  nginx \
  pastel \
  rsync \
  scc \
  sd \
  starship \
  stow \
  tldr \
  xplr \

echo "Installing optional custom homebrew packages..."
brew install \
  jesseduffield/horcrux/horcrux \
  jesseduffield/lazydocker/lazydocker \
  jesseduffield/lazynpm/lazynpm \
  mongodb/brew/mongodb-community \
  xwmx/taps/nb \

echo "Installing embark iterm theme..."
curl -OSL https://raw.githubusercontent.com/embark-theme/iterm/master/colors/Embark.itermcolors
open Embark.itermcolors
rm -rf Embark.itermcolors

echo "Installing rust toolchain installer..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "Optional manual installs..."
echo "  - Affinity Designer- https://affinity.serif.com/en-us/designer/"

echo "All done!"
