#!/usr/bin/env zsh

setopt +o nomatch

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$HOME/.config"
MACOS_DIR="Library/Application Support"

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
  ["asdfrc"]=".asdfrc"
  ["gitconfig"]=".gitconfig"
  ["gitignore"]=".gitignore"
  ["githooks"]=".githooks"
  ["hammerspoon"]=".hammerspoon"
  ["hushlogin"]=".hushlogin"
  ["inputrc"]=".inputrc"
  ["localssl"]=".localssl"
  ["npmrc"]=".npmrc"
  ["psqlrc"]=".psqlrc"
  ["ripgreprc"]=".ripgreprc"
  ["tmux.conf"]=".tmux.conf"
  ["tmuxline.conf"]=".tmuxline.conf"
  ["vim"]=".vim"
  ["vimrc"]=".vimrc"
  ["zshrc"]=".zshrc"

  # npm
  ["default-npm-packages"]="$HOME/.default-npm-packages"

  # configs
  ["direnv.toml"]="$CONFIG_DIR/direnv/direnv.toml"
  ["rc.conf"]="$CONFIG_DIR/ranger/rc.conf"
  ["init.lua"]="$CONFIG_DIR/nvim/init.lua"

  # settings
  ["settings.json"]="$MACOS_DIR/Code/User/settings.json"
  ["keybindings.json"]="$MACOS_DIR/Code/User/keybindings.json"
  ["lazydocker.yml"]="$MACOS_DIR/lazydocker/config.yml"
  ["lazygit.yml"]="$MACOS_DIR/lazygit/config.yml"
)

echo "clearing previously cached..."
rm -rf $TMP_DIR/*

for INPUT OUTPUT in "${(@kv)OUTPUTS}"
do
  SOURCE="$DOTFILES_DIR/$INPUT"
  DESTINATION=$(resolve "$OUTPUT")
  echo "symlinking $SOURCE to $DESTINATION"
  mkdir -p "$(dirname "$DESTINATION")"
  cp -rf "$DESTINATION" "$TMP_DIR/$INPUT" 2>/dev/null
  rm -rf "$DESTINATION"
  ln -sf "$SOURCE" "$DESTINATION"
done
