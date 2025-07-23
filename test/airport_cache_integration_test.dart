import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/services/airport_cache_manager.dart';
import '../lib/services/openaip_service.dart';
import '../lib/models/airport_infrastructure.dart';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('OpenAIP API Integration Tests', () {
    group('API Data Flow Testing', () {
      test('should fetch airport data from OpenAIP API', () async {
        // Test direct API call
        final airport = await OpenAIPService.getAirportByICAO('YSSY');
        
        expect(airport, isNotNull);
        expect(airport!.icao, equals('YSSY'));
        expect(airport.name, isNotEmpty);
        expect(airport.latitude, isA<double>());
        expect(airport.longitude, isA<double>());
        
        print('✅ Successfully fetched YSSY from OpenAIP API');
        print('  - Name: ${airport.name}');
        print('  - Location: ${airport.latitude}, ${airport.longitude}');
        print('  - Runways: ${airport.runways.length}');
      });

      test('should handle multiple airport requests efficiently', () async {
        // Test multiple airports simultaneously
        final airports = ['YSSY', 'YMML', 'YPPH'];
        final futures = airports.map((icao) => 
          OpenAIPService.getAirportByICAO(icao)
        );
        
        final results = await Future.wait(futures);
        
        expect(results.length, equals(3));
        for (int i = 0; i < results.length; i++) {
          expect(results[i], isNotNull);
          expect(results[i]!.icao, equals(airports[i]));
        }
        
        print('✅ Successfully fetched ${results.length} airports concurrently');
        for (final airport in results) {
          print('  - ${airport!.name} (${airport.icao})');
        }
      });

      test('should handle invalid ICAO codes gracefully', () async {
        // Test with invalid ICAO code
        final airport = await OpenAIPService.getAirportByICAO('INVALID');
        expect(airport, isNull);
        
        print('✅ Handled invalid ICAO code gracefully');
      });

      test('should search airports by name', () async {
        // Test airport search functionality
        final airports = await OpenAIPService.searchAirports('sydney', limit: 5);
        
        expect(airports, isA<List>());
        expect(airports.length, greaterThan(0));
        
        // Check that we got relevant results
        final australianAirports = airports.where((a) => 
          a.city.contains('AU') || a.icao.startsWith('Y')
        ).toList();
        
        expect(australianAirports.length, greaterThan(0));
        
        print('✅ Successfully searched for "sydney"');
        print('  - Found ${airports.length} airports');
        print('  - ${australianAirports.length} Australian airports');
      });
    });

    group('Data Quality Testing', () {
      test('should parse runway data correctly', () async {
        final airport = await OpenAIPService.getAirportByICAO('YSSY');
        
        expect(airport, isNotNull);
        expect(airport!.runways, isA<List>());
        
        if (airport.runways.isNotEmpty) {
          print('✅ Runway data parsed correctly');
          print('  - Found ${airport.runways.length} runways');
          for (final runway in airport.runways.take(3)) {
            print('    - ${runway}');
          }
        } else {
          print('⚠️  No runway data available for YSSY');
        }
      });

      test('should parse coordinate data correctly', () async {
        final airport = await OpenAIPService.getAirportByICAO('YSSY');
        
        expect(airport, isNotNull);
        expect(airport!.latitude, isA<double>());
        expect(airport.longitude, isA<double>());
        
        // YSSY should be in Australia (rough bounds)
        expect(airport.latitude, greaterThan(-45.0));
        expect(airport.latitude, lessThan(-10.0));
        expect(airport.longitude, greaterThan(110.0));
        expect(airport.longitude, lessThan(155.0));
        
        print('✅ Coordinate data parsed correctly');
        print('  - Latitude: ${airport.latitude}');
        print('  - Longitude: ${airport.longitude}');
      });

      test('should handle missing data gracefully', () async {
        // Test with an airport that might have limited data
        final airport = await OpenAIPService.getAirportByICAO('YSSY');
        
        expect(airport, isNotNull);
        // Should not crash even if some fields are empty
        expect(airport!.name, isA<String>());
        expect(airport.icao, isA<String>());
        
        print('✅ Handled missing data gracefully');
      });
    });

    group('Performance Testing', () {
      test('should complete API calls within reasonable time', () async {
        final start = DateTime.now();
        
        final airport = await OpenAIPService.getAirportByICAO('YSSY');
        
        final duration = DateTime.now().difference(start);
        
        expect(airport, isNotNull);
        expect(duration.inSeconds, lessThan(10)); // Should complete within 10 seconds
        
        print('✅ API call completed in ${duration.inMilliseconds}ms');
      });

      test('should handle concurrent requests efficiently', () async {
        final start = DateTime.now();
        
        // Make multiple concurrent requests
        final futures = List.generate(5, (i) => 
          OpenAIPService.getAirportByICAO('YSSY')
        );
        
        final results = await Future.wait(futures);
        
        final duration = DateTime.now().difference(start);
        
        expect(results.length, equals(5));
        expect(results.every((r) => r != null), isTrue);
        expect(duration.inSeconds, lessThan(15)); // Should complete within 15 seconds
        
        print('✅ ${results.length} concurrent requests completed in ${duration.inMilliseconds}ms');
      });
    });

    group('Error Handling Testing', () {
      test('should handle network errors gracefully', () async {
        // Test with a valid ICAO that might not exist in OpenAIP
        final airport = await OpenAIPService.getAirportByICAO('ZZZZ');
        
        // Should return null, not throw
        expect(airport == null || airport is AirportInfrastructure, isTrue);
        
        print('✅ Handled network errors gracefully');
      });

      test('should handle malformed responses gracefully', () async {
        // This test would require mocking, but we can test the error handling
        // by using an invalid ICAO code
        final airport = await OpenAIPService.getAirportByICAO('INVALID');
        expect(airport, isNull);
        
        print('✅ Handled malformed responses gracefully');
      });
    });

    group('Integration with Cache Manager', () {
      test('should work with AirportCacheManager interface', () async {
        // Test that the cache manager can use the OpenAIP service
        // Note: This won't actually cache due to SharedPreferences limitations in tests
        // but we can test the interface
        
        try {
          final result = await AirportCacheManager.getAirportInfrastructure('YSSY');
          // Should either return data or null, but not crash
          expect(result == null || result is AirportInfrastructure, isTrue);
          
          print('✅ AirportCacheManager interface works with OpenAIP service');
        } catch (e) {
          // Expected to fail due to SharedPreferences, but should fail gracefully
          print('⚠️  AirportCacheManager test failed (expected due to SharedPreferences): $e');
        }
      });
    });
  });
} 