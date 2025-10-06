import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/models/airport_infrastructure.dart';
import 'package:briefing_buddy/models/airport.dart';
import 'package:briefing_buddy/services/airport_system_analyzer.dart';

void main() {
  group('AirportSystemAnalyzer - Facility-Specific Analysis', () {
    late AirportSystemAnalyzer analyzer;
    late List<Notam> testNotams;
    late AirportInfrastructure testInfrastructure;

    setUp(() {
      analyzer = AirportSystemAnalyzer();
      
      // Create test NOTAMs
      testNotams = [
        Notam(
          id: '1',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now().subtract(Duration(hours: 1)),
          validTo: DateTime.now().add(Duration(hours: 24)),
          rawText: 'RWY 03/21 CLOSED DUE TO MAINTENANCE',
          decodedText: 'Runway 03/21 closed due to maintenance',
          affectedSystem: 'runway',
          isCritical: true,
          qCode: 'QMRLC',
          group: NotamGroup.runways,
        ),
        Notam(
          id: '2',
          icao: 'YPPH',
          type: NotamType.lighting,
          validFrom: DateTime.now().subtract(Duration(hours: 1)),
          validTo: DateTime.now().add(Duration(hours: 24)),
          rawText: 'PAPI RWY 03 UNAVAILABLE',
          decodedText: 'PAPI for runway 03 unavailable',
          affectedSystem: 'lighting',
          isCritical: false,
          qCode: 'QLALT', // LA = Approach Lighting, LT = Limited (YELLOW)
          group: NotamGroup.airportServices,
        ),
        Notam(
          id: '3',
          icao: 'YPPH',
          type: NotamType.navaid,
          validFrom: DateTime.now().subtract(Duration(hours: 1)),
          validTo: DateTime.now().add(Duration(hours: 24)),
          rawText: 'ILS RWY 03 U/S',
          decodedText: 'ILS for runway 03 unserviceable',
          affectedSystem: 'navaid',
          isCritical: true,
          qCode: 'QICLC',
          group: NotamGroup.instrumentProcedures,
        ),
        Notam(
          id: '4',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: DateTime.now().subtract(Duration(hours: 1)),
          validTo: DateTime.now().add(Duration(hours: 24)),
          rawText: 'TAXIWAY A LIMITED DUE TO CONSTRUCTION',
          decodedText: 'Taxiway A limited due to construction',
          affectedSystem: 'taxiway',
          isCritical: false,
          qCode: 'QMXLT', // MX = Taxiway, LT = Limited (YELLOW)
          group: NotamGroup.taxiways,
        ),
      ];

      // Create test infrastructure
      testInfrastructure = AirportInfrastructure(
        icao: 'YPPH',
        runways: [
          Runway(
            identifier: '03/21',
            length: 3000,
            surface: 'Asphalt',
            approaches: [],
            hasLighting: true,
            width: 45,
          ),
          Runway(
            identifier: '06/24',
            length: 2500,
            surface: 'Asphalt',
            approaches: [],
            hasLighting: true,
            width: 45,
          ),
        ],
        navaids: [
          Navaid(
            identifier: 'PH',
            frequency: '110.3',
            runway: '03',
            type: 'ILS',
          ),
          Navaid(
            identifier: 'PH',
            frequency: '113.1',
            runway: '06',
            type: 'VOR',
          ),
        ],
        taxiways: [
          Taxiway(
            identifier: 'A',
            connections: ['03/21', '06/24'],
            width: 23,
            hasLighting: true,
          ),
          Taxiway(
            identifier: 'B',
            connections: ['03/21', '06/24'],
            width: 23,
            hasLighting: true,
          ),
        ],
        approaches: [],
        routes: [],
        lighting: [],
        facilityStatus: {},
      );
    });

    group('Individual Facility Analysis', () {
      test('should analyze runway facility status correctly', () {
        final status = analyzer.analyzeRunwayFacilityStatus(testNotams, '03/21', 'YPPH');
        expect(status, SystemStatus.red);
      });

      test('should analyze NAVAID facility status correctly', () {
        final status = analyzer.analyzeNavaidFacilityStatus(testNotams, 'ILS 03', 'YPPH');
        expect(status, SystemStatus.red);
      });

      test('should analyze taxiway facility status correctly', () {
        final status = analyzer.analyzeTaxiwayFacilityStatus(testNotams, 'A', 'YPPH');
        expect(status, SystemStatus.yellow);
      });

      test('should analyze lighting facility status correctly', () {
        final status = analyzer.analyzeLightingFacilityStatus(testNotams, 'PAPI', 'YPPH');
        expect(status, SystemStatus.yellow);
      });

      test('should return green status for unaffected facilities', () {
        final status = analyzer.analyzeRunwayFacilityStatus(testNotams, '06/24', 'YPPH');
        expect(status, SystemStatus.green);
      });
    });

    group('Status Text Generation', () {
      test('should generate correct status text for red status', () {
        final runwayNotams = testNotams.where((n) => n.rawText.contains('03/21')).toList();
        final statusText = analyzer.getFacilityStatusText(SystemStatus.red, runwayNotams, '03/21');
        expect(statusText, 'Closed');
      });

      test('should generate correct status text for yellow status', () {
        final taxiwayNotams = testNotams.where((n) => n.rawText.contains('TAXIWAY A')).toList();
        final statusText = analyzer.getFacilityStatusText(SystemStatus.yellow, taxiwayNotams, 'A');
        expect(statusText, 'Limited'); // Q-code QMXLT = Limited, not Construction
      });

      test('should generate correct status text for green status', () {
        final statusText = analyzer.getFacilityStatusText(SystemStatus.green, [], '06/24');
        expect(statusText, 'Operational');
      });
    });

    group('Critical NOTAMs Sorting', () {
      test('should sort critical NOTAMs by priority correctly', () {
        final runwayNotams = testNotams.where((n) => 
          n.rawText.contains('03/21') || n.rawText.contains('PAPI RWY 03') || n.rawText.contains('ILS RWY 03')
        ).toList();
        
        final criticalNotams = analyzer.getCriticalFacilityNotams(runwayNotams);
        
        // Should have 3 NOTAMs affecting runway 03
        expect(criticalNotams.length, 3);
        
        // First should be runway (highest priority)
        expect(criticalNotams[0].rawText, contains('03/21'));
        
        // Second should be ILS (second priority)
        expect(criticalNotams[1].rawText, contains('ILS RWY 03'));
      });
    });

    group('Complete Facility Analysis', () {
      test('should analyze all facilities correctly', () {
        final facilityStatuses = analyzer.analyzeAllFacilities(testNotams, testInfrastructure, 'YPPH');
        
        // Check runway status
        final runwayStatus = facilityStatuses['runway_03/21'];
        expect(runwayStatus, isNotNull);
        expect(runwayStatus!['status'], SystemStatus.red);
        expect(runwayStatus!['statusText'], 'Closed');
        expect(runwayStatus!['notams'], hasLength(1));
        
        // Check NAVAID status
        final navaidStatus = facilityStatuses['navaid_ILS_03'];
        expect(navaidStatus, isNotNull);
        expect(navaidStatus!['status'], SystemStatus.red);
        expect(navaidStatus!['statusText'], 'Closed'); // Q-code QICLC = Closed, not Unserviceable
        
        // Check taxiway status
        final taxiwayStatus = facilityStatuses['taxiway_A'];
        expect(taxiwayStatus, isNotNull);
        expect(taxiwayStatus!['status'], SystemStatus.yellow);
        expect(taxiwayStatus!['statusText'], 'Limited'); // Q-code QMXLT = Limited, not Construction
        
        // Check unaffected runway
        final unaffectedRunwayStatus = facilityStatuses['runway_06/24'];
        expect(unaffectedRunwayStatus, isNotNull);
        expect(unaffectedRunwayStatus!['status'], SystemStatus.green);
        expect(unaffectedRunwayStatus!['statusText'], 'Operational');
      });
    });
  });
}
