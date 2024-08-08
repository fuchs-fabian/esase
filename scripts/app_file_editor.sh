#!/bin/bash

# DESCRIPTION:
# This script edits an app file.


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 DIRECTORIES                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Default directories
SOURCES_DIR="$CURRENT_SCRIPT_DIR/../sources"
LANG_DIR="$CURRENT_SCRIPT_DIR/../lang"

# Directories from installation
LOCAL_BIN_DIR="/usr/local/bin"              # script 'esase.sh'
LOCAL_ETC_DIR="/usr/local/etc/esase"        # dir    'lang'
LOCAL_SHARE_DIR="/usr/local/share/esase"    # dirs   'scripts' & 'sources' | image 'esase-icon.png'
VAR_LIB_DIR="/var/lib/esase"                # dir    'config'

set_directories_based_on_location() {
    #echo "CURRENT_SCRIPT_DIR: '$CURRENT_SCRIPT_DIR'"

    if [[ "$CURRENT_SCRIPT_DIR" == "$LOCAL_SHARE_DIR/scripts" ]]; then
        #echo "The current script is located in the correct installation directory."

        SOURCES_DIR="$LOCAL_SHARE_DIR/sources"
        LANG_DIR="$LOCAL_ETC_DIR/lang"
    fi

    #echo "SOURCES_DIR: '$SOURCES_DIR'"
    #echo "LANG_DIR: '$LANG_DIR'"
}

set_directories_based_on_location


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SOURCES                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

SOURCE_FILES=(
    "logger.sh"
    "general/conf.sh"
    "general/gui.sh"
    "general/preparations.sh"
    "helper/json_app_file_extractor.sh"
    "helper/popup.sh"
    "lang/language.sh"
)

for source_file in "${SOURCE_FILES[@]}"; do
    source "$SOURCES_DIR/$source_file" || { echo "Error: Could not source '$source_file' for '$0'."; exit 1; }
done


# # # # # # # # # # # #|# # # # # # # # # # # #
#                PREPARATIONS                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

check_dependencies jq yad


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   GETOPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

APP_FILE=""

while getopts ":hd:l:f:" opt; do
    case ${opt} in
        h )
            echo "Usage: $SIMPLE_SCRIPT_NAME [-h] [-d true/false] [-l LANGUAGE] [-f APP_FILE]"
            echo "  -h                 Show help"
            echo "  -d true/false      Enables debug logging"
            echo "  -l LANGUAGE        Specify language (en or de; Default: en)"
            echo "  -f APP_FILE        E.g. '<path-to-app-file>/apt.json'"
            exit 0
            ;;
        d ) 
            log_debug "'-d' selected: '$OPTARG'"
            # Overwrites the variable in 'logger.sh'
            ENABLE_DEBUG_LOGGING="${OPTARG}"
            ;;
        l )
            log_debug "'-l' selected: '$OPTARG'"
            LANGUAGE="${OPTARG}"
            ;;
        f )
            log_debug "'-f' selected: '$OPTARG'"
            APP_FILE="${OPTARG}"
            ;;
        \? )
            log_error "Invalid option: -$OPTARG"
            ;;
        : )
            log_error "Option -$OPTARG requires an argument!"
            ;;
    esac
done
shift $((OPTIND -1))

if [[ -z "$APP_FILE" ]]; then
    log_error "No app file specified!"
fi

log_debug "Language used: '$LANGUAGE'"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                WINDOW SETTINGS              #
# # # # # # # # # # # #|# # # # # # # # # # # #

set_popup_size


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   LANGUAGE                  #
# # # # # # # # # # # #|# # # # # # # # # # # #

set_language


# # # # # # # # # # # #|# # # # # # # # # # # #
#                  APP ACTIONS                #
# # # # # # # # # # # #|# # # # # # # # # # # #

popup_select_apps_for_installation() {
    local app_file=$1

    local screen_name="$TXT_SELECT_APPS_FOR_INSTALLATION"

    local app_entry_list=()
    local entry_index=1
    while IFS='|' read -r app_name app_alias app_install app_description app_category; do
        local install_checked="FALSE"
        if [[ "$app_install" == "true" ]]; then
            install_checked="TRUE"
        fi
        app_entry_list+=("$entry_index" "$install_checked" "$app_name" "$app_alias" "$app_description" "$app_category")
        ((entry_index++))
    done <<< "$(extract_all_app_entries "$app_file")"

    local gui_result=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_SELECT_APPS_FOR_INSTALLATION_PROMPT" \
        --column="$TXT_COL_INDEX" \
        --column="$TXT_COL_INSTALL":CHK \
        --column="$TXT_COL_NAME" \
        --column="$TXT_COL_ALIAS" \
        --column="$TXT_COL_DESCRIPTION" \
        --column="$TXT_COL_CATEGORY" \
        "${app_entry_list[@]}" \
        --print-all)

    if popup_is_canceled "$screen_name" "$gui_result"; then
        popup_home "$app_file"
    fi

    while IFS='|' read -r index install_flag app_name app_alias app_description app_category; do
        local install_value="false"
        if [[ "$install_flag" == "TRUE" ]]; then
            install_value="true"
        fi

        jq --arg category "$app_category" \
            --arg name "$app_name" \
            --argjson install "$install_value" \
            '(.[$category][] | select(.name == $name)).install = $install' \
            "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
    done <<< "$gui_result"

    log_info "$screen_name - Updated apps for installation."
    popup_select_apps_for_installation "$app_file"
}

popup_add_app() {
    local app_file=$1

    local screen_name="$TXT_ADD_APP"

    local dropdown_options=$(printf "%s\n" "$(extract_categories "$app_file")" | awk '{print $0"!"}' | tr -d '\n')

    local gui_result=$(yad --form --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_ADD_APP_PROMPT" \
        --field="${TXT_COL_NAME}":ENTRY "" \
        --field="${TXT_COL_ALIAS}":ENTRY "" \
        --field="${TXT_COL_INSTALL}":CHK "FALSE" \
        --field="${TXT_COL_DESCRIPTION}":ENTRY "" \
        --field="${TXT_COL_CATEGORY}":CB "$dropdown_options")

    if ! popup_is_canceled "$screen_name" "$gui_result"; then
        IFS='|' read -r name alias install description category <<< "$gui_result"

        if [[ -z "$name" ]]; then
            log_warning "$screen_name - No name provided. No entry added."
            popup_home "$app_file"
        fi

        if [[ "$install" == "TRUE" ]]; then
            install=true
        else
            install=false
        fi

        jq --arg category "$category" \
            --arg name "$name" \
            --arg alias "$alias" \
            --arg install "$install" \
            --arg description "$description" \
            '.[$category] += [{
                name: $name,
                alias: ($alias | select(length > 0) // null),
                install: ($install | test("true") // false),
                description: ($description | select(length > 0) // null)
            }]' \
            "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"

        log_info "$screen_name - Added new app: $name"
    fi

    popup_home "$app_file"
}

popup_edit_apps() {
    local app_file=$1

    local screen_name="$TXT_EDIT_APPS"

    local app_entry_list=()
    local entry_index=1
    while IFS='|' read -r app_name app_alias app_install app_description app_category; do
        app_entry_list+=("$entry_index" "$app_name" "$app_alias" "$app_install" "$app_description" "$app_category")
        ((entry_index++))
    done <<< "$(extract_all_app_entries "$app_file")"

    local gui_result=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_EDIT_APPS_SELECT_PROMPT" \
        --column="$TXT_COL_INDEX" \
        --column="$TXT_COL_NAME" \
        --column="$TXT_COL_ALIAS" \
        --column="$TXT_COL_INSTALL" \
        --column="$TXT_COL_DESCRIPTION" \
        --column="$TXT_COL_CATEGORY" \
        "${app_entry_list[@]}" \
        --selection-mode=single)

    if popup_is_canceled "$screen_name" "$gui_result"; then
        popup_home "$app_file"
    fi

    IFS='|' read -r index app_name app_alias app_install app_description app_category <<< "$gui_result"
    log_debug "$screen_name - App to edit: $app_name, $app_alias, $app_install, $app_description, $app_category"
    popup_edit_app "$app_file" "$app_name" "$app_category"

    popup_edit_apps "$app_file"
}

popup_edit_app() {
    local app_file=$1
    local app_name=$2
    local old_category=$3

    local screen_name="$TXT_EDIT_APP"

    log_debug "$screen_name - App to edit: '$app_name' ($old_category)"

    local app=$(jq -r ".${old_category}[] | select(.name == \"$app_name\")" "$app_file")
    local old_alias=$(echo "$app" | jq -r '.alias // ""')
    local old_install=$(echo "$app" | jq -r '.install')
    local old_description=$(echo "$app" | jq -r '.description // ""')

    log_info "$screen_name - Selected App: $app_name, $old_alias, $old_install, $old_description, $old_category"

    local dropdown_options="$old_category"  # Start with the current category
    while IFS= read -r cat; do
        if [[ "$cat" != "$old_category" ]]; then
            dropdown_options+="!$cat"  # Append other categories
        fi
    done <<< "$(extract_categories "$app_file")"

    local gui_result=$(yad --form --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_EDIT_APP_PROMPT" \
        --field="${TXT_COL_NAME}":ENTRY "$app_name" \
        --field="${TXT_COL_ALIAS}":ENTRY "$old_alias" \
        --field="${TXT_COL_INSTALL}":CHK "$old_install" \
        --field="${TXT_COL_DESCRIPTION}":ENTRY "$old_description" \
        --field="${TXT_COL_CATEGORY}":CB "$dropdown_options")

    if ! popup_is_canceled "$screen_name" "$gui_result"; then
        IFS='|' read -r new_name new_alias new_install new_description new_category <<< "$gui_result"
        
        if [[ "$new_install" == "TRUE" ]]; then
            new_install=true
        else
            new_install=false
        fi
        
        log_info "$screen_name - Old: $app_name, $old_alias, $old_install, $old_description, $old_category"
        log_info "$screen_name - New: $new_name, $new_alias, $new_install, $new_description, $new_category"

        jq --arg old_category "$old_category" \
            --arg new_category "$new_category" \
            --arg old_name "$app_name" \
            --arg new_name "$new_name" \
            --arg alias "$new_alias" \
            --argjson install "$new_install" \
            --arg description "$new_description" \
            'del(.[$old_category][] | select(.name == $old_name)) |
            .[$new_category] += [{
                name: $new_name,
                alias: (if $alias == "" then null else $alias end),
                install: $install,
                description: (if $description == "" then null else $description end)
            }]' \
            "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
    fi
}

popup_delete_apps() {
    local app_file=$1

    local screen_name="$TXT_DELETE_APPS"

    local app_entry_list=()
    local entry_index=1
    while IFS='|' read -r app_name app_alias app_install app_description app_category; do
        app_entry_list+=("$entry_index" "FALSE" "$app_name" "$app_alias" "$app_install" "$app_description" "$app_category")
        ((entry_index++))
    done <<< "$(extract_all_app_entries "$app_file")"

    local gui_result=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_DELETE_APPS_PROMPT" \
        --column="$TXT_COL_INDEX" \
        --column="$TXT_COL_DELETE":CHK \
        --column="$TXT_COL_NAME" \
        --column="$TXT_COL_ALIAS" \
        --column="$TXT_COL_INSTALL" \
        --column="$TXT_COL_DESCRIPTION" \
        --column="$TXT_COL_CATEGORY" \
        "${app_entry_list[@]}" \
        --print-all)

    if popup_is_canceled "$screen_name" "$gui_result"; then
        popup_home "$app_file"
    fi

    local indices_for_deletion=()
    while IFS='|' read -r index delete_flag app_name app_alias app_install app_description app_category; do
        if [[ "$delete_flag" == "TRUE" ]]; then
            log_debug "$screen_name - App to delete: $index, $app_name, $app_alias, $app_install, $app_description, $app_category"
            indices_for_deletion+=("${index}")
        fi
    done <<< "$gui_result"

    if [ ${#indices_for_deletion[@]} -eq 0 ]; then
        log_info "$screen_name - Nothing selected."
        popup_delete_apps "$app_file"
    fi

    IFS=$'\n' sorted_indices=($(sort -nr <<<"${indices_for_deletion[*]}"))
    unset IFS

    for index in "${sorted_indices[@]}"; do
        index=$((index - 1))

        local app=$(jq -r --argjson index "$index" 'to_entries | map(.key as $category | .value | map(. + {category: $category})) | flatten | .[$index]' "$app_file")
        local app_name=$(echo "$app" | jq -r '.name')
        local app_category=$(echo "$app" | jq -r '.category')

        if [[ -n "$app_name" && -n "$app_category" ]]; then
            jq --arg name "$app_name" \
                --arg category "$app_category" \
                'del(.[$category][] | select(.name == $name))' \
                "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
            log_info "$screen_name - Deleted app: $app_name ($app_category)"
        else
            log_warning "$screen_name - App name or category is empty for index '$index'."
        fi
    done

    popup_delete_apps "$app_file"
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#              CATEGORY ACTIONS               #
# # # # # # # # # # # #|# # # # # # # # # # # #

popup_add_category() {
    local app_file=$1

    local screen_name="$TXT_ADD_CATEGORY"

    local new_category=$(yad --entry --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT \
        --title="$screen_name" \
        --text="$TXT_ADD_CATEGORY_PROMPT" \
        --entry-label="$TXT_COL_NAME")

    if ! popup_is_canceled "$screen_name" "$new_category"; then
        if [[ -n "$new_category" ]]; then
            jq --arg category "$new_category" \
                '.[$category] = []' \
                "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
            log_info "$screen_name - Added new category: $new_category"
        fi
    fi
    
    popup_home "$app_file"
}

popup_edit_categories() {
    local app_file=$1
    local screen_name="$TXT_EDIT_CATEGORIES"

    local category_list=()
    local entry_index=1
    while IFS= read -r category; do
        category_list+=("$entry_index" "$category")
        ((entry_index++))
    done <<< "$(extract_categories "$app_file")"

    local gui_result=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_EDIT_CATEGORIES_SELECT_PROMPT" \
        --column="$TXT_COL_INDEX" \
        --column="$TXT_COL_CATEGORY" \
        "${category_list[@]}" \
        --selection-mode=single)

    if popup_is_canceled "$screen_name" "$gui_result"; then
        popup_home "$app_file"
    fi
    log_debug "$screen_name - Selected: $gui_result"

    IFS='|' read -r index category <<< "$gui_result"
    log_debug "$screen_name - Category to edit: $category"
    popup_edit_category "$app_file" "$category"

    popup_edit_categories "$app_file"
}

popup_edit_category() {
    local app_file=$1
    local old_category=$2

    local screen_name="$TXT_EDIT_CATEGORY"
    log_debug "$screen_name - Old Category: '$old_category'"

    local new_category=$(yad --entry --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT \
        --title="$screen_name" \
        --text="$TXT_EDIT_CATEGORY_PROMPT" \
        --entry-label="$TXT_EDIT_CATEGORY" \
        --entry-text="$old_category")

    if ! popup_is_canceled "$screen_name" "$new_category"; then
        if [[ -n "$new_category" && "$new_category" != "$old_category" ]]; then
            jq --arg old_category "$old_category" \
                --arg new_category "$new_category" \
                'if has($new_category) then . else .[$new_category] = .[$old_category] | del(.[$old_category]) end' \
                "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
            log_info "$screen_name - Renamed category: $old_category to $new_category"
        fi
    fi
}

popup_delete_categories() {
    local app_file=$1

    local screen_name="$TXT_DELETE_CATEGORIES"

    local category_list=()
    local entry_index=1
    while IFS= read -r category; do
        local apps_in_category=$(jq -r --arg category "$category" '.[$category] | map(.name) | join("; ")' "$app_file")
        category_list+=("$entry_index" "FALSE" "$category" "$apps_in_category")
        ((entry_index++))
    done <<< "$(extract_categories "$app_file")"

    local gui_result=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_DELETE_CATEGORIES_PROMPT" \
        --column="$TXT_COL_INDEX" \
        --column="$TXT_COL_DELETE":CHK \
        --column="$TXT_COL_CATEGORY" \
        --column="$TXT_COL_APPS" \
        "${category_list[@]}" \
        --print-all)

    if popup_is_canceled "$screen_name" "$gui_result"; then
        popup_home "$app_file"
    fi

    local categories_for_deletion=()
    while IFS='|' read -r index delete_flag category apps; do
        if [[ "$delete_flag" == "TRUE" ]]; then
            log_debug "$screen_name - Category to delete: $category, $apps"
            categories_for_deletion+=("$category")
        fi
    done <<< "$gui_result"

    if [ ${#categories_for_deletion[@]} -eq 0 ]; then
        log_info "$screen_name - Nothing selected."
        popup_delete_categories "$app_file"
    fi

    for category in "${categories_for_deletion[@]}"; do
        if [[ -n "$category" ]]; then
            jq --arg category "$category" \
                'del(.[$category])' \
                "$app_file" > tmp.$$.json && mv tmp.$$.json "$app_file"
            log_info "$screen_name - Deleted category: $category"
        else
            log_warning "$screen_name - Category is empty."
        fi
    done

    popup_delete_categories "$app_file"
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#                     HOME                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

popup_home() {
    local app_file=$1

    local screen_name="$TXT_TITLE_APP_FILE_EDITOR"

    local app_type=$(basename "$app_file" | sed 's/\.[^.]*$//')

    local action=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_SELECT_ACTION $app_type" \
        --column="$TXT_COL_ACTION" \
        "$TXT_SELECT_APPS_FOR_INSTALLATION" \
        "$TXT_ADD_APP" \
        "$TXT_EDIT_APPS" \
        "$TXT_DELETE_APPS" \
        "$TXT_ADD_CATEGORY" \
        "$TXT_EDIT_CATEGORIES" \
        "$TXT_DELETE_CATEGORIES" \
        --selection-mode=single | awk -F'|' '{print $1}')

    if popup_is_canceled "$screen_name" "$action"; then
        exit
    fi

    case "$action" in
        "$TXT_SELECT_APPS_FOR_INSTALLATION" )
            popup_select_apps_for_installation "$app_file"
            ;;
        "$TXT_ADD_APP" )
            popup_add_app "$app_file"
            ;;
        "$TXT_EDIT_APPS" )
            popup_edit_apps "$app_file"
            ;;
        "$TXT_DELETE_APPS" )
            popup_delete_apps "$app_file"
            ;;
        "$TXT_ADD_CATEGORY" )
            popup_add_category "$app_file"
            ;;
        "$TXT_EDIT_CATEGORIES" )
            popup_edit_categories "$app_file"
            ;;
        "$TXT_DELETE_CATEGORIES" )
            popup_delete_categories "$app_file"
            ;;
    esac
}

edit_app_file() {
    local app_file=$1

    if [[ -f "$app_file" ]]; then
        app_file=$(realpath "$app_file")
        log_info "'$app_file' is being processed."

        while true; do
            popup_home "$app_file"
        done
    else
        log_error "'$app_file' could not be found!"
    fi
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#                    LOGIC                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

log_info "'$SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION' has started."
show_log_file

edit_app_file "$APP_FILE"

exit 0