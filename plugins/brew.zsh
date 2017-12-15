export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# https://github.com/pyenv/pyenv/issues/106
alias brew="env PATH=${PATH//$(pyenv root)\/shims:/} brew"

brewup() {
  brew update
  brew upgrade
  brew upgrade --cask
  brew autoremove
  brew cleanup
  brew doctor
}

