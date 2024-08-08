#!/bin/bash

# DESCRIPTION:
# This source helps with the extraction for the 'app_file_editor.sh'.


extract_categories() {
    local apps_file=$1

    jq -r 'keys[]' "$apps_file"
}

extract_apps_for_category() {
    local apps_file=$1
    local category=$2

    jq -r --arg category "$category" ".$category[] | select(.install == true) | \"\(.name) \(.alias // .name)\"" "$apps_file"
}

extract_all_app_entries() {
    local apps_file=$1

    jq -r 'to_entries | map(.key as $category | .value | map(. + {category: $category})) | flatten | .[] | "\(.name)|\(.alias // "")|\(.install)|\(.description // "")|\(.category)"' "$apps_file"
}