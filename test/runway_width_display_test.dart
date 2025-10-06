import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:briefing_buddy/providers/settings_provider.dart';
import 'package:briefing_buddy/models/airport_infrastructure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Runway Width Display Tests', () {
    test('should format width in meters correctly', () async {
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Test with YAMB runway width (45 meters)
      final widthMeters = 45.0;
      final formattedWidth = settingsProvider.formatWidth(widthMeters);
      
      // Width should always be in meters, regardless of runway length units setting
      expect(formattedWidth, equals('45'));
    });
    
    test('should format width in meters regardless of length units', () async {
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Set to feet for runway length
      await settingsProvider.setRunwayUnits(Units.feet);
      
      // Test with YAMB runway width (45 meters)
      final widthMeters = 45.0;
      final formattedWidth = settingsProvider.formatWidth(widthMeters);
      
      // Width should always be in meters, even when length is in feet
      expect(formattedWidth, equals('45'));
    });
    
    test('should handle zero width gracefully', () {
      final settingsProvider = SettingsProvider();
      
      final formattedWidth = settingsProvider.formatWidth(0.0);
      
      // Should return empty string for zero width
      expect(formattedWidth, equals(''));
    });
    
    test('should handle negative width gracefully', () {
      final settingsProvider = SettingsProvider();
      
      final formattedWidth = settingsProvider.formatWidth(-10.0);
      
      // Should return empty string for negative width
      expect(formattedWidth, equals(''));
    });
    
    test('should provide correct unit symbol', () async {
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Default should be feet
      expect(settingsProvider.unitSymbol, equals('ft'));
      
      // Change to meters
      await settingsProvider.setRunwayUnits(Units.meters);
      expect(settingsProvider.unitSymbol, equals('m'));
      
      // Change back to feet
      await settingsProvider.setRunwayUnits(Units.feet);
      expect(settingsProvider.unitSymbol, equals('ft'));
    });
    
    test('should format YAMB runway data correctly', () async {
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Set to meters for runway length
      await settingsProvider.setRunwayUnits(Units.meters);
      
      // Create a runway with YAMB data (length in feet, width in meters)
      final runway = Runway(
        identifier: '15/33',
        length: 10000.0, // 10,000 feet (from JSON)
        width: 45.0,     // 45 meters (from JSON)
        surface: 'Asphalt',
        approaches: [],
        hasLighting: true,
      );
      
      // Test length formatting (10,000ft = 3,048m)
      final formattedLength = settingsProvider.formatLength(runway.length);
      expect(formattedLength, equals('3,048')); // Should be 3,048 meters
      
      // Test width formatting (always in meters)
      final formattedWidth = settingsProvider.formatWidth(runway.width);
      expect(formattedWidth, equals('45')); // Should be 45 meters
    });
    
    test('should show YAMB runway length in feet by default', () async {
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Set to feet for runway length (default)
      await settingsProvider.setRunwayUnits(Units.feet);
      
      // Create a runway with YAMB data (length in feet, width in meters)
      final runway = Runway(
        identifier: '15/33',
        length: 10000.0, // 10,000 feet (from JSON)
        width: 45.0,     // 45 meters (from JSON)
        surface: 'Asphalt',
        approaches: [],
        hasLighting: true,
      );
      
      // Test length formatting (show feet as-is)
      final formattedLength = settingsProvider.formatLength(runway.length);
      expect(formattedLength, equals('10,000'));
      
      // Test width formatting (always in meters)
      final formattedWidth = settingsProvider.formatWidth(runway.width);
      expect(formattedWidth, equals('45'));
    });
  });
} 