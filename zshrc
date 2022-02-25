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
autoload -U compinit && compinit

export ZPLUG_HOME="${BREW_PREFIX}/opt/zplug"
source $ZPLUG_HOME/init.zsh

zplug "mafredri/zsh-async"
zplug "sindresorhus/pure"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"

if ! zplug check; then
  zplug install
fi

zplug load

for plugin in ${DOTFILES_DIR}/plugins/*; do
  if [[ -f "${plugin}" ]]; then
    source "${plugin}"
  fi
done

typeset -U PATH
