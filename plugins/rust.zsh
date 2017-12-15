# Setup rust
# --------
export RUSTPATH="$HOME/.cargo/bin"
if [[ ! "$PATH" == *${RUSTPATH}* ]]; then
  export PATH="$PATH:${RUSTPATH}"
fi

