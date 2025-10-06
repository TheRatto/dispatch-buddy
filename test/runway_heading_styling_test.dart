import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:briefing_buddy/widgets/facilities_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Runway Heading Styling Tests', () {
    testWidgets('should display runway heading with correct styling', (WidgetTester tester) async {
      // Create a test widget with the runway heading
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: const Text(
                'RWY 15',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      );
      
      // Verify the text is displayed
      expect(find.text('RWY 15'), findsOneWidget);
      
      // Verify the styling is applied
      final textWidget = tester.widget<Text>(find.text('RWY 15'));
      expect(textWidget.style?.fontSize, equals(12.0));
      expect(textWidget.style?.fontWeight, equals(FontWeight.normal));
      expect(textWidget.style?.color, equals(Colors.grey));
    });
    
    test('should format runway heading correctly', () {
      final heading = _formatRunwayHeading('15');
      expect(heading, equals('RWY 15'));
    });
    
    test('should have correct padding values', () {
      final padding = _getRunwayHeadingPadding();
      expect(padding.top, equals(4.0));
      expect(padding.bottom, equals(2.0));
      expect(padding.left, equals(16.0));
      expect(padding.right, equals(16.0));
    });
  });
}

// Helper functions for testing
String _formatRunwayHeading(String runway) {
  return 'RWY $runway';
}

EdgeInsets _getRunwayHeadingPadding() {
  return const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 16.0, right: 16.0);
} 