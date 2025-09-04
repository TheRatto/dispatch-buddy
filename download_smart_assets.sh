#!/bin/bash

echo "🎯 Starting smart radar assets download..."

USER_AGENT="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
ACCEPT_HEADER="Accept: image/png,image/*;q=0.8,*/*;q=0.5"
BASE_URL="https://www.bom.gov.au/products/radar_transparencies/"

SUCCESS_COUNT=0
FAIL_COUNT=0

# Function to download asset if it doesn't exist locally
download_asset() {
    local site_id="$1"
    local site_name="$2"
    local range="$3"
    local layer_type="$4"  # "background" or "locations"
    
    # Calculate BOM product ID
    local range_suffix
    case "$range" in
        "64km") range_suffix="4" ;;
        "128km") range_suffix="3" ;;
        "256km") range_suffix="2" ;;
        "512km") range_suffix="1" ;;
    esac
    
    local padded_id=$(printf "%02d" "$site_id")
    local bom_product_id="IDR${padded_id}${range_suffix}"
    local url="${BASE_URL}${bom_product_id}.${layer_type}.png"
    local target_path="assets/radar_layers/sites/${site_name}/${range}/${layer_type}.png"
    
    # Create directory if needed
    mkdir -p "$(dirname "$target_path")"
    
    echo "    📥 $layer_type ($range)..."
    if curl -s -H "$USER_AGENT" -H "$ACCEPT_HEADER" "$url" -o "$target_path"; then
        if file "$target_path" | grep -q "PNG image data"; then
            local size=$(du -h "$target_path" | cut -f1)
            echo "    ✅ $layer_type ($size)"
            SUCCESS_COUNT=$((SUCCESS_COUNT+1))
            return 0
        else
            echo "    ❌ $layer_type (not available)"
            rm "$target_path" 2>/dev/null
            FAIL_COUNT=$((FAIL_COUNT+1))
            return 1
        fi
    else
        echo "    ❌ $layer_type (curl error)"
        FAIL_COUNT=$((FAIL_COUNT+1))
        return 1
    fi
}

# Process each site with a focused list (known working sites)
echo "📊 Processing key radar sites with smart range detection..."
echo ""

# Start with a few key sites for testing
KEY_SITES=(
    "71:sydney"
    "2:melbourne" 
    "24:bowen"
    "40:canberra"
    "19:cairns"
)

for site_entry in "${KEY_SITES[@]}"; do
    IFS=':' read -r site_id site_name <<< "$site_entry"
    echo "🎯 Processing $site_name (Site $site_id)"
    
    # Try all ranges, but handle failures gracefully
    for range in "64km" "128km" "256km" "512km"; do
        echo "  📡 Testing $range range..."
        
        # Download both background and locations
        download_asset "$site_id" "$site_name" "$range" "background"
        download_asset "$site_id" "$site_name" "$range" "locations"
        
        sleep 0.5  # Rate limiting
    done
    echo ""
done

echo "🎉 Smart download complete!"
echo "✅ Successful downloads: $SUCCESS_COUNT"
echo "❌ Failed downloads: $FAIL_COUNT"

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "📁 Asset size so far:"
    du -sh assets/radar_layers/ 2>/dev/null || echo "Directory not found"
fi

echo ""
echo "💡 This was a test run with key sites. Ready to expand to all sites?"
