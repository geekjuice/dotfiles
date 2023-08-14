bws() {
  local vault=$(bw status | jq -r .status)

  if [[ ${vault} == "unauthenticated" ]]; then
    export BW_SESSION=$(bw login --raw)
  elif [[ ${vault} == "locked" ]]; then
    export BW_SESSION=$(bw unlock --raw)
  else
    bw "$@"
  fi
}
