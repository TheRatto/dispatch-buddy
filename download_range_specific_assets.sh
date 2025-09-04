#!/bin/bash

# Download range-specific radar assets from BOM
echo "🎯 Starting range-specific radar assets download..."

USER_AGENT="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
ACCEPT_HEADER="Accept: image/png,image/*;q=0.8,*/*;q=0.5"
BASE_URL="https://www.bom.gov.au/products/radar_transparencies/"

# Function to get site directory name from ID
get_site_name() {
    case "$1" in
        # NSW
        "93") echo "brewarrina" ;;
        "40") echo "canberra" ;;
        "28") echo "grafton" ;;
        "94") echo "hillston" ;;
        "53") echo "moree" ;;
        "69") echo "namoi" ;;
        "4") echo "newcastle" ;;
        "71") echo "sydney" ;;
        "55") echo "wagga-wagga" ;;
        "3") echo "wollongong" ;;
        "96") echo "yeoval" ;;
        "62") echo "norfolk-island" ;;
        # VIC
        "68") echo "bairnsdale" ;;
        "2") echo "melbourne" ;;
        "97") echo "mildura" ;;
        "95") echo "rainbow" ;;
        "49") echo "yarrawonga" ;;
        # QLD
        "24") echo "bowen" ;;
        "50") echo "brisbane-marburg" ;;
        "66") echo "brisbane-stapylton" ;;
        "19") echo "cairns" ;;
        "72") echo "emerald" ;;
        "23") echo "gladstone" ;;
        "74") echo "greenvale" ;;
        "36") echo "gulf-carpentaria" ;;
        "8") echo "gympie" ;;
        "56") echo "longreach" ;;
        "22") echo "mackay" ;;
        "75") echo "mount-isa" ;;
        "107") echo "richmond" ;;
        "98") echo "taroom" ;;
        "108") echo "toowoomba" ;;
        "106") echo "townsville" ;;
        "67") echo "warrego" ;;
        "78") echo "weipa" ;;
        # WA
        "31") echo "albany" ;;
        "17") echo "broome" ;;
        "114") echo "carnarvon" ;;
        "15") echo "dampier" ;;
        "12") echo "derby" ;;
        "32") echo "esperance" ;;
        "6") echo "geraldton" ;;
        "39") echo "halls-creek" ;;
        "48") echo "kalgoorlie" ;;
        "29") echo "learmonth" ;;
        "58") echo "newdegate" ;;
        "1") echo "perth" ;;
        "79") echo "watheroo" ;;
        "7") echo "wyndham" ;;
        # SA
        "64") echo "adelaide-buckland" ;;
        "46") echo "adelaide-sellicks" ;;
        "33") echo "ceduna" ;;
        "14") echo "mount-gambier" ;;
        "27") echo "woomera" ;;
        # TAS
        "76") echo "hobart" ;;
        "52") echo "northwest-tasmania" ;;
        # NT
        "25") echo "alice-springs" ;;
        "63") echo "darwin" ;;
        "112") echo "gove" ;;
        "42") echo "katherine" ;;
        "77") echo "warruwi" ;;
        *) echo "unknown" ;;
    esac
}

# Function to get range suffix
get_range_suffix() {
    case "$1" in
        "64km") echo "4" ;;
        "128km") echo "3" ;;
        "256km") echo "2" ;;
        "512km") echo "1" ;;
        *) echo "2" ;;
    esac
}

# Function to check if site supports 64km
supports_64km() {
    local site_id="$1"
    case "$site_id" in
        "28"|"53"|"62"|"68"|"23"|"36"|"56"|"24"|"78"|"67"|"41"|"39"|"7"|"46"|"14"|"27"|"25"|"42")
            return 1  # false
            ;;
        *)
            return 0  # true
            ;;
    esac
}

SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_DOWNLOADS=0

echo "📊 Downloading assets for ${#SITE_MAP[@]} sites × 4 ranges × 2 layers = $((${#SITE_MAP[@]} * 4 * 2)) total files..."
echo ""

for SITE_ID in "${!SITE_MAP[@]}"; do
    SITE_NAME="${SITE_MAP[$SITE_ID]}"
    echo "🎯 Processing $SITE_NAME (Site $SITE_ID)"
    
    # Determine available ranges for this site
    AVAILABLE_RANGES=("128km" "256km" "512km")
    
    # Check if site supports 64km
    SUPPORTS_64KM=true
    for no_64km_site in "${NO_64KM_SITES[@]}"; do
        if [[ "$SITE_ID" == "$no_64km_site" ]]; then
            SUPPORTS_64KM=false
            break
        fi
    done
    
    if [[ "$SUPPORTS_64KM" == true ]]; then
        AVAILABLE_RANGES=("64km" "128km" "256km" "512km")
    fi
    
    for RANGE in "${AVAILABLE_RANGES[@]}"; do
        RANGE_SUFFIX="${RANGE_MAP[$RANGE]}"
        PADDED_ID=$(printf "%02d" "$SITE_ID")
        BOM_PRODUCT_ID="IDR${PADDED_ID}${RANGE_SUFFIX}"
        
        echo "  📡 Range: $RANGE ($BOM_PRODUCT_ID)"
        
        # Create target directory
        TARGET_DIR="assets/radar_layers/sites/$SITE_NAME/$RANGE"
        mkdir -p "$TARGET_DIR"
        
        # Download background layer
        BACKGROUND_URL="${BASE_URL}${BOM_PRODUCT_ID}.background.png"
        BACKGROUND_PATH="${TARGET_DIR}/background.png"
        
        echo "    📥 Background..."
        if curl -s -H "$USER_AGENT" -H "$ACCEPT_HEADER" "$BACKGROUND_URL" -o "$BACKGROUND_PATH"; then
            if file "$BACKGROUND_PATH" | grep -q "PNG image data"; then
                SIZE=$(du -h "$BACKGROUND_PATH" | cut -f1)
                echo "    ✅ Background ($SIZE)"
                SUCCESS_COUNT=$((SUCCESS_COUNT+1))
            else
                echo "    ❌ Background (HTML error)"
                rm "$BACKGROUND_PATH"
                FAIL_COUNT=$((FAIL_COUNT+1))
            fi
        else
            echo "    ❌ Background (curl error)"
            FAIL_COUNT=$((FAIL_COUNT+1))
        fi
        TOTAL_DOWNLOADS=$((TOTAL_DOWNLOADS+1))
        
        # Download locations layer
        LOCATIONS_URL="${BASE_URL}${BOM_PRODUCT_ID}.locations.png"
        LOCATIONS_PATH="${TARGET_DIR}/locations.png"
        
        echo "    📥 Locations..."
        if curl -s -H "$USER_AGENT" -H "$ACCEPT_HEADER" "$LOCATIONS_URL" -o "$LOCATIONS_PATH"; then
            if file "$LOCATIONS_PATH" | grep -q "PNG image data"; then
                SIZE=$(du -h "$LOCATIONS_PATH" | cut -f1)
                echo "    ✅ Locations ($SIZE)"
                SUCCESS_COUNT=$((SUCCESS_COUNT+1))
            else
                echo "    ❌ Locations (HTML error)"
                rm "$LOCATIONS_PATH"
                FAIL_COUNT=$((FAIL_COUNT+1))
            fi
        else
            echo "    ❌ Locations (curl error)"
            FAIL_COUNT=$((FAIL_COUNT+1))
        fi
        TOTAL_DOWNLOADS=$((TOTAL_DOWNLOADS+1))
        
        # Brief pause between downloads
        sleep 0.3
    done
    
    echo ""
done

echo "🎉 Download complete!"
echo "✅ Successful downloads: $SUCCESS_COUNT/$TOTAL_DOWNLOADS ($(( SUCCESS_COUNT * 100 / TOTAL_DOWNLOADS ))%)"
echo "❌ Failed downloads: $FAIL_COUNT"

# Calculate total size
if [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "📁 Total asset size:"
    du -sh assets/radar_layers/
fi
