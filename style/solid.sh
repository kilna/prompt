#!/bin/bash

__ps1_style_solid_block_start() {
  if __ps1_unicode; then
    echo -n "+reverse '▏'"
  else
    echo -n +reverse :space
  fi
}

__ps1_style_solid_block_end() {
  echo -n :space
}

__ps1_style_solid_block_pad() {
  if ! __ps1_unicode; then
    echo -n :space
  fi
}

