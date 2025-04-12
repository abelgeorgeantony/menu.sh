#!/bin/bash
# menu.sh 0.2
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
function get_path_fzf_preview() {
    local menu_path
    menu_path=$1
    if [ "$menu_path" == '.' ]; then
        echo ""
    else
        echo "$menu_path"
    fi
}
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
    local options
    options=$(yq "$menu_path | keys | .[]" "$menu_filename" 2>/dev/null) && {
        options=$(echo "$options" | grep -v '__cmd__')
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
function append_options_navigation() {
    local menu_path
    menu_path=$1
    local options
    options=$2
    if [ "$menu_path" == '.' ]; then
        printf -v options "%s\nquit" "$options"
    else
        printf -v options "%s\nquit-back" "$options"
    fi
    echo "$options"
}
function get_option_position() {
    local menu_filename
    menu_filename=$1
    local menu_path
    menu_path=$2
    local option
    option=$3
    local options
    options=$(get_options "$menu_filename" "$menu_path")
    options=$(echo $options | tr -d '[:cntrl:]')
    read -a options <<<"$options"
    local position
    position=1
    for opt in "${options[@]}"; do
        if [[ "$opt" = "$option" ]]; then
            echo "$position"
        fi
        position=$((position + 1))
    done
    echo 1
}
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
    if [ "$(check_if_one_option "$options")" ]; then
        echo "$options"
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
            if [ -f "$selection" ]; then
                apply_cmd_to_file "$menu_filename" "$menu_path" "$selection"
                clear
                menu_path='.'
                continue
            fi
            local fzf_preview
            fzf_preview=$(get_path_fzf_preview "$menu_path")
            menu_path="$fzf_preview.$selection"
            cursor_position=1
            ;;
        esac
    done
}
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
function eval_run() {
    local menu_filename
    menu_filename=$1
    local menu_path
    menu_path=$2
    local prompt
    prompt=$(get_path_macro "$menu_filename" "$menu_path" "prompt")
    if [ ! -z "$prompt" ]; then
        local REPLY
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
        else
            read -p "$prompt"
        fi
        if [ ! -z "$REPLY" ]; then
            local urlencode_prompt
            urlencode_prompt=$(get_path_macro "$menu_filename" "$menu_path" "urlencode")
            if [ ! -z "$urlencode_prompt" ]; then
                REPLY=$(urlencode "$REPLY")
            fi
            local cmd_fmt
            cmd_fmt=$(yq "$menu_path".run "$menu_filename")
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
function click_button() {
    local menu_filename
    menu_filename=$1
    local menu_path
    menu_path=$2
    /bin/bash -c "$(yq "$menu_path".button "$menu_filename")" &>/dev/null & disown;
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
if [ -n "$1" ]; then
    clear
    menu_loop "$1"
    exit 0
fi
