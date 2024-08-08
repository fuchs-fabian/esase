#!/bin/bash

# DESCRIPTION:
# This source helps with the preparations.


# # # # # # # # # # # #|# # # # # # # # # # # #
#     CHECKS IF DEPENDENCIES ARE INSTALLED    #
# # # # # # # # # # # #|# # # # # # # # # # # #

check_dependencies() {
    local programs=("$@")
    local missing_programs=()

    for program in "${programs[@]}"; do
        if ! command -v "$program" &> /dev/null; then
            missing_programs+=("$program")
        fi
    done

    if [ ${#missing_programs[@]} -ne 0 ]; then
        log_error "The following required programs are not installed: ${missing_programs[*]}. Please install them to proceed."
    fi

    log_debug "All dependencies are installed."
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#   CHECKS IF SCRIPTS ARE AVAILABLE + EXEC    #
# # # # # # # # # # # #|# # # # # # # # # # # #

check_scripts_and_make_scripts_executable() {
    local scripts=("$@")  # Array of script paths passed to the function

    for script in "${scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            log_error "Script not found: $script"
            return 1  # Return an error code
        fi

        # Ensure the script is executable
        if [[ ! -x "$script" ]]; then
            chmod +x "$script"
            if [[ $? -ne 0 ]]; then
                log_error "Failed to make $script executable."
                return 1  # Return an error code
            fi
        fi

        log_debug "$script is executable."
    done
    return 0  # Success
}