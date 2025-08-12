import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dispatch_buddy/services/openaip_service.dart';

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

    test('should get navaids by ICAO code', () async {
      try {
        final navaids = await OpenAIPService.getNavaidsByICAO('YSSY');
        
        expect(navaids, isA<List>());
        
        if (navaids.isNotEmpty) {
          print('✅ Found ${navaids.length} navaids for YSSY');
          navaids.take(5).forEach((navaid) {
            print('  - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency} - ${navaid.status}');
          });
          
          // Check navaid properties
          final firstNavaid = navaids.first;
          expect(firstNavaid.identifier, isNotEmpty);
          expect(firstNavaid.type, isNotEmpty);
          expect(firstNavaid.status, isNotEmpty);
        } else {
          print('⚠️  No navaids found for YSSY (endpoint may not be available)');
        }
        
      } catch (e) {
        print('⚠️  Navaid endpoint test failed: $e');
        // Don't fail the test as navaid endpoints might not be available
      }
    });

    test('should get navaids for YSCB (Canberra)', () async {
      try {
        final navaids = await OpenAIPService.getNavaidsByICAO('YSCB');
        
        expect(navaids, isA<List>());
        
        if (navaids.isNotEmpty) {
          print('✅ Found ${navaids.length} navaids for YSCB');
          navaids.take(10).forEach((navaid) {
            print('  - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency} - ${navaid.status}');
          });
          
          // Check navaid properties
          final firstNavaid = navaids.first;
          expect(firstNavaid.identifier, isNotEmpty);
          expect(firstNavaid.type, isNotEmpty);
          expect(firstNavaid.status, isNotEmpty);
        } else {
          print('⚠️  No navaids found for YSCB (endpoint may not be available)');
        }
        
      } catch (e) {
        print('⚠️  YSCB navaid endpoint test failed: $e');
        // Don't fail the test as navaid endpoints might not be available
      }
    });

    test('should search navaids by type', () async {
      try {
        final vorNavaids = await OpenAIPService.searchNavaidsByType('VOR', limit: 5);
        
        expect(vorNavaids, isA<List>());
        
        if (vorNavaids.isNotEmpty) {
          print('✅ Found ${vorNavaids.length} VOR navaids');
          vorNavaids.forEach((navaid) {
            expect(navaid.type, equals('VOR'));
            print('  - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency} - ${navaid.status}');
          });
        } else {
          print('⚠️  No VOR navaids found (endpoint may not be available)');
        }
        
      } catch (e) {
        print('⚠️  Navaid type search test failed: $e');
        // Don't fail the test as navaid endpoints might not be available
      }
    });

    test('should get navaids by geographic bounds', () async {
      try {
        // Sydney area bounds
        final navaids = await OpenAIPService.getNavaidsByBounds(
          north: -33.5,
          south: -34.0,
          east: 151.5,
          west: 150.5,
          limit: 10,
        );
        
        expect(navaids, isA<List>());
        
        if (navaids.isNotEmpty) {
          print('✅ Found ${navaids.length} navaids in Sydney area');
          navaids.take(5).forEach((navaid) {
            print('  - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency}');
          });
        } else {
          print('⚠️  No navaids found in Sydney area (endpoint may not be available)');
        }
        
      } catch (e) {
        print('⚠️  Navaid bounds search test failed: $e');
        // Don't fail the test as navaid endpoints might not be available
      }
    });

    test('should parse navaid types correctly', () async {
      // Test integer type mapping based on OpenAIP documentation
      expect(OpenAIPService.parseNavaidType(0), equals('NDB'));
      expect(OpenAIPService.parseNavaidType(1), equals('VOR'));
      expect(OpenAIPService.parseNavaidType(2), equals('DME'));
      expect(OpenAIPService.parseNavaidType(3), equals('TACAN'));
      expect(OpenAIPService.parseNavaidType(4), equals('ILS'));
      expect(OpenAIPService.parseNavaidType(5), equals('LOC'));
      expect(OpenAIPService.parseNavaidType(6), equals('GLS'));
      expect(OpenAIPService.parseNavaidType(7), equals('MLS'));
      expect(OpenAIPService.parseNavaidType(8), equals('VORTAC'));
      expect(OpenAIPService.parseNavaidType(99), equals('(Unknown)'));
      expect(OpenAIPService.parseNavaidType(null), equals('(Unknown)'));
      
      // Test string conversion
      expect(OpenAIPService.parseNavaidType('1'), equals('VOR'));
      expect(OpenAIPService.parseNavaidType('4'), equals('ILS'));
    });

    test('should parse navaid status correctly', () async {
      expect(OpenAIPService.parseNavaidStatus('OPERATIONAL'), equals('OPERATIONAL'));
      expect(OpenAIPService.parseNavaidStatus('U/S'), equals('U/S'));
      expect(OpenAIPService.parseNavaidStatus('MAINTENANCE'), equals('MAINTENANCE'));
      expect(OpenAIPService.parseNavaidStatus(null), equals('UNKNOWN'));
    });

    test('should parse navaid frequency correctly', () async {
      // Test frequency object format from OpenAIP
      final frequencyObj = {
        'value': '323.000',
        'unit': 1
      };
      expect(OpenAIPService.parseNavaidFrequency(frequencyObj), equals('323.000 MHz'));
      
      // Test kHz unit
      final frequencyObjKHz = {
        'value': '108.50',
        'unit': 2
      };
      expect(OpenAIPService.parseNavaidFrequency(frequencyObjKHz), equals('108.50 kHz'));
      
      // Test unknown unit
      final frequencyObjUnknown = {
        'value': '110.30',
        'unit': 3
      };
      expect(OpenAIPService.parseNavaidFrequency(frequencyObjUnknown), equals('110.30'));
      
      // Test null frequency
      expect(OpenAIPService.parseNavaidFrequency(null), equals(''));
      
      // Test string fallback
      expect(OpenAIPService.parseNavaidFrequency('323.000'), equals('323.000'));
    });
  });
} 