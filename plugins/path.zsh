export LOCALSBINPATH="$BREW_PREFIX/sbin"
if [[ ! "$PATH" == *${LOCALSBINPATH}* ]]; then
  export PATH="$PATH:${LOCALSBINPATH}"
fi

export DOTBINPATH="$HOME/.bin"
if [[ ! "$PATH" == *${DOTBINPATH}* ]]; then
  export PATH="$PATH:${DOTBINPATH}"
fi

export DOTLOCALBINPATH="$HOME/.local/bin"
if [[ ! "$PATH" == *${DOTLOCALBINPATH}* ]]; then
  export PATH="$PATH:${DOTLOCALBINPATH}"
fi

export PROJECTBINPATH=".git/safe/../../.bin"
if [[ ! "$PATH" == *${PROJECTBINPATH}* ]]; then
  export PATH="${PROJECTBINPATH}:${PATH}"
fi
