#!/bin/bash

# Download all radar layer assets with proper browser headers
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
ACCEPT_HEADER="image/png,image/*;q=0.8,*/*;q=0.5"

echo "🎯 Starting radar assets download..."

# Function to download with retry and validation
download_asset() {
    local url="$1"
    local output="$2" 
    local description="$3"
    
    echo "📥 Downloading $description..."
    curl -H "User-Agent: $USER_AGENT" \
         -H "Accept: $ACCEPT_HEADER" \
         -s "$url" \
         -o "$output"
    
    # Check if we got a valid PNG file
    if file "$output" | grep -q "PNG image data"; then
        local size=$(ls -lah "$output" | awk '{print $5}')
        echo "✅ $description ($size)"
        return 0
    else
        echo "❌ $description - Got HTML error page"
        rm -f "$output"
        return 1
    fi
}

# Function to get BOM product ID from base site ID and range
get_bom_id() {
    local base_id="$1"
    local range="$2"
    
    # Pad to 2 digits and add prefix/suffix based on range
    local padded_id=$(printf "%02d" "$base_id")
    
    case "$range" in
        "64km")  echo "IDR${padded_id}4" ;;
        "128km") echo "IDR${padded_id}3" ;;
        "256km") echo "IDR${padded_id}2" ;;
        "512km") echo "IDR${padded_id}1" ;;
        *)       echo "IDR${padded_id}2" ;;  # Default to 256km
    esac
}

# Download background and location layers for each site
declare -A site_mapping=(
    # NSW
    ["93"]="brewarrina" ["40"]="canberra" ["28"]="grafton" ["94"]="hillston" 
    ["53"]="moree" ["69"]="namoi" ["4"]="newcastle" ["71"]="sydney"
    ["55"]="wagga-wagga" ["3"]="wollongong" ["96"]="yeoval" ["62"]="norfolk-island"
    
    # VIC  
    ["68"]="bairnsdale" ["2"]="melbourne" ["97"]="mildura" ["95"]="rainbow" ["49"]="yarrawonga"
    
    # QLD
    ["24"]="bowen" ["50"]="brisbane-marburg" ["66"]="brisbane-stapylton" ["19"]="cairns"
    ["72"]="emerald" ["23"]="gladstone" ["74"]="greenvale" ["36"]="gulf-carpentaria"
    ["8"]="gympie" ["56"]="longreach" ["22"]="mackay" ["75"]="mount-isa"
    ["107"]="richmond" ["98"]="taroom" ["108"]="toowoomba" ["106"]="townsville"
    ["67"]="warrego" ["76"]="weipa"
    
    # WA
    ["31"]="albany" ["17"]="broome" ["5"]="carnarvon" ["15"]="dampier"
    ["12"]="derby" ["57"]="esperance" ["6"]="geraldton" ["39"]="halls-creek"
    ["16"]="kalgoorlie" ["29"]="learmonth" ["48"]="marble-bar" ["58"]="newdegate"
    ["1"]="perth" ["79"]="watheroo" ["7"]="wyndham"
    
    # SA
    ["64"]="adelaide-buckland" ["46"]="adelaide-sellicks" ["33"]="ceduna" 
    ["14"]="mount-gambier" ["80"]="woomera"
    
    # TAS
    ["76"]="hobart"
    
    # NT  
    ["25"]="alice-springs" ["63"]="darwin" ["112"]="gove" ["42"]="katherine" ["77"]="warruwi"
)

success_count=0
error_count=0

echo "📊 Downloading assets for ${#site_mapping[@]} radar sites..."

for site_id in "${!site_mapping[@]}"; do
    dir_name="${site_mapping[$site_id]}"
    bom_id=$(get_bom_id "$site_id" "256km")
    
    echo ""
    echo "🎯 Processing $dir_name (Site $site_id -> $bom_id)"
    
    # Download background layer
    bg_url="https://www.bom.gov.au/products/radar_transparencies/${bom_id}.background.png"
    bg_output="assets/radar_layers/sites/${dir_name}/background.png"
    
    if download_asset "$bg_url" "$bg_output" "Background ($dir_name)"; then
        ((success_count++))
    else
        ((error_count++))
    fi
    
    # Download locations layer  
    loc_url="https://www.bom.gov.au/products/radar_transparencies/${bom_id}.locations.png"
    loc_output="assets/radar_layers/sites/${dir_name}/locations.png"
    
    if download_asset "$loc_url" "$loc_output" "Locations ($dir_name)"; then
        ((success_count++))
    else
        ((error_count++))
    fi
    
    # Small delay to be respectful to BOM servers
    sleep 0.5
done

echo ""
echo "🎉 Download complete!"
echo "✅ Successful downloads: $success_count"
echo "❌ Failed downloads: $error_count"
echo ""
echo "📁 Total asset size:"
du -sh assets/radar_layers/
