#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

function eval_run() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local prompt
    prompt=$(get_path_macro "$menu_filename" "$menu_path" "prompt")

    # if the prompt is not empty, run the command with the prompt
    if [ ! -z "$prompt" ]; then
        local REPLY
        # if whiptail is installed, use it to get the input
        if command -v whiptail &> /dev/null; then
            export NEWT_COLORS='
                root=white,black
                window=white,black
                border=white,black
                title=white,black
                button=white,black
                compactbutton=lightgray,black
                entry=white,black
                '
            REPLY=$(whiptail --inputbox "" 8 40 --title "$prompt" 3>&1 1>&2 2>&3)
        # otherwise, use read to get the input
        else
            read -p "$prompt"
        fi

        if [ ! -z "$REPLY" ]; then
            # if the prompt is urlencoded, urlencode it
            local urlencode_prompt
            urlencode_prompt=$(get_path_macro "$menu_filename" "$menu_path" "urlencode")
            if [ ! -z "$urlencode_prompt" ]; then
                # if the prompt is a URL, urlencode it
                REPLY=$(urlencode "$REPLY")
            fi

            local cmd_fmt
            cmd_fmt=$(yq "$menu_path".run "$menu_filename")

            # even if REPLY has multiple items, return them all
            local cmd
            printf -v cmd "$cmd_fmt" "${REPLY[@]}"
            /bin/bash -c "$cmd"
        fi
    else
        /bin/bash -c "$(yq "$menu_path".run "$menu_filename")"
    fi

    local wait
    wait=$(get_path_macro "$menu_filename" "$menu_path" "wait")
    if [ ! -z "$wait" ]; then
        read -p "Press enter to continue"
    fi
}
