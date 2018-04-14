#!/bin/bash

__ps1_module_error_output() { (( $? )) && echo -n "$?"; }
__ps1_module_error_fg()     { echo -n red; }
__ps1_module_error_prefix() { echo -n "+blink ⚠ -blink ' '"; }

