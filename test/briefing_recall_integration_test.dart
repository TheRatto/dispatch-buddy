import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../lib/models/briefing.dart';
import '../lib/models/notam.dart';
import '../lib/models/weather.dart';
import '../lib/services/briefing_conversion_service.dart';
import '../lib/services/briefing_storage_service.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Briefing Recall Integration Tests', () {
    test('should save and recall briefing data correctly', () async {
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
          'type': 'runway',
          'group': 'runways',
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
          'type': 'taxiway',
          'group': 'taxiways',
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
          'windDirection': 80,
          'windSpeed': 15,
          'visibility': 10,
          'cloudCover': 'SCT',
          'temperature': 22.0,
          'dewPoint': 15.0,
          'qnh': 1013,
          'conditions': 'CAVOK',
        },
        'YPPH': {
          'icao': 'YPPH',
          'rawText': 'YPPH 250200Z 12010KT 9999 FEW030 25/18 Q1015',
          'decodedText': 'Wind 120° at 10 knots, visibility 10km, few clouds at 3000ft',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'METAR',
          'windDirection': 120,
          'windSpeed': 10,
          'visibility': 10,
          'cloudCover': 'FEW',
          'temperature': 25.0,
          'dewPoint': 18.0,
          'qnh': 1015,
          'conditions': 'CAVOK',
        },
      };

      final briefing = Briefing.create(
        name: 'Test Integration Briefing',
        airports: ['YSSY', 'YPPH'],
        notams: testNotamsMap,
        weather: testWeatherMap,
      );

      // Save the briefing
      final saveSuccess = await BriefingStorageService.saveBriefing(briefing);
      expect(saveSuccess, isTrue);

      // Load all briefings
      final loadedBriefings = await BriefingStorageService.loadAllBriefings();
      expect(loadedBriefings, isNotEmpty);

      // Find our test briefing
      final savedBriefing = loadedBriefings.firstWhere((b) => b.id == briefing.id);
      expect(savedBriefing, isNotNull);
      expect(savedBriefing.airports, equals(briefing.airports));
      expect(savedBriefing.notams.length, equals(briefing.notams.length));
      expect(savedBriefing.weather.length, equals(briefing.weather.length));

      // Test conversion from saved briefing to flight
      final flight = BriefingConversionService.briefingToFlight(savedBriefing);
      
      expect(flight, isNotNull);
      expect(flight.notams.length, equals(2));
      expect(flight.weather.length, equals(2));
      
      // Verify the data was preserved correctly
      final notamIds = flight.notams.map((n) => n.id).toSet();
      expect(notamIds, contains('NOTAM001'));
      expect(notamIds, contains('NOTAM002'));
      
      final weatherIcaos = flight.weather.map((w) => w.icao).toSet();
      expect(weatherIcaos, contains('YSSY'));
      expect(weatherIcaos, contains('YPPH'));
      
      // Verify NOTAM details were preserved
      final yssyNotam = flight.notams.firstWhere((n) => n.icao == 'YSSY');
      expect(yssyNotam.rawText, contains('RWY 16L/34R CLSD'));
      expect(yssyNotam.isCritical, isTrue);
      
      // Verify weather details were preserved
      final yssyWeather = flight.weather.firstWhere((w) => w.icao == 'YSSY');
      expect(yssyWeather.windDirection, equals(80));
      expect(yssyWeather.windSpeed, equals(15));
      expect(yssyWeather.temperature, equals(22.0));
    });

    test('should handle real-world briefing data format', () async {
      // This test simulates the actual data format used by the app
      final realNotamsMap = <String, dynamic>{
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

      final realWeatherMap = <String, dynamic>{
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
        name: 'Real World Test',
        airports: ['KJFK'],
        notams: realNotamsMap,
        weather: realWeatherMap,
      );

      // Test conversion
      final flight = BriefingConversionService.briefingToFlight(briefing);
      
      expect(flight.notams.length, equals(1));
      expect(flight.weather.length, equals(1));
      
      final notam = flight.notams.first;
      expect(notam.id, equals('FDC0245'));
      expect(notam.icao, equals('KJFK'));
      expect(notam.rawText, contains('RWY 13L/31R CLSD'));
      
      final weather = flight.weather.first;
      expect(weather.icao, equals('KJFK'));
      expect(weather.rawText, contains('28015KT'));
      expect(weather.windDirection, equals(280));
    });
  });
} 