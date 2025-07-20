import 'package:flutter_test/flutter_test.dart';
import '../lib/models/airport_infrastructure.dart';
import '../lib/data/airport_infrastructure_data.dart';

void main() {
  group('Airport Infrastructure Models', () {
    test('Runway model creation and properties', () {
      final runway = Runway(
        identifier: '07/25',
        length: 3962.0,
        surface: 'Asphalt',
        approaches: [],
        hasLighting: true,
        width: 60.0,
        status: 'OPERATIONAL',
        isPrimary: true,
      );

      expect(runway.identifier, '07/25');
      expect(runway.length, 3962.0);
      expect(runway.surface, 'Asphalt');
      expect(runway.hasLighting, true);
      expect(runway.width, 60.0);
      expect(runway.status, 'OPERATIONAL');
      expect(runway.isPrimary, true);
      expect(runway.statusEmoji, '🟢');
    });

    test('Taxiway model creation and properties', () {
      final taxiway = Taxiway(
        identifier: 'A',
        connections: ['07/25', '16L/34R'],
        width: 23.0,
        hasLighting: true,
        status: 'OPERATIONAL',
      );

      expect(taxiway.identifier, 'A');
      expect(taxiway.connections, ['07/25', '16L/34R']);
      expect(taxiway.width, 23.0);
      expect(taxiway.hasLighting, true);
      expect(taxiway.status, 'OPERATIONAL');
      expect(taxiway.statusEmoji, '🟢');
    });

    test('Navaid model creation and properties', () {
      final navaid = Navaid(
        identifier: 'ILS 07',
        frequency: '110.3',
        runway: '07/25',
        type: 'ILS',
        isPrimary: true,
        isBackup: false,
        status: 'OPERATIONAL',
      );

      expect(navaid.identifier, 'ILS 07');
      expect(navaid.frequency, '110.3');
      expect(navaid.runway, '07/25');
      expect(navaid.type, 'ILS');
      expect(navaid.isPrimary, true);
      expect(navaid.isBackup, false);
      expect(navaid.status, 'OPERATIONAL');
      expect(navaid.statusEmoji, '🟢');
    });

    test('Approach model creation and properties', () {
      final approach = Approach(
        identifier: 'ILS 07',
        type: 'ILS',
        runway: '07/25',
        minimums: 200.0,
        status: 'OPERATIONAL',
      );

      expect(approach.identifier, 'ILS 07');
      expect(approach.type, 'ILS');
      expect(approach.runway, '07/25');
      expect(approach.minimums, 200.0);
      expect(approach.status, 'OPERATIONAL');
      expect(approach.statusEmoji, '🟢');
    });

    test('AirportInfrastructure model creation and properties', () {
      final runway = Runway(
        identifier: '07/25',
        length: 3962.0,
        surface: 'Asphalt',
        approaches: [],
        hasLighting: true,
        width: 60.0,
        status: 'OPERATIONAL',
        isPrimary: true,
      );

      final taxiway = Taxiway(
        identifier: 'A',
        connections: ['07/25'],
        width: 23.0,
        hasLighting: true,
        status: 'OPERATIONAL',
      );

      final navaid = Navaid(
        identifier: 'ILS 07',
        frequency: '110.3',
        runway: '07/25',
        type: 'ILS',
        isPrimary: true,
        isBackup: false,
        status: 'OPERATIONAL',
      );

      final infrastructure = AirportInfrastructure(
        icao: 'YSSY',
        runways: [runway],
        taxiways: [taxiway],
        navaids: [navaid],
        approaches: [],
        routes: [],
        facilityStatus: {'RWY 07/25': 'OPERATIONAL'},
      );

      expect(infrastructure.icao, 'YSSY');
      expect(infrastructure.runways.length, 1);
      expect(infrastructure.taxiways.length, 1);
      expect(infrastructure.navaids.length, 1);
      expect(infrastructure.operationalRunways.length, 1);
      expect(infrastructure.operationalTaxiways.length, 1);
      expect(infrastructure.operationalNavaids.length, 1);
      expect(infrastructure.overallStatus, 'OPERATIONAL');
      expect(infrastructure.overallStatusEmoji, '🟢');
    });
  });

  group('Airport Infrastructure Data', () {
    test('Get airport infrastructure for YSSY', () {
      final infrastructure = AirportInfrastructureData.getAirportInfrastructure('YSSY');
      
      expect(infrastructure, isNotNull);
      expect(infrastructure!.icao, 'YSSY');
      expect(infrastructure.runways.length, 3);
      expect(infrastructure.taxiways.length, 4);
      expect(infrastructure.navaids.length, 5);
      expect(infrastructure.approaches.length, 8);
      expect(infrastructure.overallStatus, 'OPERATIONAL');
    });

    test('Get airport infrastructure for YPPH', () {
      final infrastructure = AirportInfrastructureData.getAirportInfrastructure('YPPH');
      
      expect(infrastructure, isNotNull);
      expect(infrastructure!.icao, 'YPPH');
      expect(infrastructure.runways.length, 2);
      expect(infrastructure.taxiways.length, 3);
      expect(infrastructure.navaids.length, 3);
      expect(infrastructure.approaches.length, 6);
      expect(infrastructure.overallStatus, 'OPERATIONAL');
    });

    test('Get airport infrastructure for non-existent airport', () {
      final infrastructure = AirportInfrastructureData.getAirportInfrastructure('XXXX');
      
      expect(infrastructure, isNull);
    });

    test('Get available airports', () {
      final airports = AirportInfrastructureData.getAvailableAirports();
      
      expect(airports, contains('YSSY'));
      expect(airports, contains('YPPH'));
      expect(airports, contains('YBBN'));
      expect(airports.length, 3);
    });

    test('Check if airport has infrastructure data', () {
      expect(AirportInfrastructureData.hasAirportInfrastructure('YSSY'), true);
      expect(AirportInfrastructureData.hasAirportInfrastructure('YPPH'), true);
      expect(AirportInfrastructureData.hasAirportInfrastructure('XXXX'), false);
    });

    test('Get database size', () {
      expect(AirportInfrastructureData.databaseSize, 3);
    });
  });

  group('Runway Status Analysis', () {
    test('Runway with ILS and VOR approaches', () {
      final runway = Runway(
        identifier: '07/25',
        length: 3962.0,
        surface: 'Asphalt',
        approaches: [
          Approach(identifier: 'ILS 07', type: 'ILS', runway: '07/25', minimums: 200.0, status: 'OPERATIONAL'),
          Approach(identifier: 'VOR 07', type: 'VOR', runway: '07/25', minimums: 300.0, status: 'OPERATIONAL'),
        ],
        hasLighting: true,
        width: 60.0,
        status: 'OPERATIONAL',
        isPrimary: true,
      );

      expect(runway.hasILS, true);
      expect(runway.hasVOR, true);
      expect(runway.availableApproaches.length, 2);
    });

    test('Runway with only VOR approach', () {
      final runway = Runway(
        identifier: '06/24',
        length: 2164.0,
        surface: 'Asphalt',
        approaches: [
          Approach(identifier: 'VOR 06', type: 'VOR', runway: '06/24', minimums: 300.0, status: 'OPERATIONAL'),
        ],
        hasLighting: true,
        width: 45.0,
        status: 'OPERATIONAL',
        isPrimary: false,
      );

      expect(runway.hasILS, false);
      expect(runway.hasVOR, true);
      expect(runway.availableApproaches.length, 1);
    });
  });
} 