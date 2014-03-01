#!/bin/bash

##################################################
#
#   Broadcast Tmux Command
#
#   Invokes command on all panes in current or
#   all tmux windows
#
#   TODO: Consider only running when in session
#         Fix callee window calls fn ~3 times
#
##################################################


# Case insenstive regex matching
shopt -s nocasematch;

# Help
showhelp () {
    printf "usage: tx [OPTIONS] [COMMAND]\n\n"
    printf "options:\n"
    printf "    -h          Show this help message\n"
    printf "    -w          All tmux windows and panes\n"
    exit 1;
}

# Function to run command
runCommand () {
    # Cache globbed command
    local _COMMAND=$@
    # Check pane task i.e. vim, bash, etc
    local _TASK=$(tmux display-message -p '#{pane_current_command}')
    # If bash or zsh i.e. no GUI, run command
    if [[ $_TASK =~ (ba|z)sh ]]; then
        tmux send-keys "$_COMMAND" C-m
    # Else place process in background, run command, and forground process
    else
        for i in {1..25}; do tmux send-keys Escape; done
        tmux send-keys C-z
        tmux send-keys "$_COMMAND; fg" C-m
    fi
}

# Loop through panes
loopPanes () {
    local _ARR=( $@ )
    local _LEN=${#_ARR[@]}
    local _COMMAND=${_ARR[@]:0:$_LEN-1}
    local _SKIP_PANE=${_ARR[$_LEN-1]}
    # Get array of panes in current window
    _PANES=$(tmux list-panes | awk '{print $1}' | tr -d ':')
    # Loop through each available pane
    for _PANE in $_PANES; do
        # Continue on if pane is the pane where command called
        if [ $_SKIP_PANE -gt 0 ]; then
            if [ $_PANE -eq $_SKIP_PANE ]; then continue; fi
        fi
        # Select pane and run command
        tmux select-pane -t $_PANE
        runCommand $_COMMAND
    done
}

# Process options
while getopts :wh opt; do
    case $opt in
        h)  # Help
            showhelp ;;
        w)  # Windows
            _USE_WINDOWS=1 ;;
        \?)  # Catch all
            printf "Invalid option: -$OPTARG\n"
            exit 1 ;;
    esac
done
shift $(($OPTIND - 1))

# Check for remaining arguments
if [[ $# -eq 0 ]]; then
    printf "Err.. not enough arguments\n\n"
    showhelp
fi

# Cache commands
_COMMAND=$@
# Cache window number where command called
_CALLEE_WINDOW=$(tmux display-message -p '#I')
# Cache pane number where command called
_CALLEE_PANE=$(tmux display-message -p '#P')
# Get array of windows in current session
_WINDOWS=$(tmux list-windows | awk '{print $1}' | tr -d ':')

# If running on all windows, loop windows
if [[ -n $_USE_WINDOWS ]]; then
    for _WINDOW in $_WINDOWS; do
        tmux select-window -t $_WINDOW
        loopPanes $_COMMAND -1
    done
# Else just loop current window
else
    loopPanes $_COMMAND $_CALLEE_PANE
fi

# Return to original pane and call command
tmux select-window -t $_CALLEE_WINDOW
tmux select-pane -t $_CALLEE_PANE
runCommand $_COMMAND
