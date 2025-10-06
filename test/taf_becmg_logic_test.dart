import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/decoder_service.dart';
import 'package:briefing_buddy/services/period_detector.dart';

void main() {
  group('TAF BECMG Logic Tests', () {
    test('should create correct periods for TAF with BECMG transition', () {
      const tafText = 'TAF CYYZ 061200Z 0612/0618 33012KT CAVOK BECMG 0612/0615 34015KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      
      expect(result.forecastPeriods, isNotNull);
      expect(result.forecastPeriods!.length, greaterThanOrEqualTo(3));
      
      // Should have an INITIAL period
      final initialPeriod = result.forecastPeriods!.where((p) => p.type == 'INITIAL').firstOrNull;
      expect(initialPeriod, isNotNull);
      expect(initialPeriod!.weather['Wind'], equals('330° at 12kt'));
      expect(initialPeriod.weather['Visibility'], equals('CAVOK'));
      
      // Should have a BECMG period (transition only)
      final becmgPeriod = result.forecastPeriods!.where((p) => p.type == 'BECMG').firstOrNull;
      expect(becmgPeriod, isNotNull);
      expect(becmgPeriod!.weather['Wind'], equals('340° at 15kt'));
      
      // Should have a POST_BECMG period (new conditions after transition)
      final postBecmgPeriod = result.forecastPeriods!.where((p) => p.type == 'POST_BECMG').firstOrNull;
      expect(postBecmgPeriod, isNotNull);
      expect(postBecmgPeriod!.weather['Wind'], equals('340° at 15kt'));
      
      print('INITIAL period: ${initialPeriod.startTime} to ${initialPeriod.endTime}');
      print('BECMG period: ${becmgPeriod.startTime} to ${becmgPeriod.endTime}');
      print('POST_BECMG period: ${postBecmgPeriod.startTime} to ${postBecmgPeriod.endTime}');
      
      // Verify timing relationships
      expect(initialPeriod.endTime, equals(becmgPeriod.endTime)); // Both end at BECMG end
      expect(becmgPeriod.endTime, equals(postBecmgPeriod.startTime)); // POST_BECMG starts when BECMG ends
    });

    test('should find correct active periods at different times', () {
      const tafText = 'TAF CYYZ 061200Z 0612/0618 33012KT CAVOK BECMG 0612/0615 34015KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      final periodDetector = PeriodDetector();
      
      // At TAF start time (12:00) - should be INITIAL baseline with BECMG concurrent
      final activeAtStart = PeriodDetector.findActivePeriodsAtTime(
        result.forecastPeriods!,
        DateTime(2025, 7, 6, 12, 0)
      );
      expect(activeAtStart['baseline']?.type, equals('INITIAL'));
      expect(activeAtStart['concurrent']?.length, equals(1));
      expect(activeAtStart['concurrent']?.first.type, equals('BECMG'));
      
      // During BECMG transition (13:00) - should still be INITIAL baseline with BECMG concurrent
      final activeDuringTransition = PeriodDetector.findActivePeriodsAtTime(
        result.forecastPeriods!,
        DateTime(2025, 7, 6, 13, 0)
      );
      expect(activeDuringTransition['baseline']?.type, equals('INITIAL'));
      expect(activeDuringTransition['concurrent']?.length, equals(1));
      expect(activeDuringTransition['concurrent']?.first.type, equals('BECMG'));
      
      // After BECMG transition (16:00) - should be POST_BECMG baseline
      final activeAfterTransition = PeriodDetector.findActivePeriodsAtTime(
        result.forecastPeriods!,
        DateTime(2025, 7, 6, 16, 0)
      );
      expect(activeAfterTransition['baseline']?.type, equals('POST_BECMG'));
      
      print('Active at 12:00: ${activeAtStart['baseline']?.type}');
      print('Active at 13:00: ${activeDuringTransition['baseline']?.type}');
      print('Active at 16:00: ${activeAfterTransition['baseline']?.type}');
    });

    test('should handle multiple BECMG periods', () {
      const tafText = 'TAF CYYZ 061200Z 0612/0618 33012KT CAVOK BECMG 0612/0615 34015KT BECMG 0615/0618 35020KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      
      expect(result.forecastPeriods, isNotNull);
      
      // Should have INITIAL, BECMG1, BECMG2, POST_BECMG2 (POST_BECMG1 is not needed since BECMG2 follows immediately)
      final initialPeriods = result.forecastPeriods!.where((p) => p.type == 'INITIAL').toList();
      final becmgPeriods = result.forecastPeriods!.where((p) => p.type == 'BECMG').toList();
      final postBecmgPeriods = result.forecastPeriods!.where((p) => p.type == 'POST_BECMG').toList();
      
      expect(initialPeriods.length, equals(1));
      expect(becmgPeriods.length, equals(2));
      expect(postBecmgPeriods.length, equals(1)); // Only one POST_BECMG since BECMG2 is the last period
      
      print('Periods found:');
      for (final period in result.forecastPeriods!) {
        print('  ${period.type}: ${period.startTime} to ${period.endTime}');
      }
    });
  });
} 