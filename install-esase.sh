#!/bin/bash

# DESCRIPTION:
# This script (un)installs 'esase'.
# To uninstall, call this script with the argument 'undo'.


DEPENDENCIES_TO_BE_INSTALLED="jq yad xrandr" # 'pkexec' is normally preinstalled


# # # # # # # # # # # #|# # # # # # # # # # # #
#                 DIRECTORIES                 #
# # # # # # # # # # # #|# # # # # # # # # # # #

CURRENT_SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Default directories
SOURCES_DIR="$CURRENT_SCRIPT_DIR/sources"
SCRIPTS_DIR="$CURRENT_SCRIPT_DIR/scripts"

# Directories for installation
LOCAL_BIN_DIR="/usr/local/bin"              # script 'esase.sh'
LOCAL_ETC_DIR="/usr/local/etc/esase"        # dir    'lang'
LOCAL_SHARE_DIR="/usr/local/share/esase"    # dirs   'scripts' & 'sources' | image 'esase-icon.png'
VAR_LIB_DIR="/var/lib/esase"                # dir    'config'

# Directory for .desktop files (current user)
DESKTOP_FILES_DIR="$HOME/.local/share/applications"


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SOURCES                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

SOURCE_FILES=(
    "logger.sh"
    "general/preparations.sh"
    "helper/system_validation.sh"
)

for source_file in "${SOURCE_FILES[@]}"; do
    source "$SOURCES_DIR/$source_file" || { echo "Error: Could not source '$source_file' for '$0'."; exit 1; }
done


# # # # # # # # # # # #|# # # # # # # # # # # #
#                   SCRIPTS                   #
# # # # # # # # # # # #|# # # # # # # # # # # #

DISTRO_BASED_ACTIONS_SCRIPT="$SCRIPTS_DIR/distro_based_actions.sh"


# # # # # # # # # # # #|# # # # # # # # # # # #
#         OVERWRITING LOGGING VARIABLES       #
# # # # # # # # # # # #|# # # # # # # # # # # #

ENABLE_DEBUG_LOGGING=false
ENABLE_GUI_FOR_LOGGING=false


# # # # # # # # # # # #|# # # # # # # # # # # #
#             INSTALL FUNCTIONALITY           #
# # # # # # # # # # # #|# # # # # # # # # # # #

copy_desktop_file() {
    local desktop_dir="$CURRENT_SCRIPT_DIR/desktop"
    local desktop_file="$desktop_dir/esase.desktop"
    local destination="$DESKTOP_FILES_DIR/esase.desktop"

    if [[ -f "$desktop_file" ]]; then
        if [[ -f "$destination" ]]; then
            log_warning "Desktop file '$destination' already exists. Skipping copy."
        else
            cp "$desktop_file" "$DESKTOP_FILES_DIR/"
            log_info "Successfully copied '$desktop_file' to '$DESKTOP_FILES_DIR/'."
        fi
    else
        log_warning "Desktop file '$desktop_file' does not exist."
    fi

    log_info "If the icon is not displayed directly: Log out and log in again or restart."
}

install_esase() {
    local script_file="$CURRENT_SCRIPT_DIR/esase.sh"

    local config_dir="$CURRENT_SCRIPT_DIR/config"
    local lang_dir="$CURRENT_SCRIPT_DIR/lang"
    local scripts_dir="$CURRENT_SCRIPT_DIR/scripts"
    local sources_dir="$CURRENT_SCRIPT_DIR/sources"
    local desktop_dir="$CURRENT_SCRIPT_DIR/desktop"

    local icon_file="$desktop_dir/esase-icon.png"

    # Directories to copy
    declare -A directories=(
        ["$config_dir"]="$VAR_LIB_DIR/config"
        ["$lang_dir"]="$LOCAL_ETC_DIR/lang"
        ["$scripts_dir"]="$LOCAL_SHARE_DIR/scripts"
        ["$sources_dir"]="$LOCAL_SHARE_DIR/sources"
    )

    # Check if 'esase' is already installed
    if [[ -f "$LOCAL_BIN_DIR/esase.sh" ]]; then
        copy_desktop_file
        log_error "'esase' is already installed. Installation aborted!"
    fi

    # Create directories and copy files
    for src_dir in "${!directories[@]}"; do
        local dest_dir="${directories[$src_dir]}"

        # Create destination directory if it doesn't exist
        sudo mkdir -p "$dest_dir"

        # Copy files
        if sudo cp -r "$src_dir/"* "$dest_dir/"; then
            log_info "Successfully copied '$src_dir' to '$dest_dir'."
        else
            log_error "Failed to copy '$src_dir' to '$dest_dir'."
        fi

        # List contents of the copied directory
        log_info "Contents of '$dest_dir':"
        ls -larth "$dest_dir"

        # Make scripts executable
        if [[ "$dest_dir" == "$LOCAL_SHARE_DIR/scripts" ]]; then
            sudo chmod +x "$dest_dir/"*
            log_info "Made scripts in '$dest_dir' executable."
        fi
    done

    # Copy the main script to /usr/local/bin
    if sudo cp "$script_file" "$LOCAL_BIN_DIR/esase.sh"; then
        sudo chmod +x "$LOCAL_BIN_DIR/esase.sh"
        log_info "Successfully copied '$script_file' to '$LOCAL_BIN_DIR/esase.sh'."
    else
        log_error "Failed to copy '$script_file' to '$LOCAL_BIN_DIR/esase.sh'."
    fi

    # Copy the icon file
    if [[ -f "$icon_file" ]]; then
        sudo cp "$icon_file" "$LOCAL_SHARE_DIR/esase-icon.png"
        log_info "Successfully copied '$icon_file' to '$LOCAL_SHARE_DIR/esase-icon.png'."
    else
        log_warning "Icon file '$icon_file' does not exist."
    fi

    # Copy the desktop file
    copy_desktop_file

    # Set permissions for /var/lib/esase/config
    if [[ -d "$VAR_LIB_DIR/config" ]]; then
        sudo chmod -R 777 "$VAR_LIB_DIR/config"
        log_info "Set permissions for '$VAR_LIB_DIR/config' and its subdirectories to '777', so that configuration files can be edited by all."
    else
        log_warning "'$VAR_LIB_DIR/config' directory does not exist."
    fi

    # Create a symbolic link for 'esase' to point to 'esase.sh'
    # This makes it possible to run 'esase' instead of 'esase.sh' directly.
    sudo ln -s $LOCAL_BIN_DIR/esase.sh $LOCAL_BIN_DIR/esase
    ls -larth $LOCAL_BIN_DIR

    log_info "Installation complete."
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#            UNINSTALL FUNCTIONALITY          #
# # # # # # # # # # # #|# # # # # # # # # # # #

uninstall_esase() {
    local script_file="$LOCAL_BIN_DIR/esase.sh"
    local symlink="$LOCAL_BIN_DIR/esase"
    local desktop_file="$DESKTOP_FILES_DIR/esase.desktop"

    # Check if 'esase' is installed
    if [[ ! -f "$script_file" ]]; then
        log_warning "'esase' is not installed or already uninstalled. Checking and removing artefacts..."
    fi

    # Remove the symbolic link
    if [[ -L "$symlink" ]]; then
        sudo rm "$symlink"
        log_info "Removed symbolic link '$symlink'."
    else
        log_warning "No symbolic link found at '$symlink'."
    fi

    # Remove the main script
    if [[ -f "$script_file" ]]; then
        sudo rm "$script_file"
        log_info "Removed script '$script_file'."
    else
        log_warning "No script found at '$script_file'."
    fi

    # Directories to remove with contents
    declare -A directories=(
        ["$LOCAL_ETC_DIR"]="$LOCAL_ETC_DIR"
        ["$LOCAL_SHARE_DIR"]="$LOCAL_SHARE_DIR"
        ["$VAR_LIB_DIR"]="$VAR_LIB_DIR"
    )

    # Remove directories with their contents
    for dir in "${!directories[@]}"; do
        # Debug output to show directories to be checked
        log_debug "Checking directory '$dir' for removal."

        # Check if the directory exists
        if [[ -d "$dir" ]]; then
            log_info "Contents of '$dir':"
            ls -larth "$dir"

            # Remove the directory and its contents
            sudo rm -rf "$dir"
            log_info "Removed directory '$dir' and its contents."
        else
            log_warning "No directory found at '$dir'."
        fi
    done

    # Remove the desktop file
    if [[ -f "$desktop_file" ]]; then
        rm "$desktop_file"
        log_info "Removed desktop file '$desktop_file'."
    else
        log_warning "No desktop file found at '$desktop_file'."
    fi

    log_info "Uninstallation complete."
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#           PROMPTS USER FOR YES/NO           #
# # # # # # # # # # # #|# # # # # # # # # # # #

# Prompts user, returns 0 (yes) or 1 (no)
prompt_user() {
    local prompt="$1"
    local response

    read -r -p "$prompt [y/n]: " response
    case "$response" in
        [Yy]* ) return 0 ;;  # Yes
        [Nn]* ) return 1 ;;  # No
        * ) log_warning "Please answer yes or no." && return 1 ;;
    esac
}


# # # # # # # # # # # #|# # # # # # # # # # # #
#                    LOGIC                    #
# # # # # # # # # # # #|# # # # # # # # # # # #

validate_system || log_error "System validation failed. Check the system compatibility!"
log_debug "The following Linux distribution is used to perform actions: '$DISTRO_NAME'"

log_debug "$PATH"

show_log_file

check_scripts_and_make_scripts_executable "$DISTRO_BASED_ACTIONS_SCRIPT" || log_error "Validation for scripts and their executability failed!"

case "$1" in
    undo )
        log_info "Uninstall 'esase'..."

        log_debug "Home directory: '$HOME'"

        # Define backup directory
        BACKUP_CONFIG_DIR="$HOME/esase_config_backup/$(date +"%Y-%m-%d_%H-%M-%S")"

        # Create backup directory if it doesn't exist
        log_info "Creating backup directory '$BACKUP_CONFIG_DIR'."
        mkdir -p "$BACKUP_CONFIG_DIR" || log_error "Failed to create backup directory '$BACKUP_CONFIG_DIR'."

        # Backup to the newly created backup directory
        log_info "Backing up '$VAR_LIB_DIR/config' to '$BACKUP_CONFIG_DIR'."
        sudo cp -r "$VAR_LIB_DIR/config" "$BACKUP_CONFIG_DIR" && log_info "Backup completed successfully. You can find your 'esase' backup under '$BACKUP_CONFIG_DIR'" || log_error "Backup failed."

        # Change ownership of the backup directory to the current user
        log_info "Changing ownership of '$BACKUP_CONFIG_DIR' to the current user."
        sudo chown -R "$USER:$USER" "$BACKUP_CONFIG_DIR" || log_error "Failed to change ownership of '$BACKUP_CONFIG_DIR'."

        uninstall_esase

        # Prompt user for dependency removal
        if prompt_user "Do you want to remove the following dependencies: $DEPENDENCIES_TO_BE_INSTALLED?"; then
            sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a remove -r "$DEPENDENCIES_TO_BE_INSTALLED" || log_error "Uninstallation of dependencies ($DEPENDENCIES_TO_BE_INSTALLED) failed!"
        else
            log_info "Skipping removal of dependencies."
        fi
        ;;
    * )
        log_info "Install 'esase'..."

        # Prompt user for dependency install
        if prompt_user "Do you want to install the required dependencies: $DEPENDENCIES_TO_BE_INSTALLED?"; then
            sudo "$DISTRO_BASED_ACTIONS_SCRIPT" -d "$ENABLE_DEBUG_LOGGING" -a install -i "$DEPENDENCIES_TO_BE_INSTALLED" || log_error "Installation of required dependencies ($DEPENDENCIES_TO_BE_INSTALLED) failed!"
        else
            log_error "Installation aborted!"
        fi

        install_esase
        ;;
esac

chmod -x "$DISTRO_BASED_ACTIONS_SCRIPT"

log_info "'$SIMPLE_SCRIPT_NAME' finished."

exit 0