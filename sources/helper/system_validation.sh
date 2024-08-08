#!/bin/bash

# DESCRIPTION:
# This source helps to validate the current system.


DISTRO_NAME=""

MIN_UBUNTU_VERSION=24
MIN_DEBIAN_VERSION=12
MIN_FEDORA_VERSION=40

validate_system() {
    local distro_version
    local min_version

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_NAME=$ID
        distro_version=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO_NAME="fedora"
        distro_version=$(rpm -E %fedora)
    else
        log_error "Unable to detect distribution. Supported distributions are Ubuntu, Debian and Fedora."
        return 1
    fi

    log_info "The following Linux distribution is used: '$DISTRO_NAME'"
    log_info "The version of the distribution is: '$distro_version'"

    case "$DISTRO_NAME" in
        ubuntu )
            min_version=$MIN_UBUNTU_VERSION
            ;;
        debian )
            min_version=$MIN_DEBIAN_VERSION
            ;;
        fedora )
            min_version=$MIN_FEDORA_VERSION
            ;;
        * )
            log_error "Unsupported distribution: '$DISTRO_NAME'"
            return 1
            ;;
    esac

    if (( $(echo "$distro_version < $min_version" | bc -l) )); then
        log_error "Unsupported version: '$distro_version' for '$DISTRO_NAME'. Minimum supported version is '$min_version'."
        return 1
    fi

    if [[ $(id -u) -ne 0 ]]; then
        local xdg_current_desktop=${XDG_CURRENT_DESKTOP:-$(echo $DESKTOP_SESSION)}

        log_info "The desktop environment is: '$xdg_current_desktop'"
        
        if [[ "$xdg_current_desktop" != "GNOME" && "$xdg_current_desktop" != "ubuntu:GNOME" ]]; then
            log_error "Unsupported desktop environment: '$xdg_current_desktop'. Only GNOME is supported."
            return 1
        fi
    else
        log_debug "Execution takes place with sudo, therefore the desktop environment cannot be determined."
    fi
}