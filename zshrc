export EDITOR="vim"
export NVM_LAZY_LOAD=true

export DOTFILES_DIR="$HOME/.dotfiles"

bindkey -v
bindkey "jj" vi-cmd-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

fpath=($fpath $DOTFILES_DIR/completions)
zstyle ":completion:*" matcher-list "m:{a-z}={A-Z}"
autoload -U compinit && compinit

source <(antibody init)

antibody bundle lukechilds/zsh-nvm
antibody bundle mattberther/zsh-pyenv
antibody bundle mafredri/zsh-async
antibody bundle sindresorhus/pure
antibody bundle zsh-users/zsh-completions
antibody bundle zsh-users/zsh-syntax-highlighting
antibody bundle blimmer/zsh-aws-vault

for plugin in $DOTFILES_DIR/plugins/*; do
  source "$plugin"
done

typeset -U PATH
