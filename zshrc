export DOTFILES_DIR="$HOME/.dotfiles"
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export NVM_LAZY_LOAD=true

bindkey -v
bindkey "jj" vi-cmd-mode
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

autoload -U compinit && compinit

source <(antibody init)

antibody bundle lukechilds/zsh-nvm
antibody bundle mafredri/zsh-async
antibody bundle sindresorhus/pure
antibody bundle zsh-users/zsh-completions
antibody bundle zsh-users/zsh-syntax-highlighting

source $DOTFILES_DIR/plugins/directories.zsh
source $DOTFILES_DIR/plugins/fzf.zsh
source $DOTFILES_DIR/plugins/go.zsh
source $DOTFILES_DIR/plugins/history.zsh
source $DOTFILES_DIR/plugins/klaviyo.zsh
source $DOTFILES_DIR/plugins/z.zsh
