#!/bin/bash
set -e

echo "Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter Web with base-href /app/..."
flutter build web --release --base-href /app/

echo "Restructuring build output..."
# Copy Flutter build to a temp location to avoid circular copy
cp -r build/web /tmp/flutter_web_build

# Clean and recreate the app subfolder
rm -rf build/web
mkdir -p build/web/app

# Move Flutter build into /app/
cp -r /tmp/flutter_web_build/* build/web/app/
rm -rf /tmp/flutter_web_build

echo "Setting up landing page at root..."
cp web/landing.html build/web/index.html
cp web/landing.html build/web/landing.html

# Copy favicon and icons for landing page
cp web/favicon.png build/web/favicon.png 2>/dev/null || true
cp -r web/icons build/web/icons 2>/dev/null || true

echo ""
echo "✅ Build complete! Final structure:"
echo "   build/web/index.html      → Landing Page (trokeeper.tnb.io.vn/)"
echo "   build/web/landing.html    → Landing Page alias"
echo "   build/web/app/index.html  → Flutter App  (trokeeper.tnb.io.vn/app/)"
