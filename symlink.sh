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
  ["editorconfig"]=".editorconfig"
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
  ["tool-versions"]=".tool-versions"
  ["vim"]=".vim"
  ["vimrc"]=".vimrc"
  ["zshrc"]=".zshrc"
  ["zimrc"]=".zimrc"

  # npm
  ["default-npm-packages"]="$HOME/.default-npm-packages"

  # claude
  ["claude/CLAUDE.md"]="$HOME/.claude/CLAUDE.md"
  ["claude/keybindings.json"]="$HOME/.claude/keybindings.json"
  ["claude/settings.json"]="$HOME/.claude/settings.json"
  ["claude/skills/pr"]="$HOME/.claude/skills/pr"
  ["claude/skills/review"]="$HOME/.claude/skills/review"

  # configs
  ["direnv.toml"]="$CONFIG_DIR/direnv/direnv.toml"
  ["yazi"]="$CONFIG_DIR/yazi"
  ["nvim"]="$CONFIG_DIR/nvim"
  ["worktrunk.toml"]="$CONFIG_DIR/worktrunk/config.toml"
  ["dex.toml"]="$CONFIG_DIR/dex/dex.toml"
  ["mise-config.toml"]="$CONFIG_DIR/mise/config.toml"

  # settings
  ["lazygit.yml"]="$MACOS_DIR/lazygit/config.yml"
  ["ghostty"]="$MACOS_DIR/com.mitchellh.ghostty/config"

  # agents
  ["agents"]="$HOME/.agents"

  # templates
  ["tmuxp"]="$HOME/.tmuxp"
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
