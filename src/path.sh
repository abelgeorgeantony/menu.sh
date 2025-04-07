#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

function get_path_parent() {
    local menu_path
    menu_path=$1

    menu_path=$(echo "$menu_path" | rev | cut -d. -f2- | rev)
    if [ -z "$menu_path" ]; then
        menu_path='.'
    fi

    echo "$menu_path"
}

# for the menu path, set this prefix for fzf's preview
function get_path_fzf_preview() {
    local menu_path
    menu_path=$1

    if [ "$menu_path" == '.' ]; then
        echo ""
    else
        echo "$menu_path"
    fi
}

# if the menu path has __${macro_name}__, return it
function get_path_macro() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local macro_name
    macro_name=$3

    local macro_yq
    if [ "$menu_path" == '.' ]; then
        macro_yq=".__${macro_name}__"
    else
        macro_yq="${menu_path}.__${macro_name}__"
    fi

    local macro_content
    macro_content=$(yq "$macro_yq" "$menu_filename")
    
    if [ ! -z "$macro_content" ] && [ "$macro_content" != "null" ]; then
        echo "$macro_content"
    fi
}
