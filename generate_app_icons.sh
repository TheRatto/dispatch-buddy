#!/bin/bash

# Briefing Buddy App Icon Generator
# This script generates all required app icon sizes from logo.png

echo "🚀 Generating Briefing Buddy App Icons..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ Error: ImageMagick is not installed."
    echo "Please install ImageMagick first:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    exit 1
fi

# Check if logo.png exists
if [ ! -f "assets/images/logo.png" ]; then
    echo "❌ Error: logo.png not found in assets/images/"
    exit 1
fi

# Create output directories
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset
mkdir -p macos/Runner/Assets.xcassets/AppIcon.appiconset

echo "📱 Generating iOS App Icons..."

# iOS App Icon sizes
convert assets/images/logo.png -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
convert assets/images/logo.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
convert assets/images/logo.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png

convert assets/images/logo.png -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
convert assets/images/logo.png -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
convert assets/images/logo.png -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png

convert assets/images/logo.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
convert assets/images/logo.png -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
convert assets/images/logo.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png

convert assets/images/logo.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
convert assets/images/logo.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png

convert assets/images/logo.png -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
convert assets/images/logo.png -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png

convert assets/images/logo.png -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png

convert assets/images/logo.png -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

echo "🖥️  Generating macOS App Icons..."

# macOS App Icon sizes
convert assets/images/logo.png -resize 16x16 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
convert assets/images/logo.png -resize 32x32 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
convert assets/images/logo.png -resize 64x64 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
convert assets/images/logo.png -resize 128x128 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
convert assets/images/logo.png -resize 256x256 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
convert assets/images/logo.png -resize 512x512 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
convert assets/images/logo.png -resize 1024x1024 macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png

echo "✅ App icons generated successfully!"
echo ""
echo "📱 iOS icons: ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo "🖥️  macOS icons: macos/Runner/Assets.xcassets/AppIcon.appiconset/"
echo ""
echo "🎯 Next steps:"
echo "1. Run 'flutter clean && flutter pub get'"
echo "2. Test the app to see the new icons"
echo "3. Commit the changes to git" 