#!/bin/bash

# Create only the icons required by Contents.json
echo "🔧 Creating required app icons..."

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
    
    # Use ImageMagick to resize and remove alpha channel by compositing on white background
    magick "$LOGO" -resize ${size}x${size} -background white -alpha remove "$OUTPUT_DIR/$filename"
}

# Create only the icons referenced in Contents.json
create_icon 20 "Icon-App-20x20@1x.png"
create_icon 40 "Icon-App-20x20@2x.png"
create_icon 60 "Icon-App-20x20@3x.png"
create_icon 29 "Icon-App-29x29@1x.png"
create_icon 58 "Icon-App-29x29@2x.png"
create_icon 87 "Icon-App-29x29@3x.png"
create_icon 40 "Icon-App-40x40@1x.png"
create_icon 80 "Icon-App-40x40@2x.png"
create_icon 120 "Icon-App-40x40@3x.png"
create_icon 60 "Icon-App-60x60@2x.png"
create_icon 180 "Icon-App-60x60@3x.png"
create_icon 76 "Icon-App-76x76@1x.png"
create_icon 152 "Icon-App-76x76@2x.png"
create_icon 167 "Icon-App-83.5x83.5@2x.png"
create_icon 1024 "Icon-App-1024x1024@1x.png"

echo "✅ Required app icons created successfully!"

# Verify the 1024x1024 icon (most important for App Store)
echo "🔍 Verifying 1024x1024 icon..."
sips -g hasAlpha "$OUTPUT_DIR/Icon-App-1024x1024@1x.png"

echo "📋 Created icons:"
ls -la "$OUTPUT_DIR"/*.png
