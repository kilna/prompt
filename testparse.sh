#!/bin/bash

#firstindex() { x="${1%%$2*}"; [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }
#lastindex()  { x="${1%$2*}";  [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }

chunk() {
  str="$1"
  ar=()
  while [[ "$str" != '' ]]; do
    
    idx1=$( x="${str%%\{*}"; [[ "$x" = "$str" ]] || echo $(( ${#x} + 1 )) )
    idx2=$( x="${str%%\}*}"; [[ "$x" = "$str" ]] || echo $(( ${#x} + 1 )) )

    nontag_val=''
    tag_val=''
    
    if [[ "$idx1" != '' && "$idx2" != '' && (( idx2 > idx1 )) ]]; then
      substr="${str:0:(( idx2 ))}"
      idx1=$( x="${substr%\{*}"; [[ "$x" = "$substr" ]] || echo $(( ${#x} + 1 )) )
      if [[ "$idx1" == '' ]]; then
        nontag_val+="$substr"
      else
        if (( idx1 != 0 )); then
          nontag_val+="${str:0:(( idx1 - 1 ))}"
        fi
        tag_val="${str:(( idx1 - 1 )):(( idx2 - idx1 + 1 ))}"
      fi
      str="${str:$idx2}"
    else
      nontag_val+="$str"
      str=''
    fi

    ar_idx=$(( "${#ar[@]}" - 1 ))
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

  for x in "${ar[@]}"; do
    echo "$x"
  done
}

chunk "as}df{foo}as}df 'foo' bar 'baz'{bar}{{/foo}asdf{}as}df's"

