#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh
# menu.sh 0.1
# 2025-04-04

MENU=$1
YQ_PATH='.'

if [ -z "$MENU" ]; then
    echo "Usage: menu.sh <menu.yml>"
    exit 1
fi

clear

while true; do
    if [ $YQ_PATH == '.' ]; then
        PREVIEW_PATH=""
        CMD_CHECK=$(yq ".__cmd__" $MENU)
    else
        PREVIEW_PATH="$YQ_PATH"
        CMD_CHECK=$(yq "${YQ_PATH}.__cmd__" $MENU)
    fi

    if [ ! -z "$CMD_CHECK" ] && [ "$CMD_CHECK" != "null" ]; then
        CATEGORY_CMD=$CMD_CHECK
    fi

    OPTIONS=$(yq "$YQ_PATH | keys | .[]" $MENU)
    # remove CMD from OPTIONS if it is there
    OPTIONS=$(echo "$OPTIONS" | grep -v '__cmd__')

    # if there is only one option, then that is automatically our CHOICE
    if [ $(echo "$OPTIONS" | wc -l) -eq 1 ]; then
        CHOICE=$(echo "$OPTIONS")
    else
        # otherwise, show the menu; add a newline and quit option
        if [ $YQ_PATH == '.' ]; then
            printf -v OPTIONS "$OPTIONS\n<- quit"
        else
            printf -v OPTIONS "$OPTIONS\n<- quit/back"
        fi
        CHOICE=$(fzf --height=~75 --margin=5,10 --reverse --border=sharp --prompt="> " --preview="yq '$PREVIEW_PATH.{}' $MENU" --preview-window=down:3:wrap <<< "$OPTIONS")
    fi

    case $CHOICE in
        run|run-wait)
            CMD=$(yq "$YQ_PATH.$CHOICE" $MENU)
            echo "Running: $CMD"
            /bin/bash -c "$CMD" 

            if [[ "$CHOICE" == "run-wait"* ]]; then
                read -p "Press enter to continue"
            fi

            exit 0
            ;;
        cmd)
            ARGS=$(yq "$YQ_PATH.$CHOICE" $MENU)
            if [ ! -z "$CATEGORY_CMD" ]; then
                rm -f /tmp/cmd.sh
                touch /tmp/cmd.sh
                chown $(whoami) /tmp/cmd.sh
                chmod 600 /tmp/cmd.sh

                {
                    echo "function _cmd() {";
                    echo "  $CATEGORY_CMD";
                    echo "}";
                    echo "_cmd $ARGS";
                } >> /tmp/cmd.sh

                /bin/bash /tmp/cmd.sh
                rm /tmp/cmd.sh
                exit 0
            else
                echo "ERROR: No __cmd__ found for $CHOICE"
            fi
            ;;
        '<- quit')
            exit 0
            ;;
        '<- quit/back')
            YQ_PATH=$(echo "$YQ_PATH" | rev | cut -d. -f2- | rev)
            if [ -z "$YQ_PATH" ]; then
                YQ_PATH='.'
            fi
            CATEGORY_CMD=""
            ;;
        *) 
            # otherwise, descend into the next level
            YQ_PATH="$PREVIEW_PATH.$CHOICE"
            ;;
    esac

    if [ "$CHOICE" == "" ]; then
        exit 0
    fi
done
