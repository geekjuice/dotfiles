#!/bin/bash

########################################
# Tmux Split Resizer
#
# written by Nicholas 'Geekjuice' Hwang
# created 2013-12-27
#
# Notes:
# - Exits if tmux or tput does not exist
#
# - Resizes panes by lines or percentage
#
# - Assumes panes of similiar split i.e.
#   all veritcal or horizontal splits.
#
# - Greedy in the sense that it exits
#   once second-to-last pane is reached
########################################


# Exit if tput and tmux do not exist
type tput >/dev/null 2>&1 && type tmux >/dev/null 2>&1 || { exit 1; }

# Use prebreak or 66/33 default on no args
PREBREAK=0

# Defaults
SPLIT="-x"          # Default to horizontal tmux splits
PANE=0              # Counter for pane loop
TOTALSIZE=0         # Total size used
PERCENTAGE=1        # Use percents
NOARG=1             # Early break on no non-opt args
DEFAULTSPLIT=67     # Default 66/33% split for no-arg falthrough

# Process options
while getopts pavh opt; do
    case $opt in
        p)  # Use Percentage
            PERCENTAGE=1;;
        a)  # Use absolute
            PERCENTAGE=0;;
        v)  # Vertical Split
            SPLIT="-y";;
        h)  # Horizontal Split
            SPLIT="-x";;
    esac
done

# Early breaker to avoid resize-pane swap
for ARG in $@; do [[ $ARG != *[!0-9]* ]] && NOARG=0 && break; done
if [[ $NOARG -eq 1 ]] && [[ $PREBREAK -eq 1 ]]; then
    echo "usage: tmux_resize_split [-vhap] args"
    exit 1;
fi

# Get total width and height
tmux resize-pane -Z
if [[ "$SPLIT" = "-y" ]]; then
    BLOCK=$(tput lines)
else
    BLOCK=$(tput cols)
fi
tmux resize-pane -Z

# Cache greedy break point
[[ $PERCENTAGE -eq 1 ]] && BREAKPOINT=100 || BREAKPOINT=$BLOCK

# Cache last pane numbe
LASTPANE=$(tmux list-panes | wc -l)

# Process arguments and resize panes (greedy)
for ARG in $@; do
    # Only process integer arguments
    if [[ $ARG != *[!0-9]* ]]; then
        TOTALSIZE=$(expr $TOTALSIZE + $ARG)
        if [[ $TOTALSIZE -lt $BREAKPOINT ]]; then
            PANE=$(expr $PANE + 1)
            # Break if last pane
            [[ $PANE -eq $LASTPANE ]] && break;
            if [[ $PERCENTAGE -eq 1 ]] ; then
                SIZE=$(expr $BLOCK \* $ARG / 100)
                tmux resize-pane $SPLIT $SIZE -t $PANE
            else
                tmux resize-pane $SPLIT $ARG -t $PANE
            fi
        fi
    fi
done

# Fallthrough default for no args
if [[ $NOARG -eq 1 ]]; then
    SIZE=$(expr $BLOCK \* $DEFAULTSPLIT / 100)
    tmux resize-pane $SPLIT $SIZE -t 1
fi
