/// Service for managing local radar layer assets
class RadarAssetsService {
  /// Maps radar site ID to local asset directory name
  static const Map<String, String> _siteIdToDirectory = {
    // NSW
    '93': 'brewarrina',
    '40': 'canberra', 
    '28': 'grafton',
    '94': 'hillston',
    '53': 'moree',
    '69': 'namoi',
    '4': 'newcastle',
    '71': 'sydney',
    '55': 'wagga-wagga',
    '3': 'wollongong',
    '96': 'yeoval',
    '62': 'norfolk-island',
    
    // VIC
    '68': 'bairnsdale',
    '2': 'melbourne',
    '97': 'mildura',
    '95': 'rainbow',
    '49': 'yarrawonga',
    
    // QLD
    '24': 'bowen',
    '50': 'brisbane-marburg',
    '66': 'brisbane-stapylton',
    '19': 'cairns',
    '72': 'emerald',
    '23': 'gladstone',
    '74': 'greenvale',
    '36': 'gulf-carpentaria',
    '8': 'gympie',
    '56': 'longreach',
    '22': 'mackay',
    '75': 'mount-isa',
    '107': 'richmond',
    '98': 'taroom',
    '108': 'toowoomba',
    '106': 'townsville',
    '67': 'warrego',
    '78': 'weipa',
    
    // WA
    '31': 'albany',
    '17': 'broome',
    '5': 'carnarvon',
    '15': 'dampier',
    '12': 'derby',
    '57': 'esperance',
    '6': 'geraldton',
    '39': 'halls-creek',
    '16': 'kalgoorlie',
    '29': 'learmonth',
    '48': 'marble-bar',
    '58': 'newdegate',
    '1': 'perth',
    '79': 'watheroo',
    '7': 'wyndham',
    
    // SA
    '64': 'adelaide-buckland',
    '46': 'adelaide-sellicks',
    '33': 'ceduna',
    '14': 'mount-gambier',
    '80': 'woomera',
    
    // TAS
    '76': 'hobart',
    
    // NT
    '25': 'alice-springs',
    '63': 'darwin',
    '112': 'gove',
    '42': 'katherine',
    '77': 'warruwi',
  };

  /// Get local asset path for background layer (range-specific)
  static String? getBackgroundAssetPath(String siteId, String range) {
    // Special handling for National radar
    if (siteId == '00' && range == 'National') {
      return 'assets/radar_layers/backgrounds/national_National.png';
    }
    
    final dirName = _siteIdToDirectory[siteId];
    if (dirName == null) return null;
    return 'assets/radar_layers/backgrounds/${dirName}_$range.png';
  }

  /// Get local asset path for locations layer (range-specific)  
  static String? getLocationsAssetPath(String siteId, String range) {
    final dirName = _siteIdToDirectory[siteId];
    if (dirName == null) return null;
    return 'assets/radar_layers/locations/${dirName}_$range.png';
  }

  /// Get local asset path for topography layer (range-specific)
  static String? getTopographyAssetPath(String siteId, String range) {
    final dirName = _siteIdToDirectory[siteId];
    if (dirName == null) return null;
    return 'assets/radar_layers/topography/${dirName}_$range.png';
  }

  /// Get local asset path for range circles
  static String getRangeAssetPath(String range) {
    // Convert range format from "256km" to "256.range"
    final rangeNumber = range.replaceAll('km', '');
    return 'assets/radar_layers/common/ranges/$rangeNumber.range.png';
  }

  /// Get local asset path for legend
  static String getLegendAssetPath() {
    return 'assets/radar_layers/common/legend/standard.png';
  }

  /// Check if site has local assets available
  static bool hasLocalAssets(String siteId) {
    return _siteIdToDirectory.containsKey(siteId);
  }

  /// Get directory name for site ID  
  static String? getDirectoryName(String siteId) {
    return _siteIdToDirectory[siteId];
  }

  /// Get all available site IDs with local assets
  static List<String> getAvailableSiteIds() {
    return _siteIdToDirectory.keys.toList();
  }
}
