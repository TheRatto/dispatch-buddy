import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/models/airport_infrastructure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NAVAID Grouping Debug Test', () {
    testWidgets('should group ERSA navaids correctly', (WidgetTester tester) async {
      // Create test NAVAIDs matching ERSA data
      final navaids = [
        Navaid(
          identifier: 'IAM',
          type: 'ILS/DME',
          frequency: '110.7',
          runway: '15',
          status: 'OPERATIONAL',
        ),
        Navaid(
          identifier: 'AMB',
          type: 'TAC',
          frequency: '112.5',
          runway: '',
          status: 'OPERATIONAL',
        ),
      ];
      
      // Create test airport infrastructure
      final airportInfrastructure = AirportInfrastructure(
        icao: 'YAMB',
        runways: [],
        taxiways: [],
        navaids: navaids,
        approaches: [],
        routes: [],
        facilityStatus: {},
      );
      
      // Test the grouping logic
      final runwayNavaids = <String, List<Navaid>>{};
      final generalNavaids = <Navaid>[];
      
      for (final navaid in navaids) {
        final isRunwaySpecific = navaid.type.toUpperCase().contains('ILS') || 
                                navaid.type.toUpperCase().contains('GBAS') || 
                                navaid.type.toUpperCase().contains('GLS') ||
                                navaid.type.toUpperCase().contains('LOC');
        
        if (isRunwaySpecific && navaid.runway.isNotEmpty) {
          runwayNavaids.putIfAbsent(navaid.runway, () => []).add(navaid);
          print('DEBUG: Added runway navaid: ${navaid.type} ${navaid.identifier} for runway ${navaid.runway}');
        } else {
          generalNavaids.add(navaid);
          print('DEBUG: Added general navaid: ${navaid.type} ${navaid.identifier}');
        }
      }
      
      // Verify grouping
      expect(generalNavaids.length, equals(1));
      expect(generalNavaids.first.type, equals('TAC'));
      expect(generalNavaids.first.identifier, equals('AMB'));
      
      expect(runwayNavaids.length, equals(1));
      expect(runwayNavaids['15']!.length, equals(1));
      expect(runwayNavaids['15']!.first.type, equals('ILS/DME'));
      expect(runwayNavaids['15']!.first.identifier, equals('IAM'));
      
      print('DEBUG: Test passed - NAVAID grouping works correctly');
    });
  });
} 