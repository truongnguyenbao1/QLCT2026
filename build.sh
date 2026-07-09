#!/bin/bash
echo "Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release
