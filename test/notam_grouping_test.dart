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
      test('should have all 7 groups defined', () {
        expect(NotamGroup.values.length, 7);
        expect(NotamGroup.values, contains(NotamGroup.runways));
        expect(NotamGroup.values, contains(NotamGroup.taxiways));
        expect(NotamGroup.values, contains(NotamGroup.instrumentProcedures));
        expect(NotamGroup.values, contains(NotamGroup.airportServices));
        expect(NotamGroup.values, contains(NotamGroup.hazards));
        expect(NotamGroup.values, contains(NotamGroup.admin));
        expect(NotamGroup.values, contains(NotamGroup.other));
      });
    });

    group('Q Code to Group Mapping', () {
      test('should map Runways Q codes correctly', () {
        final testCases = [
          {'qCode': 'QMRLC', 'expectedGroup': NotamGroup.runways}, // Runway
          {'qCode': 'QMSLC', 'expectedGroup': NotamGroup.runways}, // Stopway
          {'qCode': 'QMTLC', 'expectedGroup': NotamGroup.runways}, // Threshold
          {'qCode': 'QMULC', 'expectedGroup': NotamGroup.runways}, // Runway turning bay
          {'qCode': 'QMWLC', 'expectedGroup': NotamGroup.runways}, // Strip/shoulder
          {'qCode': 'QMDLC', 'expectedGroup': NotamGroup.runways}, // Declared distances
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

      test('should map Taxiways Q codes correctly', () {
        final testCases = [
          {'qCode': 'QMXLC', 'expectedGroup': NotamGroup.taxiways}, // Taxiway
          {'qCode': 'QMYLC', 'expectedGroup': NotamGroup.taxiways}, // Rapid exit taxiway
          {'qCode': 'QMKLC', 'expectedGroup': NotamGroup.taxiways}, // Parking area
          {'qCode': 'QMNLC', 'expectedGroup': NotamGroup.taxiways}, // Apron
          {'qCode': 'QMPLC', 'expectedGroup': NotamGroup.taxiways}, // Aircraft stands
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.taxiway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Test NOTAM',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'TWY',
            isCritical: false,
            qCode: testCase['qCode'] as String,
            group: Notam.determineGroupFromQCode(testCase['qCode'] as String),
          );

          expect(notam.group, testCase['expectedGroup'], 
              reason: 'Failed for Q code: ${testCase['qCode']}');
        }
      });

      test('should map Instrument Procedures Q codes correctly', () {
        final testCases = [
          {'qCode': 'QICLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // ILS
          {'qCode': 'QIDLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // ILS DME
          {'qCode': 'QIGLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Glide path
          {'qCode': 'QIILC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Inner marker
          {'qCode': 'QILLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Localizer
          {'qCode': 'QIMLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Middle marker
          {'qCode': 'QINLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Localizer (non-ILS)
          {'qCode': 'QIOLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Outer marker
          {'qCode': 'QISLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // ILS Category I
          {'qCode': 'QITLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // ILS Category II
          {'qCode': 'QIULC', 'expectedGroup': NotamGroup.instrumentProcedures}, // ILS Category III
          {'qCode': 'QIWLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // MLS
          {'qCode': 'QIXLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Locator, outer
          {'qCode': 'QIYLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Locator, middle
          {'qCode': 'QNALC', 'expectedGroup': NotamGroup.instrumentProcedures}, // All radio navigation
          {'qCode': 'QNBLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Nondirectional beacon
          {'qCode': 'QNCLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // DECCA
          {'qCode': 'QNDLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // DME
          {'qCode': 'QNFLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Fan marker
          {'qCode': 'QNLLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // Locator
          {'qCode': 'QNMLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // VOR/DME
          {'qCode': 'QNNLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // TACAN
          {'qCode': 'QNOLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // OMEGA
          {'qCode': 'QNTLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // VORTAC
          {'qCode': 'QNVLC', 'expectedGroup': NotamGroup.instrumentProcedures}, // VOR
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

      test('should map Airport Services Q codes correctly', () {
        final testCases = [
          {'qCode': 'QLALC', 'expectedGroup': NotamGroup.airportServices}, // Approach lighting
          {'qCode': 'QLBLC', 'expectedGroup': NotamGroup.airportServices}, // Aerodrome beacon
          {'qCode': 'QLCLC', 'expectedGroup': NotamGroup.airportServices}, // Runway centre line
          {'qCode': 'QLDLC', 'expectedGroup': NotamGroup.airportServices}, // Landing direction
          {'qCode': 'QLELC', 'expectedGroup': NotamGroup.airportServices}, // Runway edge
          {'qCode': 'QLFLC', 'expectedGroup': NotamGroup.airportServices}, // Sequenced flashing
          {'qCode': 'QLGLC', 'expectedGroup': NotamGroup.airportServices}, // Pilot-controlled
          {'qCode': 'QLHLC', 'expectedGroup': NotamGroup.airportServices}, // High intensity
          {'qCode': 'QLILC', 'expectedGroup': NotamGroup.airportServices}, // Runway end identifier
          {'qCode': 'QLJLC', 'expectedGroup': NotamGroup.airportServices}, // Runway alignment
          {'qCode': 'QLKLC', 'expectedGroup': NotamGroup.airportServices}, // CAT II components
          {'qCode': 'QLLLC', 'expectedGroup': NotamGroup.airportServices}, // Low intensity
          {'qCode': 'QLMLC', 'expectedGroup': NotamGroup.airportServices}, // Medium intensity
          {'qCode': 'QLPLC', 'expectedGroup': NotamGroup.airportServices}, // PAPI
          {'qCode': 'QLRLC', 'expectedGroup': NotamGroup.airportServices}, // All landing area
          {'qCode': 'QLSLC', 'expectedGroup': NotamGroup.airportServices}, // Stopway
          {'qCode': 'QLTLC', 'expectedGroup': NotamGroup.airportServices}, // Threshold
          {'qCode': 'QLULC', 'expectedGroup': NotamGroup.airportServices}, // Helicopter approach
          {'qCode': 'QLVLC', 'expectedGroup': NotamGroup.airportServices}, // VASIS
          {'qCode': 'QLWLC', 'expectedGroup': NotamGroup.airportServices}, // Heliport
          {'qCode': 'QLXLC', 'expectedGroup': NotamGroup.airportServices}, // Taxiway centre line
          {'qCode': 'QLYLC', 'expectedGroup': NotamGroup.airportServices}, // Taxiway edge
          {'qCode': 'QLZLC', 'expectedGroup': NotamGroup.airportServices}, // Touchdown zone
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

      test('should map Hazards Q codes correctly', () {
        final testCases = [
          {'qCode': 'QOBLC', 'expectedGroup': NotamGroup.hazards}, // Obstacle
          {'qCode': 'QOLLC', 'expectedGroup': NotamGroup.hazards}, // Obstacle lights
          {'qCode': 'QWULC', 'expectedGroup': NotamGroup.hazards}, // Unmanned aircraft
          {'qCode': 'QWALC', 'expectedGroup': NotamGroup.hazards}, // Air display
          {'qCode': 'QWWLC', 'expectedGroup': NotamGroup.hazards}, // Significant volcanic activity
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Test NOTAM',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'HAZARD',
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

    group('Text-Based Classification', () {
      test('should classify Runways NOTAMs by text', () {
        final testCases = [
          {'text': 'RWY 06/24 CLOSED for maintenance', 'expectedGroup': NotamGroup.runways},
          {'text': 'Runway 06/24 unserviceable', 'expectedGroup': NotamGroup.runways},
          {'text': 'Displaced threshold runway 06', 'expectedGroup': NotamGroup.runways},
          {'text': 'Braking action poor on runway 06', 'expectedGroup': NotamGroup.runways},
          {'text': 'TORA reduced on runway 06', 'expectedGroup': NotamGroup.runways},
          {'text': 'Declared distances changed runway 06', 'expectedGroup': NotamGroup.runways},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should classify Taxiways NOTAMs by text', () {
        final testCases = [
          {'text': 'Taxiway A closed for construction', 'expectedGroup': NotamGroup.taxiways},
          {'text': 'TWY B unserviceable', 'expectedGroup': NotamGroup.taxiways},
          {'text': 'Apron closed for maintenance', 'expectedGroup': NotamGroup.taxiways},
          {'text': 'Parking area limited', 'expectedGroup': NotamGroup.taxiways},
          {'text': 'Aircraft stand 5 closed', 'expectedGroup': NotamGroup.taxiways},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should classify Instrument Procedures NOTAMs by text', () {
        final testCases = [
          {'text': 'ILS runway 06 unserviceable', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'VOR out of service', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'NDB unserviceable', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'DME out of service', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'Localizer runway 06 unserviceable', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'Glide path unserviceable', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'Minimums increased for approach', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'Decision altitude increased', 'expectedGroup': NotamGroup.instrumentProcedures},
          {'text': 'Navigation aid maintenance', 'expectedGroup': NotamGroup.instrumentProcedures},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should classify Airport Services NOTAMs by text', () {
        final testCases = [
          {'text': 'Runway lighting unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'HIRL unserviceable runway 06', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'REIL unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'PAPI unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'VASIS unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'Approach lighting system unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'Centerline lights unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'Edge lights unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'Threshold lights unserviceable', 'expectedGroup': NotamGroup.airportServices},
          {'text': 'Aerodrome beacon unserviceable', 'expectedGroup': NotamGroup.airportServices},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should classify Hazards NOTAMs by text', () {
        final testCases = [
          {'text': 'Obstacle reported near airport', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Crane operating near runway', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Construction work near airport', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Unlit obstacle reported', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Obstacle light failure', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Wildlife hazard reported', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Bird strike reported', 'expectedGroup': NotamGroup.hazards},
          {'text': 'Maintenance work near runway', 'expectedGroup': NotamGroup.hazards},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should classify Admin NOTAMs by text', () {
        final testCases = [
          {'text': 'Curfew restrictions in effect', 'expectedGroup': NotamGroup.admin},
          {'text': 'Noise abatement procedures', 'expectedGroup': NotamGroup.admin},
          {'text': 'PPR required for operations', 'expectedGroup': NotamGroup.admin},
          {'text': 'Slot restrictions in effect', 'expectedGroup': NotamGroup.admin},
          {'text': 'Administrative procedures changed', 'expectedGroup': NotamGroup.admin},
          {'text': 'ATIS frequency changed', 'expectedGroup': NotamGroup.admin},
        ];

        for (final testCase in testCases) {
          final notam = Notam(
            id: 'TEST123',
            icao: 'YPPH',
            type: NotamType.other,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: testCase['text'] as String,
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'OTHER',
            isCritical: false,
            qCode: null, // No Q code to force text-based classification
            group: NotamGroup.other,
          );

          final assignedGroup = groupingService.assignGroup(notam);
          expect(assignedGroup, testCase['expectedGroup'], 
              reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should handle unknown text classification', () {
        final notam = Notam(
          id: 'TEST123',
          icao: 'YPPH',
          type: NotamType.other,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Some random text with no keywords',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'OTHER',
          isCritical: false,
          qCode: null, // No Q code to force text-based classification
          group: NotamGroup.other,
        );

        final assignedGroup = groupingService.assignGroup(notam);
        expect(assignedGroup, NotamGroup.other); // Should be other for unknown text
      });
    });

    group('Grouping Service Methods', () {
      test('should get correct display names', () {
        expect(groupingService.getGroupDisplayName(NotamGroup.runways), '🛬 Runways (Critical)');
        expect(groupingService.getGroupDisplayName(NotamGroup.taxiways), '🛣️ Taxiways');
        expect(groupingService.getGroupDisplayName(NotamGroup.instrumentProcedures), '📡 Instrument Procedures');
        expect(groupingService.getGroupDisplayName(NotamGroup.airportServices), '🏢 Airport Services');
        expect(groupingService.getGroupDisplayName(NotamGroup.hazards), '⚠️ Hazards');
        expect(groupingService.getGroupDisplayName(NotamGroup.admin), '📑 Admin');
        expect(groupingService.getGroupDisplayName(NotamGroup.other), '🔧 Other');
      });

      test('should get correct priorities', () {
        expect(groupingService.getGroupPriority(NotamGroup.runways), 1);
        expect(groupingService.getGroupPriority(NotamGroup.taxiways), 2);
        expect(groupingService.getGroupPriority(NotamGroup.instrumentProcedures), 3);
        expect(groupingService.getGroupPriority(NotamGroup.airportServices), 4);
        expect(groupingService.getGroupPriority(NotamGroup.hazards), 5);
        expect(groupingService.getGroupPriority(NotamGroup.admin), 6);
        expect(groupingService.getGroupPriority(NotamGroup.other), 7);
      });

      test('should sort groups by priority', () {
        final sortedGroups = groupingService.getSortedGroups();
        expect(sortedGroups.first, NotamGroup.runways);
        expect(sortedGroups.last, NotamGroup.other);
      });

      test('should group NOTAMs correctly', () {
        final notams = [
          Notam(
            id: 'TEST1',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway closed',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: null,
            group: NotamGroup.runways,
          ),
          Notam(
            id: 'TEST2',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'ILS unserviceable',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'NAV',
            isCritical: false,
            qCode: null,
            group: NotamGroup.instrumentProcedures,
          ),
          Notam(
            id: 'TEST3',
            icao: 'YPPH',
            type: NotamType.lighting,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Lighting unserviceable',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'LIGHT',
            isCritical: false,
            qCode: null,
            group: NotamGroup.airportServices,
          ),
        ];

        final groupedNotams = groupingService.groupNotams(notams);
        expect(groupedNotams[NotamGroup.runways]?.length, 1);
        expect(groupedNotams[NotamGroup.instrumentProcedures]?.length, 1);
        expect(groupedNotams[NotamGroup.airportServices]?.length, 1);
      });

      test('should sort NOTAMs within groups', () {
        final notams = [
          Notam(
            id: 'TEST1',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now().add(Duration(hours: 2)),
            validTo: DateTime.now().add(Duration(hours: 3)),
            rawText: 'Runway closed',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: null,
            group: NotamGroup.runways,
          ),
          Notam(
            id: 'TEST2',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway unserviceable',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: true, // Critical should come first
            qCode: null,
            group: NotamGroup.runways,
          ),
        ];

        final sortedNotams = groupingService.sortNotamsInGroup(notams);
        expect(sortedNotams.first.isCritical, true);
        expect(sortedNotams.first.id, 'TEST2');
      });

      test('should get group statistics', () {
        final notams = [
          Notam(
            id: 'TEST1',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway closed',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: null,
            group: NotamGroup.runways,
          ),
          Notam(
            id: 'TEST2',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'Runway unserviceable',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'RWY',
            isCritical: false,
            qCode: null,
            group: NotamGroup.runways,
          ),
          Notam(
            id: 'TEST3',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(hours: 1)),
            rawText: 'ILS unserviceable',
            decodedText: 'Decoded test NOTAM',
            affectedSystem: 'NAV',
            isCritical: false,
            qCode: null,
            group: NotamGroup.instrumentProcedures,
          ),
        ];

        final stats = groupingService.getGroupStatistics(notams);
        expect(stats[NotamGroup.runways], 2);
        expect(stats[NotamGroup.instrumentProcedures], 1);
        expect(stats[NotamGroup.airportServices], null);
      });

      test('should identify operationally significant NOTAMs', () {
        final criticalNotam = Notam(
          id: 'TEST1',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Runway closed',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: true,
          qCode: null,
          group: NotamGroup.runways,
        );

        final significantNotam = Notam(
          id: 'TEST2',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Runway unserviceable',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          qCode: null,
          group: NotamGroup.runways,
        );

        final normalNotam = Notam(
          id: 'TEST3',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 1)),
          rawText: 'Runway maintenance',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          qCode: null,
          group: NotamGroup.runways,
        );

        expect(groupingService.isOperationallySignificant(criticalNotam), true);
        expect(groupingService.isOperationallySignificant(significantNotam), true);
        expect(groupingService.isOperationallySignificant(normalNotam), false);
      });
    });
  });
} 