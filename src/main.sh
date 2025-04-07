#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

###
# if the script is run with a parameter, assume it is a filename and render the menu with it

if [ -n "$1" ]; then
    clear
    menu_loop "$1"
fi
