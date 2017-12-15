export BINPATH="$DOTFILES_DIR/bin"
if [[ ! "$PATH" == *${BINPATH}* ]]; then
  export PATH="$PATH:${BINPATH}"
fi

