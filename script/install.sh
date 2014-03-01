#!/usr/bin/env zsh

# Colors
_r='\e[0;31m'
_g='\e[0;32m'
_y='\e[0;33m'
_b='\e[0;34m'
_o='\e[0m'


# Fail Trap
trap 'ret=$?; test $ret -ne 0 && printf "\n${_r}[!] Failed\n${_o}" >&2; exit $ret' EXIT
set -e


# Fancy Echo
_echo() { printf "\n${_b}%b${_o}\n" "$1" }


# Start
printf "\n${_y}{{ Starting OS X Dev Script }}${_o}\n"

# Prompt about pre-install steps
if [[ "$SHELL" != *zsh* ]]; then
    printf "\n${_y}Did you install xcode tools and change to zsh?${_o}\n"
    printf "\n# Install C compiler (Xcode)\n"
    printf "${_g}xcode-select --install${_o}\n"
    printf "\n# Change login shell to zsh\n"
    printf "${_g}chsh -s /bin/zsh${_o}\n"
    exit 1
fi

# Fix OSX zsh env bug
if [[ -f /etc/zshenv ]]; then
    _echo "Fixing OSX zsh environment bug ..."
    sudo mv /etc/{zshenv,zshrc}
fi


# Install Brew
if (( ! $+commands[brew] )); then
    _echo "Installing Homebrew, the missing package manager of OS X ..."
    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
    brew update
    _echo "Edit /etc/paths to include local first ..."
else
    _echo "Homebrew already installed. Skipping ..."
fi


# Brews
_echo "Installing Redis, a good key-value database ..."
    brew install redis

_echo "Installing MongoDB, a good NoSQL database ..."
    brew install mongodb

_echo "Installing The Silver Searcher, a faster ack/grep ..."
    brew install the_silver_searcher

_echo "Installing vim, the one true editor ..."
    brew install vim

_echo "Installing git, a distributed revision control and source code management ..."
    brew install vim

_echo "Installing hub, git with Github flavor ..."
    brew install hub

_echo "Installing ctags, to index files for vim tab completion of methods, classes, variables ..."
    brew install ctags

_echo "Installing tmux, to save project state and switch between projects ..."
    brew install tmux

_echo "Installing reattach-to-user-namespace, for copy-paste with tmux ..."
    brew install reattach-to-user-namespace

_echo "Installing ImageMagick, to crop and resize images ..."
    brew install imagemagick

_echo "Installing QT, used by Capybara Webkit for headless Javascript integration testing ..."
    brew install qt

_echo "Installing watch, to execute a program periodically and show the output ..."
    brew install watch


# Python
_echo "Installing Python, a high-level programming language ..."
    brew install python

_echo "Installing Colout using pip for color outputs..."
    pip install colout


# NVM
_echo "Installing NVM, a Node Version Manager (Geekjuice Flavor) ..."
    curl https://raw.github.com/geekjuice/nvm/master/install.sh | sh
    git remote add upstream https://github.com/creationix/nvm.git
    nvm dev install
    nvm stable install

# Compiler and Libraries
_echo "Installing GNU Compiler Collection, a necessary prerequisite to installing Ruby ..."
    brew tap homebrew/dupes
    brew install apple-gcc42

_echo "Upgrading and linking OpenSSL ..."
    brew install openssl

_echo "Instaling cmake ..."
    brew install cmake

export CC=gcc-4.2


# Ruby
# _echo "Installing rbenv, to change Ruby versions ..."
# brew install rbenv

# _echo "Installing rbenv-gem-rehash so the shell automatically picks up binaries after installing gems with binaries..."
# brew install rbenv-gem-rehash

# _echo "Installing ruby-build, to install Rubies ..."
# brew install ruby-build

# _echo "Installing Ruby 2.0.0-p353 ..."
# rbenv install 2.0.0-p353
# rbenv install 2.1.0

# _echo "Setting Ruby 2.0.0-p353 as global default Ruby ..."
# rbenv global 2.0.0-p353
# rbenv rehash

# _echo "Updating to latest Rubygems version ..."
# gem update --system

# _echo "Installing Bundler to install project-specific Ruby gems ..."
# gem install bundler --no-document --pre

# _echo "Installing Rails ..."
# gem install rails --no-document


# CLI Clients
_echo "Installing GitHub CLI client ..."
    curl http://hub.github.com/standalone -sLo ~/.bin/hub
    chmod +x ~/.bin/hub

_echo "Installing Heroku CLI client ..."
    brew install heroku-toolbelt

_echo "Installing the heroku-config plugin to pull config variables locally to be used as ENV variables ..."
    heroku plugins:install git://github.com/ddollar/heroku-config.git


# Oh-my-zsh
_echo "Installing oh-my-zsh ..."
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

_echo "Installing zsh syntax highlighting ..."
    mkdir ~/.oh-my-zsh/custom/plugins && cd ~/.oh-my-zsh/custom/plugins
    git clone git://github.com/zsh-users/zsh-syntax-highlighting.git
    rm -rf zsh-syntax-highlighting && cd -


# Tmux
_echo "Installing Tmux-mem-cpu-load ..."
    git clone https://github.com/thewtex/tmux-mem-cpu-load.git
    cd tmux-mem-cpu-load
    cmake . && make && sudo make install
#     cd - && rm -rf tmux-mem-cpu-load

# # Personal Touch
# _echo "Cloning dotfiles into ~/.dotfiles with submodules..."
#     git clone --rescurive https://github.com/geekjuice/dotfiles ~/.dotfiles

# _echo "Creating symlinks to dotfiles ..."
#     ~/.dotfiles/script/makesymlinks.sh

# _echo "Finally, sourcing zshrc ..."
#     source ~/.dotfiles/zshrc
