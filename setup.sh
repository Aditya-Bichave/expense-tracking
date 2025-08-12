#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. INSTALL ANDROID SDK ---
echo "--- Setting up Android SDK ---"
# Define paths within the user's home directory (no sudo required)
export ANDROID_HOME="$HOME/android-sdk"
ANDROID_CMDLINE_TOOLS_VERSION="11076708" 

# Create directories for the SDK
mkdir -p "$ANDROID_HOME/cmdline-tools"

# Download and unzip Android command-line tools
wget "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -O android-tools.zip
unzip -q android-tools.zip -d "$ANDROID_HOME/cmdline-tools"
# The tools unzip to a folder named 'cmdline-tools'. We need to move its contents to a 'latest' directory.
mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
rm android-tools.zip

# Add Android SDK tools to the shell's PATH for this session
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Accept all SDK licenses automatically
echo "--- Accepting Android SDK licenses ---"
yes | sdkmanager --licenses > /dev/null

# Install required SDK packages
echo "--- Installing Android SDK platform-tools and build-tools ---"
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null


# --- 2. INSTALL FLUTTER SDK ---
echo "--- Setting up Flutter SDK ---"
FLUTTER_VERSION="3.22.2"
FLUTTER_HOME="$HOME/flutter"

# Clone the Flutter repository from GitHub
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git --branch "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi

# Add Flutter to the shell's PATH for this session
export PATH="$PATH:$FLUTTER_HOME/bin"

# Switch to the stable channel to ensure consistency
echo "--- Configuring Flutter channel ---"
flutter channel stable
flutter upgrade

# Tell Flutter where to find the Android SDK
echo "--- Configuring Flutter to use the installed Android SDK ---"
flutter config --android-sdk "$ANDROID_HOME"

# --- 3. SETUP THE FLUTTER PROJECT ---

git clone https://github.com/Aditya-Bichave/expense-tracking.git

echo "--- Navigating to project directory and installing dependencies ---"
cd /app/expense-tracking

flutter pub get

echo "--- Running build_runner for code generation ---"
flutter pub run build_runner build --delete-conflicting-outputs


# --- 4. FINAL VERIFICATION ---
echo "--- Verifying final environment with flutter doctor ---"
flutter doctor

echo "--- Environment setup complete! ---"