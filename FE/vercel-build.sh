#!/usr/bin/env bash
set -e

echo "=== MedsReminder Flutter Web Build on Vercel ==="

# Check if flutter is already cached or in PATH
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Installing Flutter SDK (channel stable)..."
  if [ ! -d "$HOME/flutter" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  fi
  export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version
flutter config --no-analytics

echo "Getting Flutter dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release

echo "Build completed successfully!"
