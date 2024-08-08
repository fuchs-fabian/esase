#!/bin/bash

# DESCRIPTION:
# This source enables the config mode (execution without GUI) for 'esase'.


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 CONFIG MODE                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

run_config_mode() {
    if [ "$(extract_flag_from_field "$CONFIG_FILE" "update_all")" == "true" ]; then
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a update-all
    fi

    sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a remove -r "$(extract_all_standard_apps_to_remove "$CONFIG_FILE")"

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "replace_terminal")" == "true" ]; then
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a replace-terminal
    fi

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "install_apps")" == "true" ]; then
        case "$DISTRO_NAME" in
            ubuntu|debian )
                sudo "$APP_INSTALLER_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -f "$APT_APPS_FILE" -c "sudo apt install"
                ;;
            fedora )
                sudo "$APP_INSTALLER_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -f "$DNF_APPS_FILE" -c "sudo dnf install"
                ;;
        esac
    fi

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "install_flatpak_apps")" == "true" ]; then
        sudo "$APP_INSTALLER_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -f "$FLATPAK_APPS_FILE" -c "flatpak install flathub"
        
        echo
        flatpak list
        echo
    fi

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "install_advanced_virtualization")" == "true" ]; then
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a install-advanced-virtualization
    fi

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "install_docker")" == "true" ]; then
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a install-docker
    fi

    if [ "$(extract_flag_from_field "$CONFIG_FILE" "install_npm")" == "true" ]; then
        sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a install-npm
    fi
}