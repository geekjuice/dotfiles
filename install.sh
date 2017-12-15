#!/usr/bin/env bash

DOTFILES_DIR=$HOME/.dotfiles

trap "exit" INT

echo "Symlinking dotfiles..."
source $DOTFILES_DIR/symlink.sh

echo "Installing homebrew..."
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Installing homebrew packages..."
brew install \
  bat \
  diff-so-fancy \
  fd \
  fx \
  fzf \
  git \
  httpie \
  hub \
  htop \
  jq \
  ncdu \
  neofetch \
  nnn \
  node \
  prettyping \
  ripgrep \
  stow \
  terraform \
  tmux \
  vim \
  watch \
  yarn \
  z \
  zsh \

echo "Installing cask packages..."
brew cask install \
  alfred \
  chromedriver \
  dash \
  flux \
  insomnia \
  hammerspoon \
  iterm2 \
  notion \
  now \
  slack \
  spotify \

echo "Installing custom homebrew packages..."
brew install \
  cjbassi/gotop/gotop \
  homebrew/cask-fonts/font-hack-nerd-font \
  jesseduffield/lazygit/lazygit \
  koekeishiya/formulae/skhd \
  koekeishiya/formulae/chunkwm \

echo "Installing tmux packages..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
$HOME/.tmux/plugins/tpm/bin/install_plugins

echo "Installing antibody..."
curl -sL https://git.io/antibody | bash -s

echo "Installing snazzy iterm theme..."
curl -OSL https://raw.githubusercontent.com/sindresorhus/iterm2-snazzy/master/Snazzy.itermcolors
open Snazzy.itermcolors
rm -rf Snazzy.itermcolors

echo "Installing powerline fonts..."
git clone https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

echo "Installing node version manager..."
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

echo "Installing latest version of node..."
nvm install node

echo "Installing global node modules..."
npm install -g \
  c8 \
  localtunnel \
  magestic \
  ndb \
  now \
  prettier \

echo "Installing vim plugins..."
vim -e +PlugInstall +qall

echo "Set desktop wallpaper..."
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$DOTFILES_DIR/wallpaper.jpg\""

echo "All done!"
