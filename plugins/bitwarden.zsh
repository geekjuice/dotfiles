function bitwarden-vault() {
  BW_SESSION=$(security find-generic-password -a ${USER} -s BW_SESSION -w)

  export BW_SESSION

  BW_STATUS=$(bw status | jq -r .status)

  case "${BW_STATUS}" in
    "unauthenticated")
      echo "Logging into BitWarden..."
      export BW_SESSION=$(bw login --raw)
      security add-generic-password -U -a ${USER} -s BW_SESSION -w "${BW_SESSION}"
      ;;

    "locked")
      echo "Unlocking Vault..."
      export BW_SESSION=$(bw unlock --raw)
      security add-generic-password -U -a ${USER} -s BW_SESSION -w "${BW_SESSION}"
      ;;

    "unlocked")
      echo "Vault is unlocked."
      export BW_SESSION
      ;;

    *)
      echo "Unknown vault status: ${BW_STATUS}"
      return 1
      ;;
  esac

  if [[ $# -ne 0 ]]; then
    bw "$@"
  fi
}

alias bwv="bitwarden-vault"
