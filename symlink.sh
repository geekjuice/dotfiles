#!/usr/bin/env bash

DOTFILES_DIR=$HOME/.dotfiles
TMP_DIR=$DOTFILES_DIR/.tmp

declare -A OUTPUTS=(
  # dotfiles
  ["gitconfig"]=".gitconfig"
  ["gitignore"]=".gitignore"
  ["hushlogin"]=".hushlogin"
  ["tmux.conf"]=".tmux.conf"
  ["tmuxline.conf"]=".tmuxline.conf"
  ["vim"]=".vim"
  ["vimrc"]=".vimrc"
  ["xinitrc"]=".xinitrc"
  ["zshrc"]=".zshrc"

  # configs
  ["i3"]=".config/i3"
  ["i3blocks"]=".config/i3blocks"
  ["rofi"]=".config/rofi"
  ["yay"]=".config/yay"

  # simple terminal
  ["st/config.h"]=".pkg/st/config.h"
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
