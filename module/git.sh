#!/bin/bash

__ps1_module_git_output() { set -o pipefail; git branch 2>/dev/null | grep -F '* ' | cut -c 2-; }
__ps1_module_git_fg()     { echo -n blue; }
__ps1_module_git_prefix() { echo -n '⌥' :space; }

