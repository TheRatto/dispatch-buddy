#!/usr/bin/env python3
"""
Fix app icons by removing alpha channel and creating proper sizes
"""
from PIL import Image
import os

def create_app_icon(input_path, output_dir):
    """Create app icons from logo without alpha channel"""
    
    # Load the original image
    img = Image.open(input_path)
    
    # Convert RGBA to RGB by compositing on white background
    if img.mode == 'RGBA':
        # Create a white background
        background = Image.new('RGB', img.size, (255, 255, 255))
        # Paste the image on white background
        background.paste(img, mask=img.split()[-1])  # Use alpha channel as mask
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Define required icon sizes
    sizes = [
        (20, 20, "Icon-App-20x20@1x.png"),
        (40, 40, "Icon-App-20x20@2x.png"),
        (60, 60, "Icon-App-20x20@3x.png"),
        (29, 29, "Icon-App-29x29@1x.png"),
        (58, 58, "Icon-App-29x29@2x.png"),
        (87, 87, "Icon-App-29x29@3x.png"),
        (40, 40, "Icon-App-40x40@1x.png"),
        (80, 80, "Icon-App-40x40@2x.png"),
        (120, 120, "Icon-App-40x40@3x.png"),
        (50, 50, "Icon-App-50x50@1x.png"),
        (57, 57, "Icon-App-57x57@1x.png"),
        (114, 114, "Icon-App-57x57@2x.png"),
        (60, 60, "Icon-App-60x60@2x.png"),
        (180, 180, "Icon-App-60x60@3x.png"),
        (72, 72, "Icon-App-72x72@1x.png"),
        (76, 76, "Icon-App-76x76@1x.png"),
        (152, 152, "Icon-App-76x76@2x.png"),
        (167, 167, "Icon-App-83.5x83.5@2x.png"),
        (1024, 1024, "Icon-App-1024x1024@1x.png"),
    ]
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate all icon sizes
    for width, height, filename in sizes:
        # Resize image with high quality
        resized = img.resize((width, height), Image.Resampling.LANCZOS)
        
        # Save as PNG without alpha channel
        output_path = os.path.join(output_dir, filename)
        resized.save(output_path, 'PNG', optimize=True)
        print(f"Created {filename} ({width}x{height})")

if __name__ == "__main__":
    input_path = "assets/images/logo.png"
    output_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    
    if os.path.exists(input_path):
        create_app_icon(input_path, output_dir)
        print("✅ App icons created successfully!")
        print("✅ All icons are now RGB (no alpha channel)")
    else:
        print(f"❌ Logo not found at {input_path}")
