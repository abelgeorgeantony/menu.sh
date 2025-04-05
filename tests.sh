#!/bin/bash

source ./menu.sh

menu_filename="./examples/__meta__.menu.yaml"

# get_path_fzf_preview

echo -n "get_path_fzf_preview root "
result=$(get_path_fzf_preview ".")
[ "$result" == "" ] && echo "OK" || echo "FAIL: $result"

echo -n "get_path_fzf_preview subdir "
result=$(get_path_fzf_preview ".examples")
[ "$result" == ".examples" ] && echo "OK" || echo "FAIL: $result"

# check_if_one_option

echo -n "check_if_one_option true "
result=$(check_if_one_option "one")
[ "$result" == "true" ] && echo "OK" || echo "FAIL: $result"

echo -n "check_if_one_option false "
printf -v _options "one\ntwo\nthree"
result=$(check_if_one_option "$_options")
[ "$result" == "" ] && echo "OK" || echo "FAIL: $result"

# get_options

echo -n "get_options root "
result=$(get_options "$menu_filename" ".")
[ "$result" != "" ] && echo "OK" || echo "FAIL: $result"

echo -n "get_options subdir "
result=$(get_options "$menu_filename" ".examples")
[ "$result" != "" ] && echo "OK" || echo "FAIL: $result"

echo -n "get_options does not exist "
result=$(get_options "$menu_filename" ".examples.does.not.exist")
[ "$result" == "" ] && echo "OK" || echo "FAIL: $result"

# append_navigation

echo -n "append_navigation root "
result=$(append_options_navigation "$menu_filename" ".")
[[ "$result" == *"quit"* ]] && echo "OK" || echo "FAIL: $result"

echo -n "append_navigation subdir "
result=$(append_options_navigation "$menu_filename" ".examples")
[[ "$result" == *"back"* ]] && echo "OK" || echo "FAIL: $result"

# get_path_cmd

echo -n "get_path_cmd has none "
result=$(get_path_cmd "$menu_filename" ".")
[ "$result" == "" ] && echo "OK" || echo "FAIL: $result"

echo -n "get_path_cmd has one "
result=$(get_path_cmd "$menu_filename" ".examples")
[ "$result" != "" ] && echo "OK" || echo "FAIL: $result"

# eval_cmd

# apply_cmd

# get_selection

# render_menu

# get_path_files

menu_filename="./examples/files.menu.yaml"

echo -n "get_path_files root "
result=$(get_path_files "$menu_filename" ".")
[ "$result" == "" ] && echo "OK" || echo "FAIL: $result"

echo -n "get_path_files subdir "
result=$(get_path_files "$menu_filename" ".examples")
[ "$result" != "" ] && echo "OK" || echo "FAIL: $result"

echo -n "expand_files "
result=$(expand_files "$menu_filename" ".examples")
[ "$result" != "" ] && echo "OK" || echo "FAIL: $result"

