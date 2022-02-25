export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export HOMEBREW_NO_ENV_HINTS=true

brewup() {
  brew update
  brew upgrade
  brew upgrade --cask
  brew autoremove
  brew cleanup
  brew doctor
}

