import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../lib/models/briefing.dart';
import '../lib/models/notam.dart';
import '../lib/models/weather.dart';
import '../lib/services/briefing_conversion_service.dart';

void main() {
  group('BriefingConversionService Tests', () {
    test('should convert briefing to flight and back correctly', () {
      // Create test data in the actual storage format
      final testNotamsMap = <String, dynamic>{
        'NOTAM001': {
          'id': 'NOTAM001',
          'icao': 'YSSY',
          'rawText': 'A1234/24 YSSY RWY 16L/34R CLSD',
          'decodedText': 'Runway 16L/34R closed',
          'validFrom': DateTime.now().toIso8601String(),
          'validTo': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'affectedSystem': 'RWY',
          'isCritical': true,
          'type': 'runway', // Use enum name, not full string
          'group': 'runways', // Use enum name, not full string
          'qCode': 'QMRLC',
        },
        'NOTAM002': {
          'id': 'NOTAM002',
          'icao': 'YPPH',
          'rawText': 'B5678/24 YPPH TWY A CLSD',
          'decodedText': 'Taxiway A closed',
          'validFrom': DateTime.now().toIso8601String(),
          'validTo': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'affectedSystem': 'TWY',
          'isCritical': false,
          'type': 'taxiway', // Use enum name, not full string
          'group': 'taxiways', // Use enum name, not full string
          'qCode': 'QMXLC',
        },
      };

      final testWeatherMap = <String, dynamic>{
        'YSSY': {
          'icao': 'YSSY',
          'rawText': 'YSSY 250200Z 08015KT 9999 SCT030 22/15 Q1013',
          'decodedText': 'Wind 080° at 15 knots, visibility 10km, scattered clouds at 3000ft',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'METAR',
          'windDirection': 80, // Integer, not double
          'windSpeed': 15, // Integer, not double
          'visibility': 10, // Integer, not double
          'cloudCover': 'SCT',
          'temperature': 22.0, // Double for temperature
          'dewPoint': 15.0, // Double for dew point
          'qnh': 1013, // Integer
          'conditions': 'CAVOK',
        },
        'YPPH': {
          'icao': 'YPPH',
          'rawText': 'YPPH 250200Z 12010KT 9999 FEW030 25/18 Q1015',
          'decodedText': 'Wind 120° at 10 knots, visibility 10km, few clouds at 3000ft',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'METAR',
          'windDirection': 120, // Integer, not double
          'windSpeed': 10, // Integer, not double
          'visibility': 10, // Integer, not double
          'cloudCover': 'FEW',
          'temperature': 25.0, // Double for temperature
          'dewPoint': 18.0, // Double for dew point
          'qnh': 1015, // Integer
          'conditions': 'CAVOK',
        },
      };

      final briefing = Briefing.create(
        name: 'Test Briefing',
        airports: ['YSSY', 'YPPH'],
        notams: testNotamsMap,
        weather: testWeatherMap,
      );

      // Test conversion from briefing to flight
      final flight = BriefingConversionService.briefingToFlight(briefing);
      
      expect(flight, isNotNull);
      expect(flight.airports.length, equals(2));
      expect(flight.notams.length, equals(2));
      expect(flight.weather.length, equals(2));
      
      // Verify NOTAMs were converted correctly
      final notamIds = flight.notams.map((n) => n.id).toSet();
      expect(notamIds, contains('NOTAM001'));
      expect(notamIds, contains('NOTAM002'));
      
      // Verify weather was converted correctly
      final weatherIcaos = flight.weather.map((w) => w.icao).toSet();
      expect(weatherIcaos, contains('YSSY'));
      expect(weatherIcaos, contains('YPPH'));
      
      // Test conversion back to briefing
      final convertedBriefing = BriefingConversionService.flightToBriefing(flight);
      
      expect(convertedBriefing, isNotNull);
      expect(convertedBriefing.airports, equals(briefing.airports));
      expect(convertedBriefing.notams.length, equals(briefing.notams.length));
      expect(convertedBriefing.weather.length, equals(briefing.weather.length));
    });

    test('should handle empty data gracefully', () {
      final briefing = Briefing.create(
        name: 'Empty Briefing',
        airports: ['YSSY'],
        notams: {},
        weather: {},
      );

      final flight = BriefingConversionService.briefingToFlight(briefing);
      
      expect(flight, isNotNull);
      expect(flight.notams, isEmpty);
      expect(flight.weather, isEmpty);
      expect(flight.airports.length, equals(1));
    });

    test('should handle malformed data gracefully', () {
      final malformedNotamsMap = <String, dynamic>{
        'NOTAM001': {
          'id': 'NOTAM001',
          'icao': 'YSSY',
          // Missing required fields
        },
      };

      final briefing = Briefing.create(
        name: 'Malformed Briefing',
        airports: ['YSSY'],
        notams: malformedNotamsMap,
        weather: {},
      );

      // Should not throw, but should handle gracefully
      final flight = BriefingConversionService.briefingToFlight(briefing);
      
      expect(flight, isNotNull);
      // Should have 0 NOTAMs due to malformed data
      expect(flight.notams, isEmpty);
    });

    test('should handle real FAA NOTAM format', () {
      // Test with actual FAA NOTAM format that the app uses
      final faaNotamsMap = <String, dynamic>{
        'FDC0245': {
          'id': 'FDC0245',
          'icao': 'KJFK',
          'rawText': 'FDC 2/0245 KJFK RWY 13L/31R CLSD 2401251200-2401261200',
          'decodedText': 'Runway 13L/31R closed',
          'validFrom': DateTime.now().toIso8601String(),
          'validTo': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'affectedSystem': 'RWY',
          'isCritical': true,
          'type': 'runway',
          'group': 'runways',
          'qCode': 'QMRLC',
        },
      };

      final faaWeatherMap = <String, dynamic>{
        'KJFK': {
          'icao': 'KJFK',
          'rawText': 'KJFK 251152Z 28015KT 10SM FEW250 22/15 A3000',
          'decodedText': 'Wind 280° at 15 knots, visibility 10 statute miles, few clouds at 25000ft',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'METAR',
          'windDirection': 280,
          'windSpeed': 15,
          'visibility': 10,
          'cloudCover': 'FEW',
          'temperature': 22.0,
          'dewPoint': 15.0,
          'qnh': 3000,
          'conditions': 'CAVOK',
        },
      };

      final briefing = Briefing.create(
        name: 'FAA Format Test',
        airports: ['KJFK'],
        notams: faaNotamsMap,
        weather: faaWeatherMap,
      );

      final flight = BriefingConversionService.briefingToFlight(briefing);
      
      expect(flight, isNotNull);
      expect(flight.notams.length, equals(1));
      expect(flight.weather.length, equals(1));
      
      // Verify FAA NOTAM was converted correctly
      final notam = flight.notams.first;
      expect(notam.id, equals('FDC0245'));
      expect(notam.icao, equals('KJFK'));
      expect(notam.rawText, contains('RWY 13L/31R CLSD'));
      expect(notam.isCritical, isTrue);
      
      // Verify FAA weather was converted correctly
      final weather = flight.weather.first;
      expect(weather.icao, equals('KJFK'));
      expect(weather.rawText, contains('28015KT'));
      expect(weather.windDirection, equals(280));
      expect(weather.windSpeed, equals(15));
    });
  });
} 