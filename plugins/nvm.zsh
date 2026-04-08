export NVM_DIR="$HOME/.nvm"

# Lazy-load nvm: only source nvm.sh when nvm/node/npm/npx is first called
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _nvm_lazy_load() {
    unset -f nvm node npm npx
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }

  nvm()  { _nvm_lazy_load; nvm  "$@"; }
  node() { _nvm_lazy_load; node "$@"; }
  npm()  { _nvm_lazy_load; npm  "$@"; }
  npx()  { _nvm_lazy_load; npx  "$@"; }
fi
