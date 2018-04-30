#!/bin/bash

firstindex() { x="${1%%$2*}"; [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }
lastindex()  { x="${1%$2*}";  [[ "$x" = "$1" ]] || echo $(( ${#x} + 1 )); }

chunk() {
  str="$1"
  #echo "$str"
  while [[ "$str" != '' ]]; do
    idx1=$( firstindex "$str" '{' )
    idx2=$( firstindex "$str" '}' )
    if [[ "$idx1" != '' && "$idx2" != '' && (( idx2 > idx1 )) ]]; then
      substr="${str:0:(( idx2 ))}"
      idx1=$( lastindex "$substr" '{' )
      if [[ "$idx1" == '' ]]; then
        echo -n "'"${substr//\'/\'\\\'\'}"' "
      else
        if (( idx1 != 0 )); then
          chunk="${str:0:(( idx1 - 1 ))}"
          echo -n "'"${chunk//\'/\'\\\'\'}"' "
        fi
        chunk="${str:(( idx1 - 1 )):(( idx2 - idx1 + 1 ))}"
        echo -n "'"${chunk//\'/\'\\\'\'}"' "
      fi
      str="${str:(( idx2 ))}"
    else
      echo -n "'"${str//\'/\'\\\'\'}"' "
      str=''
    fi
  done
}

eval 'ar=('$(chunk "as}df{foo}as}df 'foo' bar 'baz'{bar}{{/foo}asdf{}asdf's")')'

for x in "${ar[@]}"; do
  echo "$x"
done

