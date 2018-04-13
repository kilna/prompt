#!/bin/bash

__ps1_module_error_prompt_prefix() { echo -n '`export PS1_LAST_EXIT=$?`'; }

__ps1_module_error_output() {
  set -o pipefail
  (( $PS1_LAST_EXIT=$? )) && echo -n "$PS1_LAST_EXIT"
  unset PS1_LAST_EXIT
}

__ps1_module_error_color() { echo -n red; }

__ps1_module_error_prefix() { echo -n +blink ⚠ -blink; }

