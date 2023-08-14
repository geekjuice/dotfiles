#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  echo '
  ❯ ./backup.sh

  options:
    --dry, -d     perform dry run
    --help, -h    print this help message
  '
  exit
fi

cd "$(dirname "$0")"

FLAGS="
  --archive \
  --delete \
  --delete-delay \
  --exclude="*.sync-conflict*" \
  --exclude="*._*" \
  --human-readable \
  --progress \
  --stats \
"

if [[ "${1-}" =~ ^(-d|--dry)$ ]]; then
  FLAGS+="--dry-run"
fi

STORAGE="/Volumes/GeekStorage"

clone() {
  rsync ${FLAGS} \
    --exclude-from="${1}/.stignore" \
    ${1} ${STORAGE}/${2}
}

main() {
  # dotfiles
  clone "${HOME}/.dotfiles/" dotfiles

  # sync
  clone "${HOME}/sync/" sync

  # dev
  clone "${HOME}/dev/" dev
}

main "$@"
