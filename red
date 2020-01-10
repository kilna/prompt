#!/bin/bash

if [ ! "$BASH" ]; then
  echo "Script is only compatible with bash, current shell is $SHELL" >&2
  exit 1
fi

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cat <<EOF >&2
This script is meant to be added into a Bash shell session via:

source $RED_SCRIPT

After loading via source, you can use 'red reload' to reload.
EOF
  exit 1
fi

RED_ROOT="$(cd $(dirname ${BASH_SOURCE[0]}); echo $PWD)"
RED_SCRIPT="${RED_ROOT}/$(basename ${BASH_SOURCE[0]})"

trap "$(shopt -p extglob)" RETURN
shopt -s extglob

red() {

  eval "$( CFGFLAGS='-c|--config' CFGFILES=$HOME/.redrc? red::cfg "$@" )"

  # Process global options
  #RED_STYLES='default'
  #RED_STYLES='user default'
  #local user_styles=()
  local load_modules=()
  local show_help=0
  local ar=()
  while (( $# > 0 )); do
    case "$1" in
      -h|--help)         show_help=1 ;;
      -m|--module)       load_modules+=("$2"); shift ;;
      -a|--all-modules)  all_modules=1 ;;
      -d|--debug)        red::enable debug ;;
      -l|--powerline)    red::enable powerline ;;
      #-b|--bold)         red::enable bold ;;
      #-s|--style)        RED_STYLES="$2 ${RED_STYLES}"; shift ;;
      #-u|--user-style)   user_styles+=("$2"); shift ;;
      -c|--colors)       red::set ansi_color_depth "$2"; shift ;;
      *)                 ar+=("$1") ;;
    esac
    shift
  done
  set -- "${ar[@]}"
  unset ar
  if (( $show_help )); then set -- help "$@"; fi

  #typeset -x | grep RED_

  if [[ "$RED_ANSI_COLOR_DEPTH" == '' ]]; then
    IFS='' read -r RED_ANSI_COLOR_DEPTH < <(red::ansi_color_depth)
  fi

  #red::debug "RED_ROOT: $RED_ROOT"
  #red::debug "RED_SCRIPT: $RED_SCRIPT"

  if [[ "$all_modules" ]]; then
    load_modules=()
    for module_path in $RED_ROOT/module/*; do
      load_modules+=("${module_path##*/}")
    done
  fi
  unset all_modules

  for func in $(red::funcs); do
    case "$func" in red::module::*|red::style::*)
      red::debug "Unsetting $func"
      unset -f $func;;
    esac
  done

  #for user_style in "${user_styles[@]}"; do
  #  str="red::style::user::${user_style%%=*}() { echo -n '${user_style#*=}'; }"
  #  red::debug "$str"
  #  eval "$str"
  #done
  #unset user_styles

  err=0

  RED_MODULES=''
  for module in "${load_modules[@]}"; do
    red::debug "Loading module: $module"
    if ! source "${RED_ROOT}/module/${module}"; then
      echo "Unable to open red module $RED_ROOT/modules/$module" >&2
      (( err++ ))
    fi
    if typeset -F red::module::$module &>/dev/null; then
      red::debug "Module $module loaded successfully"
      RED_MODULES+="$module "
    fi
  done

#  for style in ${RED_STYLES}; do
#    #[[ "$style" == 'user' ]] && continue
#    # red::debug "RED_STYLE: $style"
#    if ! source "${RED_ROOT}/style/${style}"; then
#      echo "Unable to open red style $RED_ROOT/style/$style" >&2
#      (( err++ ))
#    fi
#  done

  # Process multiple verbs delimited by --
  while (( $# > 0 )); do
    local action="$1"
    shift
    local ar=()
    while [[ $# -gt 0 && "$1" != '--' ]]; do
      ar+=("$1")
      shift
    done
    shift
    red::$action "${ar[@]}"
  done

}

red::trim() {
  local var="${1##+([[:space:]])}"; echo -n "${x%%+([[:space:]])}"
}

red::uc() {
  if (( "${BASH_VERSINFO[0]}" > 3 )); then echo "${1^^}"
  else echo "$1" | tr a-z A-Z ;fi
}

red::pager() {
  for pager in $PAGER less more cat; do
    which $pager &>/dev/null && cat - | $pager && break
  done
}

# Escapes list entries (if needed) such that they can be eval'd in Bash
red::esc() {
  while (( $# > 0 )); do
    if [[ "$1" =~ ^[a-zA-Z0-9_.,:=+/-]+$ ]]; then
      echo -n $1
    else
      echo -n \'${1//\'/\'\\\'\'}\'
    fi
    shift
    (( $# > 0 )) && echo -n ' '
  done
  echo # End with a newline... this'll be removed it run from $(...) anyway
}

red::cfg() {

  # Clean up / unify contents of $@
  local ar=()
  local a
  while (( $# > 0 )); do
    a="$1"; shift
    case "$a" in
      --*=*) ar+=("${a%%=*}" "${a#*=}");; # break --foo=bar into --foo bar
      --*)   ar+=("$a");; # Match --flags so we skip next line
      -*)    # Unbundle grouped single-letter flags
             for (( x=1; x<${#a}; x++ )); do ar+=("-${a:$x:1}"); done;;
      *)     ar+=("$a");; # Any other kind of argument is passed through
    esac
  done
  set -- "${ar[@]}"

  # Resolve passed in config file parameters into cfgfiles array
  ar=()
  IFS=:   read -a cfgfiles <<< "$CFGFILES"
  IFS='|' read -a cfgflags <<< "$CFGFLAGS"
  local match
  while (( $# > 0 )); do
    a="$1"; shift
    match=''
    for param in "${cfgflags[@]}"; do
      if [[ "$a" == "$param" ]]; then
        match="$1"
        shift
        break
      fi
    done
    if [[ "$match" ]]; then
      cfgfiles+=("$match")
    else
      ar+=("$a")
    fi
  done
  set -- "${ar[@]}"

  # Process each config file into additional $@ parameters
  for file in "${cfgfiles[@]}"; do
    # Files ending with ? are optional, skip if not present
    if [[ "${file%'?'}" != "$file" ]]; then
      file="${file%'?'}"
      [[ ! -e $file ]] && continue
    fi
    while IFS='' read line; do
      IFS='' read -r line < <(red::trim "$line")
      case "$line" in
        ''|'#'*) : ;; # Skip blank or comment lines
        '['*']') # Config file sections get turned into verbs
                 set -- -- "${line:1:$(( ${#line} - 2))}";;
        *)       set -- "$@" "--$line";;
      esac
    done < <(cat $file)
  done

  # Generate a set statement to be eval'd, which will recreate $@
  # normalized, with all of the values from the config files in place
  red::esc set -- "$@"

}

red::remap_ansi_colors() {
  local pre='\033]'
  local post='\033\\'
  if [[ -n "$TMUX" ]]; then
    pre='\033Ptmux;\033\033]'
    post='\033\033\\\033\\'
  elif [[ "${TERM%%[-.]*}" = "screen" ]]; then
    pre='\033P\033]'
    post='\007\033\\'
  elif [[ "${TERM%%-*}" = "linux" ]]; then
    return
  fi
  local ct="${pre}4;%d;rgb:%s$post" # Set color template
  local it="$pre%s%s$post" # Set iterm template
  local vt="$pre%s;rgb:%s$post" # Set var template
  while [[ $# -gt 0 ]]; do
    local spec="$1"; shift
    local color="${spec%%=*}"
    local rgb="${spec#*=}"
    rgb="${rgb#'#'}" # Remove optional leading hash from RGB code
    if [[ "$rgb" == [0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f] ]]; then
      # 3 digit to 6 digit hex RGB codes
      rgb="${rgb:0:1}${rgb:0:1}${rgb:1:1}${rgb:1:1}${rgb:2:1}${rgb:2:1}"
    elif [[ "$rgb" != +([0-9A-Fa-f]) || "${#rgb}" -ne 6 ]]; then
      echo "Unrecognized RGB color value: $rgb" >&2
      continue
    fi
    local rgb_s="${rgb:0:2}/${rgb:2:2}/${rgb:4:2}"
    case "$color" in
       *s)              local c="${color%s}" # reds -> red, brightred
                        red::remap_ansi_colors $c=$rgb bright$c=$rgb;;
       blackbg)         red::remap_ansi_colors black=$rgb bg=$rgb;;
       whitebg)         red::remap_ansi_colors brightwhite=$rgb bg=$rgb;;
       blackfg)         red::remap_ansi_colors black=$rgb fg=$rgb;;
       whitefg)         red::remap_ansi_colors brightwhite=$rgb fg=$rgb;;
       fg)              if [[ -n "$ITERM_SESSION_ID" ]]; then
                          printf $it Pg $rgb
                          printf $it Pi $rgb
                        else
                          printf $vt 10 $rgb_s
                        fi;;
       bg)              if [[ -n "$ITERM_SESSION_ID" ]]; then
                          printf $it Ph $rgb
                        else
                          printf $vt 11 $rgb_s
                          if [[ "${TERM%%-*}" == "rxvt" ]]; then
                            printf $vt 708 $rgb_s
                          fi
                        fi;;
      [0-9]+)           printf $ct $color $rgb_s;;
      black)            printf $ct  0 $rgb_s;;
      red)              printf $ct  1 $rgb_s;;
      green)            printf $ct  2 $rgb_s;;
      yellow)           printf $ct  3 $rgb_s;;
      blue)             printf $ct  4 $rgb_s;;
      magenta)          printf $ct  5 $rgb_s;;
      cyan)             printf $ct  6 $rgb_s;;
      white|lightgray)  printf $ct  7 $rgb_s;;
      brightblack|gray) printf $ct  8 $rgb_s;;
      brightred)        printf $ct  9 $rgb_s;;
      brightgreen)      printf $ct 10 $rgb_s;;
      brightyellow)     printf $ct 11 $rgb_s;;
      brightblue)       printf $ct 12 $rgb_s;;
      brightmagenta)    printf $ct 13 $rgb_s;;
      brightcyan)       printf $ct 14 $rgb_s;;
      brightwhite)      printf $ct 15 $rgb_s;;
      *)                echo "Unrecognized color specification: $1" 1>&2;;
    esac
  done
}

red::set() {
  IFS='' read -r varname < <(red::uc RED_$1)
  export $varname="$2"
}

red::enable() {
  IFS='' read -r varname < <(red::uc RED_$1)
  export $varname=1
}

red::disable() {
  IFS='' read -r varname < <(red::uc RED_$1)
  export $varname=0;
}

red::unset() {
  IFS='' read -r varname < <(red::uc RED_$1)
  unset "$varname";
}

red::get() {
  IFS='' read -r varname < <(red::uc RED_$1)
  echo -n "${!varname}"
}

red::check() {
  IFS='' read -r varname < <(red::uc RED_$1)
  local compareval="${2:-1}"
  local defaultval="${3:-}"
  [[ "${!varname}" == '' && "$defaultval" == "$compareval" ]] && return 0
  [[ "${!varname}" == "$compareval" ]] && return 0
  return 1
}

red::reload() {
  red::unload
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
  local debug="${RED_DEBUG:-0}"
  for var in $(red::vars); do
    (( $debug )) && echo "Unsetting \$${var}" >&2
    unset $var &>/dev/null
  done
  for func in $(red::funcs); do
    (( $debug )) && echo "Unsetting ${func}()" >&2
    unset -f $func &>/dev/null
  done
}

#red::lookup() {
#  local funcname="red::${1//_/::}"
#  if typeset -F $funcname; then
#    $funcname
#    return $?
#  fi
#  local varname="red_${1//::/_}"
#  if typeset $varname; then
#    echo -n ${!varname}
#    return 0
#  fi
#  return 1
#}

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

red::debug() {
  if ! red::check debug; then set +x; return; fi
  if (( $# > 1 )); then red::esc "$@" >&2 # Escape if we're passed a list
  else echo "$1" >&2; fi # Otherwise dump just $1 verbatim
}

red::unicode() {
  [[ "$LANG" == *'UTF-8'* ]] && return 0
  return 1
}

red::powerline() {
  red::unicode || return 1
  red::check powerline || return 1
  return 0
}

export RED_SCHEME=''
export RED_STYLE_DEFAULT=''
export RED_STYLE_USER='{fg:cyan}'
export RED_STYLE_HOST='{fg:magenta}'
export RED_STYLE_FQDN='{fg:magenta}'
export RED_STYLE_DIR='{fg:green}'
export RED_STYLE_TIME='{fg:yellow}'
export RED_STYLE_TIME12='{fg:yellow}'
export RED_STYLE_DATE='{fg:yellow}'
export RED_STYLE_AMPM='{fg:yellow}'
export RED_STYLE_MODULE='{reverse}{space}'
export RED_STYLE_MODULE_END='{space}{/reverse}'
export RED_STYLE_MODULE_PAD='{space}'

#red::load_style() {
#  local file="$1"
#  local is_unicode=0
#  local code=''
#  while IFS='' read line; do
#    [[ "$line" == '#'* || "$line" =~ ^[[:space:]]*$ ]] && continue
#    if [[ "$line" != *':'* ]]; then
#      echo "Unable to parse line '$line' in file '$file'" >&2
#      continue
#    else
#      name="${line%%=*}"
#      name="${name## }"
#      name="${name%% }"
#      val="${line#*=}"
#      val="${val## }"
#      val="${val%% }"
#      #[[ "$val" == *'{u:'* ]] && is_unicode=1
#      #code+="export RED_STYLE_${name^^}='${val//\'/\\\'}'"$'\n';
#      red::set style_${name} "{$val}"
#    fi
#  done < "$1"
#  #if [[ ! red::unicode && is_unicode ]]; then
#  #  echo "File '$file' contains unicode style information but terminal is not UTF-8" >&2
#  #fi
#  #eval "$code"
#}

# Parse strings like '{tag}foo{/tag}' into a eval-able set statement to change
# $@ to the string chunked into a list of '{tag}' 'foo' '{/tag}'
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
  red::esc set -- "${ar[@]}" # Make eval-able set command for new desired $@
}

# Renders escaped ANSI as actual ANSI, if the terminal is ANSI enabled
red::ansi_echo() {
  red::check ansi_color_depth 0 0 && return
  if (( "${BASH_VERSINFO[0]}" > 3 )); then
    echo -en "$1"
  else
    printf "${1//%/%%}"
  fi
}

red::color_as_e_ansi() {

  # If we're foreground $a is set to 3, if background it's set to 4
  local a='3'; if [[ "${1:0:2}" == 'bg' ]]; then a='4'; fi

  local spec="${1:3}"

  local r g b

  case "$spec" in
    black)            echo -n '\e['"${a}0m";;
    red)              echo -n '\e['"${a}1m";;
    green)            echo -n '\e['"${a}2m";;
    yellow)           echo -n '\e['"${a}3m";;
    blue)             echo -n '\e['"${a}4m";;
    magenta)          echo -n '\e['"${a}5m";;
    cyan)             echo -n '\e['"${a}6m";;
    white|lightgray)  echo -n '\e['"${a}7m";;
    brightblack|gray) echo -n '\e['"${a}8m";;
    brightred)        echo -n '\e['"${a}9m";;
    brightgreen)      echo -n '\e['"${a}10m";;
    brightyellow)     echo -n '\e['"${a}11m";;
    brightblue)       echo -n '\e['"${a}12m";;
    brightmagenta)    echo -n '\e['"${a}13m";;
    brightcyan)       echo -n '\e['"${a}14m";;
    brightwhite)      echo -n '\e['"${a}15m";;
    +([0-9]))         echo -n '\e['"${a}8;5;${spec}m";;
    +([0-9]),+([0-9]),+([0-9]))
                      local rgb=( ${spec//,/ } )
                      r="${rgb[0]}"; g="${rgb[1]}"; b="${rgb[2]}";;
    '#'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
                      r="$(( 16#${spec:1:2} ))"
                      g="$(( 16#${spec:3:2} ))"
                      b="$(( 16#${spec:5:2} ))";;
    '#'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f])
                      r="$(( ( 16#${spec:1:1} * 16 ) + 16#${spec:1:1} ))"
                      g="$(( ( 16#${spec:2:1} * 16 ) + 16#${spec:2:1} ))"
                      b="$(( ( 16#${spec:3:1} * 16 ) + 16#${spec:3:1} ))";;
  esac

  [[ "$r$g$b" == '' ]] && return

  # If we're in 24 bit mode we don't have to round, return using RGB syntax
  if red::check ansi_color_depth '24bit'; then
    echo -n '\e['"${a}8;2;${r};${a};${b}m"
    return
  fi

  # Below rounds to the nearest ANSI 216 color cube or 24 grayscale value. See:
  # https://docs.google.com/spreadsheets/d/1n4zg5OXYC0hBdRKBb1clx4t2HSx_cu_iiot6GYpgh1c/
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

  echo -n '\e['"${a}8;5;${idx}m"
}

red::style_ansi() {
  local style="$1"
  IFS='' read -r markup < <(red::get style_$1)
  red::render_ansi "$markup"
}

red::style_wrap_ansi() {
  local style="$1"
  local content="$2"
  red::style_ansi "${style}"
  echo -n "$content"
  red::style_ansi "${style}_end"
}

red::render_ansi() {
  case "$1" in
    -p|--preparsed) : ;; # Do nothing
    *) eval "$(red::parse_markup "$@")";; # Chunk input by {tag}
  esac
  while (( $# > 0 )); do
    arg="$1"
    shift
    [[ "$arg" != '{'*'}' ]] && echo -n "${arg//\\/\\\\}" && continue
    tag="${arg:1:$(( ${#arg} - 2 ))}"
    case "$tag" in
      style:*)    red::style_e_ansi "${tag:6}";;
      /style:*)   red::style_e_ansi "${tag:7}_end";;
      space)      red::ansi_echo ' ';;
      eol)        red::ansi_echo '\n\e[0m';; # Handy when bash eats a trailing newline
      clear)      red::ansi_echo '\e[H\e[2J';;
      reset)      red::ansi_echo '\e[0m';;
      fg:*|bg:*)  IFS='' read -r e_ansi < <(red::color_as_e_ansi $tag)
                  red::ansi_echo "$e_ansi";;
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
      *)          "${arg}";;
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

red::title_ps1() {
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

red::style_ps1() {
  local style="$1"
  IFS='' read -r markup < <(red::get style_$1)
  red::render_ps1 "$markup"
}

red::style_wrap_ps1() {
  local style="$1"
  local content="$2"
  red::style_ps1 "${style}"
  echo -n "$content"
  red::style_ps1 "${style}_end"
}

red::render_ps1() {
  case "$1" in
    -p|--preparsed) : ;; # Do nothing
    *) eval "$(red::parse_markup "$@")";; # Chunk input by {tag}
  esac
  while (( $# > 0 )); do
    arg="$1"
    shift
    [[ "$arg" != '{'*'}' ]] && echo -n "$arg" && continue
    tag="${arg:1:$(( ${#arg} - 2 ))}"
    case "$tag" in
      style:*)     red::style_ps1 "${tag:6}";;
      /style:*)    red::style_ps1 "${tag:7}_end";;
      space)       echo -n ' ';;
      eol)         echo -n '\n\[\e[0m\]';;
      clear)       echo -n '\[\e[H\e[2J\]';;
      reset)       echo -n '\[\e[0m\]';;
      fg:*|bg:*)   echo -n '\['; red::color_as_e_ansi "$tag"; echo -n '\]';;
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
      user)        red::style_wrap_ps1 'user' '\u';;
      dir)         red::style_wrap_ps1 'dir' '\w';;
      basename)    red::style_wrap_ps1 'basename' '\W';;
      host)        red::style_wrap_ps1 'host' '\h';;
      fqdn)        red::style_wrap_ps1 'fqdn' '\H';;
      prompt)      red::style_wrap_ps1 'prompt' '\$';;
      date)        red::style_wrap_ps1 'date' '\d';;
      time)        red::style_wrap_ps1 'time' '\t';;
      time12)      red::style_wrap_ps1 'time12' '\T';;
      ampm)        red::style_wrap_ps1 'ampm' '\@';;
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
  #local out="$(red::module::${module} 2>/dev/null)"
  local out
  IFS='' read -r out < <(red::module::${module} 2>/dev/null)
  red::debug "   out: $out"
  [[ "$out" ]] || return $exit
  red::style_ansi $module
  red::style_ansi module
  echo -n "$out"
  red::style_ansi module_end
  red::style_ansi ${module}_end
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
    (( enabled_modules++ )) && red::style_ansi 'module_pad'
    echo -n "$module_out"
    red::render_ansi -p '{reset}'
  done
  if [[ "$enabled_modules" > 0 ]]; then
    if [[ "$newline" == 1 ]]; then
      red::render_ansi -p '{eol}'
    elif [[ "$pad"     == 1 ]]; then
      red::style_ansi 'module_pad'
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
  local infocmp
  IFS='' read -r infocmp < <(infocmp 2>/dev/null)
  if [[ "$infocmp" == *+([[:space:]])@(set24f|setf24|setrgbf)=* ]]; then
    echo '24bit'
    return
  fi
  local ansi
  IFS='' read -r ansi < <(printf '\e]4;1;?\a')
  local REPLY
  read -p "$ansi" -d $'\a' -s -t 0.1 </dev/tty
  if ! [[ -z "$REPLY" ]]; then
    local colors=''
    for idx in 255 15 7; do
      IFS='' read -r ansi < <(printf '\e]4;%d;?\a' $idx)
      read -p "$ansi" -d $'\a' -s -t 0.1 </dev/tty
      if ! [[ -z "$REPLY" ]]; then
        echo $(( idx + 1 ))
        return
      fi
    done
  fi
  local tput
  IFS='' read -r tput < <(tput colors 2>/dev/null)
  if (( tput == 8 || tput == 16 || tput == 256 )); then
    echo "$tput"
    return
  fi
  echo 0
}

red::help() {
  echo "HELP!"
}

red::help::prompt() {
  red::pager <<EOF
USAGE: source red [options]

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

  IFS='' read -r -d $'\0' title < <(red::title_ps1)
  red::debug "title: $title"
  red::debug "prompt_markup: $prompt_markup"
  IFS='' read -r -d $'\0' prompt < <(red::render_ps1 "$prompt_markup")
  red::debug "prompt: $prompt"
  export PS1="$title$prompt"
  (( err+="$?" ))
  red::debug "PS1: $PS1"
  unset set_prompt

  return $err
}

red "$@"
