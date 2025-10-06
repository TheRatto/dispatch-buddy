import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/services/notam_grouping_service.dart';

void main() {
  group('NOTAM Model Tests', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now().toUtc();
    });

    group('NOTAM Creation and Properties', () {
      test('should create NOTAM with correct properties', () {
        final notam = Notam(
          id: 'TEST123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Test NOTAM',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.runways,
        );

        expect(notam.id, 'TEST123');
        expect(notam.icao, 'YPPH');
        expect(notam.type, NotamType.runway);
        expect(notam.validFrom, now);
        expect(notam.validTo, now.add(Duration(hours: 1)));
        expect(notam.rawText, 'Test NOTAM');
        expect(notam.decodedText, 'Decoded test NOTAM');
        expect(notam.affectedSystem, 'RWY');
        expect(notam.isCritical, isTrue);
      });

      test('should handle currently active NOTAMs', () {
        final activeNotam = Notam(
          id: 'ACTIVE123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now.subtract(Duration(hours: 1)),
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Active NOTAM',
          decodedText: 'Currently active NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.runways,
        );

        expect(activeNotam.validFrom.isBefore(now), isTrue);
        expect(activeNotam.validTo.isAfter(now), isTrue);
      });

      test('should handle future NOTAMs', () {
        final futureNotam = Notam(
          id: 'FUTURE123',
          icao: 'YPPH',
          type: NotamType.navaid,
          validFrom: now.add(Duration(hours: 6)),
          validTo: now.add(Duration(hours: 12)),
          rawText: 'Future NOTAM',
          decodedText: 'Future active NOTAM',
          affectedSystem: 'NAVAID',
          isCritical: false,
          group: NotamGroup.instrumentProcedures,
        );

        expect(futureNotam.validFrom.isAfter(now), isTrue);
        expect(futureNotam.validTo.isAfter(futureNotam.validFrom), isTrue);
      });

      test('should handle past NOTAMs', () {
        final pastNotam = Notam(
          id: 'PAST123',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: now.subtract(Duration(days: 2)),
          validTo: now.subtract(Duration(days: 1)),
          rawText: 'Past NOTAM',
          decodedText: 'Past NOTAM',
          affectedSystem: 'TAXIWAY',
          isCritical: false,
          group: NotamGroup.taxiways,
        );

        expect(pastNotam.validFrom.isBefore(now), isTrue);
        expect(pastNotam.validTo.isBefore(now), isTrue);
      });
    });

    group('NOTAM Type Classification', () {
      test('should classify runway NOTAMs correctly', () {
        final runwayNotam = Notam(
          id: 'RWY123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'RWY 06/24 closed for maintenance',
          decodedText: 'Runway 06/24 closed for maintenance',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.runways,
        );

        expect(runwayNotam.type, NotamType.runway);
        expect(runwayNotam.affectedSystem, 'RWY');
      });

      test('should classify navaid NOTAMs correctly', () {
        final navaidNotam = Notam(
          id: 'NAV123',
          icao: 'YPPH',
          type: NotamType.navaid,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'ILS approach unavailable',
          decodedText: 'ILS approach unavailable',
          affectedSystem: 'NAVAID',
          isCritical: false,
          group: NotamGroup.instrumentProcedures,
        );

        expect(navaidNotam.type, NotamType.navaid);
        expect(navaidNotam.affectedSystem, 'NAVAID');
      });

      test('should classify taxiway NOTAMs correctly', () {
        final taxiwayNotam = Notam(
          id: 'TWY123',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Taxiway A closed',
          decodedText: 'Taxiway A closed',
          affectedSystem: 'TAXIWAY',
          isCritical: false,
          group: NotamGroup.taxiways,
        );

        expect(taxiwayNotam.type, NotamType.taxiway);
        expect(taxiwayNotam.affectedSystem, 'TAXIWAY');
      });

      test('should classify airspace NOTAMs correctly', () {
        final airspaceNotam = Notam(
          id: 'AIR123',
          icao: 'YPPH',
          type: NotamType.airspace,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Airspace restricted',
          decodedText: 'Airspace restricted',
          affectedSystem: 'AIRSPACE',
          isCritical: false,
          group: NotamGroup.instrumentProcedures,
        );

        expect(airspaceNotam.type, NotamType.airspace);
        expect(airspaceNotam.affectedSystem, 'AIRSPACE');
      });

      test('should classify other NOTAMs correctly', () {
        final otherNotam = Notam(
          id: 'OTH123',
          icao: 'YPPH',
          type: NotamType.other,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'General information',
          decodedText: 'General information',
          affectedSystem: 'OTHER',
          isCritical: false,
          group: NotamGroup.other,
        );

        expect(otherNotam.type, NotamType.other);
        expect(otherNotam.affectedSystem, 'OTHER');
      });
    });

    group('Critical NOTAM Detection', () {
      test('should identify critical NOTAMs', () {
        final criticalNotam = Notam(
          id: 'CRIT123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Critical runway closure',
          decodedText: 'Critical runway closure',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.runways,
        );

        expect(criticalNotam.isCritical, isTrue);
        expect(criticalNotam.type, NotamType.runway);
      });

      test('should identify non-critical NOTAMs', () {
        final nonCriticalNotam = Notam(
          id: 'NONCRIT123',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Non-critical taxiway closure',
          decodedText: 'Non-critical taxiway closure',
          affectedSystem: 'TAXIWAY',
          isCritical: false,
          group: NotamGroup.taxiways,
        );

        expect(nonCriticalNotam.isCritical, isFalse);
        expect(nonCriticalNotam.type, NotamType.taxiway);
      });
    });

    group('NOTAM Group Classification', () {
      test('should classify runway NOTAMs to runways group', () {
        final runwayNotam = Notam(
          id: 'RWY123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'RWY 06/24 closed',
          decodedText: 'Runway 06/24 closed',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.runways,
        );

        expect(runwayNotam.group, NotamGroup.runways);
      });

      test('should classify taxiway NOTAMs to taxiways group', () {
        final taxiwayNotam = Notam(
          id: 'TWY123',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Taxiway A closed',
          decodedText: 'Taxiway A closed',
          affectedSystem: 'TAXIWAY',
          isCritical: false,
          group: NotamGroup.taxiways,
        );

        expect(taxiwayNotam.group, NotamGroup.taxiways);
      });

      test('should classify navaid NOTAMs to instrument procedures group', () {
        final navaidNotam = Notam(
          id: 'NAV123',
          icao: 'YPPH',
          type: NotamType.navaid,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'ILS unavailable',
          decodedText: 'ILS unavailable',
          affectedSystem: 'NAVAID',
          isCritical: true,
          group: NotamGroup.instrumentProcedures,
        );

        expect(navaidNotam.group, NotamGroup.instrumentProcedures);
      });

      test('should classify lighting NOTAMs to airport services group', () {
        final lightingNotam = Notam(
          id: 'LIGHT123',
          icao: 'YPPH',
          type: NotamType.lighting,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Runway lighting unserviceable',
          decodedText: 'Runway lighting unserviceable',
          affectedSystem: 'LIGHTING',
          isCritical: false,
          group: NotamGroup.airportServices,
        );

        expect(lightingNotam.group, NotamGroup.airportServices);
      });

      test('should classify hazard NOTAMs to hazards group', () {
        final hazardNotam = Notam(
          id: 'HAZARD123',
          icao: 'YPPH',
          type: NotamType.other,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Bird hazard reported',
          decodedText: 'Bird hazard reported',
          affectedSystem: 'HAZARD',
          isCritical: true,
          group: NotamGroup.hazards,
        );

        expect(hazardNotam.group, NotamGroup.hazards);
      });
    });
  });
} 