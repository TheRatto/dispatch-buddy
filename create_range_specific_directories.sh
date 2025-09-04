#!/bin/bash

# Create range-specific directory structure for radar assets
echo "🏗️ Creating range-specific radar asset directories..."

# List of site directories (human-readable names)
SITES=(
    # NSW
    brewarrina canberra grafton hillston moree namoi newcastle 
    sydney wagga-wagga wollongong yeoval norfolk-island
    
    # VIC  
    bairnsdale melbourne mildura rainbow yarrawonga
    
    # QLD
    bowen brisbane-marburg brisbane-stapylton cairns emerald gladstone
    greenvale gulf-carpentaria gympie longreach mackay mount-isa
    richmond taroom toowoomba townsville warrego weipa
    
    # WA
    albany broome carnarvon dampier derby esperance geraldton
    halls-creek kalgoorlie learmonth marble-bar newdegate
    perth watheroo wyndham
    
    # SA
    adelaide-buckland adelaide-sellicks ceduna mount-gambier woomera
    
    # TAS
    hobart
    
    # NT
    alice-springs darwin gove katherine warruwi
)

# Ranges to create for each site
RANGES=(64km 128km 256km 512km)

# Create base directory
mkdir -p assets/radar_layers/sites

# Create range subdirectories for each site
for site in "${SITES[@]}"; do
    echo "📁 Creating directories for $site..."
    for range in "${RANGES[@]}"; do
        mkdir -p "assets/radar_layers/sites/$site/$range"
    done
done

echo "✅ Created directories for ${#SITES[@]} sites × ${#RANGES[@]} ranges = $((${#SITES[@]} * ${#RANGES[@]})) total directories"
echo "🎯 Ready for range-specific asset downloads!"
