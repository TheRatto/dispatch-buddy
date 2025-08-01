import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dispatch_buddy/services/ersa_data_service.dart';
import 'package:dispatch_buddy/models/airport_infrastructure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ERSADataService Tests', () {
    test('should load YAMB data correctly', () async {
      // Test that YAMB data is available
      final yambData = await ERSADataService.getAirportInfrastructure('YAMB');
      
      expect(yambData, isNotNull);
      expect(yambData!.icao, equals('YAMB'));
      
      // Check navaids
      expect(yambData.navaids.length, equals(2));
      
      // Check first navaid (ILS/DME)
      final ilsNavaid = yambData.navaids.firstWhere((n) => n.type == 'ILS/DME');
      expect(ilsNavaid.identifier, equals('IAM'));
      expect(ilsNavaid.frequency, equals('110.7'));
      expect(ilsNavaid.runway, equals('15'));
      
      // Check second navaid (TAC)
      final tacNavaid = yambData.navaids.firstWhere((n) => n.type == 'TAC');
      expect(tacNavaid.identifier, equals('AMB'));
      expect(tacNavaid.frequency, equals('112.5'));
      expect(tacNavaid.runway, equals(''));
    });
    
    test('should identify runway-specific navaids correctly', () {
      // Test that ILS/DME is identified as runway-specific
      final ilsNavaid = Navaid(
        identifier: 'IAM',
        type: 'ILS/DME',
        frequency: '110.7',
        runway: '15',
        status: 'OPERATIONAL',
      );
      
      expect(ilsNavaid.runway, equals('15'));
      expect(ilsNavaid.type, equals('ILS/DME'));
      
      // Test that TAC is identified as general
      final tacNavaid = Navaid(
        identifier: 'AMB',
        type: 'TAC',
        frequency: '112.5',
        runway: '',
        status: 'OPERATIONAL',
      );
      
      expect(tacNavaid.runway, equals(''));
      expect(tacNavaid.type, equals('TAC'));
    });
    
    test('should return null for non-Australian airports', () async {
      final nonAustralianData = await ERSADataService.getAirportInfrastructure('KLAX');
      expect(nonAustralianData, isNull);
    });
  });
} 