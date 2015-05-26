##########################################
# DIRECTORY
##########################################
DOT=$HOME/.dotfiles

##########################################
# ANTIGEN
##########################################
source $DOT/.antigen/antigen.zsh

antigen use oh-my-zsh
antigen bundle git
antigen bundle battery
antigen bundle bower
antigen bundle brew
antigen bundle node
antigen bundle npm
antigen bundle nvm
antigen bundle tmux
antigen bundle zsh-users/zsh-syntax-highlighting
antigen apply

##########################################
# OH-MY-ZSH SETUP
##########################################
# Disable auto title names
DISABLE_AUTO_TITLE=true

# Display red dots while waiting for completion
COMPLETION_WAITING_DOTS="true"

##########################################
# ZSH SETTINGS
##########################################
# Vi mode
bindkey -v
bindkey "^F" vi-cmd-mode
bindkey jj vi-cmd-mode

# Edit command in editor
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Use incremental search
bindkey "^R" history-incremental-search-backward

# Handy keybindings
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey -s "^S" "^[Isudo ^[A" # "s" for "sudo"
bindkey -s "^T" "^[Itx ^[A"   # "t" for "tmux/transmit"

# Expand functions in the prompt
setopt prompt_subst

# Ignore duplicate history entries
setopt histignorealldups

# Automatically pushd
setopt auto_pushd
export dirstacksize=5

# Enable extended globbing
setopt EXTENDED_GLOB


##########################################
# INCLUDE
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

# Rbenv
eval "$(rbenv init -)"

# Go
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

# Nvm
[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh

# Clean up path
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

