#!/bin/bash

# DESCRIPTION:
# This script is 'esase'.
# Read the README.md for more information.


REQUIRED_DEPENDENCIES="pkexec jq yad xrandr"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 DIRECTORIES                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Default directories
SOURCES_DIR="$CURRENT_SCRIPT_DIR/sources"
SCRIPTS_DIR="$CURRENT_SCRIPT_DIR/scripts"

CONFIG_DIR="$CURRENT_SCRIPT_DIR/config"
APP_FILES_DIR="$CONFIG_DIR/app_files"

LANG_DIR="$CURRENT_SCRIPT_DIR/lang"

# Directories from installation
LOCAL_BIN_DIR="/usr/local/bin"              # script 'esase.sh'
LOCAL_ETC_DIR="/usr/local/etc/esase"        # dir    'lang'
LOCAL_SHARE_DIR="/usr/local/share/esase"    # dirs   'scripts' & 'sources' | image 'esase-icon.png'
VAR_LIB_DIR="/var/lib/esase"                # dir    'config'

set_directories_based_on_location() {
    #echo "CURRENT_SCRIPT_DIR: '$CURRENT_SCRIPT_DIR'"

    if [[ "$CURRENT_SCRIPT_DIR" == "$LOCAL_BIN_DIR" ]]; then
        #echo "The current script is located in the correct installation directory."

        SOURCES_DIR="$LOCAL_SHARE_DIR/sources"
        SCRIPTS_DIR="$LOCAL_SHARE_DIR/scripts"

        CONFIG_DIR="$VAR_LIB_DIR/config"
        APP_FILES_DIR="$CONFIG_DIR/app_files"

        LANG_DIR="$LOCAL_ETC_DIR/lang"
    fi

    #echo "SOURCES_DIR: '$SOURCES_DIR'"
    #echo "SCRIPTS_DIR: '$SCRIPTS_DIR'"

    #echo "CONFIG_DIR: '$CONFIG_DIR'"
    #echo "APP_FILES_DIR: '$APP_FILES_DIR'"

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
    "helper/json_config_extractor.sh"
    "helper/popup.sh"
    "helper/system_validation.sh"
    "lang/language.sh"
    "modes/config_mode.sh"
    "modes/gui_mode.sh"
)

for source_file in "${SOURCE_FILES[@]}"; do
    source "$SOURCES_DIR/$source_file" || { echo "Error: Could not source '$source_file' for '$0'"; exit 1; }
done


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SCRIPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

DISTRO_BASED_ACTIONS_SCRIPT="$SCRIPTS_DIR/distro_based_actions.sh"
APP_FILE_EDITOR_SCRIPT="$SCRIPTS_DIR/app_file_editor.sh"
APP_INSTALLER_SCRIPT="$SCRIPTS_DIR/app_installer.sh"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                    FILES                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

DEFAULT_CONFIG_FILE="$CONFIG_DIR/config.json"

APT_APPS_FILE="$APP_FILES_DIR/apt.json"
DNF_APPS_FILE="$APP_FILES_DIR/dnf.json"
FLATPAK_APPS_FILE="$APP_FILES_DIR/flatpak.json"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 PREPARATIONS                #
# # # # # # # # # # # #|# # # # # # # # # # # #

validate_system || log_error "System validation failed. Check the system compatibility!"
log_debug "The following Linux distribution is used to perform actions: '$DISTRO_NAME'"

check_scripts_and_make_scripts_executable "$DISTRO_BASED_ACTIONS_SCRIPT" "$APP_FILE_EDITOR_SCRIPT" "$APP_INSTALLER_SCRIPT" || log_error "Validation for scripts and their executability failed!"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   GETOPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

GUI=false
CONFIG_FILE="$DEFAULT_CONFIG_FILE"
PACKAGES_TO_INSTALL=""
UPDATE_ALL_FLAG=false
PACKAGES_TO_REMOVE=""

# TODO:
# Support the following actions: replace-terminal, install-advanced-virtualization, install-docker, install-npm
# Currently only supported in gui mode or config mode
# Is that even desirable?

while getopts ":hdgc:l:i:ur:" opt; do
    case ${opt} in
        h ) 
            echo "Usage: $SIMPLE_SCRIPT_NAME [-h] [-g] [-d] [-c CONFIG_FILE] [-l LANGUAGE] [-i \"PACKAGE_1 PACKAGE_2 ...\"] [-u] [-r \"PACKAGE_1 PACKAGE_2 ...\"]"
            echo "  -h                      Show help"
            echo "  -d                      Enables debug logging"
            echo "  -g                      Use GUI"            # TODO: The config.json is currently ignored for this purpose
            echo "  -c CONFIG_FILE          Specify a custom configuration file to run actions automatically"
            echo "                          (Default: $DEFAULT_CONFIG_FILE; Ignored if \"-i\", \"-u\" or \"-r\" is selected)"
            echo "  -l LANGUAGE             Specify language"   # TODO: Support for console mode and logging
            echo "                          (en or de; Default: System language)"
            echo "  -i PACKAGES_TO_INSTALL  Specify packages to install"
            echo "                          (only used if \"-g\" was not selected)"
            echo "  -u                      Updates all - packages, flatpaks, npm, etc."
            echo "                          (only used if \"-g\" was not selected)"
            echo "  -r PACKAGES_TO_REMOVE   Specify packages to remove"
            echo "                          (only used if \"-g\" was not selected)"
            exit 0
            ;;
        d ) 
            log_debug "'-d' selected"
            # Overwrites the variable in 'logger.sh'
            ENABLE_DEBUG_LOGGING=true
            ;;
        g ) 
            log_debug "'-g' selected"
            GUI=true
            ;;
        c ) 
            log_debug "'-c' selected: '$OPTARG'"
            CONFIG_FILE="${OPTARG}"
            ;;
        l ) 
            log_debug "'-l' selected: '$OPTARG'"
            LANGUAGE="${OPTARG}"
            ;;
        i ) 
            log_debug "'-i' selected: '$OPTARG'"
            PACKAGES_TO_INSTALL="${OPTARG}"
            ;;
        u ) 
            log_debug "'-u' selected"
            UPDATE_ALL_FLAG=true
            ;;
        r ) 
            log_debug "'-r' selected: '$OPTARG'"
            PACKAGES_TO_REMOVE="${OPTARG}"
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


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   LANGUAGE                  #
# # # # # # # # # # # #|# # # # # # # # # # # #

set_language


# # # # # # # # # # # #|# # # # # # # # # # # #
#                    LOGIC                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

log_info "'$SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION' has started."
show_log_file

log_info "You can find the configuration files under: '$CONFIG_DIR'"

#log_warning "Test warning"
#log_error "Test error"

#set # Show all possible environment variables

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

if [[ $GUI == true ]]; then
    check_dependencies $REQUIRED_DEPENDENCIES
    run_gui_mode
else
    if [[ -n "$PACKAGES_TO_INSTALL" ]]; then
        log_info "Installing specified packages: $PACKAGES_TO_INSTALL"
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a install -i "$PACKAGES_TO_INSTALL" || log_error "Installation failed!"
    fi

    if [[ $UPDATE_ALL_FLAG == true ]]; then
        log_info "Updating all..."
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a update-all
    fi

    if [[ -n "$PACKAGES_TO_REMOVE" ]]; then
        log_info "Removing specified packages: $PACKAGES_TO_REMOVE"
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a remove -r "$PACKAGES_TO_REMOVE" || log_error "Remove failed!"
    fi

    if [[ -z "$PACKAGES_TO_INSTALL" && -z "$PACKAGES_TO_REMOVE" && $UPDATE_ALL_FLAG == false ]]; then
        check_dependencies "pkexec jq"
        run_config_mode
    fi
fi

exit 0