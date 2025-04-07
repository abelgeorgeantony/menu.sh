#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

# evaluate the __files__ macro as a glob and return the list of files
function expand_files() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local files
    files=$(get_path_macro "$menu_filename" "$menu_path" "files")

    if [ ! -z "$files" ]; then
        bash -c "ls -1 $files"
    fi
}

function apply_cmd_to_file() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local file
    file=$3

    local cmd
    cmd=$(get_path_macro "$menu_filename" "$menu_path" "cmd")

    if [ ! -z "$file" ]; then
        eval_cmd "$cmd" "$file"
    fi
}
