#!/bin/bash

firstindex() { x="${1%%$2*}"; [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }
lastindex()  { x="${1%$2*}";  [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }

chunk() {
  str="$1"
  #echo "$str"
  ar=()
  while [[ "$str" != '' ]]; do
    idx1=$( firstindex "$str" '{' )
    idx2=$( firstindex "$str" '}' )
    if [[ "$idx1" != '' && "$idx2" != '' && (( idx2 > idx1 )) ]]; then
      substr="${str:0:(( idx2 ))}"
      idx1=$( lastindex "$substr" '{' )
      if [[ "$idx1" == '' ]]; then
        # Non-tag chunk (no matching beginning '{')
        ar_idx=$(( "${#ar[@]}" - 1 ))
        echo "ar_idx: $ar_idx"
        if [[ (( ar_idx < 0 )) ]]; then
          ar+=("$substr")
        elif [[ "${ar[$ar_idx]}" == '{'*'}' ]]; then
          ar+=("$substr")
        else
          ar[$ar_idx]+="$substr" 
        fi
      else
        if (( idx1 != 0 )); then
          ar+=("${str:0:(( idx1 - 1 ))}") # Non-tag chunk
        fi
        ar+=("${str:(( idx1 - 1 )):(( idx2 - idx1 + 1 ))}") # Tag chunk
      fi
      str="${str:$idx2}"
    else
      ar+=("$str") # Last non-tag chunk
      str=''
    fi
  done
  for x in "${ar[@]}"; do
    echo "$x"
  done
}

chunk "as}df{foo}as}df 'foo' bar 'baz'{bar}{{/foo}asdf{}asdf's"

