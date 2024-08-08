#!/bin/bash

# DESCRIPTION:
# This source helps to set the popup sizes.


WINDOW_WIDTH=1000
WINDOW_HEIGHT=1000

set_popup_size() {
    local screen_resolution
    local screen_width
    local screen_height

    # Check if xrandr is installed
    if ! command -v xrandr &> /dev/null; then
        # xrandr not found, set default size
        log_warning "xrandr not found. Defaulting to $WINDOW_WIDTH x $WINDOW_HEIGHT for window size."
        return
    fi

    # Get the screen resolution
    screen_resolution=$(xrandr | grep '*' | awk '{print $1}')
    
    # Check if screen resolution was found
    if [[ -z "$screen_resolution" ]]; then
        # Default size if resolution could not be determined
        log_warning "Unable to determine screen resolution. Defaulting to $WINDOW_WIDTH x $WINDOW_HEIGHT."
        return
    fi
    
    # Extract width and height from the screen resolution
    screen_width=$(echo "$screen_resolution" | sed 's/x.*//')
    screen_height=$(echo "$screen_resolution" | sed 's/.*x//')

    # Set the window size to the screen size
    WINDOW_WIDTH=$screen_width
    WINDOW_HEIGHT=$screen_height

    # Log the sizes
    log_debug "Screen width: $WINDOW_WIDTH"
    log_debug "Screen height: $WINDOW_HEIGHT"
}
