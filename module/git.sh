#!/bin/bash

which git &>/dev/null || return 1

__ps1_module_git_output() {
  set -o pipefail
  git branch 2>/dev/null | grep -F '* ' | cut -c 2-
}

__ps1_module_git_color() {
  echo -n blue
}

__ps1_module_git_prefix() { 
  if __ps1_unicode; then
    echo -n "$(printf '\u2325')" :space
  else
    echo -n 'branch' :space
  fi
}

__ps1_module_git_postfix() {
  echo -n
}

