#!/bin/bash

__ps1_module_gitbranch_output() {
  set -o pipefail
  git branch 2>/dev/null | grep -F '* ' | cut -c 2-
}

__ps1_module_gitbranch_color() { echo -n blue; }

__ps1_module_gitbranch_prefix() { echo -n ⌥; }

