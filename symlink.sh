#!/usr/bin/env bash

DOTFILES_DIR="$HOME/.dotfiles"
TMP_DIR="$DOTFILES_DIR/.tmp"
CONFIG_DIR="$HOME/.config"
MACOS_DIR="Library/Application Support"
LOCAL_ETC="/usr/local/etc"

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

  # nvm
  ["default-packages"]="$NVM_DIR/default-packages"

  # configs
  ["direnv.toml"]="$CONFIG_DIR/direnv/direnv.toml"
  ["starship.toml"]="$CONFIG_DIR/starship.toml"
  ["rc.conf"]="$CONFIG_DIR/ranger/rc.conf"

  # settings
  ["nginx.conf"]="$LOCAL_ETC/nginx/nginx.conf"
  ["settings.json"]="$MACOS_DIR/Code/User/settings.json"
  ["keybindings.json"]="$MACOS_DIR/Code/User/keybindings.json"
  ["lazydocker.yml"]="$MACOS_DIR/lazydocker/config.yml"
  ["lazygit.yml"]="$MACOS_DIR/lazygit/config.yml"
  ["lazynpm.yml"]="$MACOS_DIR/lazynpm/config.yml"
)

echo "clearing previously cached..."
rm -rf $TMP_DIR/*

for INPUT in "${!OUTPUTS[@]}"
do
  OUTPUT=${OUTPUTS[$INPUT]}
  SOURCE="$DOTFILES_DIR/$INPUT"
  DESTINATION=$(resolve "$OUTPUT")
  echo "symlinking $SOURCE to $DESTINATION"
  mkdir -p "$(dirname "$DESTINATION")"
  cp -rf "$DESTINATION" "$TMP_DIR/$INPUT" 2>/dev/null
  rm -rf "$DESTINATION"
  ln -sf "$SOURCE" "$DESTINATION"
done
