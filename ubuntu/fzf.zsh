export FZF_PLUGIN_DIR="$HOME/.fzf"

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
