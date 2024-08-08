#!/bin/bash

# DESCRIPTION:
# This script executes distro based actions.


# TODO: You could go here and make certain things that are duplicated as separate functions. The question is whether this makes sense?


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 DIRECTORIES                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Default directories
SOURCES_DIR="$CURRENT_SCRIPT_DIR/../sources"

# Directories from installation
LOCAL_BIN_DIR="/usr/local/bin"              # script 'esase.sh'
LOCAL_ETC_DIR="/usr/local/etc/esase"        # dir    'lang'
LOCAL_SHARE_DIR="/usr/local/share/esase"    # dirs   'scripts' & 'sources' | image 'esase-icon.png'
VAR_LIB_DIR="/var/lib/esase"                # dir    'config'

set_directories_based_on_location() {
    #echo "CURRENT_SCRIPT_DIR: '$CURRENT_SCRIPT_DIR'"

    if [[ "$CURRENT_SCRIPT_DIR" == "$LOCAL_SHARE_DIR/scripts" ]]; then
        #echo "The current script is located in the correct installation directory."

        SOURCES_DIR="$LOCAL_SHARE_DIR/sources"
    fi

    #echo "SOURCES_DIR: '$SOURCES_DIR'"
}

set_directories_based_on_location


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SOURCES                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

SOURCE_FILES=(
    "logger.sh"
    "helper/system_validation.sh"
)

for source_file in "${SOURCE_FILES[@]}"; do
    source "$SOURCES_DIR/$source_file" || { echo "Error: Could not source '$source_file' for '$0'."; exit 1; }
done


# # # # # # # # # # # #|# # # # # # # # # # # #
#         OVERWRITING LOGGING VARIABLES       #
# # # # # # # # # # # #|# # # # # # # # # # # #

ENABLE_GUI_FOR_LOGGING=false


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 PREPARATIONS                #
# # # # # # # # # # # #|# # # # # # # # # # # #

validate_system || log_error "System validation failed. Check the system compatibility!"
log_debug "The following Linux distribution is used to perform actions: '$DISTRO_NAME'"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   GETOPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

ACTION=""
PACKAGES_TO_INSTALL=""
PACKAGES_TO_REMOVE=""

while getopts ":hd:a:i:r:" opt; do
    case ${opt} in
        h )
            echo "It is recommended to run the script with root rights to ensure that the actions work without requesting these rights."
            echo
            echo "Usage: (sudo) $SIMPLE_SCRIPT_NAME [-h] [-d true/false] [-a ACTION] [-i \"PACKAGE_1 PACKAGE_2 ...\"] [-r \"PACKAGE_1 PACKAGE_2 ...\"]"
            echo "  -h                      Show help"
            echo "  -d true/false           Enables debug logging"
            echo "  -a ACTION               Specify action to perform (install, update-all, remove, replace-terminal, install-advanced-virtualization, install-docker, install-npm)"
            echo "  -i PACKAGES_TO_INSTALL  Specify packages to install (only used with install action)"
            echo "  -r PACKAGES_TO_REMOVE   Specify packages to remove (only used with remove action)"
            exit 0
            ;;
        d ) 
            log_debug "'-d' selected: '$OPTARG'"
            # Overwrites the variable in 'logger.sh'
            ENABLE_DEBUG_LOGGING="${OPTARG}"
            ;;
        a )
            log_debug "'-a' selected: '$OPTARG'"
            ACTION="${OPTARG}"
            ;;
        i )
            log_debug "'-i' selected: '$OPTARG'"
            PACKAGES_TO_INSTALL="${OPTARG}"
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

if [[ -z "$ACTION" ]]; then
    log_error "No action specified. Please provide an action using the -a option."
fi


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   ACTIONS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

install() {
    log_info "Installing packages..."

    if [[ -z "$PACKAGES_TO_INSTALL" ]]; then
        log_warning "No packages for installation specified."
    else
        case "$DISTRO_NAME" in
            ubuntu|debian )
                sudo apt update
                sudo apt install -y $PACKAGES_TO_INSTALL
                ;;
            fedora )
                sudo dnf install -y $PACKAGES_TO_INSTALL
                ;;
        esac
    fi
}

# Here you have to interact with the console. It is not good practice to do this completely automatically
update_all() {
    log_info "Updating all..."

    case "$DISTRO_NAME" in
        ubuntu|debian )
            sudo apt update && sudo apt upgrade
            if dpkg -l | grep -q "npm"; then
                log_info "Updating 'npm'..."
                sudo npm install -g npm@latest || log_error "Failed to update npm."
            fi
            ;;
        fedora )
            sudo dnf upgrade --refresh
            if rpm -q npm &>/dev/null; then
                log_info "Updating 'npm'..."
                sudo npm install -g npm@latest || log_error "Failed to update npm."
            fi
            ;;
    esac

    log_info "Updating 'flatpak' apps..."
    flatpak update
}

# Reference: https://unix.stackexchange.com/questions/691386/remove-preinstalled-gnome-applications
remove() {
    log_info "Removing packages..."

    if [[ -z "$PACKAGES_TO_REMOVE" ]]; then
        log_warning "No packages to remove found."
    else
        case "$DISTRO_NAME" in
            ubuntu|debian )
                sudo apt remove -y $PACKAGES_TO_REMOVE
                ;;
            fedora )
                sudo dnf remove -y $PACKAGES_TO_REMOVE
                ;;
        esac
    fi
}

replace_terminal() {
    log_info "Replacing terminal..."

    case "$DISTRO_NAME" in
        ubuntu|debian )
            sudo apt remove -y gnome-terminal && sudo apt install -y gnome-console
            ;;
        fedora )
            sudo dnf remove -y gnome-terminal && sudo dnf install -y gnome-console
            ;;
    esac
}

install_advanced_virtualization() {
    log_info "Installing advanced virtualization..."

    case "$DISTRO_NAME" in
        ubuntu|debian )
            # TODO: This has not yet been tested. This still needs to be done.

            if egrep -q '^flags.*(vmx|svm)' /proc/cpuinfo; then
                log_debug "CPU supports virtualization. Proceeding with installation..."

                if dpkg-query -W -f='${Status}' virt-manager 2>/dev/null | grep -q "install ok installed"; then
                    log_info "'virt-manager' is already installed."
                else
                    log_info "Installing 'virt-manager' and related packages..."

                    # Install virt-manager and other necessary packages
                    sudo apt-get update
                    sudo apt-get install -y virt-manager qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

                    # Start libvirtd
                    sudo systemctl start libvirtd

                    # Sets the libvirtd service to start on system start
                    sudo systemctl enable libvirtd

                    # Add current user to libvirt group
                    sudo usermod -a -G libvirt $(whoami)
                    sudo usermod -a -G kvm $(whoami)
                fi
            else
                log_warning "This system does not support virtualization (vmx/svm flags not found). Installation aborted."
            fi
            ;;
        fedora )
            # Reference: https://medium.com/@Vashinator/install-virt-manager-on-fedora-5c6b8f6a274b
            if egrep -q '^flags.*(vmx|svm)' /proc/cpuinfo; then
                log_debug "CPU supports virtualization. Proceeding with installation..."

                if rpm -q virt-manager &>/dev/null; then
                    log_info "'virt-manager' is already installed."
                else
                    log_info "Installing 'virt-manager' and related packages..."

                    # Install virt-manager and other necessary packages
                    sudo dnf install @virtualization

                    # Check if these packages are installed
                    #dnf -y install edk2-ovmf swtpm swtpm-tools

                    # with optional packages
                    #sudo dnf group install --with-optional virtualization

                    # Start libvirtd
                    sudo systemctl start libvirtd

                    # Sets the libvirtd service to start on system start
                    sudo systemctl enable libvirtd

                    # Add current user to virt manager group
                    sudo usermod -a -G libvirt $(whoami)
                fi
            else
                log_warning "This system does not support virtualization (vmx/svm flags not found). Installation aborted."
            fi
            ;;
    esac
}

install_docker() {
    log_info "Installing 'docker'..."

    case "$DISTRO_NAME" in
        ubuntu|debian )
            # Reference (Ubuntu): https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
            # Reference (Debian): https://docs.docker.com/engine/install/debian/#install-using-the-repository

            if dpkg -l | grep -q docker-ce; then
                log_info "'docker-ce' is already installed."
                exit 0
            else
                log_info "Docker is not installed. Proceeding with installation..."

                # Add Docker's official GPG key
                sudo apt-get update
                sudo apt-get install ca-certificates curl
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc

                # Add the repository to Apt sources
                echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update

                # Install Docker Engine
                sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            fi

            # Reference for Uninstalling (Ubuntu): https://docs.docker.com/engine/install/ubuntu/#uninstall-docker-engine
            # Reference for Uninstalling (Debian): https://docs.docker.com/engine/install/debian/#uninstall-docker-engine
            ;;
        fedora )
            # Reference: https://docs.docker.com/engine/install/fedora/#install-using-the-repository

            if rpm -q docker-ce &>/dev/null; then
                log_info "'docker-ce' is already installed."
                exit 0
            else
                log_info "Docker is not installed. Proceeding with installation..."

                # Setup the repository (https://docs.docker.com/engine/install/fedora/#set-up-the-repository)
                sudo dnf -y install dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

                # Install Docker Engine (https://docs.docker.com/engine/install/fedora/#install-docker-engine)
                sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            fi

            # Reference for Uninstalling: https://docs.docker.com/engine/install/fedora/#uninstall-docker-engine
            ;;
    esac

    # Start docker
    sudo systemctl start docker

    # Sets the docker service to start on system start
    sudo systemctl enable docker

    # Add current user to docker group
    sudo usermod -a -G docker $(whoami)

    log_info "Testing Docker installation by running 'hello-world' container..."

    if docker run hello-world &>/dev/null; then
        log_info "Docker installation successful. 'hello-world' container ran successfully."
    else
        log_error "Docker installation failed. 'hello-world' container did not run."
    fi
}

install_npm() {
    log_info "Installing 'npm'..."

    case "$DISTRO_NAME" in
        ubuntu|debian )
            if dpkg -l | grep -q "npm"; then
                log_info "'npm' is already installed."
            else
                sudo apt-get update
                sudo apt-get install -y npm || log_error "Failed to install npm."
            fi
            ;;
        fedora )
            if rpm -q npm &>/dev/null; then
                log_info "'npm' is already installed."
            else
                sudo dnf install -y npm || log_error "Failed to install npm."
            fi
            ;;
    esac

    log_info "Updating 'npm' to the latest version..."
    sudo npm install -g npm@latest || log_error "Failed to update npm."

    npm --version
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#                    LOGIC                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

log_info "'$SIMPLE_SCRIPT_NAME_WITHOUT_FILE_EXTENSION' has started."
show_log_file

log_debug "Current user: $(whoami)"

case "$ACTION" in
    install )
        install
        ;;
    update-all )
        update_all
        ;;
    remove )
        remove
        ;;
    replace-terminal)
        replace_terminal
        ;;
    install-advanced-virtualization )
        install_advanced_virtualization
        ;;
    install-docker )
        install_docker
        ;;
    install-npm )
        install_npm
        ;;
    * )
        log_error "Unsupported action: '$ACTION'"
        ;;
esac

exit 0