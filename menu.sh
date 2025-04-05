#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh
# menu.sh 0.2
# 2025-04-05

###
# path functions

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

###
# options and selection

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

# render the current menu path with fzf and return the user's selection
function get_selection() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local fzf_preview
    fzf_preview=$(get_path_fzf_preview "$menu_path")

    local options
    options=$(get_options "$menu_filename" "$menu_path")

    # if there is only one option, then that is automatically our selection
    if [ "$(check_if_one_option "$options")" ]; then
        echo "$options"
    # otherwise, use fzf to show the menu and obtain the user's selection
    else
        options=$(append_options_navigation "$menu_path" "$options")
        fzf \
            --height=~75 \
            --margin=4,10,0,10 \
            --color='fg:#FFFFFF,border:#FFFFFF,bg+:black,gutter:gray,pointer:#FFFFFF' \
            --reverse \
            --border=sharp \
            --border-label="╢${menu_path}╟" \
            --border-label-pos=3 \
            --prompt="# " \
            --preview="yq '$fzf_preview.{}' $menu_filename" \
            --preview-window=down:3:wrap \
        <<< "$options"
    fi
}

###
# macro: __cmd__

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

###
# macro: __files__

# evaluate the __files__ macro as a glob and return the list of files
function expand_files() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local files
    files=$(get_path_macro "$menu_filename" "$menu_path" "files")

    if [ ! -z "$files" ]; then
        bash -c "ls $files"
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

###
# Main menu rendering

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

function render_menu() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path='.'

    while true; do
        local choice
        choice=$(get_selection "$menu_filename" "$menu_path")

        if [ "$choice" == "" ]; then
            exit 0
        fi

        case $choice in
            run)
                eval_run "$menu_filename" "$menu_path"
                clear
                menu_path='.'
                ;;
            cmd)
                apply_cmd "$menu_filename" "$menu_path"
                clear
                menu_path='.'
                ;;
            quit)
                exit 0
                ;;
            quit-back)
                menu_path=$(get_path_parent "$menu_path")
                ;;
            *)
                # if the choice is a file, run the command on it
                if [ -f "$choice" ]; then
                    apply_cmd_to_file "$menu_filename" "$menu_path" "$choice"
                    clear
                    menu_path='.'
                    continue
                fi

                # otherwise, descend into the next level
                local fzf_preview
                fzf_preview=$(get_path_fzf_preview "$menu_path")
                menu_path="$fzf_preview.$choice"
                ;;
        esac
    done
}

function urlencode() {
    s="${1//'%'/%25}"
    s="${s//' '/%20}"
    s="${s//'"'/%22}"
    s="${s//'#'/%23}"
    s="${s//'$'/%24}"
    s="${s//'&'/%26}"
    s="${s//'+'/%2B}"
    s="${s//','/%2C}"
    s="${s//'/'/%2F}"
    s="${s//':'/%3A}"
    s="${s//';'/%3B}"
    s="${s//'='/%3D}"
    s="${s//'?'/%3F}"
    s="${s//'@'/%40}"
    s="${s//'['/%5B}"
    s="${s//']'/%5D}"
    printf %s "$s"
}

###
# if the script is run with a parameter, assume it is a filename and render the menu with it

if [ -n "$1" ]; then
    clear
    render_menu "$1"
fi
