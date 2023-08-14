alias txn="tmux new -s nick"
alias txp="tmuxp load -a nick"
alias txh="tmuxp load -a hubble"
alias txa="tmuxp load -a ashby"

function txk() {
  if [[ ! $1 =~ "^[0-9]+$" ]]; then
    echo "Please provide window number..."
    return 1
  fi

  (tmux kill-window -t :"$1")
}

function txar() {
  txk ${1:-0} && txa
}
