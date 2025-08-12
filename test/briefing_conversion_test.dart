import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:dispatch_buddy/models/briefing.dart';
import 'package:dispatch_buddy/models/flight.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/models/weather.dart';
import 'package:dispatch_buddy/services/briefing_conversion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BriefingConversionService', () {
    test('should convert briefing to flight with NOTAMs and weather', () async {
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

      // Convert briefing to flight
      final flight = await BriefingConversionService.briefingToFlight(briefing);

      // Verify the conversion
      expect(flight.airports.length, equals(2));
      expect(flight.notams.length, equals(1));
      expect(flight.weather.length, equals(1));
      expect(flight.notams.first.id, equals('F1234/25'));
      expect(flight.weather.first.icao, equals('YSSY'));
    });

    test('should convert flight to briefing', () {
      // Create a test flight
      final flight = Flight(
        id: 'test_flight',
        route: 'YSSY → YMML',
        departure: 'YSSY',
        destination: 'YMML',
        etd: DateTime.now(),
        flightLevel: 'FL100',
        alternates: [],
        createdAt: DateTime.now(),
        airports: [],
        notams: [
          Notam(
            id: 'F1234/25',
            type: NotamType.runway,
            icao: 'YSSY',
            rawText: 'TEST NOTAM',
            decodedText: 'Test NOTAM decoded',
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(const Duration(days: 1)),
            affectedSystem: 'RWY',
            isCritical: true,
            group: NotamGroup.runways,
          ),
        ],
        weather: [
          Weather(
            icao: 'YSSY',
            timestamp: DateTime.now(),
            rawText: 'YSSY 251130Z 06006KT 9999 SCT110 09/01 Q1023',
            decodedText: 'Wind 060° at 6kt, visibility 10km',
            windDirection: 60,
            windSpeed: 6,
            visibility: 10,
            cloudCover: 'SCT',
            temperature: 9.0,
            dewPoint: 1.0,
            qnh: 1023,
            conditions: 'CAVOK',
            type: 'METAR',
          ),
        ],
      );

      // Convert flight to briefing
      final briefing = BriefingConversionService.flightToBriefing(flight);

      // Verify the conversion
      expect(briefing.airports.length, equals(2));
      expect(briefing.notams.length, equals(1));
      expect(briefing.weather.length, equals(1));
    });

    test('should handle empty briefing data', () async {
      // Create an empty briefing
      final briefing = Briefing.create(
        airports: ['YSSY'],
        notams: {},
        weather: {},
      );

      // Convert briefing to flight
      final flight = await BriefingConversionService.briefingToFlight(briefing);

      // Verify the conversion handles empty data
      expect(flight.airports.length, equals(1));
      expect(flight.notams.length, equals(0));
      expect(flight.weather.length, equals(0));
    });

    test('should validate briefing data quality', () {
      // Create a valid briefing
      final validBriefing = Briefing.create(
        airports: ['YSSY'],
        notams: {'F1234/25': {'id': 'F1234/25'}},
        weather: {'METAR_YSSY': {'type': 'METAR', 'icao': 'YSSY'}},
      );

      // Test validation
      final isValid = BriefingConversionService.validateBriefingDataQuality(validBriefing);
      expect(isValid, isTrue);
    });

    test('should handle invalid briefing data', () {
      // Create an invalid briefing (no airports)
      final invalidBriefing = Briefing.create(
        airports: [],
        notams: {},
        weather: {},
      );

      // Test validation
      final isValid = BriefingConversionService.validateBriefingDataQuality(invalidBriefing);
      expect(isValid, isFalse);
    });

    test('should handle NOTAM conversion errors gracefully', () async {
      // Create a briefing with invalid NOTAM data
      final briefing = Briefing.create(
        airports: ['YSSY'],
        notams: {
          'F1234/25': {
            'id': 'F1234/25',
            // Missing required fields
          },
        },
        weather: {},
      );

      // Convert briefing to flight - should handle errors gracefully
      final flight = await BriefingConversionService.briefingToFlight(briefing);

      // Should still create a flight, but with empty NOTAMs
      expect(flight.airports.length, equals(1));
      expect(flight.notams.length, equals(0));
    });

    test('should handle weather conversion errors gracefully', () async {
      // Create a briefing with invalid weather data
      final briefing = Briefing.create(
        airports: ['YSSY'],
        notams: {},
        weather: {
          'METAR_YSSY': {
            'type': 'METAR',
            // Missing required fields
          },
        },
      );

      // Convert briefing to flight - should handle errors gracefully
      final flight = await BriefingConversionService.briefingToFlight(briefing);

      // Should still create a flight, but with empty weather
      expect(flight.airports.length, equals(1));
      expect(flight.weather.length, equals(0));
    });
  });
} 