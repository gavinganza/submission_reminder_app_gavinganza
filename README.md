# submission_reminder_app_gavinganza

This repository contains the setup and runner scripts for a submission reminder application.

## The Scripts

1.  `create_environment.sh`: Sets up the application structure, configuration, and data files.
2.  `copilot_shell_script.sh`: Allows a user to change the assignment being checked and reruns the application.

## How to Run

1.  **Setup Environment:** Run the main setup script and enter a suffix when prompted (e.g., 'gavin').
    `./create_environment.sh`

2.  **Initial Check (Assignment 1):** Run the application for the default assignment.
    `./submission_reminder_gavin/startup.sh`

3.  **Update and Rerun (Assignment 2/4):** To check a different assignment, run the copilot script. You must enter the suffix you used in Step 1.
    `./copilot_shell_script.sh`
