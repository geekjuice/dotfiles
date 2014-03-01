#!/bin/bash
##############################
# FANCY SYMBOLS
##############################
# Colors
RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
RESET='\e[0m'

printf "${BLUE}Fancy Symbols ${RESET}have been turned: "
if [[ "$FANCY_SYMBOLS" = "true" ]] || [[ "$1" = *off* ]]; then
    export FANCY_SYMBOLS=false
    printf "${RED}OFF\n"
else
    export FANCY_SYMBOLS=true
    printf "${GREEN}ON\n"
fi
