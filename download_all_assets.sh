#!/bin/bash

echo "🎯 Starting FULL radar assets download for all sites..."

USER_AGENT="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
ACCEPT_HEADER="Accept: image/png,image/*;q=0.8,*/*;q=0.5"
BASE_URL="https://www.bom.gov.au/products/radar_transparencies/"

SUCCESS_COUNT=0
FAIL_COUNT=0
SITE_COUNT=0

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
    
    # Skip if already exists
    if [ -f "$target_path" ]; then
        echo "    ⏭️  $layer_type ($range) - already exists"
        return 0
    fi
    
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

# All radar sites with their IDs and names
ALL_SITES=(
    # NSW
    "93:brewarrina" "40:canberra" "28:grafton" "94:hillston" "53:moree" 
    "69:namoi" "4:newcastle" "71:sydney" "55:wagga-wagga" "3:wollongong" 
    "96:yeoval" "62:norfolk-island"
    
    # VIC
    "68:bairnsdale" "2:melbourne" "97:mildura" "95:rainbow" "49:yarrawonga"
    
    # QLD
    "24:bowen" "50:brisbane-marburg" "66:brisbane-stapylton" "19:cairns"
    "72:emerald" "23:gladstone" "74:greenvale" "36:gulf-carpentaria"
    "8:gympie" "56:longreach" "22:mackay" "75:mount-isa" "107:richmond"
    "98:taroom" "108:toowoomba" "106:townsville" "67:warrego" "78:weipa"
    "41:willis-island" "104:yarraman"
    
    # WA
    "31:albany" "17:broome" "114:carnarvon" "15:dampier" "12:derby"
    "32:esperance" "6:geraldton" "39:halls-creek" "48:kalgoorlie"
    "29:learmonth" "48:marble-bar" "58:newdegate" "1:perth" "79:watheroo" "7:wyndham"
    
    # SA
    "64:adelaide-buckland" "46:adelaide-sellicks" "33:ceduna" "14:mount-gambier" "27:woomera"
    
    # TAS
    "76:hobart" "52:northwest-tasmania"
    
    # NT
    "25:alice-springs" "63:darwin" "112:gove" "42:katherine" "77:warruwi"
)

echo "📊 Processing ${#ALL_SITES[@]} radar sites across Australia..."
echo "⏱️  Estimated time: 8-12 minutes (with rate limiting)"
echo ""

for site_entry in "${ALL_SITES[@]}"; do
    IFS=':' read -r site_id site_name <<< "$site_entry"
    SITE_COUNT=$((SITE_COUNT+1))
    
    echo "🎯 [$SITE_COUNT/${#ALL_SITES[@]}] Processing $site_name (Site $site_id)"
    
    # Try all ranges, handle failures gracefully
    for range in "64km" "128km" "256km" "512km"; do
        echo "  📡 Testing $range range..."
        
        # Download both background and locations
        download_asset "$site_id" "$site_name" "$range" "background"
        download_asset "$site_id" "$site_name" "$range" "locations"
        
        # Brief pause between downloads to be respectful
        sleep 0.3
    done
    
    # Progress update every 10 sites
    if [ $((SITE_COUNT % 10)) -eq 0 ]; then
        echo ""
        echo "📈 Progress: $SITE_COUNT/${#ALL_SITES[@]} sites complete"
        echo "✅ Successful: $SUCCESS_COUNT | ❌ Failed: $FAIL_COUNT"
        echo ""
    fi
done

echo ""
echo "🎉 FULL download complete!"
echo "📊 Final Results:"
echo "   🏢 Sites processed: $SITE_COUNT"
echo "   ✅ Successful downloads: $SUCCESS_COUNT"
echo "   ❌ Failed downloads: $FAIL_COUNT"

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "📁 Total asset size:"
    du -sh assets/radar_layers/
    echo ""
    echo "📈 Assets by site (top 10):"
    du -sh assets/radar_layers/sites/* | sort -hr | head -10
fi

echo ""
echo "🚀 Ready to integrate with RadarAssetsService!"

