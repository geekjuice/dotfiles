#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
TMP_DIR="$DOTFILES_DIR/.tmp"

resolve() {
  if [[ "$OUTPUT" =~ ^/ ]]; then
    echo "$OUTPUT"
  else
    echo "$HOME/$OUTPUT"
  fi
}

declare -A OUTPUTS=(
  # dotfiles
  ["gitconfig"]=".gitconfig"
  ["gitignore"]=".gitignore"
  ["githooks"]=".githooks"
  ["inputrc"]=".inputrc"
  ["hushlogin"]=".hushlogin"
  ["psqlrc"]=".psqlrc"
  ["ripgreprc"]=".ripgreprc"
  ["tmux.conf"]=".tmux.conf"
  ["tmuxline.conf"]=".tmuxline.conf"
  ["vim"]=".vim"

  # ubuntu specific
  ["ubuntu/vimrc"]=".vimrc"
  ["ubuntu/zshrc"]=".zshrc"
)

echo "clearing previously cached..."
rm -rf $TMP_DIR/*

for INPUT in "${!OUTPUTS[@]}"
do
  OUTPUT=${OUTPUTS[$INPUT]}
  SOURCE="$DOTFILES_DIR/$INPUT"
  DESTINATION=$(resolve "$OUTPUT")
  echo "symlinking $SOURCE to $DESTINATION"
  cp -rf "$DESTINATION" "$TMP_DIR/$INPUT" 2>/dev/null
  rm -rf "$DESTINATION"
  ln -sf "$SOURCE" "$DESTINATION"
done
