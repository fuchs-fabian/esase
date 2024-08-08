#!/bin/bash

# DESCRIPTION:
# This source enables the GUI mode for 'esase'.


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   GUI MODE                  #
# # # # # # # # # # # #|# # # # # # # # # # # #

popup_select_app_file_for_edit() {
    local screen_name="$TXT_SELECT_APP_FILE"

    local action=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_SELECT_APP_FILE_PROMPT" \
        --column="$TXT_COL_APP_FILE" \
        "$TXT_APT_APP_FILE_SELECTION" \
        "$TXT_DNF_APP_FILE_SELECTION" \
        "$TXT_FLATPAK_APP_FILE_SELECTION" \
        --selection-mode=single | awk -F'|' '{print $1}')

    if popup_is_canceled "$screen_name" "$action"; then
        popup_home
    fi

    case "$action" in
        "$TXT_APT_APP_FILE_SELECTION" )
            "$APP_FILE_EDITOR_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -l "$LANGUAGE" -f "$APT_APPS_FILE"
            ;;
        "$TXT_DNF_APP_FILE_SELECTION" )
            "$APP_FILE_EDITOR_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -l "$LANGUAGE" -f "$DNF_APPS_FILE"
            ;;
        "$TXT_FLATPAK_APP_FILE_SELECTION" )
            "$APP_FILE_EDITOR_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -l "$LANGUAGE" -f "$FLATPAK_APPS_FILE"
            ;;
    esac

    popup_select_app_file_for_edit
}

popup_select_action_to_perform() {
    local screen_name="$TXT_RUN_ACTIONS"

    local action=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_SELECT_ACTION_PROMPT" \
        --column="$TXT_COL_ACTION" \
        "$TXT_UPDATE_ALL" \
        "$TXT_REMOVE_STANDARD_APPS" \
        "$TXT_REPLACE_TERMINAL" \
        "$TXT_INSTALL_APPS" \
        "$TXT_INSTALL_FLATPAK_APPS" \
        "$TXT_INSTALL_ADVANCED_VIRTUALIZATION" \
        "$TXT_INSTALL_DOCKER" \
        "$TXT_INSTALL_NPM" \
        --selection-mode=single | awk -F'|' '{print $1}')

    if popup_is_canceled "$screen_name" "$action"; then
        popup_home
    fi

    local command_to_run_with_sudo

    case "$action" in
        "$TXT_UPDATE_ALL" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a update-all"
            ;;
        "$TXT_REMOVE_STANDARD_APPS" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a remove -r \"$(extract_all_standard_apps_to_remove "$CONFIG_FILE")\""
            ;;
        "$TXT_REPLACE_TERMINAL" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a replace-terminal"
            ;;
        "$TXT_INSTALL_APPS" )
            case "$DISTRO_NAME" in
                ubuntu|debian )
                    command_to_run_with_sudo="$APP_INSTALLER_SCRIPT -d $ENABLE_DEBUG_LOGGING -f $APT_APPS_FILE -c 'sudo apt install'"
                    ;;
                fedora )
                    command_to_run_with_sudo="$APP_INSTALLER_SCRIPT -d $ENABLE_DEBUG_LOGGING -f $DNF_APPS_FILE -c 'sudo dnf install'"
                    ;;
            esac
            ;;
        "$TXT_INSTALL_FLATPAK_APPS" )
            command_to_run_with_sudo="$APP_INSTALLER_SCRIPT -d $ENABLE_DEBUG_LOGGING -f $FLATPAK_APPS_FILE -c 'flatpak install flathub'"
            ;;
        "$TXT_INSTALL_ADVANCED_VIRTUALIZATION" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a install-advanced-virtualization"
            ;;
        "$TXT_INSTALL_DOCKER" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a install-docker"
            ;;
        "$TXT_INSTALL_NPM" )
            command_to_run_with_sudo="$DISTRO_BASED_ACTIONS_SCRIPT -d $ENABLE_DEBUG_LOGGING -a install-npm"
            ;;
    esac

    log_debug "Command to run with sudo: '$command_to_run_with_sudo'"

    run_with_sudo "$command_to_run_with_sudo"
    if [[ $? -ne 0 ]]; then
        log_debug "Authentication failed for '$command_to_run_with_sudo'."
    else
        yad --info --width=$NOTIFICATION_WINDOW_WIDTH --height=$NOTIFICATION_WINDOW_HEIGHT \
        --title="$TXT_SUCCESS" \
        --text="$action" \
        --button="OK:0"
    fi

    popup_select_action_to_perform
}

popup_home() {
    local screen_name="$TXT_TITLE_ESASE"

    local action=$(yad --list --width=$WINDOW_WIDTH --height=$WINDOW_HEIGHT --separator="|" \
        --title="$screen_name" \
        --text="$TXT_SELECT_ACTION_PROMPT" \
        --column="$TXT_COL_ACTION" \
        "$TXT_RUN_ACTIONS" \
        "$TXT_EDIT_APP_FILES" \
        --selection-mode=single | awk -F'|' '{print $1}')

    if popup_is_canceled "$screen_name" "$action"; then
        exit 0
    fi

    case "$action" in
        "$TXT_RUN_ACTIONS" )
            popup_select_action_to_perform
            ;;
        "$TXT_EDIT_APP_FILES" )
            popup_select_app_file_for_edit
            ;;
    esac

    popup_home
}

run_gui_mode() {
    set_popup_size
    popup_home
}