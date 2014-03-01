##############################
# TMUX COMMANDS
##############################
alias tx="$SCRIPT/tx.sh"
alias tmx="$SCRIPT/tmux_session.sh"
alias tma="$SCRIPT/start_tmux.sh"
alias trs="$SCRIPT/tmux_resize_split.sh"
alias tmn="tmux attach -t nick &> /dev/null || tmux new -s nick"
alias tml="tmux ls 2> /dev/null"
alias tmk="tmux kill-session -t"
