import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';

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
          group: NotamGroup.movementAreas,
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
          group: NotamGroup.movementAreas,
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
          group: NotamGroup.navigationAids,
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
          group: NotamGroup.movementAreas,
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
          group: NotamGroup.movementAreas,
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
          group: NotamGroup.navigationAids,
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
          group: NotamGroup.movementAreas,
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
          group: NotamGroup.airspace,
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
          group: NotamGroup.movementAreas,
        );

        expect(criticalNotam.isCritical, isTrue);
      });

      test('should identify normal NOTAMs', () {
        final normalNotam = Notam(
          id: 'NORM123',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Normal taxiway maintenance',
          decodedText: 'Normal taxiway maintenance',
          affectedSystem: 'TAXIWAY',
          isCritical: false,
          group: NotamGroup.movementAreas,
        );

        expect(normalNotam.isCritical, isFalse);
      });
    });

    group('NOTAM Serialization', () {
      test('should serialize and deserialize correctly', () {
        final originalNotam = Notam(
          id: 'SER123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Serialization test NOTAM',
          decodedText: 'Decoded serialization test NOTAM',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.movementAreas,
        );

        final json = originalNotam.toJson();
        final deserializedNotam = Notam.fromJson(json);

        expect(deserializedNotam.id, originalNotam.id);
        expect(deserializedNotam.icao, originalNotam.icao);
        expect(deserializedNotam.type, originalNotam.type);
        expect(deserializedNotam.validFrom, originalNotam.validFrom);
        expect(deserializedNotam.validTo, originalNotam.validTo);
        expect(deserializedNotam.rawText, originalNotam.rawText);
        expect(deserializedNotam.decodedText, originalNotam.decodedText);
        expect(deserializedNotam.affectedSystem, originalNotam.affectedSystem);
        expect(deserializedNotam.isCritical, originalNotam.isCritical);
      });

      test('should handle database serialization', () {
        final originalNotam = Notam(
          id: 'DB123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Database test NOTAM',
          decodedText: 'Decoded database test NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.movementAreas,
        );

        final dbJson = originalNotam.toDbJson('FLIGHT123');
        final deserializedNotam = Notam.fromDbJson(dbJson);

        expect(deserializedNotam.id, originalNotam.id);
        expect(deserializedNotam.icao, originalNotam.icao);
        expect(deserializedNotam.type, originalNotam.type);
        expect(deserializedNotam.validFrom, originalNotam.validFrom);
        expect(deserializedNotam.validTo, originalNotam.validTo);
        expect(deserializedNotam.rawText, originalNotam.rawText);
        expect(deserializedNotam.decodedText, originalNotam.decodedText);
        expect(deserializedNotam.affectedSystem, originalNotam.affectedSystem);
        expect(deserializedNotam.isCritical, originalNotam.isCritical);
      });
    });

    group('NOTAM Validation', () {
      test('should validate NOTAM dates', () {
        final validNotam = Notam(
          id: 'VALID123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now,
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Valid NOTAM',
          decodedText: 'Valid NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.movementAreas,
        );

        expect(validNotam.validFrom.isBefore(validNotam.validTo), isTrue);
      });

      test('should handle permanent NOTAMs', () {
        final permanentNotam = Notam(
          id: 'PERM123',
          icao: 'YPPH',
          type: NotamType.other,
          validFrom: now.subtract(Duration(days: 30)),
          validTo: now.add(Duration(days: 365 * 10)), // 10 years in future
          rawText: 'Permanent NOTAM',
          decodedText: 'Permanent NOTAM',
          affectedSystem: 'OTHER',
          isCritical: false,
          group: NotamGroup.other,
        );

        expect(permanentNotam.validTo.isAfter(now.add(Duration(days: 365 * 5))), isTrue);
      });
    });
  });
} 