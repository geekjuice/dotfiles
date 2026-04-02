export EDITOR="vim"

export DOTFILES_DIR="${HOME}/.dotfiles"

if [[ "$(uname -p)" == "arm" ]]; then
  export BREW_PREFIX="/opt/homebrew"
else
  export BREW_PREFIX="/usr/local"
fi

eval "$(${BREW_PREFIX}/bin/brew shellenv)"

bindkey -v
bindkey "jj" vi-cmd-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

fpath=($fpath $DOTFILES_DIR/completions)
zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"

export ZIM_HOME="${HOME}/.zim"
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
  source ${ZIM_HOME}/zimfw.zsh install -q
fi
source ${ZIM_HOME}/init.zsh

for plugin in ${DOTFILES_DIR}/plugins/*; do
  if [[ -f "${plugin}" ]]; then
    source "${plugin}"
  fi
done

typeset -U PATH
