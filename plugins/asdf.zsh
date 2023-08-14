export SHIMPATH="$HOME/.asdf/shims"
if [[ ! "$PATH" == *${SHIMPATH}* ]]; then
  export PATH="$PATH:${SHIMPATH}"
fi

