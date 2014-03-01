# Updated version of zsh battery to use arrows
if [[ $(uname) == "Darwin" ]] ; then
  function battery_pct_prompt_custom () {
    if [[ $(ioreg -rc AppleSmartBattery | grep -c '^.*"ExternalConnected"\ =\ No') -eq 1 ]] ; then
      b=$(battery_pct_remaining)
      brm='['
      if [[ $b -gt 5 ]]; then
        for i in {1..$((b/5))}; do
          brm+='▹'
        done
        brm+='] '
      else
          brm='[x_x] '
      fi

      message=''
      if [[ $b -gt 50 ]] ; then
        color='green'
      elif [[ $b -gt 20 ]] ; then
        color='yellow'
      else
        color='red'
        if [[ $b -gt 10 ]]; then
          message="I'm dying, Nick... "
        else
          message="...Good...bye...Nick... "
        fi
      fi

      echo "%{$fg[$color]%}$message$brm$(battery_pct_remaining)%%%{$reset_color%}"
    else
      echo "∞"
    fi
  }

elif [[ $(uname) == "Linux"  ]] ; then

  function battery_pct_prompt_custom () {
    b=$(battery_pct_remaining)
    if [[ $(acpi 2&>/dev/null | grep -c '^Battery.*Discharging') -gt 0 ]] ; then
      brm='['
      if [[ $b -gt 5 ]]; then
        for i in {1..$((b/5))}; do
          brm+='▹'
        done
        brm+='] '
      else
          brm='[x_x] '
      fi

      message=''
      if [[ $b -gt 50 ]] ; then
        color='green'
      elif [[ $b -gt 20 ]] ; then
        color='yellow'
      else
        color='red'
        if [[ $b -gt 5 ]]; then
          message="He's dying, Nick... "
        else
          message="He's dead, Nick... "
        fi
      fi

      echo "%{$fg[$color]%}$message$brm$(battery_pct_remaining)%%%{$reset_color%}"
    else
      if [[ $(uname -p) == *armv* ]]; then
        echo "%{$fg[blue]%}[C%{$fg[red]%}hr%{$fg[yellow]%}om%{$fg[blue]%}eb%{$fg[green]%}oo%{$fg[red]%}k]%{$reset_color%}"
      else
        echo "∞"
      fi
    fi
  }
fi
