export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export HOMEBREW_NO_ENV_HINTS=true

brewup() {
  brew update
  brew upgrade --no-ask
  brew upgrade --cask --no-ask
  brew autoremove
  brew cleanup
  brew doctor
}

