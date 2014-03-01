#!/bin/sh
############################
# PATH Cleaner
############################

# Turn off globbing, to allow unprotected variable substitutions
set -f
IFS=:
old_PATH=$PATH:; PATH=
while [ -n "$old_PATH" ]; do
    x=${old_PATH%%:*}       # the first remaining entry
    case $PATH: in
        *:${x}:*) :;;         # already there
        *) PATH=$PATH:$x;;    # not there yet
    esac
    old_PATH=${old_PATH#*:}
done
PATH=${PATH#:}
set +f; unset IFS old_PATH x
export PATH=$PATH
