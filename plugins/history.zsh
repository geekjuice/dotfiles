export HISTFILE=$HOME/.zhistory

export HISTSIZE=50000
export SAVEHIST=50000

setopt BANG_HIST              # treat '!' specially during expansion
setopt EXTENDED_HISTORY       # write timestamps to history file
setopt HIST_EXPIRE_DUPS_FIRST # expire duplicates first when trimming
setopt HIST_FIND_NO_DUPS      # don't display duplicates when searching
setopt HIST_IGNORE_DUPS       # don't record consecutive duplicates
setopt HIST_IGNORE_SPACE      # skip commands starting with space
setopt HIST_VERIFY            # show expanded history before executing
setopt SHARE_HISTORY          # share history across sessions
