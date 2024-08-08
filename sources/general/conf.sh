#!/bin/bash

# DESCRIPTION:
# This source makes it possible to read the '.conf' files.


# # # # # # # # # # # #|# # # # # # # # # # # #
#           GET CONFIGURATION VALUES          #
# # # # # # # # # # # #|# # # # # # # # # # # #

get_conf_value() {
    local conf_file=$1
    local key=$2
    local value

    # Search for the key in the configuration file
    value=$(grep "^$key=" "$conf_file" | cut -d'=' -f2-)

    # Remove surrounding quotes
    value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
    
    # Check if the value was found
    if [[ -z $value ]]; then
        log_error "Key '$key' not found in configuration file!"
    fi

    # Output the value
    echo "$value"
}