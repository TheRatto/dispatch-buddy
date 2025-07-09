import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';

void main() {
  group('NOTAM Grouping Tests', () {
    late NotamGroupingService groupingService;

    setUp(() {
      groupingService = NotamGroupingService();
    });

    group('NotamGroup Enum', () {
      test('should have all 9 groups defined', () {
        expect(NotamGroup.values.length, 9);
        expect(NotamGroup.values, contains(NotamGroup.movementAreas));
        expect(NotamGroup.values, contains(NotamGroup.navigationAids));
        expect(NotamGroup.values, contains(NotamGroup.departureApproachProcedures));
        expect(NotamGroup.values, contains(NotamGroup.airportAtcAvailability));
        expect(NotamGroup.values, contains(NotamGroup.lighting));
        expect(NotamGroup.values, contains(NotamGroup.hazardsObstacles));
        expect(NotamGroup.values, contains(NotamGroup.airspace));
        expect(NotamGroup.values, contains(NotamGroup.proceduralAdmin));
        expect(NotamGroup.values, contains(NotamGroup.other));
      });
    });

    group('Q Code to Group Mapping', () {
      test('should map Movement Areas Q codes correctly', () {
        final testCases = [
          {'qCode': 'QMRLC', 'expectedGroup': NotamGroup.movementAreas}, // Runway
          {'qCode': 'QMXLC', 'expectedGroup': NotamGroup.movementAreas}, // Taxiway
          {'qCode': 'QMSLC', 'expectedGroup': NotamGroup.movementAreas}, // Stopway
          {'qCode': 'QMTLC', 'expectedGroup': NotamGroup.movementAreas}, // Threshold
          {'qCode': 'QMULC', 'expectedGroup': NotamGroup.movementAreas}, // Runway turning bay
          {'qCode': 'QMWLC', 'expectedGroup': NotamGroup.movementAreas}, // Strip/shoulder
          {'qCode': 'QMYLC', 'expectedGroup': NotamGroup.movementAreas}, // Rapid exit taxiway
          {'qCode': 'QMKLC', 'expectedGroup': NotamGroup.movementAreas}, // Parking area
          {'qCode': 'QMNLC', 'expectedGroup': NotamGroup.movementAreas}, // Apron
          {'qCode': 'QMPLC', 'expectedGroup': NotamGroup.movementAreas}, // Aircraft stands
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Test NOTAM',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: testCase['qCode'] as String,
            group: Notam.determineGroupFromQCode(testCase['qCode'] as String),
          );

          expect(notam.group, testCase['expectedGroup'], 
              reason: 'Failed for Q code: ${testCase['qCode']}');
        }
      });

      test('should map Navigation Aids Q codes correctly', () {
        final testCases = [
          {'qCode': 'QICLC', 'expectedGroup': NotamGroup.navigationAids}, // ILS
          {'qCode': 'QIDLC', 'expectedGroup': NotamGroup.navigationAids}, // ILS DME
          {'qCode': 'QIGLC', 'expectedGroup': NotamGroup.navigationAids}, // Glide path
          {'qCode': 'QIILC', 'expectedGroup': NotamGroup.navigationAids}, // Inner marker
          {'qCode': 'QILLC', 'expectedGroup': NotamGroup.navigationAids}, // Localizer
          {'qCode': 'QIMLC', 'expectedGroup': NotamGroup.navigationAids}, // Middle marker
          {'qCode': 'QINLC', 'expectedGroup': NotamGroup.navigationAids}, // Localizer (non-ILS)
          {'qCode': 'QIOLC', 'expectedGroup': NotamGroup.navigationAids}, // Outer marker
          {'qCode': 'QISLC', 'expectedGroup': NotamGroup.navigationAids}, // ILS Category I
          {'qCode': 'QITLC', 'expectedGroup': NotamGroup.navigationAids}, // ILS Category II
          {'qCode': 'QIULC', 'expectedGroup': NotamGroup.navigationAids}, // ILS Category III
          {'qCode': 'QIWLC', 'expectedGroup': NotamGroup.navigationAids}, // MLS
          {'qCode': 'QIXLC', 'expectedGroup': NotamGroup.navigationAids}, // Locator, outer
          {'qCode': 'QIYLC', 'expectedGroup': NotamGroup.navigationAids}, // Locator, middle
          {'qCode': 'QNALC', 'expectedGroup': NotamGroup.navigationAids}, // All radio navigation
          {'qCode': 'QNBLC', 'expectedGroup': NotamGroup.navigationAids}, // Nondirectional beacon
          {'qCode': 'QNCLC', 'expectedGroup': NotamGroup.navigationAids}, // DECCA
          {'qCode': 'QNDLC', 'expectedGroup': NotamGroup.navigationAids}, // DME
          {'qCode': 'QNFLC', 'expectedGroup': NotamGroup.navigationAids}, // Fan marker
          {'qCode': 'QNLLC', 'expectedGroup': NotamGroup.navigationAids}, // Locator
          {'qCode': 'QNMLC', 'expectedGroup': NotamGroup.navigationAids}, // VOR/DME
          {'qCode': 'QNNLC', 'expectedGroup': NotamGroup.navigationAids}, // TACAN
          {'qCode': 'QNOLC', 'expectedGroup': NotamGroup.navigationAids}, // OMEGA
          {'qCode': 'QNTLC', 'expectedGroup': NotamGroup.navigationAids}, // VORTAC
          {'qCode': 'QNVLC', 'expectedGroup': NotamGroup.navigationAids}, // VOR
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Test NOTAM',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'NAV',
            isCritical: false,
            qCode: testCase['qCode'] as String,
            group: Notam.determineGroupFromQCode(testCase['qCode'] as String),
          );

          expect(notam.group, testCase['expectedGroup'], 
              reason: 'Failed for Q code: ${testCase['qCode']}');
        }
      });

      test('should map Lighting Q codes correctly', () {
        final testCases = [
          {'qCode': 'QLALC', 'expectedGroup': NotamGroup.lighting}, // Approach lighting
          {'qCode': 'QLBLC', 'expectedGroup': NotamGroup.lighting}, // Aerodrome beacon
          {'qCode': 'QLCLC', 'expectedGroup': NotamGroup.lighting}, // Runway centre line
          {'qCode': 'QLDLC', 'expectedGroup': NotamGroup.lighting}, // Landing direction
          {'qCode': 'QLELC', 'expectedGroup': NotamGroup.lighting}, // Runway edge
          {'qCode': 'QLFLC', 'expectedGroup': NotamGroup.lighting}, // Sequenced flashing
          {'qCode': 'QLGLC', 'expectedGroup': NotamGroup.lighting}, // Pilot-controlled
          {'qCode': 'QLHLC', 'expectedGroup': NotamGroup.lighting}, // High intensity
          {'qCode': 'QLILC', 'expectedGroup': NotamGroup.lighting}, // Runway end identifier
          {'qCode': 'QLJLC', 'expectedGroup': NotamGroup.lighting}, // Runway alignment
          {'qCode': 'QLKLC', 'expectedGroup': NotamGroup.lighting}, // CAT II components
          {'qCode': 'QLLLC', 'expectedGroup': NotamGroup.lighting}, // Low intensity
          {'qCode': 'QLMLC', 'expectedGroup': NotamGroup.lighting}, // Medium intensity
          {'qCode': 'QLPLC', 'expectedGroup': NotamGroup.lighting}, // PAPI
          {'qCode': 'QLRLC', 'expectedGroup': NotamGroup.lighting}, // All landing area
          {'qCode': 'QLSLC', 'expectedGroup': NotamGroup.lighting}, // Stopway
          {'qCode': 'QLTLC', 'expectedGroup': NotamGroup.lighting}, // Threshold
          {'qCode': 'QLULC', 'expectedGroup': NotamGroup.lighting}, // Helicopter approach
          {'qCode': 'QLVLC', 'expectedGroup': NotamGroup.lighting}, // VASIS
          {'qCode': 'QLWLC', 'expectedGroup': NotamGroup.lighting}, // Heliport
          {'qCode': 'QLXLC', 'expectedGroup': NotamGroup.lighting}, // Taxiway centre line
          {'qCode': 'QLYLC', 'expectedGroup': NotamGroup.lighting}, // Taxiway edge
          {'qCode': 'QLZLC', 'expectedGroup': NotamGroup.lighting}, // Touchdown zone
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.lighting,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Test NOTAM',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'LIGHT',
            isCritical: false,
            qCode: testCase['qCode'] as String,
            group: Notam.determineGroupFromQCode(testCase['qCode'] as String),
          );

          expect(notam.group, testCase['expectedGroup'], 
              reason: 'Failed for Q code: ${testCase['qCode']}');
        }
      });

      test('should handle invalid Q codes', () {
        final invalidQCodes = [null, '', 'ABC', 'QABC', 'QABCDE', 'XMRLC'];
        
        for (final qCode in invalidQCodes) {
          final group = Notam.determineGroupFromQCode(qCode);
          expect(group, NotamGroup.other, 
              reason: 'Failed for invalid Q code: $qCode');
        }
      });
    });

    group('NotamGroupingService', () {
      test('should get correct display names', () {
        expect(groupingService.getGroupDisplayName(NotamGroup.movementAreas), '🛬 Movement Areas');
        expect(groupingService.getGroupDisplayName(NotamGroup.navigationAids), '📡 Navigation Aids');
        expect(groupingService.getGroupDisplayName(NotamGroup.departureApproachProcedures), '🛫 Departure/Approach Procedures');
        expect(groupingService.getGroupDisplayName(NotamGroup.airportAtcAvailability), '🏢 Airport & ATC Availability');
        expect(groupingService.getGroupDisplayName(NotamGroup.lighting), '💡 Lighting');
        expect(groupingService.getGroupDisplayName(NotamGroup.hazardsObstacles), '⚠️ Hazards & Obstacles');
        expect(groupingService.getGroupDisplayName(NotamGroup.airspace), '✈️ Airspace');
        expect(groupingService.getGroupDisplayName(NotamGroup.proceduralAdmin), '📑 Procedural & Admin');
        expect(groupingService.getGroupDisplayName(NotamGroup.other), '🔧 Other');
      });

      test('should get correct priority orders', () {
        expect(groupingService.getGroupPriority(NotamGroup.movementAreas), 1);
        expect(groupingService.getGroupPriority(NotamGroup.navigationAids), 2);
        expect(groupingService.getGroupPriority(NotamGroup.departureApproachProcedures), 3);
        expect(groupingService.getGroupPriority(NotamGroup.airportAtcAvailability), 4);
        expect(groupingService.getGroupPriority(NotamGroup.lighting), 5);
        expect(groupingService.getGroupPriority(NotamGroup.hazardsObstacles), 6);
        expect(groupingService.getGroupPriority(NotamGroup.airspace), 7);
        expect(groupingService.getGroupPriority(NotamGroup.proceduralAdmin), 8);
        expect(groupingService.getGroupPriority(NotamGroup.other), 9);
      });

      test('should sort groups by priority', () {
        final sortedGroups = groupingService.getSortedGroups();
        expect(sortedGroups.length, 9);
        expect(sortedGroups.first, NotamGroup.movementAreas);
        expect(sortedGroups.last, NotamGroup.other);
      });

      test('should group NOTAMs correctly', () {
        final notams = [
          Notam(
            id: 'RWY001',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway closed',
            decodedText: 'Runway 06/24 closed',
            affectedSystem: 'RWY',
            isCritical: true,
            qCode: 'QMRLC',
            group: NotamGroup.movementAreas,
          ),
          Notam(
            id: 'NAV001',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'ILS unserviceable',
            decodedText: 'ILS runway 06 unserviceable',
            affectedSystem: 'ILS',
            isCritical: false,
            qCode: 'QICLC',
            group: NotamGroup.navigationAids,
          ),
          Notam(
            id: 'LIGHT001',
            icao: 'YPPH',
            type: NotamType.lighting,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'PAPI unserviceable',
            decodedText: 'PAPI runway 06 unserviceable',
            affectedSystem: 'PAPI',
            isCritical: false,
            qCode: 'QLPLC',
            group: NotamGroup.lighting,
          ),
        ];

        final groupedNotams = groupingService.groupNotams(notams);
        
        expect(groupedNotams.length, 3);
        expect(groupedNotams[NotamGroup.movementAreas]?.length, 1);
        expect(groupedNotams[NotamGroup.navigationAids]?.length, 1);
        expect(groupedNotams[NotamGroup.lighting]?.length, 1);
        expect(groupedNotams[NotamGroup.other], null);
      });

      test('should sort NOTAMs within groups correctly', () {
        final notams = [
          Notam(
            id: 'RWY001',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now().add(Duration(hours: 2)),
            validTo: DateTime.now().add(Duration(hours: 3)),
            rawText: 'Runway closed later',
            decodedText: 'Runway 06/24 closed later',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: 'QMRLC',
            group: NotamGroup.movementAreas,
          ),
          Notam(
            id: 'RWY002',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway closed now',
            decodedText: 'Runway 06/24 closed now',
            affectedSystem: 'RWY',
            isCritical: true,
            qCode: 'QMRLC',
            group: NotamGroup.movementAreas,
          ),
        ];

        final sortedNotams = groupingService.sortNotamsInGroup(notams);
        
        // Critical NOTAM should come first, then by time
        expect(sortedNotams.first.id, 'RWY002'); // Critical
        expect(sortedNotams.last.id, 'RWY001');  // Non-critical, later time
      });

      test('should get group statistics', () {
        final notams = [
          Notam(
            id: 'RWY001',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway closed',
            decodedText: 'Runway 06/24 closed',
            affectedSystem: 'RWY',
            isCritical: true,
            qCode: 'QMRLC',
            group: NotamGroup.movementAreas,
          ),
          Notam(
            id: 'RWY002',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Taxiway closed',
            decodedText: 'Taxiway A closed',
            affectedSystem: 'TWY',
            isCritical: false,
            qCode: 'QMXLC',
            group: NotamGroup.movementAreas,
          ),
          Notam(
            id: 'NAV001',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'ILS unserviceable',
            decodedText: 'ILS runway 06 unserviceable',
            affectedSystem: 'ILS',
            isCritical: false,
            qCode: 'QICLC',
            group: NotamGroup.navigationAids,
          ),
        ];

        final stats = groupingService.getGroupStatistics(notams);
        
        expect(stats[NotamGroup.movementAreas], 2);
        expect(stats[NotamGroup.navigationAids], 1);
        expect(stats[NotamGroup.lighting], null);
      });

      test('should identify operationally significant NOTAMs', () {
        final significantNotam = Notam(
          id: 'RWY001',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Runway 06/24 CLOSED for maintenance',
          decodedText: 'Runway 06/24 closed for maintenance',
          affectedSystem: 'RWY',
          isCritical: true,
          qCode: 'QMRLC',
          group: NotamGroup.movementAreas,
        );

        final nonSignificantNotam = Notam(
          id: 'RWY002',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Runway 06/24 lighting reduced intensity',
          decodedText: 'Runway 06/24 lighting reduced intensity',
          affectedSystem: 'RWY',
          isCritical: false,
          qCode: 'QMRLC',
          group: NotamGroup.movementAreas,
        );

        expect(groupingService.isOperationallySignificant(significantNotam), true);
        expect(groupingService.isOperationallySignificant(nonSignificantNotam), false);
      });
    });
  });
} 