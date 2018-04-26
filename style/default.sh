#!/bin/bash

__ps1_style_default_user()        { echo -n :fg cyan; }
__ps1_style_default_host()        { echo -n :fg magenta; }
__ps1_style_default_dir()         { echo -n :fg green; }
__ps1_style_default_time()        { echo -n :fg blue +reverse; }
__ps1_style_default_date()        { echo -n :fg blue +reverse; }
__ps1_style_default_block_start() { echo -n '[' :space; }
__ps1_style_default_block_end()   { echo -n :space ']'; }
__ps1_style_default_block_pad()   { echo -n :space; }

