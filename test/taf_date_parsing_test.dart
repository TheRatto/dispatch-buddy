import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/decoder_service.dart';

void main() {
  group('TAF Date Parsing Tests', () {
    late DecoderService decoderService;

    setUp(() {
      decoderService = DecoderService();
    });

    group('Core Logic Tests', () {
      test('should use current month for TAF validity periods (FIXED BUG)', () {
        // This test verifies the fix for the original bug
        // The bug was: comparing days to determine month
        // The fix is: always use current month for TAF validity periods
        
        final day = 15; // 15th of month
        final hour = 15; // 15:00
        
        final result = decoderService.createDateTimeWithMonthTransition(day, hour, 0);
        
        // Should use current month, not compare days
        expect(result.day, equals(15));
        expect(result.hour, equals(15));
        
        // This is the key fix - should use current month regardless of day value
        final now = DateTime.now();
        expect(result.month, equals(now.month));
        expect(result.year, equals(now.year));
      });

      test('should handle month transition in end time correctly', () {
        // Test that end time correctly increments month when needed
        final startTime = DateTime(2024, 6, 30, 20, 0); // 30th 20:00
        final endDay = 1; // 1st of next month
        final endHour = 0; // 00:00
        
        final result = decoderService.createEndDateTimeWithMonthTransition(startTime, endDay, endHour);
        
        expect(result.day, equals(1));
        expect(result.hour, equals(0));
        expect(result.month, equals(7)); // Should increment to next month
      });

      test('should not increment month when end day >= start day', () {
        // Test that month stays the same when end day is >= start day
        final startTime = DateTime(2024, 6, 15, 20, 0); // 15th 20:00
        final endDay = 16; // 16th (same month)
        final endHour = 0; // 00:00
        
        final result = decoderService.createEndDateTimeWithMonthTransition(startTime, endDay, endHour);
        
        expect(result.day, equals(16));
        expect(result.hour, equals(0));
        expect(result.month, equals(6)); // Should stay in same month
      });
    });

    group('Timeline Creation Tests', () {
      test('should create timeline for TAF validity period', () {
        // Test that timeline creation works with the fixed logic
        final tafText = 'TAF YSSY 151500Z 1515/1600 12015KT CAVOK';
        final timeline = decoderService.createTimelineFromTaf(tafText);
        
        expect(timeline, isNotEmpty);
        expect(timeline.first.day, equals(15));
        expect(timeline.first.hour, equals(15));
        
        // Timeline should span multiple hours
        expect(timeline.length, greaterThan(1));
      });

      test('should handle the specific problematic case 2315/2500', () {
        // This was the original bug case that was causing highlighting issues
        final tafText = 'TAF YSSY 231500Z 2315/2500 12015KT CAVOK';
        final timeline = decoderService.createTimelineFromTaf(tafText);
        
        // Verify the fix works - should create correct timeline
        expect(timeline, isNotEmpty);
        expect(timeline.first.day, equals(23));
        expect(timeline.first.hour, equals(15));
        
        // Should span multiple days
        expect(timeline.length, greaterThan(24)); // More than 24 hours
      });

      test('should handle TAF format with space before Z (NAIPS format)', () {
        // This tests the specific format that was failing: "120503 Z" instead of "120503Z"
        final tafText = 'TAF YPPH 120503 Z 1206/1312 02010KT CAVOK';
        final timeline = decoderService.createTimelineFromTaf(tafText);
        
        // Should now work correctly with the regex fix
        expect(timeline, isNotEmpty);
        expect(timeline.first.day, equals(12));
        expect(timeline.first.hour, equals(6));
        
        // Should span multiple days (12th to 13th)
        expect(timeline.length, greaterThan(24)); // More than 24 hours
      });

      test('should handle month boundary case 3020/0100', () {
        // This tests month transition logic
        final tafText = 'TAF YSSY 302000Z 3020/0100 12015KT CAVOK';
        final timeline = decoderService.createTimelineFromTaf(tafText);
        
        expect(timeline, isNotEmpty);
        expect(timeline.first.day, equals(30));
        expect(timeline.first.hour, equals(20));
        
        // Should handle month transition correctly (4 hours: 20:00-00:00)
        expect(timeline.length, equals(4)); // 4 hours for 3020/0100
      });
    });

    group('Edge Cases', () {
      test('should handle invalid TAF format gracefully', () {
        final invalidTaf = 'TAF YSSY 151500Z INVALID_FORMAT';
        final timeline = decoderService.createTimelineFromTaf(invalidTaf);
        
        expect(timeline, isEmpty);
      });

      test('should handle very short validity period', () {
        final shortTaf = 'TAF YSSY 151500Z 1515/1516 12015KT CAVOK';
        final timeline = decoderService.createTimelineFromTaf(shortTaf);
        
        expect(timeline, isNotEmpty);
        expect(timeline.length, equals(1)); // Only one hour
        expect(timeline.first.hour, equals(15));
      });
    });
  });
} 