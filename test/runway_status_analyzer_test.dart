import 'package:flutter_test/flutter_test.dart';
import '../lib/services/runway_status_analyzer.dart';
import '../lib/models/notam.dart';

void main() {
  group('RunwayStatusAnalyzer', () {
    Notam makeNotam(String text) => Notam(
      id: '1',
      icao: 'KJFK',
      type: NotamType.runway,
      validFrom: DateTime.utc(2025, 7, 16),
      validTo: DateTime.utc(2025, 7, 23),
      rawText: text,
      decodedText: text,
      affectedSystem: 'runways',
      isCritical: false,
      qCode: null,
      group: NotamGroup.runways,
    );

    test('Extracts runway identifiers from NOTAM text', () {
      final notam = makeNotam('RWY 04R closed for maintenance');
      final ids = RunwayStatusAnalyzer.extractRunwayIdentifiers(notam.rawText);
      expect(ids, contains('RWY 04R'));
    });

    test('Assigns red status for closed runway', () {
      final notam = makeNotam('RWY 22L closed due to construction');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([notam]);
      expect(status.overallStatus, SystemStatus.red);
      expect(status.runways.first.status, SystemStatus.red);
      expect(status.runways.first.impacts, contains('Runway closed'));
    });

    test('Assigns yellow status for runway with restrictions', () {
      final notam = makeNotam('RWY 13R restricted for maintenance');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([notam]);
      expect(status.overallStatus, SystemStatus.yellow);
      expect(status.runways.first.status, SystemStatus.yellow);
      expect(status.runways.first.impacts, contains('Operational restrictions'));
    });

    test('Assigns yellow status for construction', () {
      final notam = makeNotam('RWY 31L open, construction work ongoing');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([notam]);
      expect(status.overallStatus, SystemStatus.yellow);
      expect(status.runways.first.impacts, contains('Construction work'));
    });

    test('Extracts ILS outages as operational impact', () {
      final notam = makeNotam('ILS RWY 04R out of service');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([notam]);
      expect(status.operationalImpacts, contains('ILS outages'));
    });

    test('Generates correct summary for closed and restricted runways', () {
      final closed = makeNotam('RWY 04L closed');
      final restricted = makeNotam('RWY 22R restricted');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([closed, restricted]);
      expect(status.summary, contains('1 runway(s) closed'));
    });

    test('Returns green status when all runways operational', () {
      final notam = makeNotam('Runway lights checked, all operational');
      final status = RunwayStatusAnalyzer.analyzeRunwayStatus([notam]);
      expect(status.overallStatus, SystemStatus.green);
    });
  });
} 