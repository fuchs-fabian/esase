#!/bin/bash

# DESCRIPTION:
# This source helps with the extraction for the config mode of 'esase.sh'.


extract_flag_from_field() {
    local config_file=$1
    local field=$2

    jq -r ".$field" "$config_file"
}

extract_all_standard_apps_to_remove() {
    local config_file=$1

    jq -r '.remove[]' "$config_file" | tr '\n' ' ' | awk '{$1=$1};1'
}