#!/bin/bash

# --- Environment Setup Script for submission_reminder_app (Updated Structure) ---

echo "Enter your name to personalize the application directory:"
read USER_NAME
DIR_NAME="submission_reminder_${USER_NAME//[[:space:]]/_}"

if mkdir "$DIR_NAME"; then
    echo "Created main application directory: $DIR_NAME"
else
    echo "Error: Could not create directory $DIR_NAME. Exiting."
    exit 1
fi

cd "$DIR_NAME" || { echo "Error: Failed to enter directory $DIR_NAME. Exiting."; exit 1; }

# 2. Create the necessary subdirectories: app, modules, assets, config, logs
mkdir -p app modules assets config logs
echo "Created subdirectories: app, modules, assets, config, logs"

# 3. Populate the 'config/config.env' file
CONFIG_FILE="config/config.env"
cat << EOF > "$CONFIG_FILE"
# Configuration settings for the Submission Reminder App
# The ASSIGNMENT value is checked against the submissions.txt file
ASSIGNMENT=Assignment1
DATA_FILE=assets/submissions.txt
LOG_FILE=logs/reminder.log
EOF
echo "Created and populated $CONFIG_FILE"

# 4. Populate the 'assets/submissions.txt' file (Updated path)
DATA_FILE="assets/submissions.txt"
cat << EOF > "$DATA_FILE"
Student_ID,Name,Assignment1,Assignment2,Assignment3
S001,Alice,Submitted,Pending,Submitted
S002,Bob,Pending,Submitted,Pending
S003,Charlie,Submitted,Pending,Submitted
S004,Diana,Pending,Pending,Pending
S005,Ethan,Submitted,Submitted,Submitted
S006,Fiona,Pending,Submitted,Pending
S007,George,Submitted,Pending,Submitted
S008,Hannah,Pending,Submitted,Pending
S009,Ivy,Submitted,Submitted,Submitted
S010,Jack,Pending,Pending,Submitted
EOF
echo "Created and populated $DATA_FILE with at least 5 additional records"

# 5. Populate the 'modules/functions.sh' file (Updated path)
FUNCTIONS_FILE="modules/functions.sh"
cat << 'EOF' > "$FUNCTIONS_FILE"
#!/bin/bash
# ... (contents of functions.sh remain the same) ...
# [Note: The internal code of functions.sh does not require changes 
# as it relies on exported variables like $DATA_FILE and $LOG_FILE]

# Function to check if a file exists
check_file_exists() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo "Error: Configuration file not found at $file_path"
        exit 1
    fi
}
# ... (rest of functions.sh code) ...
load_config() {
    local config_file="$1"
    check_file_exists "$config_file"
    while IFS='=' read -r key value; do
        if [[ ! "$key" =~ ^# && -n "$key" ]]; then
            export "$key"="$value"
        fi
    done < "$config_file"
}
# ... (rest of functions.sh code - log_message and process_submissions) ...
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

process_submissions() {
    log_message "Starting submission check for assignment: $ASSIGNMENT"
    
    check_file_exists "$DATA_FILE"

    local header_line
    IFS=$',' read -r -a header_line <<< "$(head -n 1 "$DATA_FILE")"
    
    local assignment_index=-1
    for i in "${!header_line[@]}"; do
        if [[ "${header_line[$i]}" == "$ASSIGNMENT" ]]; then
            assignment_index=$i
            break
        fi
    done

    if [[ "$assignment_index" -eq -1 ]]; then
        log_message "Error: Assignment '$ASSIGNMENT' column not found in $DATA_FILE."
        return 1
    fi
    return 0
}

EOF
echo "Created and populated $FUNCTIONS_FILE"


# 6. Populate the 'app/reminder.sh' file (Final, Robust Version)
REMINDER_FILE="app/reminder.sh"
cat << 'EOF' > "$REMINDER_FILE"
#!/bin/bash

# Find the directory where this script is located.
SCRIPT_DIR=$(dirname "$0")

# Source the function files using a path relative to this script.
FUNCTIONS_FILE="$SCRIPT_DIR/../modules/functions.sh"

if [[ ! -f "$FUNCTIONS_FILE" ]]; then
    echo "Error: Functions file not found at $FUNCTIONS_FILE"
    exit 1
fi
source "$FUNCTIONS_FILE"

# Load the configuration file to get the initial variable values.
CONFIG_FILE="$SCRIPT_DIR/../config/config.env"
load_config "$CONFIG_FILE"


# --- FIX FOR VARIABLE SCOPE ---
# The variables from config.env (e.g., LOG_FILE=logs/reminder.log) are relative.
# We must convert them into absolute paths so the application works from any directory.
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# Re-export the variables with the full, correct paths.
export LOG_FILE="$PROJECT_ROOT/$LOG_FILE"
export DATA_FILE="$PROJECT_ROOT/$DATA_FILE"

# Now that LOG_FILE is an absolute path, we can safely create its parent directory.
mkdir -p "$(dirname "$LOG_FILE")"

log_message "--- Application Start ---"

# Process submissions. This function will now use the correct DATA_FILE path.
process_submissions

log_message "Running final check and collecting pending students..."

# Get the header line and find the assignment index
header_line=$(head -n 1 "$DATA_FILE")
IFS=',' read -r -a header_cols <<< "$header_line"

assignment_index=-1
for i in "${!header_cols[@]}"; do
    if [[ "${header_cols[$i]}" == "$ASSIGNMENT" ]]; then
        assignment_index=$i
        break
    fi
done

if [[ "$assignment_index" -eq -1 ]]; then
    log_message "Error: Assignment column '$ASSIGNMENT' not found in header."
    exit 1
fi

PENDING_STUDENTS=()
# Use 'tail -n +2' to skip the header, then redirect the output directly to the while loop's standard input.
# This prevents the whole while loop block from being grouped into a subshell if it's the last command.
# This is often the most reliable way to maintain array scope.
while IFS=',' read -r -a student_data; do
    # Check if the status column exists for this row
    if [[ ${#student_data[@]} -gt "$assignment_index" ]]; then
        status="${student_data[$assignment_index]}"
        if [[ "$status" == "Pending" ]]; then
            PENDING_STUDENTS+=("${student_data[1]}") # Add the student's name
        fi
    fi
done < <(tail -n +2 "$DATA_FILE")


if [ ${#PENDING_STUDENTS[@]} -gt 0 ]; then
    echo ""
    log_message "🚨 REMINDER: The following students have not submitted '$ASSIGNMENT':"
    # Use printf for safer array printing
    printf -- "- %s\n" "${PENDING_STUDENTS[@]}"
    echo ""
else
    echo ""
    log_message "✅ All students have submitted '$ASSIGNMENT'."
    echo "✅ All students have submitted '$ASSIGNMENT'."
    echo ""
fi

log_message "--- Application End ---"
EOF
echo "Created and populated $REMINDER_FILE"


# 7. Create the 'startup.sh' script (Robust execution path)
STARTUP_FILE="startup.sh"
cat << 'EOF' > "$STARTUP_FILE"
#!/bin/bash

# Startup script for the Submission Reminder App

# --- Best Practice ---
# Find the directory where this script is located. This makes the script
# runnable from anywhere on the system, not just from its own directory.
SCRIPT_DIR=$(dirname "$0")

echo "Starting Submission Reminder Application..."

# Execute the main reminder script using a path relative to this script's location.
"$SCRIPT_DIR/app/reminder.sh"

echo "Application finished."
EOF
echo "Created $STARTUP_FILE"

# 8. Set executable permissions for all .sh files
find . -type f -name "*.sh" -exec chmod +x {} \;
echo "Set executable permissions for all .sh scripts."

# 9. Return to the original directory
cd ..
echo "Setup complete! Run './$DIR_NAME/startup.sh' to test the application."
