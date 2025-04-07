#!/bin/bash
# Ian Dennis Miller
# https://github.com/iandennismiller/menu.sh

mkdir -p var

# combine the source files into one file
cat \
    src/path.sh \
    src/options.sh \
    src/ui.sh \
    src/cmd.sh \
    src/files.sh \
    src/run.sh \
    src/utils.sh \
    src/main.sh \
    > var/cat-menu.sh

# remove comments
sed \
    -e 's:^\s*#.*$::g' \
    -e 's/^[ \t]*#[^!].*$//g' \
    -e 's/[ \t]#.*$//g' \
    var/cat-menu.sh \
    > var/no-comments-menu.sh

# remove duplicated empty lines
cat var/no-comments-menu.sh \
    | awk 'BEGIN{RS="\n\n" ; ORS="\n";}{ print }' \
    | awk 'BEGIN{RS="\n\n" ; ORS="\n";}{ print }' \
    | awk 'BEGIN{RS="\n\n" ; ORS="\n";}{ print }' \
    | awk 'BEGIN{RS="\n\n" ; ORS="\n";}{ print }' \
    > var/newlines-menu.sh

# prepend the header to the file
cat \
    src/header.sh \
    var/newlines-menu.sh \
    > var/menu.sh

# and make it executable
chmod +x var/menu.sh

echo "menu.sh built in var/menu.sh"
