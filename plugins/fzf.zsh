export FZF_PLUGIN_DIR="$BREW_PREFIX/opt/fzf"

# Auto-completion
[[ -r "$FZF_PLUGIN_DIR/shell/completion.zsh" ]] && source "$FZF_PLUGIN_DIR/shell/completion.zsh"

# Key bindings
[[ -r "$FZF_PLUGIN_DIR/shell/key-bindings.zsh" ]] && source "$FZF_PLUGIN_DIR/shell/key-bindings.zsh"

# Prefer ripgrep
if [[ -x "$(command -v rg)" ]]; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --no-messages"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
