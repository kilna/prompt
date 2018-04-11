#!/bin/bash

title() { export PS1_TITLE="$1"; }

__ps1_ansi_term() {
  case "$TERM" in
    xterm*)   return 0 ;;
    *vt*)     return 0 ;;
    konsole*) return 0 ;;
    ansi*)    return 0 ;;
    *)        return 1 ;;
  esac
}

__ansi() {
  __ps1_ansi_term || return
  items=()
  for spec in "$@"; do
    if [[ "${spec:0:1}" == ':' ]]; then
      local varname='$PS1_'"${spec:1}"
      items+=(eval '__ansi '"${varname^^}")
    else
      items+=("$spec")
    fi
  done
  for item in "${items[@]}"; do
    echo "ITEM: $item"
    case "$item" in
      +black)       echo -en '\e[30m'    ;;
      +red)         echo -en '\e[31m'    ;;
      +green)       echo -en '\e[32m'    ;;
      +yellow)      echo -en '\e[33m'    ;;
      +blue)        echo -en '\e[34m'    ;;
      +magenta)     echo -en '\e[35m'    ;;
      +cyan)        echo -en '\e[36m'    ;;
      +white)       echo -en '\e[37m'    ;;
      +blackbg)     echo -en '\e[40m'    ;;
      +redbg)       echo -en '\e[41m'    ;;
      +greenbg)     echo -en '\e[42m'    ;;
      +yellowbg)    echo -en '\e[43m'    ;;
      +bluebg)      echo -en '\e[44m'    ;;
      +magentabg)   echo -en '\e[45m'    ;;
      +cyanbg)      echo -en '\e[46m'    ;;
      +whitebg)     echo -en '\e[47m'    ;;
      +bold)        echo -en '\e[1m'     ;;
      -bold)        echo -en '\e[21m'    ;;
      +dim)         echo -en '\e[2m'     ;;
      -dim)         echo -en '\e[22m'    ;;
      +italic)      echo -en '\e[3m'     ;;
      -italic)      echo -en '\e[23m'    ;;
      +underline)   echo -en '\e[4m'     ;;
      -underline)   echo -en '\e[24m'    ;;
      +blink)       echo -en '\e[5m'     ;;
      -blink)       echo -en '\e[25m'    ;;
      +reverse)     echo -en '\e[7m'     ;;
      -reverse)     echo -en '\e[27m'    ;;
      +hidden)      echo -en '\e[8m'     ;;
      -hidden)      echo -en '\e[28m'    ;;
      +title)       echo -en '\e]0;'     ;;
      -notitle)     echo -en '\a'        ;;
      +reset)       echo -en '\e[0m'     ;;
      +clear)       echo -en '\e[H\e[2J' ;;
      *)            echo -n "$code"      ;;
    esac
  done
}

__ps1_status() {
  local msg=$(cat -)
  [[ "$msg" ]] || return
  PS1_STATUS="$msg" __ansi :$1
}

__ps1() {
  local last_err=$?
  if __ps1_ansi_term; then
    local title=''
    if [[ "$PS1_TITLE" ]]; then
      title="$PS1_TITLE"
    else
      if [[ "${PS1_SHOW_HOST:-true}" == 'true' ]]; then
        title="${USER,,}@${HOSTNAME,,} "
      fi
      title+="$(dirs +0)"
    fi
    __ansi +title "$title" -title
  fi
  echo
  local status_line=$(
    set -o pipefail
    (( $last_err )) && echo "$last_err" | __ps1_status ERROR 
    git branch 2>/dev/null | grep -F '* ' | cut -c 2- | __ps1_status GITBRANCH
  )
  [[ "$status_line" ]] && echo "$status_line"
  if [[ "${PS1_SHOW_HOST:-true}" == 'true' ]]; then
    __ansi :USER "${USER,,}" :PROMPT '@' :HOSTNAME "${HOSTNAME,,}" ' ' +reset
  fi
  __ansi :DIR "$(dirs +0)" :PROMPT "$( (( EUID )) && echo -n '$ ' || echo -n '# ' )" +reset
  echo
}

export PS1_USER='+magenta'
export PS1_PROMPT='+white'
export PS1_HOSTNAME='+cyan'
export PS1_DIR='+green'
export PS1_STATUS_PREFIX="+reverse '▏ '"
export PS1_STATUS_SEPARATOR="' '"
export PS1_STATUS_POSTFIX="' '"
export PS1_ERROR="+red :STATUS_PREFIX +blink +yellowbg '⚠' +blackgb -blink :STATUS_SEPARATOR :STATUS :STATUS_POSTFIX"
export PS1_GITBRANCH="+blue :STATUS_PREFIX '⌥' :STATUS_SEPARATOR :STATUS :STATUS_POSTFIX"

export PS1='`__ps1`'
export USER="${USER:-${USERNAME:-$(whoami)}}"
export HOSTNAME="${HOSTNAME:-$(hostname)}"

