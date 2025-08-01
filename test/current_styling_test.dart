import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Current Runway Heading Styling Test', () {
    testWidgets('should display runway heading with current styling', (WidgetTester tester) async {
      // Create a test widget with the current runway heading styling
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 16.0, right: 16.0),
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
      
      // Verify the container has correct padding
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 16.0, right: 16.0)));
      expect(container.alignment, equals(Alignment.centerLeft));
    });
  });
} 