#!/bin/bash

set_title() { export PS1_TITLE="$1"; }
set_prompt() {
  args=("$@")
  if (( "$#" == 0 )) ; then
    args=(
      :statusline
      :fg:cyan :user :fg:white @ :fg:blue :host :reset :space :fg:green :dir :eol
      :prompt :space
    )
  fi
  export PS1="$(__ps1_prompt "${args[@]}")";
}

__ps1_ansi_echo() { (( PS1_ANSI_TERM )) && echo -en "$1"; }

__ps1_ansi() {
  local out=''
  for arg in "$@"; do
    case "$arg" in
      :nl|:newline)  echo;;
      :space)        echo -n ' ';;
      :eol)          __ps1_ansi_echo '\e[0m\n\e[0m';; # Handy when bash eats a trailing newline
      :clear)        __ps1_ansi_echo '\e[H\e[2J';;
      +title)        __ps1_ansi_echo '\e]0;';;
      -title)        __ps1_ansi_echo '\a';;
      :reset)        __ps1_ansi_echo '\e[0m';;
      +bold)         __ps1_ansi_echo '\e[1m';;
      +dim)          __ps1_ansi_echo '\e[2m';;
      +italic)       __ps1_ansi_echo '\e[3m';;
      +underline)    __ps1_ansi_echo '\e[4m';;
      +blink)        __ps1_ansi_echo '\e[5m';;
      +reverse)      __ps1_ansi_echo '\e[7m';;
      +hidden)       __ps1_ansi_echo '\e[8m';;
      -bold)         __ps1_ansi_echo '\e[21m';;
      -dim)          __ps1_ansi_echo '\e[22m';;
      -italic)       __ps1_ansi_echo '\e[23m';;
      -underline)    __ps1_ansi_echo '\e[24m';;
      -blink)        __ps1_ansi_echo '\e[25m';;
      -reverse)      __ps1_ansi_echo '\e[27m';;
      -hidden)       __ps1_ansi_echo '\e[28m';;
      :fg:black)     __ps1_ansi_echo '\e[30m';;
      :fg:red)       __ps1_ansi_echo '\e[31m';;
      :fg:green)     __ps1_ansi_echo '\e[32m';;
      :fg:yellow)    __ps1_ansi_echo '\e[33m';;
      :fg:blue)      __ps1_ansi_echo '\e[34m';;
      :fg:magenta)   __ps1_ansi_echo '\e[35m';;
      :fg:cyan)      __ps1_ansi_echo '\e[36m';;
      :fg:white)     __ps1_ansi_echo '\e[37m';;
      :bg:black)     __ps1_ansi_echo '\e[40m';;
      :bg:red)       __ps1_ansi_echo '\e[41m';;
      :bg:green)     __ps1_ansi_echo '\e[42m';;
      :bg:yellow)    __ps1_ansi_echo '\e[43m';;
      :bg:blue)      __ps1_ansi_echo '\e[44m';;
      :bg:magenta)   __ps1_ansi_echo '\e[45m';;
      :bg:cyan)      __ps1_ansi_echo '\e[46m';;
      :bg:white)     __ps1_ansi_echo '\e[47m';;
      *)             echo -n "$arg";;
    esac
  done
}

__ps1_prompt() {
  for arg in "$@"; do
    case "$arg" in
      :title*)
        local -A o;
        local IFS=:
        for targ in $arg; do o[${targ%%=*}]="${targ#*=}"; done
        unset IFS
        local opts
        if [[ "${o[host]}" == 'off' ]]; then
          if [[ "${o[user]:-on}" == 'off' ]]; then
            opts=''
          else
            opts='\u'
          fi
        elif [[ "${o[host]}" == 'fqdn' ]]; then
          if [[ "${o[user]:-on}" == 'off' ]]; then
            opts='\H'
          else
            opts='\u@\H'
          fi
        else
          if [[ "${o[user]:-on}" == 'off' ]]; then
            opts='\h'
          else
            opts='\u@\h'
          fi
        fi
        if [[ "${o[dir]:-before}" == 'before' ]]; then
          if [[ "${o[basedir]:-off}" == 'off' ]]; then
            opts="\w $opts"
          else
            opts="\W $opts"
          fi
        elif [[ "${o[dir]:-before}" == 'after' ]]; then
          if [[ "${o[basedir]:-off}" == 'off' ]]; then
            opts="$opts \w"
          else
            opts="$opts \W"
          fi
        fi
        echo -n '\[\e]0;\]'
        if [[ "${o[title]:-before}" == 'before' ]]; then
          echo -n '`echo -n "$PS1_TITLE${PS1_title:+ - }"`'
          echo -n "$opts"
        elif [[ "${o[title]:-before}" == 'after' ]]; then
          echo -n "$opts"
          echo -n '`echo -n "${PS1_title:+ - }$PS1_TITLE"`'
        fi
        echo -n '\a'
        ;;
      :nl|:newline)  echo -n '\n';;
      :space)        echo -n ' ';;
      :eol)          echo -n '\[\e[0m\]\n\[\e[0m\]';;
      +title)        echo -n '\[\e]0;\]';;
      -title)        echo -n '\a';;
      :reset)        echo -n '\[\e[0m\]';;
      +bold)         echo -n '\[\e[1m\]';;
      +dim)          echo -n '\[\e[2m\]';;
      +italic)       echo -n '\[\e[3m\]';;
      +underline)    echo -n '\[\e[4m\]';;
      +blink)        echo -n '\[\e[5m\]';;
      +reverse)      echo -n '\[\e[7m\]';;
      +hidden)       echo -n '\[\e[8m\]';;
      -bold)         echo -n '\[\e[21m\]';;
      -dim)          echo -n '\[\e[22m\]';;
      -italic)       echo -n '\[\e[23m\]';;
      -underline)    echo -n '\[\e[24m\]';;
      -blink)        echo -n '\[\e[25m\]';;
      -reverse)      echo -n '\[\e[27m\]';;
      -hidden)       echo -n '\[\e[28m\]';;
      :fg:black)     echo -n '\[\e[30m\]';;
      :fg:red)       echo -n '\[\e[31m\]';;
      :fg:green)     echo -n '\[\e[32m\]';;
      :fg:yellow)    echo -n '\[\e[33m\]';;
      :fg:blue)      echo -n '\[\e[34m\]';;
      :fg:magenta)   echo -n '\[\e[35m\]';;
      :fg:cyan)      echo -n '\[\e[36m\]';;
      :fg:white)     echo -n '\[\e[37m\]';;
      :bg:black)     echo -n '\[\e[40m\]';;
      :bg:red)       echo -n '\[\e[41m\]';;
      :bg:green)     echo -n '\[\e[42m\]';;
      :bg:yellow)    echo -n '\[\e[43m\]';;
      :bg:blue)      echo -n '\[\e[44m\]';;
      :bg:magenta)   echo -n '\[\e[45m\]';;
      :bg:cyan)      echo -n '\[\e[46m\]';;
      :bg:white)     echo -n '\[\e[47m\]';;
      :clear)        echo -n '\[\e[H\e[2J\]';;
      :user)         echo -n '\u';;
      :dir)          echo -n '\w';;
      :basename)     echo -n '\W';;
      :host)         echo -n '\h';;
      :fqdn)         echo -n '\H';;
      :date)         echo -n '\d';;
      :escape)       echo -n '\e';;
      :jobs)         echo -n '\j';;
      :device)       echo -n '\l';;
      :bell)         echo -n '\a';;
      :shell)        echo -n '\s';;
      :time|time-24) echo -n '\t';;
      :time-12)      echo -n '\T';;
      :time-ampm)    echo -n '\@';;
      :version)      echo -n '\v';;
      :version-full) echo -n '\V';;
      :history)      echo -n '\!';;
      :command)      echo -n '\#';;
      :prompt)       echo -n '\$';;
      :backslash)    echo -n '\\';;
      :status)       echo -n '`__ps1_status`';;
      :statusline)   echo -n '`__ps1_status -n`';;
      *)             echo -n "$arg";;
    esac
  done
}

__ps1_default_fg()      { echo -n white; }
__ps1_default_bg()      { echo -n black; }
__ps1_default_prefix()  { echo -n; }
__ps1_default_postfix() { echo -n; }

__ps1_style() {
  if [[ "${PS1_STYLE:-default}" != 'default' ]]; then
    [[ "$(type -t __ps1_style_${PS1_STYLE}_$1)" == 'function' ]] \
      || source $PS1_ROOT/style/${PS1_STYLE}.sh
  fi
  __ps1_style_${PS1_STYLE:-default}_$1
}

__ps1_style_default_block_start() { echo -n +reverse '▏'; }
__ps1_style_default_block_end()   { echo -n :space; }
__ps1_style_default_block_pad()   { echo -n; }

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
      __ps1_ansi :fg:$(__ps1_config $module fg) :bg:$(__ps1_config $module bg) \
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

