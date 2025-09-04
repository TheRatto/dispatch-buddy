#!/bin/bash

# NSW radar sites
mkdir -p assets/radar_layers/sites/{brewarrina,canberra,grafton,hillston,moree,namoi,newcastle,sydney,wagga-wagga,wollongong,yeoval,norfolk-island}

# VIC radar sites  
mkdir -p assets/radar_layers/sites/{bairnsdale,melbourne,mildura,rainbow,yarrawonga}

# QLD radar sites (already created some, but completing the list)
mkdir -p assets/radar_layers/sites/{bowen,brisbane-marburg,brisbane-stapylton,cairns,emerald,gladstone,greenvale,gulf-carpentaria,gympie,longreach,mackay,mount-isa,richmond,taroom,toowoomba,townsville,warrego,weipa}

# WA radar sites
mkdir -p assets/radar_layers/sites/{albany,broome,carnarvon,dampier,derby,esperance,geraldton,halls-creek,kalgoorlie,learmonth,marble-bar,newdegate,perth,watheroo,wyndham}

# SA radar sites  
mkdir -p assets/radar_layers/sites/{adelaide-buckland,adelaide-sellicks,ceduna,mount-gambier,woomera}

# TAS radar sites
mkdir -p assets/radar_layers/sites/{hobart}

# NT radar sites
mkdir -p assets/radar_layers/sites/{alice-springs,darwin,gove,katherine,warruwi}

echo "All radar site directories created!"
