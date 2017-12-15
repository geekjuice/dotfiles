export FZF_PLUGIN_DIR="/usr/share/fzf"

# Auto-completion
# ---------------
if [[ -f "$FZF_PLUGIN_DIR/completion.zsh"  ]]; then
  source "$FZF_PLUGIN_DIR/completion.zsh" 2> /dev/null
fi

# Key bindings
# ------------
if [[ -f "$FZF_PLUGIN_DIR/key-bindings.zsh"  ]]; then
  source "$FZF_PLUGIN_DIR/key-bindings.zsh" 2> /dev/null
fi

# Prefer ripgrep
# ----------------------
if [[ -x "$(command -v rg)"  ]]; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --no-messages"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
