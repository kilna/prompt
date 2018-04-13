#!/bin/bash


case "$TERM" in linux|xterm*|*vt*|con*|*ansi*|screen) export ANSI_TERM=1;; esac

title() { export PS1_TITLE="$1"; }

__prompt_ansi() { echo -n '\[\e\[${1}m\]'; }
__ansi_color() {
  case "$1" in
    black)   echo -n 0;;
    red)     echo -n 1;;
    green)   echo -n 2;;
    yellow)  echo -n 3;;
    blue)    echo -n 4;;
    magenta) echo -n 5;;
    cyan)    echo -n 6;;
    white)   echo -n 7;;
  esac
}

set_prompt() {
  local prompt=''
  for item in "${arg[@]}"; do
    case "$arg" in
      :fg:*) prompt+=$(__prompt_ansi 3$(__ansi_color ${arg:4}));;
      :bg:*) prompt+=$(__prompt_ansi 4$(__ansi_color ${arg:4}));;
      :reset) prompt+=$(__prompt_ansi 0);;
      :clear) prompt+='\e[H\e[2J';;
      +title)     prompt+='\[\e]0;\]';;        -title)     prompt+='\a';;
      +bold)      prompt+=$(__prompt_ansi 1);; -bold)      prompt+=$(__prompt_ansi 21);;
      +dim)       prompt+=$(__prompt_ansi 2);; -dim)       prompt+=$(__prompt_ansi 22);;
      +italic)    prompt+=$(__prompt_ansi 3);; -italic)    prompt+=$(__prompt_ansi 23);;
      +underline) prompt+=$(__prompt_ansi 4);; -underline) prompt+=$(__prompt_ansi 24);;
      +blink)     prompt+=$(__prompt_ansi 5);; -blink)     prompt+=$(__prompt_ansi 25);;
      +reverse)   prompt+=$(__prompt_ansi 7);; -reverse)   prompt+=$(__prompt_ansi 27);;
      +hidden)    prompt+=$(__prompt_ansi 8);; -hidden)    prompt+=$(__prompt_ansi 28);;
      :newline)      prompt+='\n'$(__prompt_ansi 0);;
      :user)         prompt+='\u' ;;
      :dir)          prompt+='\w' ;;
      :basename)     prompt+='\W' ;;
      :host)         prompt+='\h' ;;
      :fqdn)         prompt+='\H' ;;
      :date)         prompt+='\d' ;;
      :escpae)       prompt+='\e' ;;
      :jobs)         prompt+='\j' ;;
      :device)       prompt+='\l' ;;
      :nl|:newline)  prompt+='\n' ;;
      :cr|:return)   prompt+='\r' ;;
      :shell)        prompt+='\s' ;;
      :time|time-24) prompt+='\t' ;;
      :time-12)      prompt+='\T' ;;
      :time-ampm)    prompt+='\@' ;;
      :version)      prompt+='\v' ;;
      :version-full) prompt+='\V' ;;
      :history)      prompt+='\!' ;;
      :command)      prompt+='\#' ;;
      :prompt)       prompt+='\$' ;;
      :backslash)    prompt+='\\' ;;
      :status)       prompt+='`__ps1_status`' ;;
      :statusline)   prompt+='`__ps1_status --newline`' ;;
      :title*)       opts=''
                     [[ "$arg" == *'no-user'* ]] || [[ "$arg" == *'no-host'* ]] && opts+='\u' || opts+='\u@'
                     [[ "$arg" == *'no-host'* ]] || [[ "$arg" == *'fqdn'* ]] && opts+='\H' || opts+='\h'
                     [[ "$arg" == *'no-dir'* ]] || [[ "$arg" == *'base'* ]] && opts+=' \W' || opts+=' \w'
                     prompt+='\[\e]0;\]`[[ "$PS1_TITLE" ]] && echo -n "$PS1_TITLE - "`'"$opts"'\a'
                     ;;
      *)             prompt+="$arg" ;;
    esac
  done
  export PS1="$prompt"
}

__ps1_status() {
  export PS1_LAST_EXIT=$?
}

__ps1_status_block() {
  local msg=$(cat -)
  [[ "$msg" ]] || return
  PS1_STATUS="$msg" __ansi :$1
}

__ps1() {
  local status_line=$(
    set -o pipefail
    (( $last_err )) && echo "$last_err" | __ps1_status ERROR 
    git branch 2>/dev/null | grep -F '* ' | cut -c 2- | __ps1_status GITBRANCH
  )
  [[ "$status_line" ]] && echo "$status_line"
  if [[ "${PS1_SHOW_HOST:-true}" == 'true' ]]; then
    __ansi :USER "${USER,,}" :PROMPT '@' :HOSTNAME "${HOSTNAME,,}" ' ' +reset
  fi
  __ansi :DIR "$(dirs +0)" :PROMPT "$( (( EUID )) && prompt+='$ ' || prompt+='# ' )" +reset
  echo
}

export PS1_STATUS_PREFIX="+reverse '▏ '"
export PS1_STATUS_SEPARATOR="' '"
export PS1_STATUS_POSTFIX="' '"
export PS1_ERROR="+red :STATUS_PREFIX +blink +yellowbg '⚠' +blackgb -blink :STATUS_SEPARATOR :STATUS :STATUS_POSTFIX"
export PS1_GITBRANCH="+blue :STATUS_PREFIX '⌥' :STATUS_SEPARATOR :STATUS :STATUS_POSTFIX"


