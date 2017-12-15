#!/usr/bin/env bash

USER="ubuntu"
DOTFILES_DIR="$HOME/.dotfiles"
TPM_DIR="$HOME/.tmux/plugins/tpm"
FZF_DIR="$HOME/.fzf"

trap "exit" INT

if [[ $(uname -s) != "Linux" ]]; then
  echo "Script meant for Ubuntu Linux. Exiting..."
  exit 1
fi

echo "Symlinking dotfiles..."
source $DOTFILES_DIR/ubuntu/symlink.sh

echo "Updating packages..."
sudo apt-get update
sudo apt-get upgrade -y

echo "Installing packages..."
sudo apt-get install -y \
  git \
  httpie \
  htop \
  jq \
  ranger \
  tmux \
  vim \
  zsh \

echo "Installing fzf..."
git clone --depth 1 https://github.com/junegunn/fzf.git $FZF_DIR
$FZF_DIR/install --bin

echo "Making zsh default shell..."
sudo chsh -s $(which zsh) ubuntu

echo "Installing tmux packages..."
[[ -d $TPM_DIR ]] && rm -rf $TPM_DIR
git clone https://github.com/tmux-plugins/tpm $TPM_DIR
tmux new-session -d -s installing
$TPM_DIR/bin/install_plugins
tmux kill-session -t installing

echo "Installing antibody..."
curl -sfL git.io/antibody | sudo sh -s - -b /usr/local/bin

echo "Installing vim plugins..."
vim -e +PlugInstall +qall

echo "All done!"
