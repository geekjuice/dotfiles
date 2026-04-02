#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"

trap "exit" INT

if [[ $(uname -s) != "Darwin" ]]; then
  echo "Script meant for MacOS. Exiting..."
  exit 1
fi

echo "Installing optional packages from Brewfile.optional..."
brew bundle --file=$DOTFILES_DIR/Brewfile.optional

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
