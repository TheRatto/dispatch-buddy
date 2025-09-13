#!/bin/bash

# Create Android app icons from logo
echo "🔧 Creating Android app icons..."

# Input logo
LOGO="assets/images/logo.png"
ANDROID_RES_DIR="android/app/src/main/res"

# Check if logo exists
if [ ! -f "$LOGO" ]; then
    echo "❌ Logo not found at $LOGO"
    exit 1
fi

# Function to create icon with specific size
create_android_icon() {
    local size=$1
    local density=$2
    local filename=$3
    
    echo "Creating $filename (${size}x${size}) for $density"
    
    # Create directory if it doesn't exist
    mkdir -p "$ANDROID_RES_DIR/$density"
    
    # Use ImageMagick to resize to square by cropping to center and removing alpha channel
    magick "$LOGO" -resize ${size}x${size}^ -gravity center -extent ${size}x${size} -background white -alpha remove "$ANDROID_RES_DIR/$density/$filename"
}

# Create all required Android icon sizes
create_android_icon 48 "mipmap-mdpi" "ic_launcher.png"
create_android_icon 72 "mipmap-hdpi" "ic_launcher.png"
create_android_icon 96 "mipmap-xhdpi" "ic_launcher.png"
create_android_icon 144 "mipmap-xxhdpi" "ic_launcher.png"
create_android_icon 192 "mipmap-xxxhdpi" "ic_launcher.png"

echo "✅ Android app icons created successfully!"
