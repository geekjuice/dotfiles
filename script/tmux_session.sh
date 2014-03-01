#!/bin/zsh

# Colors
blue='\e[0;34m'
yellow='\e[0;33m'
reset='\e[0m'

# If not attached to tmux session
if [ ! -n "$TMUX" ]; then
  # NOTE: Should replace with flag options (getopts)
  args=("$@")
  [ "$args[1]" = "-m" ] && MIN=1 || MIN=0
  [ "$args[1+MIN]" != "" ] && SESSIONNAME="$args[1+MIN]" || SESSIONNAME=$(basename `pwd`)
  [ "$args[2+MIN]" != "" ] && DIRNAME="$args[2+MIN]" || DIRNAME="$(pwd)"

  # Check is session exists
  tmux has-session -t $SESSIONNAME &> /dev/null

  if [ $? != 0 ]; then
    # Go to dir
    [ -d "$DIRNAME" ] && cd $DIRNAME

    # First window (General Shell)
    tmux new-session -s $SESSIONNAME -n shell -d
    tmux send-keys -t $SESSIONNAME "cls" C-m

    # Second window (Vim)
    tmux new-window -n vim
    tmux split-window -h -p 33
    tmux select-pane -t 2
    if [[ -d .git ]]; then
      tmux send-keys "clear" C-m "git status" C-m
    fi
    tmux select-pane -t 1
    if [[ -f Session.vim ]]; then
      tmux send-keys -t $SESSIONNAME "clear" C-m "vim -S Session.vim"
    else
      tmux send-keys -t $SESSIONNAME "clear" C-m "vim"
    fi

    # Third window (Servers)
    if [ $MIN = 0 ];then
      tmux new-window -n server
      tmux split-window -h -p 66
      tmux select-pane -t 2
      tmux send-keys "clear" C-m "foreman start"
      tmux select-pane -t 1
      tmux send-keys "clear && list" C-m
      tmux split-window -v -p 50
      tmux send-keys "clear" C-m "zeus start"
      tmux select-pane -t 1
    fi

    # Select second window
    tmux select-window -t $SESSIONNAME:2

    # Return to original dir
    [ -d "$DIRNAME" ] && cd -;
  fi

  # Attach to created session
  tmux attach -t $SESSIONNAME
else
  echo "${blue}In session: ${yellow}$(tmux display-message -p '#S')${reset}"
fi
