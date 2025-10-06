import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/airport_cache_manager.dart';
import 'package:briefing_buddy/services/ersa_data_service.dart';
import 'package:briefing_buddy/models/airport_infrastructure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ERSA Integration Tests', () {
    test('should use ERSA data for YAMB after cache clear', () async {
      // Clear cache first
      await AirportCacheManager.clearCache();
      
      // Get YAMB data
      final yambData = await AirportCacheManager.getAirportInfrastructure('YAMB');
      
      expect(yambData, isNotNull);
      expect(yambData!.icao, equals('YAMB'));
      
      // Should have 2 navaids from ERSA data
      expect(yambData.navaids.length, equals(2));
      
      // Check for ILS/DME navaid
      final ilsNavaid = yambData.navaids.firstWhere(
        (n) => n.type == 'ILS/DME',
        orElse: () => throw Exception('ILS/DME navaid not found'),
      );
      expect(ilsNavaid.identifier, equals('IAM'));
      expect(ilsNavaid.frequency, equals('110.7'));
      expect(ilsNavaid.runway, equals('15'));
      
      // Check for TAC navaid
      final tacNavaid = yambData.navaids.firstWhere(
        (n) => n.type == 'TAC',
        orElse: () => throw Exception('TAC navaid not found'),
      );
      expect(tacNavaid.identifier, equals('AMB'));
      expect(tacNavaid.frequency, equals('112.5'));
      expect(tacNavaid.runway, equals(''));
    });
    
    test('should return null for non-Australian airports', () async {
      final nonAustralianData = await AirportCacheManager.getAirportInfrastructure('KLAX');
      expect(nonAustralianData, isNull);
    });
    
    test('should load ERSA data directly', () async {
      final ersaData = await ERSADataService.getAirportInfrastructure('YAMB');
      
      expect(ersaData, isNotNull);
      expect(ersaData!.icao, equals('YAMB'));
      expect(ersaData.navaids.length, equals(2));
      
      // Verify the navaid data matches the JSON
      final ilsNavaid = ersaData.navaids.firstWhere((n) => n.type == 'ILS/DME');
      expect(ilsNavaid.identifier, equals('IAM'));
      expect(ilsNavaid.frequency, equals('110.7'));
      
      final tacNavaid = ersaData.navaids.firstWhere((n) => n.type == 'TAC');
      expect(tacNavaid.identifier, equals('AMB'));
      expect(tacNavaid.frequency, equals('112.5'));
    });
  });
} 