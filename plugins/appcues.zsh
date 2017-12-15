ensure_node_version() {
  local NVMRC=".nvmrc"

  if [[ -f "$NVMRC" ]]; then
    local CURRENT=$(nvm current)
    local EXPECTED=$(cat $NVMRC)

    if [[ "$EXPECTED" != "$CURRENT" ]]; then
      local INSTALLED=$(nvm version $EXPECTED)

      if [[ "$INSTALLED" == "N/A" ]]; then
        nvm install $EXPECTED
      fi

      nvm use
    fi
  fi
}

apm() {
  ensure_node_version
  eval "aws-okta exec appcues -- command npm $@"
}

opscues() {
  local OPSCUES_DIR="${HOME}/dev/appcues/opscues"
  eval "BUNDLE_GEMFILE=${OPSCUES_DIR}/Gemfile bundle exec ${OPSCUES_DIR}/exe/opscues $@"
}
