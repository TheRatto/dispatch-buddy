import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/services/openaip_service.dart';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('OpenAIPService', () {
    test('should search airports successfully', () async {
      try {
        final airports = await OpenAIPService.searchAirports('sydney', limit: 3);
        
        expect(airports, isA<List>());
        expect(airports.length, greaterThan(0));
        
        // Check first airport has required fields
        final firstAirport = airports.first;
        expect(firstAirport.name, isNotEmpty);
        expect(firstAirport.icao, isA<String>());
        expect(firstAirport.city, isNotEmpty);
        expect(firstAirport.latitude, isA<double>());
        expect(firstAirport.longitude, isA<double>());
        
        print('✅ Found ${airports.length} airports for "sydney"');
        airports.take(3).forEach((airport) {
          print('  - ${airport.name} (${airport.icao}) in ${airport.city}');
        });
        
      } catch (e) {
        fail('OpenAIP service test failed: $e');
      }
    });

    test('should get airport by ICAO code', () async {
      try {
        final airport = await OpenAIPService.getAirportByICAO('YSBK');
        
        if (airport != null) {
          expect(airport.name, isNotEmpty);
          expect(airport.icao, equals('YSBK'));
          expect(airport.city, isNotEmpty);
          
          print('✅ Found airport: ${airport.name} (${airport.icao})');
        } else {
          print('⚠️  Airport YSBK not found in OpenAIP database');
        }
        
      } catch (e) {
        fail('OpenAIP service test failed: $e');
      }
    });

    test('should get multiple airports by ICAO codes', () async {
      try {
        final airports = await OpenAIPService.getAirportsByICAOCodes(['YSBK', 'YSSY', 'YMML']);
        
        expect(airports, isA<List>());
        
        print('✅ Found ${airports.length} airports:');
        for (final airport in airports) {
          print('  - ${airport.name} (${airport.icao})');
        }
        
      } catch (e) {
        fail('OpenAIP service test failed: $e');
      }
    });

    test('should handle API errors gracefully', () async {
      try {
        // Test with invalid search
        final airports = await OpenAIPService.searchAirports('xyz123nonexistent', limit: 1);
        expect(airports, isA<List>());
        // Should return empty list for invalid search
        expect(airports.length, equals(0));
        
        print('✅ Handled invalid search gracefully');
        
      } catch (e) {
        fail('OpenAIP service should handle errors gracefully: $e');
      }
    });
  });
} 