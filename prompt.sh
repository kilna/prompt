#!/bin/bash

title() { export PS1_TITLE="$1"; }

if [[ "$TERM" == xterm* || "$TERM" == *vt* || "$TERM" == konsole* ]]; then
  declare -x -A -g trm=(
    [black]=$(echo -en '\e[30m')
    [red]=$(echo -en '\e[31m')
    [green]=$(echo -en '\e[32m')
    [yellow]=$(echo -en '\e[33m')
    [blue]=$(echo -en '\e[34m')
    [magenta]=$(echo -en '\e[35m')
    [cyan]=$(echo -en '\e[36m')
    [white]=$(echo -en '\e[37m')
    [blackbg]=$(echo -en '\e[40m')
    [redbg]=$(echo -en '\e[41m')
    [greenbg]=$(echo -en '\e[42m')
    [yellowbg]=$(echo -en '\e[43m')
    [bluebg]=$(echo -en '\e[44m')
    [magentabg]=$(echo -en '\e[45m')
    [cyanbg]=$(echo -en '\e[46m')
    [whitebg]=$(echo -en '\e[47m')
    [bold]=$(echo -en '\e[1m')
    [dim]=$(echo -en '\e[2m')
    [italic]=$(echo -en '\e[3m')
    [underline]=$(echo -en '\e[4m')
    [blink]=$(echo -en '\e[5m')
    [reverse]=$(echo -en '\e[7m')
    [hidden]=$(echo -en '\e[8m')
    [nobold]=$(echo -en '\e[21m')
    [noitalic]=$(echo -en '\e[23m')
    [nodim]=$(echo -en '\e[22m')
    [nounderline]=$(echo -en '\e[24m')
    [noblink]=$(echo -en '\e[25m')
    [noreverse]=$(echo -en '\e[27m')
    [nohidden]=$(echo -en '\e[28m')
    [reset]=$(echo -en '\e[0m')
    [clear]=$(echo -en '\e[H\e[2J')
    [title]=$(echo -en '\e]0;')
    [notitle]=$(echo -en '\a')
  )
fi

__ps1_status() {
  local msg=$(cat -)
  [[ "$msg" ]] || return
  echo -n "${trm[$1]}${trm[reverse]}▏$2${2:+ }$msg ${trm[noreverse]}"
}

__ps1_title() {
  if [[ "$PS1_TITLE" ]]; then
    echo -n "${trm[title]}${PS1_TITLE}${trm[notitle]}"
    return
  fi
  if [[ "${PS1_SHOW_HOST:-true}" == 'true' ]]; then
    echo -n "${trm[title]}${USER,,}@${HOSTNAME,,} $(dirs +0)${trm[notitle]}"
    return
  fi
  echo -n "${trm[title]}$(dirs +0)${trm[notitle]}"
}

__ps1() {
  local last_err=$?
  [[ "${trm[title]}" ]] && __ps1_title
  echo
  local status_line=$(
    set -o pipefail
    (( $last_err )) && echo "$last_err" | __ps1_status red ${trm[blink]}⚠${trm[noblink]}
    git branch 2>/dev/null | grep -F '* ' | cut -c 2- | __ps1_status blue ⌥
  )
  [[ "$status_line" ]] && echo "$status_line${trm[reset]}"
  if [[ "${PS1_SHOW_HOST:-true}" == 'true' ]]; then
    echo -n "${trm[cyan]}${USER,,}${trm[reset]}@${trm[blue]}${HOSTNAME,,}${trm[reset]} "
  fi
  echo "${trm[green]}$(dirs +0)${trm[reset]}"
  echo '$ '
}

export PS1='`__ps1`'

