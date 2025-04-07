#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

# evaluate the category command with the arguments
function eval_cmd() {
    local category_cmd
    category_cmd=$1

    local args
    args=$2

    rm -f /tmp/cmd.sh
    touch /tmp/cmd.sh    
    chmod 600 /tmp/cmd.sh || {
        echo "ERROR: unable to create /tmp/cmd.sh"
        exit 1
    }

    {
        echo "function _cmd() {";
        echo "  $category_cmd";
        echo "}";
        echo "_cmd $args";
    } >> /tmp/cmd.sh

    /bin/bash /tmp/cmd.sh
    rm /tmp/cmd.sh
}

# identify the category command and its arguments, then run it if possible
function apply_cmd() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local category_cmd
    category_cmd=$(get_path_macro "$menu_filename" $(get_path_parent "$menu_path") "cmd")
    if [ ! -z "$category_cmd" ]; then
        local args
        args=$(yq "$menu_path.cmd" "$menu_filename")
        eval_cmd "$category_cmd" "$args"
    else
        echo "ERROR: $menu_path.__cmd__ not found in menu file"
    fi
}
