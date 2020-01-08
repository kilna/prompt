#!/bin/bash

if [ ! "$BASH" ]; then
  echo "Script is only compatible with bash, current shell is $SHELL" >&2
  exit 1
fi

RED_ROOT="$(cd `dirname ${BASH_SOURCE[0]}` &>/dev/null; echo $PWD)"
RED_NAME="${BASH_SOURCE[0]##*/}"
RED_SCRIPT="$RED_ROOT/$RED_NAME"
IFS='' read -r RED_ANSI_COLOR_DEPTH < <(red::ansi_color_depth)
for p in $PAGER less more cat; do
  which $p &>/dev/null && RED_PAGER="$p" && break
done

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cat <<EOF >&2
This script is meant to be added into a Bash shell session via:

source $RED_SCRIPT

After loading via source, you can use 'red reload' to reload.
EOF
  exit 1
fi

trap "$(shopt -p extglob)" RETURN
shopt -s extglob

red() {

  eval $( CONFIGPARAMS='-c|--config' CONFIGFILES=$HOME/.redrc? red::cfg "$@" )

  # Process global options
  RED_STYLES='user default'
  local user_styles=()
  local load_modules=()
  for a in "$@"; do
    case "$a" in
      -m|--module)       load_modules+=("$1"); shift ;;
      -a|--all-modules)  all_modules=1 ;;
      -d|--debug)        RED_DEBUG=1;;
      -l|--powerline)    RED_POWERLINE=1;;
      -b|--bold)         RED_BOLD=1 ;;
      -s|--style)        RED_STYLES="$1 ${RED_STYLES}"; shift ;;
      -u|--user-style)   user_styles+=("$1"); shift ;;
      -c|--colors)       RED_ANSI_COLOR_DEPTH=("$1"); shift ;;
      *)                 ar+=("$a");;
    esac
  done
  set -- "${ar[@]}"
  ar=()

  red::debug "RED_ROOT: $RED_ROOT"
  red::debug "RED_NAME: $RED_NAME"
  red::debug "RED_SCRIPT: $RED_SCRIPT"

  if [[ "$all_modules" ]]; then
    load_modules=()
    for module_path in $RED_ROOT/module/*; do
      load_modules+=("${module_path##*/}")
    done
  fi
  unset all_modules

  for func in $(red::funcs); do
    if [[ "$func" == 'red::module_'* || "$func" == 'red::style_'* ]]; then
      red::debug "Unsetting $func"
      unset -f $func
    fi
  done

  for user_style in "${user_styles[@]}"; do
    str="red::style_user_${user_style%%=*}() { echo -n '${user_style#*=}'; }"
    red::debug "$str"
    eval "$str"
  done
  unset user_styles

  err=0

  RED_MODULES=''
  for module in "${load_modules[@]}"; do
    red::debug "Loading module: $module"
    if ! source "${RED_ROOT}/module/${module}"; then
      echo "Unable to open $RED_NAME module $RED_ROOT/modules/$module" >&2
      (( err++ ))
    fi
    if typeset -F red::module_$module &>/dev/null; then
      red::debug "Module $module loaded successfully"
      RED_MODULES+="$module "
    fi
  done

  for style in ${RED_STYLES}; do
    [[ "$style" == 'user' ]] && continue
    red::debug "RED_STYLE: $style"
    if ! source "${RED_ROOT}/style/${style}"; then
      echo "Unable to open $RED_NAME style $RED_ROOT/style/$style" >&2
      (( err++ ))
    fi
  done

  local action="$1"
  shift

  case "$action" in
    -h|--help) red::help;;
    help)      if [[ "$1" != '' ]]; then red::help
               else action="$1"; shift; red::help::$action "$@"; fi;;
    line)      red::prompt "$@";;
    eye)       red::ansi_remap "$@";;
    *)         red::$action "$@";;
  esac

}

cfg() {

  # Clean up / unify contents of $@
  local ar=()
  local a
  while (( $# > 0 )); do
    a="$1"; shift
    case "$a" in
      --)    ar+=("${@:1}"); break;; # -- is end of processable args
      --*=*) ar+=("${a%%=*}" "${a#*=}");; # break --foo=bar into --foo bar
      --*)   ar+=("$a");; # Match --flag so we skip next line
      -*)    # Unbundle grouped single-letter flags
             for (( x=1; x<${#a}; x++ )); do ar+=("-${a:$x:1}"); done;;
      *)     ar+=("$a");; # Any other kind of argument is passed through
    esac
  done
  set -- "${ar[@]}"

  # Resolve passed in config file parameters into configfiles array
  ar=()
  IFS=: read -a configfiles <<< "$CONFIGFILES"
  IFS=\| read -a configparams <<< "$CONFIGPARAMS"
  local match
  while (( $# > 0 )); do
    a="$1"; shift
    match=''
    for param in "${configparams[@]}"; do
      if [[ "$a" == "$param" ]]; then
        match="$1"
        shift
        break
      fi
    done
    if [[ "$match" ]]; then
      configfiles+=("$match")
    else
      ar+=("$a")
    fi
  done
  set -- "${ar[@]}"

  # Process each configfile into additional prepended $@ parameters
  for file in "${configfiles[@]}"; do
    # Files ending with ? are optional, skip if not presetn
    if [[ "${file%'?'}" != "$file" ]]; then
      file="${file%'?'}"
      [[ ! -e $file ]] && continue
    fi
    while IFS='' read line; do
      case "$line" in
        ''|'#'*) : ;; # Skip blank or comment lines
        *)       set -- "$@" "--$line";;
      esac
    done < <(cat $file)
  done

  # Generate a set statement to be eval'd, which will recreate $@
  # normalized, with all of the values from the config files in place
  echo -n "set -- "
  for a in "$@"; do
    echo -n \'${a//\'/\'\\\'\'}\'' '
  done

}

red::title() { export RED_TITLE="$1"; }

red::notitle() { unset RED_TITLE; }

red::reload() {
  red::debug "Running $RED_SCRIPT"
  if [[ -e $RED_SCRIPT ]]; then
    source $RED_SCRIPT "$@"
  else
    echo "Unable to find RED_SCRIPT: $RED_SCRIPT" >&2
    return 1
  fi
}

red::unload() {
  if [[ "$RED_PS1_ORIG" != '' ]]; then export PS1="$RED_PS1_ORIG"; fi
  local debug="$RED_DEBUG"
  for var in $(red::vars); do
    [[ "$debug" ]] && echo "Unsetting $var" >&2
    unset $var &>/dev/null
  done
  for func in $(red::funcs); do
    [[ "$debug" ]] && echo "Unsetting $func" >&2
    unset -f $func &>/dev/null
  done
}

red::lookup() {
  if typeset -F red::$1; then red::$1; return $?; fi
  if typeset $1; then eval 'echo -n $red_'"$1"; return 0; fi
  return 1
}

red::funcs() {
  while IFS='' read line; do
    local f=($line)
    if [[ "${f[0]}" == 'declare' &&
          "${f[1]}" == '-f' && 
          "${f[2]}" == 'red::'*
       ]]; then
      echo -n "${f[2]} "
    fi
  done < <(typeset -F)
}

red::vars() {
  while IFS='' read line; do
    local f=($line)
    if [[ "${f[0]}" == 'declare' &&
          "${f[1]}" == '-x' &&
          "${f[2]}" == 'RED_'*'='
       ]]; then
      echo -n "${f[2]%%=*} "
    fi
  done < <(typeset -x)
}

red::debug() { [[ "$RED_DEBUG" ]] && echo "$@" >&2; }

red::unicode() { case "$LANG" in *'UTF-8'*) return 0;; *) return 1;; esac; }

red::powerline() {
  red::unicode || return 1
  if [[ "${RED_POWERLINE:-0}" != 1 ]]; then return 1; fi
  return 0
}

red::load_style() {
  local file="$1"
  local is_unicode=0
  local code=''
  while IFS='' read line; do
    [[ "$line" == '#'* || "$line" =~ ^[[:space:]]*$ ]] && continue
    if [[ "$line" != *':'* ]]; then
      echo "Unable to parse line '$line' in file '$file'" >&2
      continue
    else
      name="${line%%=*}"
      name="${name## }"
      name="${name%% }"
      val="${line#*=}"
      val="${val## }"
      val="${val%% }"
      [[ "$val" == *'{u:'* ]] && is_unicode=1
      code+="export RED_SYLE_${name^^}='${val//\'/\\\'}'"$'\n';
    fi
  done < "$1"
  if [[ ! red::unicode && is_unicode ]]; then
    echo "File '$file' contains unicode style information but terminal is not UTF-8" >&2
  fi
  eval "$code"
}

red::parse_markup() {
  local ar=()
  for str in "$@"; do
    while [[ "$str" != '' ]]; do
      x="${str%%\{*}"
      [[ "$x" = "$str" ]] || idx1=$(( ${#x} + 1 ))
      x="${str%%\}*}"
      [[ "$x" = "$str" ]] || idx2=$(( ${#x} + 1 ))
      nontag_val=''
      tag_val=''
      if [[ "$idx1" != '' && "$idx2" != '' && (( idx2 > idx1 )) ]]; then
        substr="${str:0:$idx2}"
        x="${substr%\{*}"
        [[ "$x" = "$substr" ]] || idx1=$(( ${#x} + 1 ))
        if [[ "$idx1" == '' ]]; then
          nontag_val+="$substr"
        else
          idx1x=$(( idx1 - 1 ))
          if (( idx1 != 0 )); then
            nontag_val+="${str:0:$idx1x}"
          fi
          idx2x=$(( idx2 - idx1 + 1 ))
          tag_val="${str:$idx1x:$idx2x}"
        fi
        str="${str:$idx2}"
      else
        nontag_val+="$str"
        str=''
      fi
      ar_idx=$(( ${#ar[@]} - 1 ))
      if [[ "$nontag_val" != '' ]]; then
        if [[ "$ar_idx" -lt 0 || "${ar[$ar_idx]}" == '{'*'}' ]]; then
          ar+=("$nontag_val")
        else
          ar[$ar_idx]+="$nontag_val" 
        fi
      fi
      if [[ "$tag_val" != '' ]]; then
        ar+=("$tag_val")
      fi
    done
  done
  export red_markup_parsed=''
  for chunk in "${ar[@]}"; do
    red_markup_parsed+="$chunk"$'\033'
  done
}

red::ansi_echo() {
  [[ -z "$RED_ANSI_COLOR_DEPTH" || "$RED_ANSI_COLOR_DEPTH" == '0' ]] \
    || echo -en "$1"
}

red::style_as_ansi() {
  [[ "$RED_BOLD" ]] && red::markup_as_ansi '{bold}'
  for property in "$1" 'default'; do
    for style in ${RED_STYLES}; do
      local out
      IFS='' read -r out < <(red::style_${style}_${property} 2>/dev/null)
      if [[ "$out" != '' ]]; then
        red::markup_as_ansi "$out"
        return
      fi
    done
  done
}

red::rgb_as_ansi() {
  # Rounds to the nearest ANSI 216 color cube or 24 grayscale value. See:
  # https://docs.google.com/spreadsheets/d/1n4zg5OXYC0hBdRKBb1clx4t2HSx_cu_iiot6GYpgh1c/
  local ansi_fgbg="$1" # ANSI fg/bg code (either 3 or 4)
  local r="$2"
  local g="$3"
  local b="$4"

  # If we're in 24 bit mode we don't have to round, return using RGB syntax
  if [[ "$RED_ANSI_COLOR_DEPTH" == '24bit' ]]; then
    echo -n '\e['"${ansi_fgbg}8;2;${r};${g};${b}m"
    return
  fi

  local min=''
  local max=''
  local total=0
  for c in $r $g $b; do
    if [[ "$min" == '' ]] || (( c < min )); then min="$c"; fi
    if [[ "$max" == '' ]] || (( c > max )); then max="$c"; fi
    total=$(( total + c ))
  done

  local idx=''
  if (( ( max - min ) <= 26 )); then
    # If the delta between min and max is less than 26 (roughly 1/2 the 51.2
    # shades per 6x6x6 colors) then the color is effectively gray.
    local gray=$(( total / 3 )) # RGB colors as passed averaged into single 0-255 gray
    if ((
      ( gray >= 8   && gray < 51  ) || ( gray >= 58  && gray < 102 ) ||
      ( gray >= 108 && gray < 153 ) || ( gray >= 158 && gray < 204 ) ||
      ( gray >= 208 && gray < 248 )
    )); then
      # If we aren't better matched to the 6x6x6 cube, use a 24-shade ANSI gray
      idx=$(( 230 + ( ( $gray + 12 ) / 10 ) ))
    fi
  fi

  if [[ "$idx" == '' ]]; then
    # Otherwise, map to ANSI 216 indexed color cube
    idx=$((
      16 + ( ( ( $r + 26 ) / 51 ) * 36 ) + ( ( ( $g + 26 ) / 51 ) * 6  )
         + ( ( ( $b + 26 ) / 51 ) * 1  )
    ))
  fi

  echo -n '\e['"${ansi_fgbg}8;5;${idx}m"
}

red::color_tag_as_ansi() {
  # If we're foreground $g is set to 3, if background it's set to 4
  local ansi_fgbg='3'; if [[ "${1:0:2}" == 'bg' ]]; then ansi_fgbg='4'; fi
  local spec="${1:3}"
  red::debug "COLOR TAG: $1 FG/BG: $g SPEC: $spec"
  case "$spec" in
    black)    echo -n '\e['"${ansi_fgbg}0m";;
    red)      echo -n '\e['"${ansi_fgbg}1m";;
    green)    echo -n '\e['"${ansi_fgbg}2m";;
    yellow)   echo -n '\e['"${ansi_fgbg}3m";;
    blue)     echo -n '\e['"${ansi_fgbg}4m";;
    magenta)  echo -n '\e['"${ansi_fgbg}5m";;
    cyan)     echo -n '\e['"${ansi_fgbg}6m";;
    white)    echo -n '\e['"${ansi_fgbg}7m";;
    +([0-9])) echo -n '\e['"${ansi_fgbg}8;5;${spec}m";;
    +([0-9]),+([0-9]),+([0-9]))
              red::rgb_as_ansi "$ansi_fgbg" ${spec//,/ };;
    '#'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
              red::rgb_as_ansi \
                "$ansi_fgbg" \
                "$(( 16#${spec:1:2} ))" \
                "$(( 16#${spec:3:2} ))" \
                "$(( 16#${spec:5:2} ))"
              ;;
    '#'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
              red::rgb_as_ansi \
                "$ansi_fgbg" \
                "$(( ( 16#${spec:1:1} * 16 ) + 16#${spec:1:1} ))" \
                "$(( ( 16#${spec:2:1} * 16 ) + 16#${spec:2:1} ))" \
                "$(( ( 16#${spec:3:1} * 16 ) + 16#${spec:3:1} ))"
              ;;
  esac
}

red::markup_as_ansi() {
  red::parse_markup "$@"
  local chunks=()
  while IFS='' read -r -d $'\033' chunk; do
    red::debug "CHUNK: '$chunk'"
    chunks+=("$chunk")
  done < <(echo "${red_markup_parsed}")
  set -- "${chunks[@]}"
  unset chunks red_markup_parsed
  trap "$(shopt -p extglob)" RETURN
  shopt -s extglob
  while (( $# > 0 )); do
    arg="$1"
    shift
    [[ "$arg" != '{'*'}' ]] && echo -n "$arg" && continue
    tag="${arg:1:$(( ${#arg} - 2 ))}"
    case "$tag" in
      style:*)    red::style_as_ansi "${tag:6}";;
      /style:*)   red::style_as_ansi "${tag:7}_end";;
      eol)        red::ansi_echo '\n\e[0m';; # Handy when bash eats a trailing newline
      clear)      red::ansi_echo '\e[H\e[2J';;
      reset)      red::ansi_echo '\e[0m';;
      fg:*|bg:*)  IFS='' read -d $'\0' -r color < <(red::color_tag_as_ansi $tag);
                  red::debug "COLOR: $color";
                  red::ansi_echo "$color";;
      bold)       red::ansi_echo '\e[1m';;
      /bold)      red::ansi_echo '\e[21m';;
      dim)        red::ansi_echo '\e[2m';;
      /dim)       red::ansi_echo '\e[22m';;
      italic)     red::ansi_echo '\e[3m';;
      /italic)    red::ansi_echo '\e[23m';;
      underline)  red::ansi_echo '\e[4m';;
      /underline) red::ansi_echo '\e[24m';;
      blink)      red::ansi_echo '\e[5m';;
      /blink)     red::ansi_echo '\e[25m';;
      fastblink)  red::ansi_echo '\e[6m';;
      /fastblink) red::ansi_echo '\e[26m';;
      reverse)    red::ansi_echo '\e[7m';;
      /reverse)   red::ansi_echo '\e[27m';;
      hidden)     red::ansi_echo '\e[8m';;
      /hidden)    red::ansi_echo '\e[28m';;
      space)      echo -n ' ';;
      *)          echo -n "{$tag}";;
    esac
  done
}

red::title() {
  local last_err="$?" # Cache last command's error...
  if [[ "$RED_TITLE" ]]; then
    case "$RED_TITLE_MODE" in
      prepend)     echo -n "$RED_TITLE"' - ';;
      append)      echo -n ' - '"$RED_TITLE";;
      interpolate) echo -n "$RED_TITLE";;
    esac
  fi
  return $last_err # Needed by red::modules to show error
}

red::title_as_ps1() {
  if [[ "$RED_TITLE_MODE" != 'disabled' ]]; then
    echo -n '\[\e]0;\]'
    case "$RED_TITLE_MODE" in
      static)      echo -n "$RED_TITLE_FORMAT";;
      prepend)     echo -n '`red::title`'"$RED_TITLE_FORMAT";;
      append)      echo -n "$RED_TITLE_FORMAT"'`red::title`';;
      interpolate) echo -n "${RED_TITLE_FORMAT//\\z/'`red::title`'}";;
    esac
    echo -n '\a'
  fi
}

red::style_as_ps1() {
  [[ "$RED_BOLD" ]] && red::markup_as_ps1 '{bold}'
  for property in $1 default; do
    for style in ${RED_STYLES}; do
      local out
      IFS='' read -r out < <(red::style_${style}_${property} 2>/dev/null)
      if [[ "$out" != '' ]]; then
        red::markup_as_ps1 "$out"
        return
      fi
    done
  done
}

red::markup_as_ps1() {
  red::parse_markup "$@"
  local chunks=()
  while IFS='' read -r -d $'\033' chunk; do
    red::debug "CHUNK: '$chunk'"
    chunks+=("$chunk")
  done < <(echo "${red_markup_parsed}")
  set -- "${chunks[@]}"
  trap "$(shopt -p extglob)" RETURN
  shopt -s extglob
  while (( $# > 0 )); do
    arg="$1"
    shift
    [[ "$arg" != '{'*'}' ]] && echo -n "$arg" && continue
    tag="${arg:1:$(( ${#arg} - 2 ))}"
    case "$tag" in
      style:*)     red::style_as_ps1 "${tag:6}";;
      /style:*)    red::style_as_ps1 "${tag:7}_end";;
      eol)         echo -n '\n\[\e[0m\]';; # Handy when bash eats a trailing newline
      clear)       echo -n '\[\e[H\e[2J\]';;
      reset)       echo -n '\[\e[0m\]';;
      fg:*|bg:*)   echo -n '\['; red::color_tag_as_ansi "$tag"; echo -n '\]';;
      bold)        echo -n '\[\e[1m\]';;
      /bold)       echo -n '\[\e[21m\]';;
      dim)         echo -n '\[\e[2m\]';;
      /dim)        echo -n '\[\e[22m\]';;
      italic)      echo -n '\[\e[3m\]';;
      /italic)     echo -n '\[\e[23m\]';;
      underline)   echo -n '\[\e[4m\]';;
      /underline)  echo -n '\[\e[24m\]';;
      blink)       echo -n '\[\e[5m\]';;
      /blink)      echo -n '\[\e[25m\]';;
      fastblink)   echo -n '\[\e[6m\]';;
      /fastblink)  echo -n '\[\e[26m\]';;
      reverse)     echo -n '\[\e[7m\]';;
      /reverse)    echo -n '\[\e[27m\]';;
      hidden)      echo -n '\[\e[8m\]';;
      /hidden)     echo -n '\[\e[28m\]';;
      user)        red::markup_as_ps1 '{style:user}\u{/style:user}';;
      dir)         red::markup_as_ps1 '{style:dir}\w{/style:dir}';;
      basename)    red::markup_as_ps1 '{style:basename}\W{/style:basename}';;
      host)        red::markup_as_ps1 '{style:host}\h{/style:host}';;
      fqdn)        red::markup_as_ps1 '{style:fqdn}\H{/style:fqdn}';;
      prompt)      red::markup_as_ps1 '{style:prompt}\${/style:prompt}';;
      date)        red::markup_as_ps1 '{style:date}\d{/style:date}';;
      time)        red::markup_as_ps1 '{style:time}\t{/style:time}';;
      time12)      red::markup_as_ps1 '{style:time12}\T{/style:time12}';;
      ampm)        red::markup_as_ps1 '{style:ampm}\@{/style:ampm}';;
      module:*)    echo -n '`red::module '${tag:8}'`';;
      modules)     echo -n '`red::modules`';;
      modules:eol) echo -n '`red::modules -n`';;
      modules:pad) echo -n '`red::modules -p`';;
      *)           echo -n "{$tag}";;
    esac
  done
}

red::module() {
  local exit="$?"
  module="$1"
  red::debug "module: $module"
  #local out="$(red::module_${module} 2>/dev/null)"
  local out
  IFS='' read -r out < <(red::module_${module} 2>/dev/null)
  red::debug "   out: $out"
  [[ "$out" ]] || return $exit
  red::style_as_ansi $module
  red::style_as_ansi module
  echo -n "$out"
  red::style_as_ansi module_end
  red::style_as_ansi ${module}_end
  return $exit
}

red::modules() {
  RED_LAST_ERR="$?"
  local newline=0
  if [[ "$1" == '-n' ]]; then
    newline=1
    shift
  fi
  local pad=0
  if [[ "$1" == '-p' ]]; then
    pad=1
    shift
  fi
  local enabled_modules=0
  for module in ${RED_MODULES}; do
    #local module_out="$(red::module $module)"
    local module_out
    IFS='' read -r module_out < <(red::module $module)
    [[ "$module_out" ]] || continue
    (( enabled_modules++ )) && red::style_as_ansi 'module_pad'
    echo -n "$module_out"
    red::markup_as_ansi '{reset}'
  done
  if [[ "$enabled_modules" > 0 ]]; then
    if [[ "$newline" == 1 ]]; then
      red::markup_as_ansi '{eol}'
    elif [[ "$pad"     == 1 ]]; then
      red::style_as_ansi 'module_pad'
    fi
  fi
  local err="$RED_LAST_ERR"
  unset RED_LAST_ERR
  return $err
}

red::ansi_color_depth() {
  case "$TERM$COLORTERM" in
    *truecolor*|*24bit*) echo '24bit'; return;;
    *256*)               echo '256';   return;;
  esac
  trap "$(shopt -p extglob)" RETURN
  shopt -s extglob
  local t
  IFS='' read -r t < <(infocmp 2>/dev/null)
  if [[ "$t" == *+([[:space:]])@(set24f|setf24|setrgbf)=* ]]; then
    echo '24bit'
    return
  fi
  local REPLY
  echo -e -n '\e]4;1;?\a'
  read -p "$(echo -e -n '\e]4;1;?\a')" -d $'\a' -s -t 0.1 </dev/tty
  if ! [[ -z "$REPLY" ]]; then
    local colors=''
    for idx in 255 15 7; do
      printf '\e]4;%d;?\a' $idx
      read -d $'\a' -s -t 0.1 </dev/tty
      if ! [[ -z "$REPLY" ]]; then
        echo $(( idx + 1 ))
        return
      fi
    done
  fi
  IFS='' read -r t < <(tput colors 2>/dev/null)
  (( t == 8 || t == 16 || t == 256 )) && echo "$t"
}

red::help() {
  echo "HELP!"
}

red::help::prompt() {
  cat <<EOF | $RED_PAGER
USAGE: source $RED_NAME [options]

Sets the prompt in a bash session

Options:

         --module NAME :  Enable module NAME
               -m NAME    Modules can be found in:
                            $RED_ROOT/module

         --all-modules :  Enable all modules
                    -a

          --style NAME :  Enable style NAME
               -s NAME    Styles can be found in:
                            $RED_ROOT/style

         --colors SPEC :  Override auto-detection for the number of ANSI colors
               -c SPEC      the current terminal supports.

                          SPEC is one of:
                            0       No ANSI color support
                            8
                            16
                            256
                            24bit   Truecolor ANSI terminal support

           --powerline :  Use Powerline font symbols
                    -l

                --bold :  Bold all styles
                    -b

                --help :  Shows help
                    -h

               --debug :  Enable debugging information
                    -d

 --title-format FORMAT :  Format for status line / window title using bash
             -f FORMAT    PS1 syntax

     --title-mode MODE :  Sets how status line / window title is handled
               -t MODE    Custom titles can be set with the 'title' command

                          MODE is one of:
                            prepend      Add custom-set title as the
                                         begining (default)

                            append       Add custom-set title at the end

                            static       No custom-set title

                            interpolate  Interpolate escape \\z in
                                         title-format as custom set title

                            disabled     No title set in prompt

For more information and additonal usage: https://github.com/kilna/prompt
EOF
}

red::prompt() {

  if [[ "$RED_PS1_ORIG" == '' ]]; then RED_PS1_ORIG="$PS1"; fi
  red::debug "RED_PS1_ORIG: $RED_PS1_ORIG"

  for var in $(red::vars); do
    [[ "$var" != 'RED_PS1_ORIG' ]] && unset $var
  done

  local prompt_markup='{modules:eol}{user}{reset}@{host} {dir}{eol}{prompt} {reset}'
  while (( $# > 0 )); do
    arg="$1"
    shift
    case "$arg" in
      -p|--prompt)       prompt_markup="$1"; shift ;;
      -f|--title-format) RED_TITLE_FORMAT="$1"; shift ;;
      -t|--title-mode)   RED_TITLE_MODE="$1"; shift ;;
      -h|--help)         red::help::prompt; return ;;
    esac
  done

  RED_TITLE_MODE="${RED_TITLE_MODE:-prepend}"
  red::debug "RED_TITLE_MODE: $RED_TITLE_MODE"

  RED_TITLE_FORMAT="${RED_TITLE_FORMAT:-\\u@\\h \\w}"
  red::debug "RED_TITLE_FORMAT: $RED_TITLE_FORMAT"

  IFS='' read -r -d $'\0' title < <(red::title_as_ps1)
  red::debug "title: $title"
  red::debug "prompt_markup: $prompt_markup"
  IFS='' read -r -d $'\0' prompt < <(red::markup_as_ps1 "$prompt_markup")
  red::debug "prompt: $prompt"
  export PS1="$title$prompt"
  (( err+="$?" ))
  red::debug "PS1: $PS1"
  unset set_prompt

  return $err
}
