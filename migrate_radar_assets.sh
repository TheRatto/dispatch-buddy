#!/bin/bash

# Radar Assets Migration Script
# Migrates from: assets/radar_layers/sites/{site}/{range}/{layer}.png
# To: assets/radar_layers/{layer}s/{site}_{range}.png

set -e  # Exit on any error

echo "🔄 Starting Radar Assets Migration..."
echo "=================================="

# Create new directory structure
echo "📁 Creating new directory structure..."
mkdir -p assets/radar_layers/backgrounds
mkdir -p assets/radar_layers/locations  
mkdir -p assets/radar_layers/topography
mkdir -p assets/radar_layers/common

# Counter for progress tracking
total_files=0
migrated_files=0

echo "📊 Counting total files to migrate..."
total_files=$(find assets/radar_layers/sites -name "*.png" | wc -l)
echo "Found $total_files files to migrate"

echo ""
echo "🔄 Migrating files..."

# Migrate background files
echo "  📍 Migrating background files..."
for file in assets/radar_layers/sites/*/256km/background.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/256km/background.png|\1|')
    cp "$file" "assets/radar_layers/backgrounds/${site}_256km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/128km/background.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/128km/background.png|\1|')
    cp "$file" "assets/radar_layers/backgrounds/${site}_128km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/64km/background.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/64km/background.png|\1|')
    cp "$file" "assets/radar_layers/backgrounds/${site}_64km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/512km/background.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/512km/background.png|\1|')
    cp "$file" "assets/radar_layers/backgrounds/${site}_512km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

# Migrate locations files
echo "  📍 Migrating locations files..."
for file in assets/radar_layers/sites/*/256km/locations.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/256km/locations.png|\1|')
    cp "$file" "assets/radar_layers/locations/${site}_256km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/128km/locations.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/128km/locations.png|\1|')
    cp "$file" "assets/radar_layers/locations/${site}_128km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/64km/locations.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/64km/locations.png|\1|')
    cp "$file" "assets/radar_layers/locations/${site}_64km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/512km/locations.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/512km/locations.png|\1|')
    cp "$file" "assets/radar_layers/locations/${site}_512km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

# Migrate topography files
echo "  📍 Migrating topography files..."
for file in assets/radar_layers/sites/*/256km/topography.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/256km/topography.png|\1|')
    cp "$file" "assets/radar_layers/topography/${site}_256km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/128km/topography.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/128km/topography.png|\1|')
    cp "$file" "assets/radar_layers/topography/${site}_128km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/64km/topography.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/64km/topography.png|\1|')
    cp "$file" "assets/radar_layers/topography/${site}_64km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

for file in assets/radar_layers/sites/*/512km/topography.png; do
  if [ -f "$file" ]; then
    site=$(echo "$file" | sed 's|assets/radar_layers/sites/\([^/]*\)/512km/topography.png|\1|')
    cp "$file" "assets/radar_layers/topography/${site}_512km.png"
    migrated_files=$((migrated_files + 1))
  fi
done

# Migrate common files
echo "  📍 Migrating common files..."
if [ -d "assets/radar_layers/common" ]; then
  cp -r assets/radar_layers/common/* assets/radar_layers/common/ 2>/dev/null || true
fi

# Special case for National radar
if [ -f "assets/radar_layers/sites/national/National/background.png" ]; then
  cp "assets/radar_layers/sites/national/National/background.png" "assets/radar_layers/backgrounds/national_National.png"
  migrated_files=$((migrated_files + 1))
fi

echo ""
echo "📊 Migration Summary:"
echo "===================="
echo "Total files found: $total_files"
echo "Files migrated: $migrated_files"

# Verify migration
echo ""
echo "🔍 Verifying migration..."
background_count=$(find assets/radar_layers/backgrounds -name "*.png" | wc -l)
locations_count=$(find assets/radar_layers/locations -name "*.png" | wc -l)
topography_count=$(find assets/radar_layers/topography -name "*.png" | wc -l)

echo "Background files: $background_count"
echo "Locations files: $locations_count"
echo "Topography files: $topography_count"

echo ""
echo "✅ Migration completed successfully!"
echo ""
echo "Next steps:"
echo "1. Update pubspec.yaml with new asset declarations"
echo "2. Update RadarAssetsService code"
echo "3. Test the app"
echo "4. Remove old assets/radar_layers/sites/ directory"
