import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dispatch_buddy/services/ersa_data_service.dart';
import 'package:dispatch_buddy/services/airport_cache_manager.dart';
import 'package:dispatch_buddy/models/airport_infrastructure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('YAMB Display Tests', () {
    test('should load YAMB runway data with width', () async {
      // Test that YAMB data includes width information
      final infrastructure = await ERSADataService.getAirportInfrastructure('YAMB');
      
      expect(infrastructure, isNotNull);
      expect(infrastructure!.icao, equals('YAMB'));
      expect(infrastructure.runways, isNotEmpty);
      
      // Check runway 04/22
      final runway0422 = infrastructure.runways.firstWhere(
        (r) => r.identifier == '04/22',
        orElse: () => throw Exception('Runway 04/22 not found'),
      );
      
      expect(runway0422.length, equals(5000.0)); // 5,000 feet (from JSON)
      expect(runway0422.width, equals(45.0));    // 45 meters (from JSON)
      expect(runway0422.surface, equals('Asphalt'));
      
      // Check runway 15/33
      final runway1533 = infrastructure.runways.firstWhere(
        (r) => r.identifier == '15/33',
        orElse: () => throw Exception('Runway 15/33 not found'),
      );
      
      expect(runway1533.length, equals(10000.0)); // 10,000 feet (from JSON)
      expect(runway1533.width, equals(45.0));     // 45 meters (from JSON)
      expect(runway1533.surface, equals('Asphalt'));
    });
    
    test('should convert YAMB data through AirportCacheManager', () async {
      // Test that AirportCacheManager returns ERSA data for YAMB
      final infrastructure = await AirportCacheManager.getAirportInfrastructure('YAMB');
      
      expect(infrastructure, isNotNull);
      expect(infrastructure!.icao, equals('YAMB'));
      expect(infrastructure.runways, isNotEmpty);
      
      // Verify width data is preserved
      for (final runway in infrastructure.runways) {
        expect(runway.width, greaterThan(0));
        expect(runway.length, greaterThan(0));
      }
    });
    
    test('should have correct YAMB runway dimensions', () async {
      final infrastructure = await ERSADataService.getAirportInfrastructure('YAMB');
      
      expect(infrastructure, isNotNull);
      
      // Verify runway 04/22 dimensions
      final runway0422 = infrastructure!.runways.firstWhere((r) => r.identifier == '04/22');
      expect(runway0422.length, equals(5000.0)); // 5,000m
      expect(runway0422.width, equals(45.0));    // 45m
      
      // Verify runway 15/33 dimensions  
      final runway1533 = infrastructure.runways.firstWhere((r) => r.identifier == '15/33');
      expect(runway1533.length, equals(10000.0)); // 10,000m
      expect(runway1533.width, equals(45.0));     // 45m
    });
    
    test('should have correct YAMB navaid data', () async {
      final infrastructure = await ERSADataService.getAirportInfrastructure('YAMB');
      
      expect(infrastructure, isNotNull);
      expect(infrastructure!.navaids, isNotEmpty);
      
      // Check ILS/DME
      final ilsNavaid = infrastructure.navaids.firstWhere(
        (n) => n.identifier == 'IAM',
        orElse: () => throw Exception('IAM navaid not found'),
      );
      
      expect(ilsNavaid.type, equals('ILS/DME'));
      expect(ilsNavaid.frequency, equals('110.7'));
      expect(ilsNavaid.runway, equals('15'));
      
      // Check TAC
      final tacNavaid = infrastructure.navaids.firstWhere(
        (n) => n.identifier == 'AMB',
        orElse: () => throw Exception('AMB navaid not found'),
      );
      
      expect(tacNavaid.type, equals('TAC'));
      expect(tacNavaid.frequency, equals('112.5'));
    });
  });
} 