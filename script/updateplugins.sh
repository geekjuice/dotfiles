#!/bin/bash
# Update VIM bundles

# Vim bundle dir
DOT=$HOME/.dotfiles

# Colors
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
blue='\e[0;34m'
reset='\e[0m'

# Start
printf "${blue}=========================================================${reset}\n"
printf "${yellow}                 Updating Git Submodules                ${reset}\n"
printf "${blue}=========================================================${reset}\n"

# Cache location of directory
if [[ "$1" = "" ]]; then
    dir=$DOT/vim/bundle  # vim-plugin dir
else
    dir="$1"
fi

# Cache original location
original_location=$(pwd)

# Change to the vim-plugins directory
printf "\nChanging to the ${red}vim bundles${reset} directory ...\n"
cd $dir

# gather plugins
files=(`ls`)    # get list of bundles
ignores=()      # list of dir to ignore
edgecases=($DOT/terminal/flat-terminal $DOT/zsh-plugins/zsh-syntax-highlighting)  # edge case submodules

# Filter out ignores and add edgecases
for ignore in "${ignores[@]}"; do
    files=(${files[@]//*$ignore*})
done
for edgecase in "${edgecases[@]}"; do
    files+=($edgecase)
done

# Update submodules
for file in "${files[@]}"; do
    cd $file
    printf "\n\nUpdating ${red}%-30s${reset}\r" "{$(basename $file)}"
    git checkout -q master
    git pull --rebase 2>&1 | grep -q "up to date." && UTD="" || UTD="*"
    if [[ "$UTD" = "*" ]]; then
        printf "Updating ${red}%-38.38s${reset}${yellow}%10s${reset}" "{$(basename $file)}" '[Updated]'
    else
        printf "Updating ${red}%-35.35s${reset}${green}%13s${reset}" "{$(basename $file)}" '[Up to date]'
    fi
    cd $dir
done

# Return to original location
cd $original_location

# notify finish
printf "${green}\n\nPlugin updating completed.${reset}\n"
