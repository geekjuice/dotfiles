##########################################
# OH-MY-ZSH SETUP
##########################################
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
DOT=$HOME/.dotfiles

# Disable auto title names
DISABLE_AUTO_TITLE=true

# Display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Plugins
plugins=(battery bower brew gem npm nvm zsh-syntax-highlighting)

# Start zsh
source $ZSH/oh-my-zsh.sh


##########################################
# ZSH SETTINGS
##########################################
# vi mode
bindkey -v
bindkey "^F" vi-cmd-mode
bindkey jj vi-cmd-mode

# use incremental search
bindkey "^R" history-incremental-search-backward

# handy keybindings
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey -s "^S" "^[Isudo ^[A" # "s" for "sudo"
bindkey -s "^T" "^[Itx ^[A"   # "t" for "tmux/transmit"

# expand functions in the prompt
setopt prompt_subst

# ignore duplicate history entries
setopt histignorealldups

# automatically pushd
setopt auto_pushd
export dirstacksize=5

# Enable extended globbing
setopt EXTENDED_GLOB


##########################################
# INCLUDES
##########################################
[ -e "$DOT/aliases" ] && source "$DOT/aliases"


##########################################
# ZSH ALIAS
##########################################
alias zr="vim $DOT/zshrc"
alias rf='unalias -m "*" && source ~/.zshrc'


##############################
# PROMPT
##############################
[ -e "$DOT/include/prompt" ] && source "$DOT/include/prompt"


##########################################
# RBENV, JENV, CABAL, NVM, & CLEANUP PATH
##########################################
# Haskell/Cabal
export PATH=$HOME/Library/Haskell/bin:$DOT/bin:$HOME/.rbenv/bin:$PATH

# Java
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# RBENV
eval "$(rbenv init -)"

# GO
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

# NVM
[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh

# CLEAN UP
[ -e "$DOT/script/cleanup_path.sh" ] && source "$DOT/script/cleanup_path.sh"


##########################################
# Z
##########################################
if command -v brew >/dev/null 2>&1; then
    [ -f $(brew --prefix)/etc/profile.d/z.sh ] && source $(brew --prefix)/etc/profile.d/z.sh
fi


##########################################
# HUBSPOT
##########################################
source ~/.hsrc


##########################################
# Initiate TMUX
##########################################
[[ -z "$TMUX" ]] && $SCRIPT/start_tmux.sh hubspot

