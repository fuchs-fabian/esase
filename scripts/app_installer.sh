#!/bin/bash

# DESCRIPTION:
# This script installs apps from an app file.


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 DIRECTORIES                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Default directories
SOURCES_DIR="$CURRENT_SCRIPT_DIR/../sources"

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
    fi

    #echo "SOURCES_DIR: '$SOURCES_DIR'"
}

set_directories_based_on_location


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SOURCES                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

SOURCE_FILES=(
    "logger.sh"
    "general/preparations.sh"
    "helper/json_app_file_extractor.sh"
)

for source_file in "${SOURCE_FILES[@]}"; do
    source "$SOURCES_DIR/$source_file" || { echo "Error: Could not source '$source_file' for '$0'."; exit 1; }
done


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 PREPARATIONS                #
# # # # # # # # # # # #|# # # # # # # # # # # #

check_dependencies jq


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   GETOPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

APP_FILE=""
INSTALL_COMMAND=""

while getopts ":hd:f:c:" opt; do
    case ${opt} in
        h )
            echo "It is recommended to run the script with root rights to ensure that the installations work without requesting these rights."
            echo
            echo "Usage: (sudo) $SIMPLE_SCRIPT_NAME [-h] [-d true/false] [-f APP_FILE] [-c INSTALL_COMMAND]"
            echo "  -h                    Show help"
            echo "  -d true/false         Enables debug logging"
            echo "  -f APP_FILE           E.g. '<path-to-app-file>/apt.json'"
            echo "  -c INSTALL_COMMAND    E.g. 'sudo apt install'"
            exit 0
            ;;
        d ) 
            log_debug "'-d' selected: '$OPTARG'"
            # Overwrites the variable in 'logger.sh'
            ENABLE_DEBUG_LOGGING="${OPTARG}"
            ;;
        f )
            log_debug "'-f' selected: '$OPTARG'"
            APP_FILE="${OPTARG}"
            ;;
        c )
            log_debug "'-c' selected: '$OPTARG'"
            INSTALL_COMMAND="${OPTARG}"
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
    log_error "No apps file specified!"
fi

if [[ -z "$INSTALL_COMMAND" ]]; then
    log_error "No install command specified!"
fi


# # # # # # # # # # # #|# # # # # # # # # # # #
#             INSTALL FUNCTIONALITY           #
# # # # # # # # # # # #|# # # # # # # # # # # #

install_apps_by_category() {
    local app_file=$1
    local install_command=$2
    local category=$3

    while read -r line; do
        if [ -n "$line" ]; then
            name=$(echo "$line" | awk '{print $1}')
            alias=$(echo "$line" | cut -d' ' -f2-)

            log_info "Installing $alias ($name)..."

            $install_command $name -y
        fi
    done <<< "$(extract_apps_for_category "$app_file" "$category")"
}

install_apps() {
    local app_file=$1
    local install_command=$2

    if [[ -f "$app_file" ]]; then
        app_file=$(realpath "$app_file")
        
        log_debug "'$app_file' is being processed."
        log_debug "Installing apps with '$install_command'..."

        for category in $(extract_categories "$app_file"); do
            log_debug "Processing category: $category"
            install_apps_by_category "$app_file" "$install_command" "$category"
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

install_apps "$APP_FILE" "$INSTALL_COMMAND"

exit 0