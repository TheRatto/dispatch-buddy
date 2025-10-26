import 'lib/services/bom_radar_service.dart';

void main() {
  print('🎯 Testing Sydney BOM URL Generation');
  print('====================================');
  
  const baseSiteId = '71'; // Sydney
  const range = '128km';
  
  // Test BOM product ID generation
  final bomSiteId = BomRadarService.getBomSiteId(baseSiteId, range);
  print('Base Site ID: $baseSiteId');
  print('Range: $range');
  print('BOM Product ID: $bomSiteId');
  
  // Generate expected remote URLs
  const transparencyBaseUrl = 'https://reg.bom.gov.au/products/radar_transparencies/';
  
  final remoteBackground = '${transparencyBaseUrl}$bomSiteId.background.png';
  final remoteLocations = '${transparencyBaseUrl}$bomSiteId.locations.png';
  final remoteTopography = '${transparencyBaseUrl}$bomSiteId.topography.png';
  final remoteRange = '${transparencyBaseUrl}$bomSiteId.range.png';
  final remoteLegend = '${transparencyBaseUrl}IDR.legend.0.png';
  
  print('\nRemote URLs (fallback):');
  print('  Background:  $remoteBackground');
  print('  Locations:   $remoteLocations');
  print('  Topography:  $remoteTopography');
  print('  Range:       $remoteRange');
  print('  Legend:      $remoteLegend');
  
  // Test radar site lookup
  final site = BomRadarService.findRadarSite(baseSiteId);
  if (site != null) {
    print('\nSydney Radar Site Info:');
    print('  Name: ${site.name}');
    print('  Location: ${site.location}');
    print('  State: ${site.state}');
    print('  Available Ranges: ${site.availableRanges}');
    print('  Supports $range: ${site.supportsRange(range)}');
  }
}
