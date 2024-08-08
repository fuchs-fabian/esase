#!/bin/bash

# DESCRIPTION:
# This script uninstalls 'esase' by calling the install script with 'undo'.


INSTALL_SCRIPT="./install-esase.sh"

# Check if the install script exists
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
    echo "ERROR: The main script '$INSTALL_SCRIPT' was not found."
    exit 1
fi

# Make the install script executable
chmod +x "$INSTALL_SCRIPT"

# Call the install script with 'undo'
"$INSTALL_SCRIPT" undo

# Check if the uninstallation was successful
if [[ $? -eq 0 ]]; then
    echo "Uninstallation of 'esase' completed successfully."
else
    echo "ERROR: Uninstallation of 'esase' failed."
    exit 1
fi

# Make the install script non-executable
chmod -x "$INSTALL_SCRIPT"

exit 0