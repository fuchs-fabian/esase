#!/bin/bash

# DESCRIPTION:
# This source helps with the use of GUI (popup) interactions.


# # # # # # # # # # # #|# # # # # # # # # # # #
#      EXECUTING SUDO COMMANDS WITH GUI       #
# # # # # # # # # # # #|# # # # # # # # # # # #

run_with_sudo() {
    local command=$1

    log_debug "Run: 'sudo $command'"
    pkexec bash -c "$command"
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#      CHECKS IF POPUP HAS BEEN CANCELED      #
# # # # # # # # # # # #|# # # # # # # # # # # #

popup_is_canceled() {
    local screen_name=$1
    local result=$2

    if [[ -z "$result" ]]; then
        log_debug "$screen_name - User selected: 'Cancel'"
        return 0
    fi
    log_debug "$screen_name - User selected: 'OK'"
    return 1
}