# Setup go
# --------
export GOPATH="$HOME/.go"
if [[ ! "$PATH" == *${GOPATH}* ]]; then
  export PATH="$PATH:${GOPATH}"
fi
