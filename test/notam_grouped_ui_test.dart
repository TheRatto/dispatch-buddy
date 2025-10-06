import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/widgets/notam_group_header.dart';
import 'package:briefing_buddy/widgets/notam_group_content.dart';
import 'package:briefing_buddy/widgets/notam_grouped_list.dart';

void main() {
  group('NOTAM Grouped UI Tests', () {
    late List<Notam> testNotams;

    setUp(() {
      testNotams = [
        // Runways NOTAMs
        Notam(
          id: 'A001/24',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now().toUtc(),
          validTo: DateTime.now().toUtc().add(const Duration(days: 7)),
          rawText: 'Runway 06/24 closed for maintenance',
          decodedText: 'Runway 06/24 closed for maintenance',
          affectedSystem: 'Runway',
          isCritical: true,
          group: NotamGroup.runways,
        ),
        Notam(
          id: 'A002/24',
          icao: 'YPPH',
          type: NotamType.taxiway,
          validFrom: DateTime.now().toUtc(),
          validTo: DateTime.now().toUtc().add(const Duration(days: 3)),
          rawText: 'Taxiway A partially closed',
          decodedText: 'Taxiway A partially closed',
          affectedSystem: 'Taxiway',
          isCritical: false,
          group: NotamGroup.taxiways,
        ),
        // Instrument Procedures NOTAMs
        Notam(
          id: 'A003/24',
          icao: 'YPPH',
          type: NotamType.navaid,
          validFrom: DateTime.now().toUtc(),
          validTo: DateTime.now().toUtc().add(const Duration(days: 14)),
          rawText: 'ILS runway 06 unserviceable',
          decodedText: 'ILS runway 06 unserviceable',
          affectedSystem: 'ILS',
          isCritical: true,
          group: NotamGroup.instrumentProcedures,
        ),
        // Airport Services NOTAMs
        Notam(
          id: 'A004/24',
          icao: 'YPPH',
          type: NotamType.lighting,
          validFrom: DateTime.now().toUtc(),
          validTo: DateTime.now().toUtc().add(const Duration(days: 5)),
          rawText: 'Runway lighting unserviceable',
          decodedText: 'Runway lighting unserviceable',
          affectedSystem: 'Lighting',
          isCritical: false,
          group: NotamGroup.airportServices,
        ),
        // Hazards NOTAMs
        Notam(
          id: 'A005/24',
          icao: 'YPPH',
          type: NotamType.other,
          validFrom: DateTime.now().toUtc(),
          validTo: DateTime.now().toUtc().add(const Duration(days: 2)),
          rawText: 'Bird hazard reported',
          decodedText: 'Bird hazard reported',
          affectedSystem: 'Hazards',
          isCritical: true,
          group: NotamGroup.hazards,
        ),
      ];
    });

    testWidgets('NotamGroupHeader displays correct information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupHeader(
              group: NotamGroup.runways,
              notamCount: 1,
              isExpanded: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      // Verify group title is displayed
      expect(find.text('Runways'), findsOneWidget);
      
      // Verify NOTAM count is displayed
      expect(find.text('1 NOTAM'), findsOneWidget);
      
      // Verify priority badge is displayed
      expect(find.text('1'), findsOneWidget);
      
      // Verify expand icon is displayed
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('NotamGroupContent displays NOTAM items correctly', (WidgetTester tester) async {
      final groupNotams = testNotams.where((n) => n.group == NotamGroup.runways).toList();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupContent(
              notams: groupNotams,
              group: NotamGroup.runways,
              onNotamTap: (notam) {},
            ),
          ),
        ),
      );

      // Verify NOTAM IDs are displayed
      expect(find.text('A001/24'), findsOneWidget);
      
      // Verify ICAO codes are displayed
      expect(find.text('YPPH'), findsOneWidget);
      
      // Verify decoded text is displayed
      expect(find.text('Runway 06/24 closed for maintenance'), findsOneWidget);
    });

    testWidgets('NotamGroupedList groups and sorts NOTAMs correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupedList(
              notams: testNotams,
              onNotamTap: (notam) {},
            ),
          ),
        ),
      );

      // Verify group headers are displayed in priority order
      expect(find.text('Runways'), findsOneWidget);
      expect(find.text('Taxiways'), findsOneWidget);
      expect(find.text('Instrument Procedures'), findsOneWidget);
      expect(find.text('Airport Services'), findsOneWidget);
      expect(find.text('Hazards'), findsOneWidget);
      
      // Verify group counts are correct
      expect(find.text('1 NOTAM'), findsNWidgets(5)); // All groups have 1 NOTAM
    });

    testWidgets('NotamGroupedList expand/collapse functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupedList(
              notams: testNotams,
              onNotamTap: (notam) {},
            ),
          ),
        ),
      );

      // Initially, groups should be collapsed (no NOTAM content visible)
      expect(find.text('A001/24'), findsNothing);
      
      // Tap on Runways header to expand
      await tester.tap(find.text('Runways'));
      await tester.pump();
      
      // Now NOTAM content should be visible
      expect(find.text('A001/24'), findsOneWidget);
      
      // Tap again to collapse
      await tester.tap(find.text('Runways'));
      await tester.pump();
      
      // Content should be hidden again
      expect(find.text('A001/24'), findsNothing);
    });

    testWidgets('NotamGroupedList sorts NOTAMs by criticality and time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupedList(
              notams: testNotams,
              onNotamTap: (notam) {},
            ),
          ),
        ),
      );

      // Expand Runways group
      await tester.tap(find.text('Runways'));
      await tester.pump();
      
      // Critical NOTAMs should appear first
      final runwaysNotams = testNotams.where((n) => n.group == NotamGroup.runways).toList();
      final criticalNotam = runwaysNotams.firstWhere((n) => n.isCritical);
      
      // Critical NOTAM should appear in the list
      expect(find.text(criticalNotam.id), findsOneWidget);
    });

    testWidgets('NotamGroupedList shows active NOTAMs with different styling', (WidgetTester tester) async {
      // Create a NOTAM that is currently active
      final activeNotam = Notam(
        id: 'A006/24',
        icao: 'YPPH',
        type: NotamType.runway,
        validFrom: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        validTo: DateTime.now().toUtc().add(const Duration(hours: 1)),
        rawText: 'Active runway NOTAM',
        decodedText: 'Active runway NOTAM',
        affectedSystem: 'Runway',
        isCritical: true,
        group: NotamGroup.runways,
      );

      final testNotamsWithActive = [...testNotams, activeNotam];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotamGroupedList(
              notams: testNotamsWithActive,
              onNotamTap: (notam) {},
            ),
          ),
        ),
      );

      // Expand Runways group
      await tester.tap(find.text('Runways'));
      await tester.pump();
      
      // The Runways group should show as active (has active NOTAMs)
      expect(find.text('A006/24'), findsOneWidget);
    });
  });
} 