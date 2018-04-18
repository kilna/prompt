#!/bin/bash

set_title() { export PS1_TITLE="$1"; }
unset_title() { unset PS1_TITLE; }

set_prompt() {
  export PS1_ORIG="$PS1"
  args=("$@")
  (( "$#" == 0 )) && args=(
    :newline :statusline
    :user '@' :host :space :dir :title :eol
    :prompt :space :reset
  )
  export PS1="$(__ps1_prompt "${args[@]}")";
}
unset_prompt() { export PS1="$PS1_ORIG"; }

__ps1_color() {
  [[ "$1" == ':bg' ]] && prefix='4' || prefix='3'
  case "$2" in
    black)   echo -n '\e['$prefix'0m';;  red)     echo -n '\e['$prefix'1m';;
    green)   echo -n '\e['$prefix'2m';;  yellow)  echo -n '\e['$prefix'3m';;
    blue)    echo -n '\e['$prefix'4m';;  magenta) echo -n '\e['$prefix'5m';;
    cyan)    echo -n '\e['$prefix'6m';;  white)   echo -n '\e['$prefix'7m';;
  esac
}

__ps1_mode() {
  [[ "${1:0:1}" == '-' ]] && prefix='2'
  case "${1:1}" in
    bold)      echo -n '\e['$prefix'1m';;  dim)       echo -n '\e['$prefix'2m';;
    italic)    echo -n '\e['$prefix'3m';;  underline) echo -n '\e['$prefix'4m';;
    blink)     echo -n '\e['$prefix'5m';;  fastblink) echo -n '\e['$prefix'6m';;
    reverse)   echo -n '\e['$prefix'7m';;  hidden)    echo -n '\e['$prefix'8m';;
  esac
}

__ps1_ansi_echo() { (( PS1_ANSI_TERM )) && echo -en "$1"; }

__ps1_stylize() { content="$1"; shift; __ps1_ansi $(__ps1_style "$@") "$content" :reset; }

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
      :title)
        local title="${PS1_TITLE_FORMAT:-\\z\\-\\u@\\h \\w}"
        title="${title//\\z/'`echo -n "$PS1_TITLE"`'}"
        title="${title//\\-/'`echo -n "${PS1_TITLE:+ - }"`'}"
        echo -n '\[\e]0;\]'"$title"'\a'
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
      :time-12)       echo -n '\T';;
      :time-ampm)     echo -n '\@';;
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

__ps1_default_fg()      { echo -n white; }
__ps1_default_bg()      { echo -n black; }
__ps1_default_prefix()  { echo -n; }
__ps1_default_postfix() { echo -n; }

__ps1_style() {
  style="${PS1_STYLE:-default}"
  properties=("$@" 'default')
  if [[ \
    "$style" != 'default' && \
    "$(type -t __ps1_style_${style}_default)" != 'function' && \
    -e $PS1_ROOT/style/$style.sh \
  ]]; then
    source $PS1_ROOT/style/$style.sh
  fi
  for property in "${properties[@]}"; do
    __ps1_style_${style}_$property 2>/dev/null && return
  done
}

__ps1_style_default_user()        { echo -n :fg cyan; }
__ps1_style_default_host()        { echo -n :fg magenta; }
__ps1_style_default_dir()         { echo -n :fg green; }
__ps1_style_default_time()        { echo -n :fg blue +reverse; }
__ps1_style_default_date()        { echo -n :fg blue +reverse; }
__ps1_style_default_block_start() { echo -n '[' :space; }
__ps1_style_default_block_end()   { echo -n :space ']'; }
__ps1_style_default_block_pad()   { echo -n :space; }

__ps1_style_block_block_start() { echo -n +reverse '▏'; }
__ps1_style_block_block_end()   { echo -n :space; }
__ps1_style_block_block_pad()   { echo -n; }

__ps1_config() {
  local module="$1"
  local key="$2"
  [[ "$(type -t __ps1_module_${module}_${key})" == 'function' ]] \
    && __ps1_module_${module}_${key} && return
  [[ "$(type -t __ps1_default_${key})" == 'function' ]] \
    && __ps1_module_default_${key}
}

__ps1_module_error_output()  { (( "$PS1_LAST_ERR" )) && echo -n $PS1_LAST_ERR; }
__ps1_module_error_fg()      { echo -n red; }
__ps1_module_error_bg()      { echo -n black; }
__ps1_module_error_prefix()  { echo -n +blink ⚠ -blink :space; }
__ps1_module_error_postfix() { echo -n; }

__ps1_status() {
  export PS1_LAST_ERR="$?"
  while (( "$#" > 0 )); do arg="$1"; shift;
    case "$arg" in
      -n|--newline) newline=1;;
    esac
  done
  local status_items=0
  for module in ${PS1_MODULES}; do
    local module_out=$(__ps1_module_${module}_output)
    if [[ "$module_out" != '' ]]; then
      (( status_items++ )) && __ps1_ansi $(__ps1_style block_pad)
      __ps1_ansi :fg $(__ps1_config $module fg) :bg $(__ps1_config $module bg) \
                 $(__ps1_style block_start) $(__ps1_config $module prefix)
      echo -n "$module_out"
      __ps1_ansi $(__ps1_config $module postfix) $(__ps1_style block_end)
    fi
  done
  (( status_items )) && (( newline )) && __ps1_ansi :eol
}

case "$TERM" in linux|xterm*|*vt*|con*|*ansi*|screen) export PS1_ANSI_TERM=1;; esac
export PS1_ROOT=$(cd "$(dirname '${BASH_SOURCE[@]}')" &>/dev/null && pwd)
export PS1_MODULES=${PS1_MODULES:-error}
export PATH="$PATH:$PS1_ROOT/bin"

