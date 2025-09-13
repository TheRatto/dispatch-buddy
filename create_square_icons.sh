#!/bin/bash

# Create properly square app icons
echo "🔧 Creating square app icons..."

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

# Function to create square icon with specific size
create_square_icon() {
    local size=$1
    local filename=$2
    
    echo "Creating $filename (${size}x${size})"
    
    # Use ImageMagick to resize to square by cropping to center and removing alpha channel
    magick "$LOGO" -resize ${size}x${size}^ -gravity center -extent ${size}x${size} -background white -alpha remove "$OUTPUT_DIR/$filename"
}

# Create all required icon sizes as perfect squares
create_square_icon 20 "Icon-App-20x20@1x.png"
create_square_icon 40 "Icon-App-20x20@2x.png"
create_square_icon 60 "Icon-App-20x20@3x.png"
create_square_icon 29 "Icon-App-29x29@1x.png"
create_square_icon 58 "Icon-App-29x29@2x.png"
create_square_icon 87 "Icon-App-29x29@3x.png"
create_square_icon 40 "Icon-App-40x40@1x.png"
create_square_icon 80 "Icon-App-40x40@2x.png"
create_square_icon 120 "Icon-App-40x40@3x.png"
create_square_icon 60 "Icon-App-60x60@2x.png"
create_square_icon 180 "Icon-App-60x60@3x.png"
create_square_icon 76 "Icon-App-76x76@1x.png"
create_square_icon 152 "Icon-App-76x76@2x.png"
create_square_icon 167 "Icon-App-83.5x83.5@2x.png"
create_square_icon 1024 "Icon-App-1024x1024@1x.png"

echo "✅ Square app icons created successfully!"

# Verify the 1024x1024 icon
echo "🔍 Verifying 1024x1024 icon..."
sips -g pixelWidth -g pixelHeight "$OUTPUT_DIR/Icon-App-1024x1024@1x.png"
sips -g hasAlpha "$OUTPUT_DIR/Icon-App-1024x1024@1x.png"

echo "📋 Created icons:"
ls -la "$OUTPUT_DIR"/*.png
