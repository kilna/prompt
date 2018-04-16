#!/bin/bash

__ps1_ansi_echo() { (( PS1_ANSI_TERM )) && echo -en "$1"; }

__ps1_ansi() {
  local out=''
  for arg in "$@"; do
    case "$arg" in
      :nl|:newline)  echo;;
      :space)        echo -n ' ';;
      :eol)          __ps1_ansi_echo '\e[0m\n';;
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

set_title() { export PS1_TITLE="$1"; }

set_prompt() {
  out=''
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
        out+='\[\e]0;\]'
        if [[ "${o[title]:-before}" == 'before' ]]; then
          out+='`[[ "$PS1_TITLE" ]] && echo -n "$PS1_TITLE - "`'
          out+="$opts"
        elif [[ "${o[title]:-before}" == 'after' ]]; then
          out+="$opts"
          out+='`[[ "$PS1_TITLE" ]] && echo -n " - $PS1_TITLE"`'
        fi
        out+='\a'
        ;;
      :nl|:newline)  out+='\n';;
      :space)        out+=' ';;
      :eol)          out+='\[\e[0m\]\n';;
      +title)        out+='\[\e]0;\]';;
      -title)        out+='\a';;
      :reset)        out+='\[\e[0m\]';;
      +bold)         out+='\[\e[1m\]';;
      +dim)          out+='\[\e[2m\]';;
      +italic)       out+='\[\e[3m\]';;
      +underline)    out+='\[\e[4m\]';;
      +blink)        out+='\[\e[5m\]';;
      +reverse)      out+='\[\e[7m\]';;
      +hidden)       out+='\[\e[8m\]';;
      -bold)         out+='\[\e[21m\]';;
      -dim)          out+='\[\e[22m\]';;
      -italic)       out+='\[\e[23m\]';;
      -underline)    out+='\[\e[24m\]';;
      -blink)        out+='\[\e[25m\]';;
      -reverse)      out+='\[\e[27m\]';;
      -hidden)       out+='\[\e[28m\]';;
      :fg:black)     out+='\[\e[30m\]';;
      :fg:red)       out+='\[\e[31m\]';;
      :fg:green)     out+='\[\e[32m\]';;
      :fg:yellow)    out+='\[\e[33m\]';;
      :fg:blue)      out+='\[\e[34m\]';;
      :fg:magenta)   out+='\[\e[35m\]';;
      :fg:cyan)      out+='\[\e[36m\]';;
      :fg:white)     out+='\[\e[37m\]';;
      :bg:black)     out+='\[\e[40m\]';;
      :bg:red)       out+='\[\e[41m\]';;
      :bg:green)     out+='\[\e[42m\]';;
      :bg:yellow)    out+='\[\e[43m\]';;
      :bg:blue)      out+='\[\e[44m\]';;
      :bg:magenta)   out+='\[\e[45m\]';;
      :bg:cyan)      out+='\[\e[46m\]';;
      :bg:white)     out+='\[\e[47m\]';;
      :clear)        out+='\[\e[H\e[2J\]';;
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
      *)             out+="$arg";;
    esac
  done
  export PS1="$out"
}

__ps1_default_fg()     { echo -n white; }
__ps1_default_bg()     { echo -n black; }
__ps1_default_prefix() { echo -n; }

__ps1_style() {
#  if [[ "${PS1_STYLE:-default}" != 'default' ]]; then
#    [[ "$(type -t __ps1_style_${PS1_STYLE}_$1)" == 'function' ]] \
#      || source $PS1_ROOT/style/${PS1_STYLE}.sh
#  fi
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

__ps1_module_error_output()  { [[ "$PS1_LAST_ERR" != 0 ]] && echo -n $PS1_LAST_ERR; }
__ps1_module_error_fg()      { echo -n red; }
__ps1_module_error_bg()      { echo -n black; }
__ps1_module_error_prefix()  { echo -n +blink ⚠ -blink :space; }
__ps1_module_error_postfix() { echo -n; }

__ps1_status() {
  export PS1_LAST_ERR="$?"
  local out=''
  for module in ${PS1_MODULES}; do
    local module_out=$(__ps1_module_${module}_output)
    if [[ "$module_out" != '' ]]; then
      [[ "$out" != '' ]] && __ps1_ansi $(__ps1_style block_pad)
      __ps1_ansi :fg:$(__ps1_config $module fg) :bg:$(__ps1_config $module bg) \
                 $(__ps1_style block_start) $(__ps1_config $module prefix)
      echo -n "$module_out"
      __ps1_ansi $(__ps1_config $module postfix) $(__ps1_style block_end) :reset
    fi
  done
  [[ "$out" ]] || return
  [[ "$1" == '--newline' ]] && echo
}

case "$TERM" in linux|xterm*|*vt*|con*|*ansi*|screen) export PS1_ANSI_TERM=1;; esac
export PS1_ROOT=$(cd "$(dirname '${BASH_SOURCE[@]}')" &>/dev/null && pwd)
export PS1_MODULES=${PS1_MODULES:-error}
export PATH="$PATH:$PS1_ROOT/bin"

