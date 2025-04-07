#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

function check_if_one_option() {
    local options
    options=$1

    [ $(echo "$options" | wc -l) -eq 1 ] && echo "true"
}

function get_options() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    # get the list of options from the menu file
    local options
    options=$(yq "$menu_path | keys | .[]" "$menu_filename" 2> /dev/null) && {
        # remove __cmd__ from options if it is there
        options=$(echo "$options" | grep -v '__cmd__')

        # if there is a files macro, expand it
        local files
        files=$(expand_files "$menu_filename" "$menu_path")
        if [ ! -z "$files" ]; then
            if [ ! -z "$options" ]; then
                options=$(printf "%s\n%s" "$options" "$files")
            else
                options="$files"
            fi
            options=$(echo "$options" | grep -v '__files__')
        fi

        options=$(echo "$options" | grep -v '__prompt__')
        options=$(echo "$options" | grep -v '__urlencode__')
        options=$(echo "$options" | grep -v '__wait__')
        echo "$options"
    }
}

# append the navigation options to the menu
function append_options_navigation() {
    local menu_path
    menu_path=$1

    local options
    options=$2

    # otherwise, show the menu; add a newline and quit option
    if [ "$menu_path" == '.' ]; then
        printf -v options "%s\nquit" "$options"
    else
        printf -v options "%s\nquit-back" "$options"
    fi

    echo "$options"
}
