#!/bin/bash

# Script to update the assignment name in the configuration and rerun the app.

echo "--- Copilot Assignment Updater ---"

# --- Configuration ---

# 1. Prompt the user for the name suffix used during setup.
echo "Enter the name/suffix used during the initial setup (e.g., yve):"
read DIR_SUFFIX

# 2. Construct the dynamic directory path.
APP_DIR="submission_reminder_$DIR_SUFFIX"
CONFIG_FILE="$APP_DIR/config/config.env"
STARTUP_SCRIPT="$APP_DIR/startup.sh"

# --- Main Logic ---

# 1. Check if the application directory exists
if [ ! -d "$APP_DIR" ]; then
    echo "Error: Application directory '$APP_DIR' not found."
    echo "Did you enter the correct suffix? Please run create_environment.sh first."
    exit 1
fi

# 2. Prompt for the new assignment name
echo "Enter the new assignment name (e.g., Assignment2 or Assignment4):"
read NEW_ASSIGNMENT

# Basic input validation
if [ -z "$NEW_ASSIGNMENT" ]; then
    echo "Error: Assignment name cannot be empty. Exiting."
    exit 1
fi

# 3. Update the config/config.env file using sed
echo "Updating $CONFIG_FILE to set ASSIGNMENT=$NEW_ASSIGNMENT..."

# Use sed to find the line starting with ASSIGNMENT= and replace the whole line.
sed -i.bak '/^ASSIGNMENT=/c\ASSIGNMENT='$NEW_ASSIGNMENT $CONFIG_FILE

# Check if sed was successful
if [ $? -eq 0 ]; then
    echo "Successfully updated ASSIGNMENT to '$NEW_ASSIGNMENT'."
    # Remove the backup file created by sed -i.bak
    rm -f "$CONFIG_FILE.bak"
else
    echo "Error: Failed to update the configuration file."
    exit 1
fi

# 4. Rerun the application
echo ""
echo "Rerunning the submission reminder application to check the new assignment..."
"$STARTUP_SCRIPT"

echo "--- Copilot Script Finished ---"
