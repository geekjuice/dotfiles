flushdnsservers() {
  sudo killall -HUP mDNSResponder
}

getdnsservers() {
  networksetup -getdnsservers Wi-Fi
}

setdnsservers() {
  networksetup -setdnsservers Wi-Fi $@
}

dnsmessage() {
  local message="using $1 dns servers"
  if [[ ! -z "$2" ]]; then
    message="$message ($2)"
  fi
  echo $message
}

dns() {
  local CLOUDFLARE="1.1.1.1"
  local GOOGLE="8.8.8.8"
  local RESET="empty"

  case "$1" in
    cloudflare)
      dnsmessage "cloudflare" $CLOUDFLARE
      setdnsservers $CLOUDFLARE
      ;;

    google)
      dnsmessage "google" $GOOGLE
      setdnsservers $GOOGLE
      ;;

    reset)
      dnsmessage "default"
      setdnsservers $RESET
      ;;

    flush)
      flushdnsservers
      ;;

    *)
      local current=$(getdnsservers)
      case "$(getdnsservers)" in
        $CLOUDFLARE)
          dnsmessage "cloudflare" $CLOUDFLARE
          ;;

        $GOOGLE)
          dnsmessage "google" $GOOGLE
          ;;

        *)
          echo $current
          ;;
      esac
  esac
}
