import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/models/airport.dart';
import 'package:dispatch_buddy/services/airport_system_analyzer.dart';

void main() {
  group('AirportSystemAnalyzer Q-Code Enhancement', () {
    late AirportSystemAnalyzer analyzer;

    setUp(() {
      analyzer = AirportSystemAnalyzer();
    });

    group('Q-Code Impact Assessment', () {
      test('should return RED status for closed facilities based on Q-code', () {
        final notams = [
          Notam(
            id: '1',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 CLOSED DUE TO MAINTENANCE',
            decodedText: 'Runway 07/25 closed due to maintenance',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRLC', // MR = Runway, LC = Closed
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.red));
      });

      test('should return RED status for unserviceable facilities based on Q-code', () {
        final notams = [
          Notam(
            id: '2',
            icao: 'YSSY',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'ILS RWY 07 UNSERVICEABLE',
            decodedText: 'ILS for runway 07 unserviceable',
            affectedSystem: 'navaid',
            isCritical: false,
            qCode: 'QICAS', // IC = ILS, AS = Unserviceable
            group: NotamGroup.instrumentProcedures,
          ),
        ];

        final status = analyzer.analyzeNavaidFacilityStatus(notams, 'ILS 07', 'YSSY');
        expect(status, equals(SystemStatus.red));
      });

      test('should return YELLOW status for limited facilities based on Q-code', () {
        final notams = [
          Notam(
            id: '3',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 LIMITED OPERATIONS',
            decodedText: 'Runway 07/25 limited operations',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRLT', // MR = Runway, LT = Limited
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.yellow));
      });

      test('should return YELLOW status for maintenance facilities based on Q-code', () {
        final notams = [
          Notam(
            id: '4',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 MAINTENANCE WORK',
            decodedText: 'Runway 07/25 maintenance work',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRMT', // MR = Runway, MT = Maintenance
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.yellow));
      });

      test('should return YELLOW status for displaced threshold based on Q-code', () {
        final notams = [
          Notam(
            id: '5',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 DISPLACED THRESHOLD',
            decodedText: 'Runway 07/25 displaced threshold',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRDP', // MR = Runway, DP = Displaced
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.yellow));
      });

      test('should return GREEN status for operational facilities with Q-code', () {
        final notams = [
          Notam(
            id: '6',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 OPERATIONAL',
            decodedText: 'Runway 07/25 operational',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMROP', // MR = Runway, OP = Operational
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.green));
      });

      test('should fallback to text analysis when Q-code is null', () {
        final notams = [
          Notam(
            id: '7',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 CLOSED DUE TO MAINTENANCE',
            decodedText: 'Runway 07/25 closed due to maintenance',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: null, // No Q-code
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.red)); // Should still work via text analysis
      });

      test('should fallback to text analysis when Q-code is invalid', () {
        final notams = [
          Notam(
            id: '8',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 LIMITED OPERATIONS',
            decodedText: 'Runway 07/25 limited operations',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'INVALID', // Invalid Q-code
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.yellow)); // Should still work via text analysis
      });
    });

    group('Q-Code Status Description', () {
      test('should provide human-readable Q-code status descriptions', () {
        expect(analyzer.getQCodeStatusDescription('QMRLC'), equals('Runway - Closed'));
        expect(analyzer.getQCodeStatusDescription('QICAS'), equals('ILS - Unserviceable'));
        expect(analyzer.getQCodeStatusDescription('QMRLT'), equals('Runway - Limited'));
        expect(analyzer.getQCodeStatusDescription('QMRMT'), equals('Runway - Maintenance'));
        expect(analyzer.getQCodeStatusDescription('QMRDP'), equals('Runway - Displaced'));
        expect(analyzer.getQCodeStatusDescription('QMROP'), equals('Runway - Operational'));
      });

      test('should handle unknown Q-codes gracefully', () {
        expect(analyzer.getQCodeStatusDescription(null), equals('Unknown Status'));
        expect(analyzer.getQCodeStatusDescription('INVALID'), equals('Unknown Status'));
        expect(analyzer.getQCodeStatusDescription('Q'), equals('Unknown Status'));
        expect(analyzer.getQCodeStatusDescription('QMR'), equals('Unknown Status'));
      });
    });

    group('Status Text Enhancement', () {
      test('should use Q-code for RED status text when available', () {
        final notam = Notam(
          id: '1',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 07/25 CLOSED',
          decodedText: 'Runway 07/25 closed',
          affectedSystem: 'runway',
          isCritical: false,
          qCode: 'QMRLC', // MR = Runway, LC = Closed
          group: NotamGroup.runways,
        );

        final statusText = analyzer.getFacilityStatusText(SystemStatus.red, [notam], '07/25');
        expect(statusText, equals('Closed')); // Should use Q-code status
      });

      test('should use Q-code for YELLOW status text when available', () {
        final notam = Notam(
          id: '2',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 07/25 MAINTENANCE',
          decodedText: 'Runway 07/25 maintenance',
          affectedSystem: 'runway',
          isCritical: false,
          qCode: 'QMRMT', // MR = Runway, MT = Maintenance
          group: NotamGroup.runways,
        );

        final statusText = analyzer.getFacilityStatusText(SystemStatus.yellow, [notam], '07/25');
        expect(statusText, equals('Maintenance')); // Should use Q-code status
      });

      test('should fallback to text analysis when Q-code is not available', () {
        final notam = Notam(
          id: '3',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 07/25 CONSTRUCTION WORK',
          decodedText: 'Runway 07/25 construction work',
          affectedSystem: 'runway',
          isCritical: false,
          qCode: null, // No Q-code
          group: NotamGroup.runways,
        );

        final statusText = analyzer.getFacilityStatusText(SystemStatus.yellow, [notam], '07/25');
        expect(statusText, equals('Construction')); // Should fallback to text analysis
      });
    });

    group('Priority and Fallback Logic', () {
      test('should prioritize Q-code analysis over text analysis', () {
        final notams = [
          Notam(
            id: '1',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 MAINTENANCE WORK', // Text suggests maintenance
            decodedText: 'Runway 07/25 maintenance work',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRLC', // But Q-code says closed
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.red)); // Q-code should take priority
      });

      test('should handle mixed Q-code and text scenarios', () {
        final notams = [
          Notam(
            id: '1',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 LIMITED OPERATIONS',
            decodedText: 'Runway 07/25 limited operations',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: 'QMRMT', // Maintenance
            group: NotamGroup.runways,
          ),
          Notam(
            id: '2',
            icao: 'YSSY',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 1)),
            rawText: 'RWY 07/25 CONSTRUCTION WORK',
            decodedText: 'Runway 07/25 construction work',
            affectedSystem: 'runway',
            isCritical: false,
            qCode: null, // No Q-code
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayFacilityStatus(notams, '07/25', 'YSSY');
        expect(status, equals(SystemStatus.yellow)); // Should be yellow due to Q-code
      });
    });
  });
}
