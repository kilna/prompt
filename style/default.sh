#!/bin/bash

__ps1_style_default_default()     { echo -n; }
__ps1_style_default_user()        { echo -n :fg cyan; }
__ps1_style_default_host()        { echo -n :fg magenta; }
__ps1_style_default_dir()         { echo -n :fg green; }
__ps1_style_default_time()        { echo -n :fg blue +reverse; }
__ps1_style_default_date()        { echo -n :fg blue +reverse; }

__ps1_style_default_block_start() {
  if __ps1_unicode; then
    echo -n +reverse "$(printf '\u258F')"
  else
    echo -n +reverse :space
  fi
}

__ps1_style_default_block_end() {
  if __ps1_unicode; then
    echo -n "$(printf '\u2595')"
  else
    echo -n :space
  fi
}

__ps1_style_default_block_pad() {
  if ! __ps1_unicode; then
    echo -n :space
  fi
}

