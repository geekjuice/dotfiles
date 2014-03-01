#!/bin/bash
############################
# Symlink from .files
############################

# Colors
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
blue='\e[0;34m'
reset='\e[0m'

# Start
printf "${blue}=========================================================${reset}\n"
printf "${yellow}                   Symlinking dotfiles                   ${reset}\n"
printf "${blue}=========================================================${reset}\n"

# Helper Functions
script_location() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    SOURCE="$DIR/$SOURCE"
  done
  echo $( cd -P "$( dirname "$SOURCE" )" && pwd )
}

linker() {
    local file=$1
    local src=$2
    local dest=$3
    local dot=$4
    local action=$5
    [[ "$dot" -eq 1 ]] && dot=".$file" || dot="$file"
    rm -rf $dest/$dot
    if [[ "$action" = *delete* ]]; then
        printf "\n${red}Removing ${yellow}$file${reset}"
    else
        printf "\n${green}Linking ${yellow}$file${reset}"
        ln -s $src/$file $dest/$dot
    fi
}

# Directories
dir=$(dirname $(script_location))  # dotfiles directory
ohmyplugs=$HOME/.oh-my-zsh/custom/plugins
unisondir=$HOME/.unison
muttdir=$HOME/.mutt

# Handpicked Files
files=(agignore gemrc ghci gitconfig gitignore hushlogin htoprc muttrc rspec tmux.conf vimrc vim zshrc)
plugins=(battery-plus zsh-syntax-highlighting)
[[ "$SHELL" = *bash* ]] && files+=(profile)

# OS Message
[[ "$(uname)" = *Linux* ]] && printf "\n${green}Linux Settings${white}"
[[ "$(uname)" = *Darwin* ]] && printf "\n${green}OSX Settings${white}"

# change to the dotfiles directory
printf "${reset}: Changing to the ${red}dotfiles${reset} directory ...\n"
cd $dir

# create main symlinks
for file in ${files[@]}; do
    linker $file $dir $HOME 1 $1
done

# symlink unison profiles
for profile in $(ls $dir/unison); do
    [[ ! -d $unisondir ]] && mkdir $unisondir
    linker $profile $dir/unison $unisondir 0 $1
done

# mutt setup
if [[ ! -d $muttdir ]]; then
    echo "Initializing Mutt cache..."
    mkdir -p $muttdir/cache/{bodies,headers}
    touch $muttdir/certificates
fi

# symlink zsh plugins
if [[ -d $HOME/.oh-my-zsh ]]; then
    mkdir -p $ohmyplugs
    for plugin in ${plugins[@]}; do
        linker $plugin $dir/zsh-plugins $ohmyplugs 0 $1
    done
fi

# notify finish
printf "${green}\n\nDotfiles symlinked!${reset}\n"
