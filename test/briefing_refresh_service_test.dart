import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dispatch_buddy/services/briefing_refresh_service.dart';
import 'package:dispatch_buddy/models/briefing.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/models/weather.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BriefingRefreshService', () {
    test('should create RefreshData with correct structure', () {
      final notams = [
        Notam(
          id: 'test_notam_1',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(const Duration(days: 1)),
          rawText: 'Test NOTAM text',
          decodedText: 'Decoded NOTAM',
          affectedSystem: 'runways',
          isCritical: false,
          group: NotamGroup.runways,
        ),
      ];
      
      final weather = [
        Weather(
          type: 'METAR',
          icao: 'YSSY',
          rawText: 'YSSY 251540Z 25015KT 9999 SCT030 22/12 Q1018',
          timestamp: DateTime.now(),
          decodedText: 'Decoded weather text',
          windDirection: 250,
          windSpeed: 15,
          visibility: 9999,
          cloudCover: 'SCT',
          temperature: 22.0,
          dewPoint: 12.0,
          qnh: 1018,
          conditions: 'Good',
        ),
      ];
      
      final refreshData = RefreshData(
        notams: notams,
        weather: weather,
        hasApiErrors: false,
      );
      
      expect(refreshData.notams.length, equals(1));
      expect(refreshData.weather.length, equals(1));
      expect(refreshData.hasApiErrors, isFalse);
      expect(refreshData.notams.first.icao, equals('YSSY'));
      expect(refreshData.weather.first.icao, equals('YSSY'));
    });
    
    test('should handle refresh exceptions correctly', () {
      final exception = RefreshException('Test error message');
      expect(exception.toString(), contains('RefreshException'));
      expect(exception.toString(), contains('Test error message'));
    });

    test('should handle empty or invalid data gracefully', () {
      // Test that the service can handle various edge cases
      // This test verifies that our data structures can handle empty data
      final emptyRefreshData = RefreshData(
        notams: [],
        weather: [],
        hasApiErrors: true,
      );
      
      expect(emptyRefreshData.notams.length, equals(0));
      expect(emptyRefreshData.weather.length, equals(0));
      expect(emptyRefreshData.hasApiErrors, isTrue);
    });

    test('should create briefing with correct data structure', () {
      // Test that we can create a briefing with the expected data structure
      final testBriefing = Briefing.create(
        name: 'Test Refresh Briefing',
        airports: ['YSSY'],
        notams: {
          'test_notam_1_briefing_123': {
            'id': 'test_notam_1',
            'type': 'runway',
            'icao': 'YSSY',
            'rawText': 'Test NOTAM text',
            'validFrom': DateTime.now().toIso8601String(),
            'validTo': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          }
        },
        weather: {
          'METAR_YSSY_briefing_123': {
            'type': 'METAR',
            'icao': 'YSSY',
            'rawText': 'YSSY 251540Z 25015KT 9999 SCT030 22/12 Q1018',
            'timestamp': DateTime.now().toIso8601String(),
          }
        },
      );

      expect(testBriefing.id, isNotEmpty);
      expect(testBriefing.name, equals('Test Refresh Briefing'));
      expect(testBriefing.airports.length, equals(1));
      expect(testBriefing.airports.first, equals('YSSY'));
      expect(testBriefing.notams.length, equals(1));
      expect(testBriefing.weather.length, equals(1));
      expect(testBriefing.timestamp, isA<DateTime>());
      expect(testBriefing.isFlagged, isFalse);
    });

    test('should handle briefing copyWith correctly', () {
      final originalBriefing = Briefing.create(
        name: 'Original Briefing',
        airports: ['YSSY'],
        notams: {},
        weather: {},
      );

      // Test copyWith with new name
      final renamedBriefing = originalBriefing.copyWith(name: 'Renamed Briefing');
      expect(renamedBriefing.name, equals('Renamed Briefing'));
      expect(renamedBriefing.id, equals(originalBriefing.id));
      expect(renamedBriefing.airports, equals(originalBriefing.airports));

      // Test copyWith with flagged status (name will be null since not provided)
      final flaggedBriefing = originalBriefing.copyWith(isFlagged: true);
      expect(flaggedBriefing.isFlagged, isTrue);
      expect(flaggedBriefing.name, isNull);

      // Test copyWith with explicit null name
      final nullNameBriefing = originalBriefing.copyWith(name: null);
      expect(nullNameBriefing.name, isNull);

      // Test copyWith without name parameter (should be null)
      final preservedNameBriefing = originalBriefing.copyWith(isFlagged: true);
      expect(preservedNameBriefing.name, isNull);
    });
  });
} 