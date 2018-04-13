#!/bin/bash

case "$TERM" in linux|xterm*|*vt*|con*|*ansi*|screen) export PS1_ANSI_TERM=1;; esac

__ansi() { echo -n '\e\[${1}m'; }
__prompt_ansi() { echo -n '\[\e\[${1}m\]'; }
__ansi_color() {
  case "$1" in
    black) echo -n 0;; red) echo -n 1;; green) echo -n 2;; yellow) echo -n 3;;
    blue) echo -n 4;; magenta) echo -n 5;; cyan) echo -n 6;; white) echo -n 7;;
  esac
}

compile_ansi() {
  local out=''
  for arg in "${arg[@]}"; do
    case "$arg" in
      :*|+*|-*)
        if (( PS1_ANSI_TERM )); then
          case "$arg" in
            :fg:*)         out+=$(__ansi 3$(__ansi_color ${arg:4}));;
            :bg:*)         out+=$(__ansi 4$(__ansi_color ${arg:4}));;
            :reset)        out+=$(__ansi 0);;
            :clear)        out+='\e[H\e[2J';;
            +title)        out+='\e]0;';;
            -title)        out+='\a';;
            +bold)         out+=$(__ansi 1);; -bold)      out+=$(__ansi 21);;
            +dim)          out+=$(__ansi 2);; -dim)       out+=$(__ansi 22);;
            +italic)       out+=$(__ansi 3);; -italic)    out+=$(__ansi 23);;
            +underline)    out+=$(__ansi 4);; -underline) out+=$(__ansi 24);;
            +blink)        out+=$(__ansi 5);; -blink)     out+=$(__ansi 25);;
            +reverse)      out+=$(__ansi 7);; -reverse)   out+=$(__ansi 27);;
            +hidden)       out+=$(__ansi 8);; -hidden)    out+=$(__ansi 28);;
          esac
        fi
      ;;
      :eol)          out+=$( (( PS1_ANSI_TERM )) && __ansi 0)$'\n';;
      :nl|:newline)  out+=$'\n';;
      :cr|:return)   out+=$'\r';;
      *)             out+="$arg";;
    esac
  done
  echo -n "$out"
}

set_title() { export PS1_TITLE="$1"; }

set_prompt() { local prompt=$(compile_prompt "$@"); export PS1="$prompt"; }

compile_prompt() {
  local out=''
  for module in "${PS1_MODILES[@]}"; do
    source `dirname $0`/module/$module.sh
    if [[ type -t "__ps1_module_${module}_prompt_prefix" == 'function' ]]; then
      out+=$(__ps1_module_${module}_prompt_prefix)
    fi
  done
  for arg in "${arg[@]}"; do
    case "$arg" in
      :fg:*)         out+=$(__prompt_ansi 3$(__ansi_color ${arg:4}));;
      :bg:*)         out+=$(__prompt_ansi 4$(__ansi_color ${arg:4}));;
      :reset)        out+=$(__prompt_ansi 0);;
      :clear)        out+='\[\e[H\e[2J\]';;
      +title)        out+='\[\e]0;\]';;        -title)     out+='\a';;
      +bold)         out+=$(__prompt_ansi 1);; -bold)      out+=$(__prompt_ansi 21);;
      +dim)          out+=$(__prompt_ansi 2);; -dim)       out+=$(__prompt_ansi 22);;
      +italic)       out+=$(__prompt_ansi 3);; -italic)    out+=$(__prompt_ansi 23);;
      +underline)    out+=$(__prompt_ansi 4);; -underline) out+=$(__prompt_ansi 24);;
      +blink)        out+=$(__prompt_ansi 5);; -blink)     out+=$(__prompt_ansi 25);;
      +reverse)      out+=$(__prompt_ansi 7);; -reverse)   out+=$(__prompt_ansi 27);;
      +hidden)       out+=$(__prompt_ansi 8);; -hidden)    out+=$(__prompt_ansi 28);;
      :eol)          out+=$(__prompt_ansi 0)'\n';;
      :user)         out+='\u';;
      :dir)          out+='\w';;
      :basename)     out+='\W';;
      :host)         out+='\h';;
      :fqdn)         out+='\H';;
      :date)         out+='\d';;
      :escape)       out+='\e';;
      :jobs)         out+='\j';;
      :device)       out+='\l';;
      :nl|:newline)  out+='\n';;
      :cr|:return)   out+='\r';;
      :bell)         out+='\a';;
      :shell)        out+='\s';;
      :time|time-24) out+='\t';;
      :time-12)      out+='\T';;
      :time-ampm)    out+='\@';;
      :version)      out+='\v';;
      :version-full) out+='\V';;
      :history)      out+='\!';;
      :command)      out+='\#';;
      :prompt)       out+='\$';;
      :backslash)    out+='\\';;
      :status)       out+='`__ps1_status`';;
      :statusline)   out+='`__ps1_status --newline`';;
      :title*)       opts=''
                     [[ "$arg" == *'no-user'* ]] || [[ "$arg" == *'no-host'* ]] && opts+='\u' || opts+='\u@'
                     [[ "$arg" == *'no-host'* ]] || [[ "$arg" == *'fqdn'* ]] && opts+='\H' || opts+='\h'
                     [[ "$arg" == *'no-dir'* ]] || [[ "$arg" == *'base'* ]] && opts+=' \W' || opts+=' \w'
                     out+='\[\e]0;\]`[[ "$PS1_TITLE" ]] && echo -n "$PS1_TITLE - "`'"$opts"'\a'
                     ;;
      *)             out+="$arg";;
    esac
  done
  echo -n "$out"
}

__ps1_status() {
  for module in "${PS1_MODILES[@]}"; do
    if [[ type -t "__ps1_module_${module}_output" == 'function' ]]; then
      out=$(__ps1_module_${module}_output)
    fi
  done
  [[ "$1" == '--newline' ]] && echo _ansi :eol
}

__ps1_status_block() {
  local msg=$(cat -)
  [[ "$msg" ]] || return
  PS1_STATUS="$msg" __ansi :$1
}

export PS1_MODULES=(error)

