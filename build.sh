#!/bin/bash
echo "Cloning Flutter stable..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

echo "Adding Flutter to PATH..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter pub get..."
flutter pub get

echo "Building Flutter Web into /app/ subfolder..."
flutter build web --release --base-href /app/

echo "Moving Flutter build into /app/ subfolder..."
mkdir -p build/web/app
cp -r build/web/* build/web/app/ 2>/dev/null || true
# Remove the app folder from inside itself (avoid recursion)
rm -rf build/web/app/app

echo "Copying landing page to root..."
cp web/landing.html build/web/index.html
cp web/landing.html build/web/landing.html
cp web/favicon.png build/web/favicon.png 2>/dev/null || true
cp -r web/icons build/web/icons 2>/dev/null || true

echo "Build complete! Structure:"
echo "  / → landing page"
echo "  /app/ → Flutter app"
