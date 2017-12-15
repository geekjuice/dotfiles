GLOBAL_ENV="$HOME/.env"
if [[ -r "$GLOBAL_ENV" ]]; then
  source $GLOBAL_ENV
fi

envrc() {
  local ENVRC_ACTIVE=".envrc"
  local ENVRC_INACTIVE="${ENVRC_ACTIVE}_"

  if [[ -f "${ENVRC_ACTIVE}" ]]; then
    echo "Disabling direnv..."
    mv "${ENVRC_ACTIVE}" "${ENVRC_INACTIVE}"
  elif [[ -f "${ENVRC_INACTIVE}" ]]; then
    echo "Enabling direnv..."
    mv "${ENVRC_INACTIVE}" "${ENVRC_ACTIVE}"
  fi
}
