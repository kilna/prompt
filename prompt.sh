#!/bin/bash

__ps1_ansi_code() { echo -en '\e\[${1}m'; }

__ps1_ansi_color() {
  case "$1" in
    black) echo -n 0;; red) echo -n 1;; green) echo -n 2;; yellow) echo -n 3;;
    blue) echo -n 4;; magenta) echo -n 5;; cyan) echo -n 6;; white) echo -n 7;;
  esac
}

__ps1_ansi_compile() {
  local out=''
  for arg in "$@"; do
    case "$arg" in
      :*|+*|-*)
        if [[ "${PS1_ANSI_TERM:-0}" -ne 0 ]]; then
          case "$arg" in
            :fg:*)         out+=$(__ps1_ansi_code 3$(__ps1_ansi_color ${arg:4}));;
            :bg:*)         out+=$(__ps1_ansi_code 4$(__ps1_ansi_color ${arg:4}));;
            :reset)        out+=$(__ps1_ansi_code 0);;
            :clear)        out+='\e[H\e[2J';;
            +title)        out+='\e]0;';;
            -title)        out+='\a';;
            +bold)         out+=$(__ps1_ansi_code 1);; -bold)      out+=$(__ps1_ansi_code 21);;
            +dim)          out+=$(__ps1_ansi_code 2);; -dim)       out+=$(__ps1_ansi_code 22);;
            +italic)       out+=$(__ps1_ansi_code 3);; -italic)    out+=$(__ps1_ansi_code 23);;
            +underline)    out+=$(__ps1_ansi_code 4);; -underline) out+=$(__ps1_ansi_code 24);;
            +blink)        out+=$(__ps1_ansi_code 5);; -blink)     out+=$(__ps1_ansi_code 25);;
            +reverse)      out+=$(__ps1_ansi_code 7);; -reverse)   out+=$(__ps1_ansi_code 27);;
            +hidden)       out+=$(__ps1_ansi_code 8);; -hidden)    out+=$(__ps1_ansi_code 28);;
          esac
        fi
      ;;
      :eol)          out+=$( [[ "${PS1_ANSI_TERM:-0}" -ne 0 ]] && __ps1_ansi_code 0)$'\n';;
      :nl|:newline)  out+=$'\n';;
      :cr|:return)   out+=$'\r';;
      *)             out+="$arg";;
    esac
  done
  echo -n "$out"
}

__ps1_default_fg()     { echo -n white; }
__ps1_default_bg()     { echo -n black; }
__ps1_default_prefix() { echo -n ''; }

__ps1_style() {
  if [[ "${PS1_STYLE:-default}" != 'default' ]]; then
    [[ "$(type -t __ps1_style_${PS1_STYLE}_$1)" == 'function' ]] \
      || source $PS1_ROOT/style/${PS1_STYLE}.sh
  fi
  __ps1_style_${PS1_STYLE:-default}_$1
}

__ps1_style_default_block_start() { echo -n "+reverse '▏'"; }
__ps1_style_default_block_end()   { echo -n "' ' -reverse"; }
__ps1_style_default_block_pad()   { echo -n "' '"; }

__ps1_config() {
  local module="$1"
  local key="$2"
  [[ "$(type -t __ps1_module_${module}_${key})" == 'function' ]] \
    && __ps1_module_${module}_${key} && return
  [[ "$(type -t __ps1_default_${key})" == 'function' ]] \
    && __ps1_module_default_${key}
}

__ps1_status() {
  local out=''
  for module in ${PS1_MODULES}; do
    [[ "$(type -t __ps1_module_${module}_output)" == 'function' ]] \
      || source $PS1_ROOT/module/${module}.sh
    local module_out=$(__ps1_module_${module}_output)
    if [[ "$module_out" != '' ]]; then
      [[ "$out" != '' ]] && out+="$(__ps1_ansi_code $(__ps1_style block_pad))"
      out+="$(
        __ps1_ansi_compile \
          :fg:$(__ps1_config $module fg) \
          :bg:$(__ps1_config $module bg) \
          $(__ps1_style block_start) \
          $(__ps1_config $module prefix) \
          '$module_out' \
          $(__ps1_config $module postfix) \
          $(__ps1_style block_end)
      )"
    fi
  done
  [[ "$out" ]] || return
  echo $out
  [[ "$1" == '--newline' ]] && echo __ps1_ansi_compile :eol
}

case "$TERM" in linux|xterm*|*vt*|con*|*ansi*|screen) export PS1_ANSI_TERM=1;; esac
export PS1_ROOT=$(cd "$(dirname '${BASH_SOURCE[@]}')" &>/dev/null && pwd)
export PS1_MODULES=${PS1_MODULES:-error}
export PATH="$PATH:$PS1_ROOT/bin"

