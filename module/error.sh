#!/bin/bash

__ps1_module_error_output() {
  #env | grep PS1_ >&2
  (( "$PS1_LAST_ERR" )) && echo -n $PS1_LAST_ERR
}

__ps1_module_error_color() {
  echo -n red
}

__ps1_module_error_prefix() {
  if __ps1_unicode; then
    echo -n +blink "$(printf '\u26A0')" -blink :space
  else
    echo -n 'err' :space
  fi
}

__ps1_module_error_postfix() {
  echo -n
}

