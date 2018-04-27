#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cat <<EOF >&2
This script is meant to be added into a bash shell session via:

source $0

You cannot call this script directly.
EOF
  return 1
fi

set_title() { export PS1_TITLE="$1"; }
unset_title() { unset PS1_TITLE; }

set_prompt() {
  if [[ "$PS1_ORIG" == "" ]]; then
    export PS1_ORIG="$PS1"
  fi
  export PS1="$(__ps1_prompt "$@" :title)";
}

default_prompt() {
  set_prompt :statusline :user '@' :host ' ' :dir :eol :prompt ' ' :reset
}

unset_prompt() {
  export PS1="$PS1_ORIG"
  unset PS1_ORIG
}

reset_prompt() {
  unset_prompt
  unset PS1_MODULES
  unset PS1_TYPE
  source $PS1_ROOT/prompt.sh "$@"
}


__ps1_unicode() {
  case "$LANG" in
    *'UTF-8'*) return 0;;
    *)         return 1;;
  esac
}

__ps1_color() {
  case "$1" in
    :bg) prefix='4';;
    :fg) prefix='3';;
  esac
  case "$2" in
    black)   echo -n '\e['$prefix'0m';;
    red)     echo -n '\e['$prefix'1m';;
    green)   echo -n '\e['$prefix'2m';;
    yellow)  echo -n '\e['$prefix'3m';;
    blue)    echo -n '\e['$prefix'4m';;
    magenta) echo -n '\e['$prefix'5m';;
    cyan)    echo -n '\e['$prefix'6m';;
    white)   echo -n '\e['$prefix'7m';;
  esac
}

__ps1_mode() {
  prefix=''
  if [[ "${1:0:1}" == '-' ]]; then
    prefix='2'
  fi
  case "${1:1}" in
    bold)      echo -n '\e['$prefix'1m';;
    dim)       echo -n '\e['$prefix'2m';;
    italic)    echo -n '\e['$prefix'3m';;
    underline) echo -n '\e['$prefix'4m';;
    blink)     echo -n '\e['$prefix'5m';;
    fastblink) echo -n '\e['$prefix'6m';;
    reverse)   echo -n '\e['$prefix'7m';;
    hidden)    echo -n '\e['$prefix'8m';;
  esac
}

__ps1_ansi_echo() {
  case "$TERM" in
    linux|xterm*|*vt*|con*|*ansi*|screen) echo -en "$1";;
  esac
}

__ps1_stylize() {
  content="$1"
  shift
  __ps1_ansi $(__ps1_style "$@") "$content" :reset
}

__ps1_ansi() {
  while (( "$#" > 0 )); do
    arg="$1"
    shift
    case "$arg" in
      :nl|:newline) echo;;
      :space)  echo -n ' ';;
      :eol)    __ps1_ansi_echo '\e[0m\n\e[0m';; # Handy when bash eats a trailing newline
      :clear)  __ps1_ansi_echo '\e[H\e[2J';;
      :reset)  __ps1_ansi_echo '\e[0m';;
      :fg|:bg) __ps1_ansi_echo $(__ps1_color "$arg" "$1"); shift;;
      +*|-*)   __ps1_ansi_echo $(__ps1_mode "$arg");;
      *)       echo -n "$arg";;
    esac
  done
}

__ps1_prompt_stylize() {
  content="$1"
  shift
  __ps1_prompt $(__ps1_style "$@") "$content" :reset
}

__ps1_prompt() {
  while (( "$#" > 0 )); do
    arg="$1"
    shift
    case "$arg" in
      :bootstrap)     
        echo -n '`__ps1_bootstrap`';;
      :title)     
        local title="${PS1_TITLE_FORMAT:-\\z\\-\\u@\\h \\w}"
        title="${title//\\z/'`echo -n "$PS1_TITLE"`'}"
        title="${title//\\-/'`echo -n "${PS1_TITLE:+ - }"`'}"
        str+='\[\e]0;\]'"$title"'\a'
        echo -n "${str//\`\`/;}"
        ;;
      :nl|:newline)   echo -n '\n';;
      :space)         echo -n ' ';;
      :eol)           echo -n '\[\e[0m\]\n\[\e[0m\]';;
      :reset)         echo -n '\[\e[0m\]';;
      :fg|:bg)        echo -n '\['; __ps1_color "$arg" "$1"; shift; echo -n '\]';;
      :user)          __ps1_prompt_stylize '\u' user;;
      :dir)           __ps1_prompt_stylize '\w' dir;;
      :basename)      __ps1_prompt_stylize '\W' basename dir;;
      :host)          __ps1_prompt_stylize '\h' host;;
      :fqdn)          __ps1_prompt_stylize '\H' fqdn host;;
      :prompt)        __ps1_prompt_stylize '\$' prompt;;
      :date)          __ps1_prompt_stylize '\d' date time;;
      :time|:time-24) __ps1_prompt_stylize '\t' time date;;
      :time-12)       __ps1_prompt_stylize '\T' time date;;
      :time-ampm)     __ps1_prompt_stylize '\@' time date;;
      :escape)        echo -n '\e';;
      :jobs)          echo -n '\j';;
      :device)        echo -n '\l';;
      :bell)          echo -n '\a';;
      :shell)         echo -n '\s';;
      :version)       echo -n '\v';;
      :version-full)  echo -n '\V';;
      :history)       echo -n '\!';;
      :command)       echo -n '\#';;
      :prompt)        echo -n '\$';;
      :backslash)     echo -n '\\';;
      :status)        echo -n '`__ps1_status`';;
      :statusline)    echo -n '`__ps1_status -n`';;
      +*|-*)          echo -n '\['; __ps1_mode "$arg"; echo -n '\]';;
      *)              echo -n "$arg";;
    esac
  done
}

__ps1_style() {
  style="${PS1_STYLE:-default}"
  properties=("$@" 'default')
  for property in "${properties[@]}"; do
    __ps1_style_${style}_$property 2>/dev/null && return
    __ps1_style_default_$property 2>/dev/null
  done
}

__ps1_status() {
  export PS1_LAST_ERR="$?"
  local status_items=0
  for module in "${PS1_MODULES[@]}"; do
    local module_out="$(__ps1_module_${module}_output)"
    [[ "$module_out" == '' ]] && continue
    (( status_items++ )) && __ps1_ansi $(__ps1_style block_pad)
    __ps1_ansi \
      :fg $(__ps1_module_${module}_color) \
      $(__ps1_style block_start) \
      $(__ps1_module_${module}_prefix) \
      "$module_out" \
      $(__ps1_module_${module}_postfix) \
      $(__ps1_style block_end) \
      :reset
  done
  unset PS1_LAST_ERR
  if [[ "$status_items" > 0 && "$1" == '-n' ]]; then
    __ps1_ansi :eol
  fi
}

export PS1_ROOT=$(cd "$(dirname '${BASH_SOURCE[@]}')" &>/dev/null && pwd)

#for module in "$@"; do
#  source $PS1_ROOT/module/$module.sh
#  (( "$?" )) || PS1_MODULES+=("$module")
#done
#for module in "${PS1_MODULES[@]}"; do
#  echo "MODULE: $module"
#done

export PS1_MODULES=()
for module_path in $PS1_ROOT/module/*.sh; do
  [[ -x $module_path ]] || continue
  if source $module_path; then
    PS1_MODULES+=("$(basename -s .sh $module_path)")
  fi
done

for style_path in $PS1_ROOT/style/*.sh; do
  source $style_path
done
export PS1_STYLE=solid

if [[ "$PS1_ORIG" == '' ]]; then
  default_prompt
fi

