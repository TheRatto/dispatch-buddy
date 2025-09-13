#!/bin/bash

# Fix app icons by removing alpha channel and creating proper sizes
echo "🔧 Fixing app icons..."

# Input logo
LOGO="assets/images/logo.png"
OUTPUT_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Check if logo exists
if [ ! -f "$LOGO" ]; then
    echo "❌ Logo not found at $LOGO"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to create icon with specific size
create_icon() {
    local size=$1
    local filename=$2
    
    echo "Creating $filename (${size}x${size})"
    
    # Use sips to resize and remove alpha channel
    sips -s format png -s formatOptions default -z $size $size "$LOGO" --out "$OUTPUT_DIR/$filename"
    
    # Remove alpha channel by converting to RGB
    sips -s format png -s formatOptions default -s hasAlpha NO "$OUTPUT_DIR/$filename" --out "$OUTPUT_DIR/$filename"
}

# Create all required icon sizes
create_icon 20 "Icon-App-20x20@1x.png"
create_icon 40 "Icon-App-20x20@2x.png"
create_icon 60 "Icon-App-20x20@3x.png"
create_icon 29 "Icon-App-29x29@1x.png"
create_icon 58 "Icon-App-29x29@2x.png"
create_icon 87 "Icon-App-29x29@3x.png"
create_icon 40 "Icon-App-40x40@1x.png"
create_icon 80 "Icon-App-40x40@2x.png"
create_icon 120 "Icon-App-40x40@3x.png"
create_icon 50 "Icon-App-50x50@1x.png"
create_icon 57 "Icon-App-57x57@1x.png"
create_icon 114 "Icon-App-57x57@2x.png"
create_icon 60 "Icon-App-60x60@2x.png"
create_icon 180 "Icon-App-60x60@3x.png"
create_icon 72 "Icon-App-72x72@1x.png"
create_icon 76 "Icon-App-76x76@1x.png"
create_icon 152 "Icon-App-76x76@2x.png"
create_icon 167 "Icon-App-83.5x83.5@2x.png"
create_icon 1024 "Icon-App-1024x1024@1x.png"

echo "✅ App icons created successfully!"
echo "✅ All icons are now RGB (no alpha channel)"

# Verify the 1024x1024 icon (most important for App Store)
echo "🔍 Verifying 1024x1024 icon..."
sips -g hasAlpha "$OUTPUT_DIR/Icon-App-1024x1024@1x.png"
