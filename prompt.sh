#!/bin/bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cat <<EOF >&2
This script is meant to be added into a bash shell session via:

source $0

You cannot call this script directly.
EOF
  return 1
fi

set_title() {
  export PS1_TITLE="$1"
}

unset_title() {
  unset PS1_TITLE
}

reset_prompt() {
  #env | grep PS1_ | __ps1_debug 
  export PS1="$PS1_ORIG"
  unset PS1_ORIG
  unset PS1_MODULES
  unset PS1_STYLES
  unset PS1_DEBUG
  unset PS1_TITLE
  unset PS1_TITLE_FORMAT
  #env | grep PS1_ | __ps1_debug 
  for func in "$(typeset -F | cut -d ' ' -f 3 | grep -E '^__ps1_')"; do
    unset -f $func
  done
  source $PS1_ROOT/prompt.sh "$@"
}

__ps1_debug() {
  (( "${PS1_DEBUG:-0}" )) || return
  echo "$@" >&2
  #cat - >&2
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
  __ps1_ansi $(__ps1_style "$@") "$content"
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
      :style)  __ps1_ansi_echo $(__ps1_style "$1"); shift;;
      :fg|:bg) __ps1_ansi_echo $(__ps1_color "$arg" "$1"); shift;;
      +*|-*)   __ps1_ansi_echo $(__ps1_mode "$arg");;
      *)       echo -n "$arg";;
    esac
  done
}

__ps1_prompt_stylize() {
  content="$1"
  shift
  __ps1_prompt $(__ps1_style "$@") "$content" 
}

__ps1_prompt() {
  while (( "$#" > 0 )); do
    arg="$1"
    shift
    case "$arg" in
      :title)         if [[ "${PS1_NO_TITLE:-0}" != 0 ]]; then
                        local title="${PS1_TITLE_FORMAT:-\\z\\-\\u@\\h \\w}"
                        title="${title//\\z/'`echo -n "$PS1_TITLE"`'}"
                        title="${title//\\-/'`echo -n "${PS1_TITLE:+ - }"`'}"
                        echo -n '\[\e]0;\]'"${title//\`\`/;}"'\a'
                      fi;;
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
      :style)         __ps1_prompt $(__ps1_style "$1");;
      :status)        echo -n '`__ps1_status`';;
      :statusline)    echo -n '`__ps1_status -n`';;
      +*|-*)          echo -n '\['; __ps1_mode "$arg"; echo -n '\]';;
      *)              echo -n "$arg";;
    esac
  done
}

__ps1_style() {
  properties=("$@" 'default')
  for property in "${properties[@]}"; do
    for style in "${PS1_STYLES[@]}"; do
      __ps1_style_${style}_${property} 2>/dev/null && return
    done
  done
}

__ps1_status() {
  export PS1_LAST_ERR="$?"
  local newline=0; if [[ "$1" == '-n' ]]; then newline=1; shift; fi
  local modules=("${PS1_MODULES[@]}"); [[ "$1" ]] && modules=("$@")
  local status_items=0
  for module in "${modules[@]}"; do
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
  if [[ "$status_items" > 0 && "$newline" == 1 ]]; then
    __ps1_ansi :eol
  fi
  return $PS1_LAST_ERR
}

# Process --key=val args into --key val, un-bundle single-letter flags
args=(); for (( i=1; i<=$#; i++ )); do a="${@:$i:1}"
  [[   "$a" == '--'       ]] && args+=("${@:$i}")            && break
  [[   "$a" == '--'*'='*  ]] && args+=("${a%%=*}" "${a#*=}") && continue
  [[ ! "$a" =~ ^-([^-]+)$ ]] && args+=("$a")                 && continue
  args+=( $( for (( x=1; x<${#a}; x++ )); do echo "-${a:$x:1}"; done ) )
done
set -- "${arg[@]}"

export PS1_MODULES=()
export PS1_STYLES=('user' 'default')
export PS1_ROOT=$(cd "$(dirname '${BASH_SOURCE[@]}')" &>/dev/null && pwd)
all_modules=0
while (( "$#" > 0 )); do arg="$1"; shift; case "$arg" in
  -m|--module)      PS1_MODULES+=("$1"); shift ;;
  -a|--all-modules) all_modules=1 ;;
  -s|--style)       PS1_STYLES=("$1" "${PS1_STYLES[@]}"); shift ;;
  -u|--user-style)  str="__ps1_style_user_${1%%=*}() { echo -n ${1#*=}; }"
                    __ps1_debug "$str"
                    eval "$str";;
  -r|--root)        PS1_ROOT="$1"; shift ;;
  -p|--prompt)      [[ "$PS1_ORIG" == '' ]] && export PS1_ORIG="$PS1"
                    export PS1="$(__ps1_prompt $1 :title)"
                    shift;;
  -d|--debug)       PS1_DEBUG=1 ;;
  -t|--title)       PS1_TITLE_FORMAT="$1"; shift ;;
  -n|--no-title)    PS1_NO_TITLE=1 ;;
esac; done

__ps1_debug "PS1_ROOT: $PS1_ROOT"

if (( all_modules )); then
  PS1_MODULES=()
  for module_path in $PS1_ROOT/module/*.sh; do
    PS1_MODULES+=("$(basename -s .sh $module_path)")
  done
fi

err=0
for module in "${PS1_MODULES[@]}"; do
  __ps1_debug "PS1_MODULE: $module"
  if ! source ${PS1_ROOT}/module/${module}.sh; then
    echo "Unable to open $0 module ${PS1_ROOT}/modules/${module}.sh" >&2
    (( err++ ))
  fi
done
for style in "${PS1_STYLES[@]}"; do
  [[ "$style" == 'user' ]] && continue
  __ps1_debug "PS1_STYLE: $style"
  if ! source ${PS1_ROOT}/style/${style}.sh; then
    echo "Unable to open $0 style ${PS1_ROOT}/style/${style}.sh" >&2
    (( err++ ))
  fi
done

if [[ "$PS1_ORIG" == '' ]]; then
  # Set default prompt if we haven't set one already
  export PS1="$(
    __ps1_prompt :statusline \
      :user :reset '@' :host ' ' :dir :eol \
      :prompt ' ' :title :reset
  )"
fi

return $err

