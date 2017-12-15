# setup adsf
# ----------
ASDF_LAZY_LOADED=false

lazy_asdf() {
  if [[ "$ASDF_LAZY_LOADED" = false ]]; then
    unalias asdf

    . $(brew --prefix asdf)/asdf.sh
    . $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash

    ASDF_LAZY_LOADED=true
  fi

  asdf $@
}

alias asdf="lazy_asdf"
