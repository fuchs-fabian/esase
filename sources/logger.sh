#!/bin/bash

# DESCRIPTION:
# This source enables the logging of a bash script.
# It is also possible to use popups for logging if the 'yad' package is installed.


ENABLE_ADVANCED_LOGGING=true    # Can be overwritten without problems
ENABLE_DEBUG_LOGGING=false      # Can be overwritten without problems
ENABLE_GUI_FOR_LOGGING=true     # Can be overwritten without problems

LOG_FILE_PATH="/tmp"            # Can be overwritten, but is not recommended


# # # # # # # # # # # #|# # # # # # # # # # # #
#              SCRIPT INFORMATION             #
# # # # # # # # # # # #|# # # # # # # # # # # #

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SCRIPT_NAME="$0"
SIMPLE_SCRIPT_NAME=$(basename "$SCRIPT_NAME")
SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION="${SIMPLE_SCRIPT_NAME%.*}"


# # # # # # # # # # # #|# # # # # # # # # # # #
#           NOTIFICATION POPUP SIZES          #
# # # # # # # # # # # #|# # # # # # # # # # # #

NOTIFICATION_WINDOW_WIDTH=500
NOTIFICATION_WINDOW_HEIGHT=100


# # # # # # # # # # # #|# # # # # # # # # # # #
#              LOGGING DIRECTORIES            #
# # # # # # # # # # # #|# # # # # # # # # # # #

LOG_DIR="${LOG_FILE_PATH}/${SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION}_logs/"
LOG_FILE="$(date +"%Y-%m-%d_%H-%M-%S")_log_${SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION}.txt"
LOG_FILE_WITH_LOG_DIR="${LOG_DIR}${LOG_FILE}"


# # # # # # # # # # # #|# # # # # # # # # # # #
#             LOGGING FUNCTIONALITY           #
# # # # # # # # # # # #|# # # # # # # # # # # #

log() {
    local level="$1"
    local message="$2"

    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
    fi

    local script_info=""
    if [ "$ENABLE_ADVANCED_LOGGING" = true ]; then
        script_info=" ($SIMPLE_SCRIPT_NAME)"
    fi

    if [[ -n "$message" ]]; then
        while IFS= read -r line; do
            echo "$(date +"%d.%m.%Y %H:%M:%S") - $level - $line" >> "$LOG_FILE_WITH_LOG_DIR"
            echo "  $level$script_info - $line"
        done <<< "$message"
    fi
}

log_debug() {
    if [ "$ENABLE_DEBUG_LOGGING" = true ]; then
        log "DEBUG  " "$1"
    fi
}

check_gui_support() {
    if ! command -v yad &> /dev/null; then
        log_debug "'yad' is not installed. Please install to use GUI popups."
        return 1
    fi
    return 0
}

log_cmd() {
    log "CMD    " "$1"
}

log_info() {
    log "INFO   " "$1"
}

log_warning() {
    log "WARNING" "$1"

    if [ "$ENABLE_GUI_FOR_LOGGING" = true ] && check_gui_support; then
        yad --warning --width=$NOTIFICATION_WINDOW_WIDTH --height=$NOTIFICATION_WINDOW_HEIGHT \
            --title="WARNING" \
            --text="$1" \
            --button="OK:0"
    fi
}

show_log_file() {
    if [[ -f "$LOG_FILE_WITH_LOG_DIR" ]]; then
        log_info "Log file: '${LOG_FILE_WITH_LOG_DIR}'"
    else
        echo "E R R O R - Log file creation failed: '${LOG_FILE_WITH_LOG_DIR}' - E R R O R"
    fi
}

log_error() {
    log "ERROR  " "$1"

    if [ "$ENABLE_GUI_FOR_LOGGING" = true ] && check_gui_support; then
        if [[ -f "$LOG_FILE_WITH_LOG_DIR" ]]; then
            yad --error --width=$NOTIFICATION_WINDOW_WIDTH --height=$NOTIFICATION_WINDOW_HEIGHT \
                --title="ERROR" \
                --text="$1\n\nLogfile: $LOG_FILE_WITH_LOG_DIR" \
                --button="OK:0"
        fi
    fi
    show_log_file
    exit 1
}