#!/bin/bash

# adds a button functionality
function click_button() {
    local menu_filename
    menu_filename=$1
    local menu_path
    menu_path=$2
    /bin/bash -c "$(yq "$menu_path".button "$menu_filename")" &>/dev/null & disown;
}
