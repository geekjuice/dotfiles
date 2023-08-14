#!/usr/bin/env zsh

DOTFILES_DIR="$HOME/.dotfiles"
TPM_DIR="$HOME/.tmux/plugins/tpm"

trap "exit" INT

if [[ $(uname -s) != "Darwin" ]]; then
  echo "Script meant for MacOS. Exiting..."
  exit 1
fi

echo "Symlinking dotfiles..."
source $DOTFILES_DIR/symlink.sh

echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(brew shellenv)"

echo "Installing core cask packages..."
brew install --cask \
  arc \
  bitwarden \
  cleanshot \
  clop \
  docker \
  figma \
  font-hack-nerd-font \
  google-chrome \
  hammerspoon \
  httpie \
  iterm2 \
  jordanbaird-ice \
  meetingbar \
  proxyman \
  raycast \
  slack \
  spotify \
  syncthing \
  tailscale \
  temurin \
  visual-studio-code \

echo "Installing core homebrew packages..."
brew install \
  asdf \
  ast-grep \
  bash \
  bat \
  coreutils \
  direnv \
  eza \
  fd \
  flyctl \
  fx \
  fzf \
  gh \
  git \
  git-delta \
  gnu-sed \
  htop \
  jq \
  mkcert \
  neovim \
  pam-reattach \
  ranger \
  ripgrep \
  rsync \
  tmux \
  tmuxp \
  viddy \
  vim \
  watch \
  zoxide \
  zplug \
  zsh \

echo "Installing custom homebrew packages..."
brew install \
  jesseduffield/lazygit/lazygit \

echo "Installing tmux packages..."
[[ -d $TPM_DIR ]] && rm -rf $TPM_DIR
git clone https://github.com/tmux-plugins/tpm $TPM_DIR
tmux new-session -d -s installing
$TPM_DIR/bin/install_plugins
tmux kill-session -t installing

echo "Installing nord iterm theme..."
curl -OSL https://raw.githubusercontent.com/arcticicestudio/nord-iterm2/master/src/xml/Nord.itermcolors
open Nord.itermcolors
rm -rf Nord.itermcolors

echo "Installing powerline fonts..."
git clone https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

echo "Installing vim plugins..."
vim -e +PlugInstall +qall

echo "Generating SSL certificate localhost..."
mkcert -install
mkcert \
  -cert-file localssl/localhost.pem \
  -key-file localssl/localhost.key \
  localhost

echo "Manual installs..."
echo "  - Amphetamine   - https://apps.apple.com/us/app/amphetamine/id937984704"

echo "To enable terminal Touch ID..."
echo "Run 'sudo vim /etc/pam.d/sudo_local'"
echo "And the following lines to the top"
echo "auth optional /opt/homebrew/lib/pam/pam_reattach.so"
echo "auth sufficient pam_tid.so"
echo
echo "And for iTerm2, set 'Prefs -> Advanced -> Allow sessions to survive logging out and back in' to 'no'"

echo "All done!"
