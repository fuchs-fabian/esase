#!/usr/bin/env bash

# DESCRIPTION:
# This source enables the logging of a bash script.
# It is also possible to use popups for logging if the 'yad' package is installed.

ENABLE_DEBUG_LOGGING=false  # Can be overwritten without problems
ENABLE_GUI_FOR_LOGGING=true # Can be overwritten without problems

# # # # # # # # # # # #|# # # # # # # # # # # #
#              SCRIPT INFORMATION             #
# # # # # # # # # # # #|# # # # # # # # # # # #

SCRIPT_NAME="$0"
SIMPLE_SCRIPT_NAME=$(basename "$SCRIPT_NAME")
SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION="${SIMPLE_SCRIPT_NAME%.*}"

# # # # # # # # # # # #|# # # # # # # # # # # #
#           NOTIFICATION POPUP SIZES          #
# # # # # # # # # # # #|# # # # # # # # # # # #

NOTIFICATION_WINDOW_WIDTH=500
NOTIFICATION_WINDOW_HEIGHT=100

# # # # # # # # # # # #|# # # # # # # # # # # #
#             LOGGING FUNCTIONALITY           #
# # # # # # # # # # # #|# # # # # # # # # # # #

LOG_DIR="/tmp/"

function log {
    local severity="$1"
    local message="$2"

    local log_level
    if [ "$ENABLE_DEBUG_LOGGING" = true ]; then
        log_level=7
    else
        log_level=6
    fi

    local log_dir="$LOG_DIR"

    local severity_code

    # Set severity code
    case "$severity" in
    debug | 7)
        severity_code=7
        ;;
    info | 6)
        severity_code=6
        ;;
    notice | 5)
        severity_code=5
        ;;
    warn | 4)
        severity_code=4
        ;;
    error | 3)
        severity_code=3
        ;;
    crit | 2)
        severity_code=2
        ;;
    alert | 1)
        severity_code=1
        ;;
    emerg | 0)
        severity_code=0
        ;;
    *)
        # Default to debug if severity is unknown
        severity_code=7
        echo "Unknown severity: $severity"
        ;;
    esac

    if [ "$severity_code" -le 4 ]; then
        simbashlog_action="log"
    else
        simbashlog_action="console"
    fi

    local simbashlog_command=("simbashlog" "--action" "$simbashlog_action" "--severity" "$severity_code" "--message" "$message" "--log-level" "$log_level")

    if [ "$severity_code" -le 4 ]; then
        simbashlog_command+=("--log-dir" "$log_dir")
    fi

    # Execute simbashlog command
    "${simbashlog_command[@]}" ||
        {
            echo "Failed to execute: simbashlog"
            exit 1
        }

    # Exit if severity is error or higher
    if [[ "$severity_code" -lt 3 ]]; then
        exit 1
    fi
}

log_debug() {
    log debug "$1"
}

check_gui_support() {
    if ! command -v yad &>/dev/null; then
        log_debug "'yad' is not installed. Please install to use GUI popups."
        return 1
    fi
    return 0
}

log_cmd() {
    log debug "CMD: $1"
}

log_info() {
    log info "$1"
}

log_warning() {
    log warn "$1"

    if [ "$ENABLE_GUI_FOR_LOGGING" = true ] && check_gui_support; then
        yad --warning --width=$NOTIFICATION_WINDOW_WIDTH --height=$NOTIFICATION_WINDOW_HEIGHT \
            --title="WARNING" \
            --text="$1" \
            --button="OK:0"
    fi
}

log_error() {
    if [ "$ENABLE_GUI_FOR_LOGGING" = true ] && check_gui_support; then
        if [[ -f "$LOG_FILE_WITH_LOG_DIR" ]]; then
            yad --error --width=$NOTIFICATION_WINDOW_WIDTH --height=$NOTIFICATION_WINDOW_HEIGHT \
                --title="ERROR" \
                --text="$1\n\nLogfile: $LOG_FILE_WITH_LOG_DIR" \
                --button="OK:0"
        fi
    fi

    log error "$1"
}
