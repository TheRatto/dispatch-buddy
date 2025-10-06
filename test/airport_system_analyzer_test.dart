import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/models/airport.dart';
import 'package:briefing_buddy/services/airport_system_analyzer.dart';

void main() {
  group('AirportSystemAnalyzer', () {
    late AirportSystemAnalyzer analyzer;

    setUp(() {
      analyzer = AirportSystemAnalyzer();
    });

    group('Runway Status Analysis', () {
      test('should return green when no runway NOTAMs exist', () {
        final notams = <Notam>[];
        final status = analyzer.analyzeRunwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.green));
      });

      test('should return red when runway is closed', () {
        final notams = [
          Notam(
            id: 'A1234/24',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RWY 03/21 CLOSED DUE TO MAINTENANCE',
            decodedText: 'Runway 03/21 closed due to maintenance',
            affectedSystem: 'Runways',
            isCritical: true,
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.red));
      });

      test('should return yellow when runway has maintenance', () {
        final notams = [
          Notam(
            id: 'A1235/24',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RWY 03/21 MAINTENANCE WORK IN PROGRESS',
            decodedText: 'Runway 03/21 maintenance work in progress',
            affectedSystem: 'Runways',
            isCritical: false,
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.yellow));
      });
    });

    group('Navaid Status Analysis', () {
      test('should return green when no navaid NOTAMs exist', () {
        final notams = <Notam>[];
        final status = analyzer.analyzeNavaidStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.green));
      });

      test('should return red when ILS is unserviceable', () {
        final notams = [
          Notam(
            id: 'A1236/24',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'ILS RWY 03 U/S',
            decodedText: 'ILS Runway 03 unserviceable',
            affectedSystem: 'Navaids',
            isCritical: true,
            group: NotamGroup.instrumentProcedures,
          ),
        ];

        final status = analyzer.analyzeNavaidStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.red));
      });
    });

    group('Taxiway Status Analysis', () {
      test('should return green when no taxiway NOTAMs exist', () {
        final notams = <Notam>[];
        final status = analyzer.analyzeTaxiwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.green));
      });

      test('should return yellow when taxiway has construction', () {
        final notams = [
          Notam(
            id: 'A1237/24',
            icao: 'YPPH',
            type: NotamType.taxiway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'TWY A CONSTRUCTION WORK IN PROGRESS',
            decodedText: 'Taxiway A construction work in progress',
            affectedSystem: 'Taxiways',
            isCritical: false,
            group: NotamGroup.taxiways,
          ),
        ];

        final status = analyzer.analyzeTaxiwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.yellow));
      });
    });

    group('Lighting Status Analysis', () {
      test('should return green when no lighting NOTAMs exist', () {
        final notams = <Notam>[];
        final status = analyzer.analyzeLightingStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.green));
      });

      test('should return red when runway lighting is unserviceable', () {
        final notams = [
          Notam(
            id: 'A1238/24',
            icao: 'YPPH',
            type: NotamType.lighting,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RUNWAY LIGHTING U/S',
            decodedText: 'Runway lighting unserviceable',
            affectedSystem: 'Lighting',
            isCritical: true,
            group: NotamGroup.airportServices,
          ),
        ];

        final status = analyzer.analyzeLightingStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.red));
      });
    });

    group('System NOTAMs Mapping', () {
      test('should correctly map NOTAMs to systems', () {
        final notams = [
          // Runway NOTAM
          Notam(
            id: 'A1234/24',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RWY 03/21 MAINTENANCE',
            decodedText: 'Runway 03/21 maintenance',
            affectedSystem: 'Runways',
            isCritical: false,
            group: NotamGroup.runways,
          ),
          // Navaid NOTAM
          Notam(
            id: 'A1235/24',
            icao: 'YPPH',
            type: NotamType.navaid,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'ILS RWY 03 U/S',
            decodedText: 'ILS Runway 03 unserviceable',
            affectedSystem: 'Navaids',
            isCritical: true,
            group: NotamGroup.instrumentProcedures,
          ),
          // Taxiway NOTAM
          Notam(
            id: 'A1236/24',
            icao: 'YPPH',
            type: NotamType.taxiway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'TWY A CONSTRUCTION',
            decodedText: 'Taxiway A construction',
            affectedSystem: 'Taxiways',
            isCritical: false,
            group: NotamGroup.taxiways,
          ),
          // Lighting NOTAM
          Notam(
            id: 'A1237/24',
            icao: 'YPPH',
            type: NotamType.lighting,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RUNWAY LIGHTING U/S',
            decodedText: 'Runway lighting unserviceable',
            affectedSystem: 'Lighting',
            isCritical: true,
            group: NotamGroup.airportServices,
          ),
        ];

        final systemNotams = analyzer.getSystemNotams(notams, 'YPPH');

        // With new grouping system, runway lighting is in airportServices group
        expect(systemNotams['runways'], hasLength(1));
        expect(systemNotams['navaids'], hasLength(1));
        expect(systemNotams['taxiways'], hasLength(1));
        expect(systemNotams['lighting'], hasLength(1));

        // Check that NOTAMs are in correct groups
        final runwayIds = systemNotams['runways']!.map((n) => n.id).toList();
        expect(runwayIds, contains('A1234/24')); // Runway NOTAM
        
        expect(systemNotams['navaids']!.first.id, equals('A1235/24'));
        expect(systemNotams['taxiways']!.first.id, equals('A1236/24'));
        expect(systemNotams['lighting']!.first.id, equals('A1237/24')); // Lighting NOTAM
      });
    });

    group('Status Calculation Logic', () {
      test('should prioritize critical NOTAMs as red', () {
        final notams = [
          Notam(
            id: 'A1234/24',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RWY 03/21 MAINTENANCE',
            decodedText: 'Runway 03/21 maintenance',
            affectedSystem: 'Runways',
            isCritical: true, // Critical should override maintenance
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.red));
      });

      test('should prioritize closures over maintenance', () {
        final notams = [
          Notam(
            id: 'A1234/24',
            icao: 'YPPH',
            type: NotamType.runway,
            validFrom: DateTime.now(),
            validTo: DateTime.now().add(Duration(days: 30)),
            rawText: 'RWY 03/21 CLOSED',
            decodedText: 'Runway 03/21 closed',
            affectedSystem: 'Runways',
            isCritical: false, // Not critical but closed
            group: NotamGroup.runways,
          ),
        ];

        final status = analyzer.analyzeRunwayStatus(notams, 'YPPH');
        expect(status, equals(SystemStatus.red));
      });
    });
  });
} 