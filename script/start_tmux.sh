#!/bin/bash

# Colors
red='\e[0;31m'
green='\e[0;32m'
blue='\e[0;34m'
yellow='\e[0;33m'
reset='\e[0m'

# Validate input
validate_input() {
    local input=$1
    local limit=$2
    local re='^(\s*|[0-9]+)$'
    if ! [[ "$input" =~ $re ]]; then
        printf "${red}Error: $input is not a valid number\n" >&2; exit 1
    fi
    if ! [[ $input -gt 0 && $input -le $limit ]]; then
        printf "${red}Error: $input is not a valid choice\n" >&2; exit 1
    fi
}

# Detach and connect
detach_and_connect() {
    local session=$1
    local attach_type="attach"
    [[ "$2" =~ [sS] ]] && attach_type="switch"
    if [[ -n "$(tmux list-clients -t $session)" ]]; then
        printf "${blue}Detach existing clients from ${yellow}[$session]${blue}?${reset}\n"
        printf "${red}» ${green}" && read detach && printf "${reset}"
        if [[ "$detach" =~ [yY] ]]; then
            tmux $attach_type -d -t $session
        else
            tmux $attach_type -t $session
        fi
    else
        tmux $attach_type -t $session
    fi
}

# Obtain array of tmux sessions
sessions=( $(tmux ls 2> /dev/null | cut -d ':' -f 1) )
number_of_sessions=${#sessions[@]}
# If there are sessions
if [[ $number_of_sessions -gt 0 ]]; then
    current_session=$(tmux display-message -p '#S')
    # If there is only one session
    if [[ $number_of_sessions -eq 1 ]]; then
        if [[ ! -n "$TMUX" ]]; then
            detach_and_connect ${sessions[0]}
        else
            printf "${blue}Already in the only session: ${yellow}$current_session${reset}\n"
        fi
    else
        # List out sessions
        printf "${blue}Enter session to attach ${yellow}[Default: nick || 1]${blue}:${reset}\n"
        for (( n=0; n<$number_of_sessions; n++ )); do
            printf "${green}[$(expr $n + 1)] ${reset}${sessions[$n]}\n"
        done
        # Prompt for user input
        printf "${red}» ${green}" && read chosen_session && printf "${reset}"
        validate_input $chosen_session $number_of_sessions
        # Determine new session
        if [ -n "$chosen_session" ]; then
            chosen_session=$(expr $chosen_session - 1)
            new_session=${sessions[$chosen_session]}
        else
            if [[ "$(tmux ls)" == *nick* ]]; then
                new_session="nick"
            else
                new_session=${sessions[0]}
            fi
        fi
        if [[ "$new_session" != "$current_session" ]]; then
            # Attach or switch to new session
            if [[ ! -n "$TMUX" ]]; then
                detach_and_connect $new_session
            else
                detach_and_connect $new_session "switch"
            fi
        else
            printf "${blue}Already in session: ${yellow}$current_session${reset}\n"
        fi
    fi
    # Else if no sessions, create new called nick
else
    tmux new-session -s nick -n geek -d
    tmux send-keys -t nick "cls" C-m
    tmux attach -t nick
fi

