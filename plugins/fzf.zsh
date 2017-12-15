export FZF_PLUGIN_DIR="/usr/local/opt/fzf"

# Setup fzf
# ---------
if [[ ! "$PATH" == *$FZF_PLUGIN_DIR/bin* ]]; then
  export PATH="$PATH:$FZF_PLUGIN_DIR/bin"
fi

# Auto-completion
# ---------------
if [[ -r "$FZF_PLUGIN_DIR/shell/completion.zsh" ]]; then
  source "$FZF_PLUGIN_DIR/shell/completion.zsh" 2> /dev/null
fi

# Key bindings
# ------------
if [[ -r "$FZF_PLUGIN_DIR/shell/key-bindings.zsh" ]]; then
  source "$FZF_PLUGIN_DIR/shell/key-bindings.zsh" 2> /dev/null
fi

# Prefer ripgrep
# ----------------------
if [[ -x "$(command -v rg)" ]]; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --no-messages"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
