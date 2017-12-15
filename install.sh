#!/usr/bin/env bash

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
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Installing core cask packages..."
brew install --cask \
  alfred \
  bitwarden \
  chromedriver \
  dash \
  docker \
  google-chrome \
  hammerspoon \
  iterm2 \
  mkcert \
  ngrok \
  now \
  skitch \
  slack \
  spotify \
  syncthing \
  visual-studio-code \

echo "Installing optional cask packages..."
brew install --cask \
  adoptopenjdk \
  beekeeper-studio \
  charles \
  discord \
  emacs \
  figma \
  firefox \
  http-toolkit \
  insomnia \
  keybase \
  mongodb-compass \
  numi \
  openemu \
  proxyman \
  virtualbox \

echo "Installing core homebrew packages..."
brew install \
  bash \
  bat \
  coreutils \
  diff-so-fancy \
  direnv \
  exa \
  fd \
  fzf \
  git \
  gnu-sed \
  httpie \
  htop \
  jq \
  ranger \
  ripgrep \
  rsync \
  tmux \
  vim \
  watch \
  z \
  zsh \

echo "Installing optional homebrew packages..."
brew install \
  asdf \
  deno \
  glances \
  golang \
  hyperfine \
  imagemagick \
  ncdu \
  neofetch \
  nginx \
  pastel \
  postgresql \
  redis \
  scc \
  starship \
  stow \
  thefuck \

echo "Installing custom homebrew packages..."
brew install \
  caskroom/fonts/font-hack \
  cjbassi/gotop/gotop \
  github/gh/gh \
  homebrew/cask-fonts/font-hack-nerd-font \
  jesseduffield/horcrux/horcrux \
  jesseduffield/lazydocker/lazydocker \
  jesseduffield/lazygit/lazygit \
  jesseduffield/lazynpm/lazynpm \
  jondot/tap/hygen \
  mongodb/brew/mongodb-community \
  Rigellute/tap/spotify-tui \
  xwmx/taps/nb \

echo "Installing tmux packages..."
[[ -d $TPM_DIR ]] && rm -rf $TPM_DIR
git clone https://github.com/tmux-plugins/tpm $TPM_DIR
tmux new-session -d -s installing
$TPM_DIR/bin/install_plugins
tmux kill-session -t installing

echo "Installing antibody..."
curl -sfL git.io/antibody | sh -s - -b /usr/local/bin

echo "Installing nord iterm theme..."
curl -OSL https://raw.githubusercontent.com/arcticicestudio/nord-iterm2/master/src/xml/Nord.itermcolors
open Nord.itermcolors
rm -rf Nord.itermcolors

echo "Installing embark iterm theme..."
curl -OSL https://raw.githubusercontent.com/embark-theme/iterm/master/colors/Embark.itermcolors
open Embark.itermcolors
rm -rf Embark.itermcolors

echo "Installing powerline fonts..."
git clone https://github.com/powerline/fonts.git
./fonts/install.sh
rm -rf fonts

echo "Installing vim plugins..."
vim -e +PlugInstall +qall

echo "Installing vscode extensions..."
code --install-extension arcticicestudio.nord-visual-studio-code
code --install-extension coenraads.bracket-pair-colorizer
code --install-extension dbaeumer.vscode-eslint
code --install-extension eamodio.gitlens
code --install-extension esbenp.prettier-vscode
code --install-extension jebbs.plantuml
code --install-extension msjsdiag.debugger-for-chrome
code --install-extension PKief.material-icon-theme
code --install-extension pnp.polacode
code --install-extension robbowen.synthwave-vscode
code --install-extension vscode-icons-team.vscode-icons
code --install-extension vscodevim.vim

echo "Installing rust toolchain installer..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "Generating SSL certificate localhost..."
mkcert -install
mkcert \
  -cert-file localssl/localhost.pem \
  -key-file localssl/localhost.key \
  localhost


echo "Set desktop wallpaper..."
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$DOTFILES_DIR/wallpaper.jpg\""

echo "Manual installs..."
echo "  - Port Manager - https://portmanager.app/"
echo "  - Affinity Designer- https://affinity.serif.com/en-us/designer/"

echo "All done!"
