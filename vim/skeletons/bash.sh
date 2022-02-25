#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [[ "${TRACE-0}" == "1" ]]; then
  set -o xtrace
fi

if [[ "${1-}" =~ ^(-h|--help)$ ]]; then
  echo '
  ❯ ./script.sh

  options:
    --help, -h    print this help message
  '
  exit
fi

cd "$(dirname "$0")"

main() {
  echo
  echo "Nothing to see here...(╯°□°)╯︵ ┻━┻"
  echo
}

main "$@"
