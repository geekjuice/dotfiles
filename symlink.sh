#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
TMP_DIR="$DOTFILES_DIR/.tmp"
MACOS_DIR="Library/Application Support"

declare -A OUTPUTS=(
  # dotfiles
  ["gitconfig"]=".gitconfig"
  ["gitignore"]=".gitignore"
  ["hammerspoon"]=".hammerspoon"
  ["hushlogin"]=".hushlogin"
  ["tmux.conf"]=".tmux.conf"
  ["tmuxline.conf"]=".tmuxline.conf"
  ["vim"]=".vim"
  ["vimrc"]=".vimrc"
  ["zshrc"]=".zshrc"

  # settings
  ["settings.json"]="$MACOS_DIR/Code/User/settings.json"
)

echo "Clearing previously cached..."
rm -rf $TMP_DIR/*

for INPUT in "${!OUTPUTS[@]}"
do
  SOURCE="$DOTFILES_DIR/$INPUT"
  DESTINATION="$HOME/${OUTPUTS[$INPUT]}"
  echo "Symlinking $SOURCE to $DESTINATION"
  cp -rf "$DESTINATION" "$TMP_DIR/$INPUT" 2>/dev/null
  rm -rf "$DESTINATION"
  ln -sf "$SOURCE" "$DESTINATION"
done
