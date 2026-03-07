#!/bin/bash

# run_e2e.sh — Bash wrapper for run_e2e.bat or native bash E2E runner for Windows Git Bash

# Detect if we are in Git Bash / WSL
OS_TYPE="native"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="windows_bash"
fi

echo "--- Detected OS Type: $OS_TYPE ---"

if [[ "$OS_TYPE" == "windows_bash" ]]; then
    # In Git Bash on Windows, easiest is to call the .bat using cmd /c
    # But we need to convert the path to windows style if needed
    echo "Running run_e2e.bat via cmd..."
    cmd //c "run_e2e.bat $@"
else
    # Native Linux/macOS implementation (for later if needed)
    echo "Native Bash E2E runner (Linux/macOS) not yet fully implemented."
    echo "Please use run_e2e.bat on Windows."
    exit 1
fi
