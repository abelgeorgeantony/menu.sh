#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

# render the current menu path with fzf and return the user's selection
function render_fzf_menu() {
    local menu_filename
    menu_filename=$1

    local menu_path
    menu_path=$2

    local cursor_position
    cursor_position=$3

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
            --sync --bind 'result:transform:[[ -z {q} ]] && echo "pos('${cursor_position}')"' \
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
            <<<"$options"
    fi
}

function menu_loop() {
    local menu_filename
    menu_filename=$1
    local menu_path
    menu_path='.'
    local cursor_position
    cursor_position=1
    declare -a selection_stack
    while true; do
        local selection
        selection=$(render_fzf_menu "$menu_filename" "$menu_path" $cursor_position)
        selection_stack+=("$selection")
        if [ "$selection" == "" ]; then
            exit 0
        fi
        case $selection in
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
        button)
            click_button "$menu_filename" "$menu_path"
            clear
            menu_path=$(get_path_parent "$menu_path")
            unset selection_stack[-1]
            cursor_position=$(get_option_position "$menu_filename" "$menu_path" "${selection_stack[-1]}")
            unset selection_stack[-1]
            ;;
        quit)
            exit 0
            ;;
        quit-back)
            menu_path=$(get_path_parent "$menu_path")
            unset selection_stack[-1]
            cursor_position=$(get_option_position "$menu_filename" "$menu_path" "${selection_stack[-1]}")
            unset selection_stack[-1]
            ;;
        *)
            # if the selection is a file, run the command on it
            if [ -f "$selection" ]; then
                apply_cmd_to_file "$menu_filename" "$menu_path" "$selection"
                clear
                menu_path='.'
                continue
            fi
            # otherwise, descend into the next level
            local fzf_preview
            fzf_preview=$(get_path_fzf_preview "$menu_path")
            menu_path="$fzf_preview.$selection"
            cursor_position=1
            ;;
        esac

    done
}
