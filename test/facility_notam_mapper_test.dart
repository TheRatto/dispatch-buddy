import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/services/facility_notam_mapper.dart';

void main() {
  group('FacilityNotamMapper', () {
    late FacilityNotamMapper mapper;
    late List<Notam> testNotams;

    setUp(() {
      mapper = FacilityNotamMapper();
      
      // Create test NOTAMs
      testNotams = [
        Notam(
          id: '1',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 07/25 CLOSED DUE TO MAINTENANCE',
          decodedText: 'Runway 07/25 closed due to maintenance',
          affectedSystem: 'runway',
          isCritical: true,
          qCode: 'QMRLC',
          group: NotamGroup.runways,
        ),
        Notam(
          id: '2',
          icao: 'YSSY',
          type: NotamType.navaid,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'ILS RWY 07 UNSERVICEABLE',
          decodedText: 'ILS for runway 07 unserviceable',
          affectedSystem: 'navaid',
          isCritical: true,
          qCode: 'QICAS',
          group: NotamGroup.instrumentProcedures,
        ),
        Notam(
          id: '3',
          icao: 'YSSY',
          type: NotamType.taxiway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'TAXIWAY A CLOSED FOR REPAIRS',
          decodedText: 'Taxiway A closed for repairs',
          affectedSystem: 'taxiway',
          isCritical: false,
          qCode: 'QMX',
          group: NotamGroup.taxiways,
        ),
        Notam(
          id: '4',
          icao: 'YSSY',
          type: NotamType.lighting,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'PAPI RWY 07 UNAVAILABLE',
          decodedText: 'PAPI for runway 07 unavailable',
          affectedSystem: 'lighting',
          isCritical: false,
          qCode: 'QOLAS',
          group: NotamGroup.runways,
        ),
        Notam(
          id: '5',
          icao: 'YSSY',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 16L/34R DISPLACED THRESHOLD 500FT',
          decodedText: 'Runway 16L/34R displaced threshold 500ft',
          affectedSystem: 'runway',
          isCritical: false,
          qCode: 'QMRLC',
          group: NotamGroup.runways,
        ),
        Notam(
          id: '6',
          icao: 'YSSY',
          type: NotamType.navaid,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'VOR SYD UNSERVICEABLE',
          decodedText: 'VOR SYD unserviceable',
          affectedSystem: 'navaid',
          isCritical: true,
          qCode: 'QNV',
          group: NotamGroup.instrumentProcedures,
        ),
      ];
    });

    group('getRunwayNotams', () {
      test('should return NOTAMs affecting specific runway', () {
        final runwayNotams = mapper.getRunwayNotams(testNotams, '07/25');
        
        expect(runwayNotams.length, 1);
        expect(runwayNotams.first.id, '1');
        expect(runwayNotams.first.rawText, contains('RWY 07/25 CLOSED'));
      });

      test('should return NOTAMs affecting runway with single direction', () {
        final runwayNotams = mapper.getAllRunwayAffectingNotams(testNotams, '07');
        
        expect(runwayNotams.length, 3); // 07/25, ILS 07, and PAPI 07
        expect(runwayNotams.any((n) => n.id == '1'), true); // 07/25
        expect(runwayNotams.any((n) => n.id == '2'), true); // ILS 07
        expect(runwayNotams.any((n) => n.id == '4'), true); // PAPI 07
      });

      test('should return empty list for non-existent runway', () {
        final runwayNotams = mapper.getRunwayNotams(testNotams, '99/99');
        
        expect(runwayNotams, isEmpty);
      });
    });

    group('getNavaidNotams', () {
      test('should return NOTAMs affecting specific NAVAID', () {
        final navaidNotams = mapper.getNavaidNotams(testNotams, 'ILS 07');
        
        expect(navaidNotams.length, 1);
        expect(navaidNotams.first.id, '2');
        expect(navaidNotams.first.rawText, contains('ILS RWY 07'));
      });

      test('should return NOTAMs affecting VOR', () {
        final navaidNotams = mapper.getNavaidNotams(testNotams, 'VOR SYD');
        
        expect(navaidNotams.length, 1);
        expect(navaidNotams.first.id, '6');
        expect(navaidNotams.first.rawText, contains('VOR SYD'));
      });

      test('should return empty list for non-existent NAVAID', () {
        final navaidNotams = mapper.getNavaidNotams(testNotams, 'ILS 99');
        
        expect(navaidNotams, isEmpty);
      });
    });

    group('getTaxiwayNotams', () {
      test('should return NOTAMs affecting specific taxiway', () {
        final taxiwayNotams = mapper.getTaxiwayNotams(testNotams, 'A');
        
        expect(taxiwayNotams.length, 1);
        expect(taxiwayNotams.first.id, '3');
        expect(taxiwayNotams.first.rawText, contains('TAXIWAY A'));
      });

      test('should return empty list for non-existent taxiway', () {
        final taxiwayNotams = mapper.getTaxiwayNotams(testNotams, 'Z');
        
        expect(taxiwayNotams, isEmpty);
      });
    });

    group('getLightingNotams', () {
      test('should return NOTAMs affecting specific lighting system', () {
        final lightingNotams = mapper.getLightingNotams(testNotams, 'PAPI');
        
        expect(lightingNotams.length, 1);
        expect(lightingNotams.first.id, '4');
        expect(lightingNotams.first.rawText, contains('PAPI RWY 07'));
      });

      test('should return empty list for non-existent lighting system', () {
        final lightingNotams = mapper.getLightingNotams(testNotams, 'UNKNOWN');
        
        expect(lightingNotams, isEmpty);
      });
    });

    group('getFacilityNotams', () {
      test('should return runway NOTAMs when facility type is runway', () {
        final facilityNotams = mapper.getFacilityNotams(testNotams, 'runway', '07/25');
        
        expect(facilityNotams.length, 1);
        expect(facilityNotams.first.id, '1');
      });

      test('should return NAVAID NOTAMs when facility type is navaid', () {
        final facilityNotams = mapper.getFacilityNotams(testNotams, 'navaid', 'ILS 07');
        
        expect(facilityNotams.length, 1);
        expect(facilityNotams.first.id, '2');
      });

      test('should return empty list for unknown facility type', () {
        final facilityNotams = mapper.getFacilityNotams(testNotams, 'unknown', 'test');
        
        expect(facilityNotams, isEmpty);
      });
    });

    group('Pattern Matching', () {
      test('should match runway patterns correctly', () {
        final notam = Notam(
          id: 'test',
          icao: 'TEST',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'RWY 16L/34R CLOSED',
          decodedText: 'Runway 16L/34R closed',
          affectedSystem: 'runway',
          isCritical: true,
          qCode: 'QMRLC',
          group: NotamGroup.runways,
        );
        
        expect(mapper.getRunwayNotams([notam], '16L/34R').length, 1);
        expect(mapper.getRunwayNotams([notam], '16L').length, 1);
        expect(mapper.getRunwayNotams([notam], '34R').length, 1);
      });

      test('should match NAVAID patterns correctly', () {
        final notam = Notam(
          id: 'test',
          icao: 'TEST',
          type: NotamType.navaid,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'VOR TEST UNSERVICEABLE',
          decodedText: 'VOR TEST unserviceable',
          affectedSystem: 'navaid',
          isCritical: true,
          qCode: 'QNV',
          group: NotamGroup.instrumentProcedures,
        );
        
        expect(mapper.getNavaidNotams([notam], 'VOR TEST').length, 1);
        expect(mapper.getNavaidNotams([notam], 'TEST').length, 1);
      });
    });
  });
}
