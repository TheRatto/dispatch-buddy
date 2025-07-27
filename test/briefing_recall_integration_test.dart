import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../lib/models/briefing.dart';
import '../lib/models/notam.dart';
import '../lib/models/weather.dart';
import '../lib/services/briefing_conversion_service.dart';
import '../lib/services/briefing_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Briefing Recall Integration Tests', () {
    test('should save and recall briefing with NOTAMs and weather', () async {
      // Create a test briefing
      final briefing = Briefing.create(
        airports: ['YSSY', 'YMML'],
        notams: {
          'F1234/25': {
            'id': 'F1234/25',
            'type': 'runway',
            'icao': 'YSSY',
            'rawText': 'TEST NOTAM',
            'decodedText': 'Test NOTAM decoded',
            'validFrom': '2025-01-01T00:00:00.000Z',
            'validTo': '2025-12-31T23:59:59.000Z',
            'affectedSystem': 'RWY',
            'isCritical': true,
            'group': 'runways',
          },
        },
        weather: {
          'METAR_YSSY': {
            'type': 'METAR',
            'icao': 'YSSY',
            'rawText': 'YSSY 251130Z 06006KT 9999 SCT110 09/01 Q1023',
            'decodedText': 'Wind 060° at 6kt, visibility 10km',
            'timestamp': '2025-01-25T11:30:00.000Z',
            'windDirection': 60,
            'windSpeed': 6,
            'visibility': 10,
            'cloudCover': 'SCT',
            'temperature': 9.0,
            'dewPoint': 1.0,
            'qnh': 1023,
            'conditions': 'CAVOK',
          },
        },
      );

      // Save the briefing
      final saveSuccess = await BriefingStorageService.saveBriefing(briefing);
      expect(saveSuccess, isTrue);

      // Load all briefings
      final loadedBriefings = await BriefingStorageService.loadAllBriefings();
      expect(loadedBriefings.length, greaterThan(0));

      // Find our test briefing
      final recalledBriefing = loadedBriefings.firstWhere((b) => b.id == briefing.id);
      expect(recalledBriefing, isNotNull);

      // Convert to flight
      final flight = await BriefingConversionService.briefingToFlight(recalledBriefing);

      // Verify the data was preserved
      expect(flight.notams.length, equals(1));
      expect(flight.weather.length, equals(1));
      expect(flight.notams.first.id, equals('F1234/25'));
      expect(flight.weather.first.icao, equals('YSSY'));
    });

    test('should handle multiple briefings correctly', () async {
      // Create multiple test briefings
      final briefing1 = Briefing.create(
        airports: ['YSSY'],
        notams: {
          'F1234/25': {
            'id': 'F1234/25',
            'type': 'runway',
            'icao': 'YSSY',
            'rawText': 'TEST NOTAM 1',
            'decodedText': 'Test NOTAM 1 decoded',
            'validFrom': '2025-01-01T00:00:00.000Z',
            'validTo': '2025-12-31T23:59:59.000Z',
            'affectedSystem': 'RWY',
            'isCritical': true,
            'group': 'runways',
          },
        },
        weather: {},
      );

      final briefing2 = Briefing.create(
        airports: ['YMML'],
        notams: {},
        weather: {
          'METAR_YMML': {
            'type': 'METAR',
            'icao': 'YMML',
            'rawText': 'YMML 251130Z 06006KT 9999 SCT110 09/01 Q1023',
            'decodedText': 'Wind 060° at 6kt, visibility 10km',
            'timestamp': '2025-01-25T11:30:00.000Z',
            'windDirection': 60,
            'windSpeed': 6,
            'visibility': 10,
            'cloudCover': 'SCT',
            'temperature': 9.0,
            'dewPoint': 1.0,
            'qnh': 1023,
            'conditions': 'CAVOK',
          },
        },
      );

      // Save both briefings
      await BriefingStorageService.saveBriefing(briefing1);
      await BriefingStorageService.saveBriefing(briefing2);

      // Load all briefings
      final loadedBriefings = await BriefingStorageService.loadAllBriefings();
      expect(loadedBriefings.length, greaterThanOrEqualTo(2));

      // Verify each briefing can be converted correctly
      for (final loadedBriefing in loadedBriefings) {
        final flight = await BriefingConversionService.briefingToFlight(loadedBriefing);
        expect(flight.airports.length, greaterThan(0));
      }
    });

    test('should handle briefing updates correctly', () async {
      // Create initial briefing
      final initialBriefing = Briefing.create(
        airports: ['YSSY'],
        notams: {},
        weather: {},
      );

      // Save initial briefing
      await BriefingStorageService.saveBriefing(initialBriefing);

      // Update the briefing
      final updatedBriefing = initialBriefing.copyWith(
        notams: {
          'F1234/25': {
            'id': 'F1234/25',
            'type': 'runway',
            'icao': 'YSSY',
            'rawText': 'UPDATED NOTAM',
            'decodedText': 'Updated NOTAM decoded',
            'validFrom': '2025-01-01T00:00:00.000Z',
            'validTo': '2025-12-31T23:59:59.000Z',
            'affectedSystem': 'RWY',
            'isCritical': true,
            'group': 'runways',
          },
        },
      );

      // Update the briefing
      final updateSuccess = await BriefingStorageService.updateBriefing(updatedBriefing);
      expect(updateSuccess, isTrue);

      // Load the updated briefing
      final loadedBriefing = await BriefingStorageService.loadBriefing(initialBriefing.id);
      expect(loadedBriefing, isNotNull);

      // Convert to flight and verify update
      final flight = await BriefingConversionService.briefingToFlight(loadedBriefing!);
      expect(flight.notams.length, equals(1));
      expect(flight.notams.first.rawText, equals('UPDATED NOTAM'));
    });
  });
} 