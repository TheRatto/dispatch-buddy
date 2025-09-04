import 'lib/services/radar_assets_service.dart';

void main() {
  print('🎯 Testing Sydney Radar Asset Paths');
  print('=====================================');
  
  const siteId = '71'; // Sydney
  const range = '128km'; // As shown in the image
  
  // Test asset path generation
  final backgroundPath = RadarAssetsService.getBackgroundAssetPath(siteId, range);
  final locationsPath = RadarAssetsService.getLocationsAssetPath(siteId, range);
  final topographyPath = RadarAssetsService.getTopographyAssetPath(siteId, range);
  final legendPath = RadarAssetsService.getLegendAssetPath();
  final rangePath = RadarAssetsService.getRangeAssetPath(range);
  
  print('Sydney (ID: $siteId) $range Assets:');
  print('  Background:  $backgroundPath');
  print('  Locations:   $locationsPath');
  print('  Topography:  $topographyPath');
  print('  Legend:      $legendPath');
  print('  Range:       $rangePath');
  
  print('\n✅ All asset paths generated successfully!');
  
  // Test directory mapping
  final dirName = RadarAssetsService.getDirectoryName(siteId);
  final hasAssets = RadarAssetsService.hasLocalAssets(siteId);
  
  print('\nSite Info:');
  print('  Directory:   $dirName');
  print('  Has Assets:  $hasAssets');
}
