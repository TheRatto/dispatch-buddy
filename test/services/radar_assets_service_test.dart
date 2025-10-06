import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/radar_assets_service.dart';

void main() {
  group('RadarAssetsService', () {
    test('should return correct background asset path for Sydney', () {
      final path = RadarAssetsService.getBackgroundAssetPath('71', '256km');
      expect(path, equals('assets/radar_layers/sites/sydney/256km/background.png'));
    });

    test('should return correct locations asset path for Melbourne', () {
      final path = RadarAssetsService.getLocationsAssetPath('2', '128km');
      expect(path, equals('assets/radar_layers/sites/melbourne/128km/locations.png'));
    });

    test('should return correct background asset path for National radar', () {
      final path = RadarAssetsService.getBackgroundAssetPath('00', 'National');
      expect(path, equals('assets/radar_layers/sites/national/National/background.png'));
    });

    test('should return null for non-existent site', () {
      final path = RadarAssetsService.getBackgroundAssetPath('999', '256km');
      expect(path, isNull);
    });

    test('should return correct range asset path', () {
      final path = RadarAssetsService.getRangeAssetPath('256km');
      expect(path, equals('assets/radar_layers/common/ranges/256km.png'));
    });

    test('should return correct legend asset path', () {
      final path = RadarAssetsService.getLegendAssetPath();
      expect(path, equals('assets/radar_layers/common/legend/standard.png'));
    });

    test('should check if site has local assets', () {
      expect(RadarAssetsService.hasLocalAssets('71'), isTrue); // Sydney
      expect(RadarAssetsService.hasLocalAssets('2'), isTrue);  // Melbourne
      expect(RadarAssetsService.hasLocalAssets('999'), isFalse); // Non-existent
    });

    test('should get directory name for site ID', () {
      expect(RadarAssetsService.getDirectoryName('71'), equals('sydney'));
      expect(RadarAssetsService.getDirectoryName('2'), equals('melbourne'));
      expect(RadarAssetsService.getDirectoryName('999'), isNull);
    });

    test('should get all available site IDs', () {
      final siteIds = RadarAssetsService.getAvailableSiteIds();
      expect(siteIds, contains('71')); // Sydney
      expect(siteIds, contains('2'));  // Melbourne
      expect(siteIds.length, greaterThan(50)); // Should have many sites
    });
  });
}
