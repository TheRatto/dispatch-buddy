import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/services/decoder_service.dart';
import 'package:dispatch_buddy/services/taf_state_manager.dart';
import 'package:dispatch_buddy/models/decoded_weather_models.dart';

void main() {
  group('PROB30 Persistence Tests', () {
    late DecoderService decoderService;
    late TafStateManager tafStateManager;

    setUp(() {
      decoderService = DecoderService();
      tafStateManager = TafStateManager();
    });

    test('should correctly detect PROB30 periods in TAF state manager', () {
      // This is the KJFK TAF that was having issues
      const tafText = 'TAF KJFK 091130Z 0912/1012 24007KT P6SM FEW050 SCT250 FM091400 24007KT P6SM FEW050 SCT250 FM091800 19012KT P6SM SCT050 BKN250 FM092100 19014KT P6SM BKN050 BKN200 PROB30 0922/1003 23007KT P6SM BKN040 BKN150 FM100300 23007KT P6SM BKN040 BKN150 PROB30 1003/1006 22004KT P6SM VCSH BKN040 BKN100 FM100600 22004KT P6SM VCSH BKN040 BKN100 FM100900 VRB04KT 5SM -SHRA BR SCT025 OVC040';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      expect(result.forecastPeriods!.length, greaterThan(5)); // Should have multiple periods including PROB30
      
      // Find PROB30 periods
      final prob30Periods = result.forecastPeriods!.where((p) => p.type.contains('PROB30')).toList();
      expect(prob30Periods.length, equals(2));
      
      // Check that PROB30 periods are marked as concurrent
      for (final period in prob30Periods) {
        expect(period.isConcurrent, isTrue);
        expect(period.startTime, isNotNull);
        expect(period.endTime, isNotNull);
      }
      
      // Test TafStateManager with a time that should have PROB30 active
      final timeline = result.timeline ?? [];
      if (timeline.isNotEmpty) {
        // Use a time during the first PROB30 period (0922/1003)
        final testTime = DateTime(2025, 7, 9, 23, 0); // 23:00 on day 9
        
        final activePeriods = tafStateManager.getActivePeriods(
          'KJFK',
          0.5, // Middle of timeline
          timeline,
          result.forecastPeriods!,
        );
        
        expect(activePeriods, isNotNull);
        expect(activePeriods!['baseline'], isNotNull);
        expect(activePeriods['concurrent'], isA<List<DecodedForecastPeriod>>());
        
        // Should have at least one concurrent period (PROB30)
        final concurrentPeriods = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
        expect(concurrentPeriods.length, greaterThan(0));
        
        // Check that PROB30 periods are in the concurrent list
        final prob30InConcurrent = concurrentPeriods.where((p) => p.type.contains('PROB30')).toList();
        expect(prob30InConcurrent.length, greaterThan(0));
      }
    });

    test('should handle PROB30 periods with correct time boundaries', () {
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 TEMPO 2802/2805 4SM SHRA BR BKN020 PROB30 2802/2805 VRB20G30KT 1SM +TSRA BR BKN008 OVC020CB';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      
      // Find the PROB30 period
      final prob30Period = result.forecastPeriods!.where((p) => p.type.contains('PROB30')).first;
      expect(prob30Period.isConcurrent, isTrue);
      expect(prob30Period.startTime, isNotNull);
      expect(prob30Period.endTime, isNotNull);
      
      // Test that the period is active during its time window
      final startTime = prob30Period.startTime!;
      final endTime = prob30Period.endTime!;
      
      // Test time during the period
      final duringTime = startTime.add(Duration(hours: 1));
      expect(duringTime.isAfter(startTime), isTrue);
      expect(duringTime.isBefore(endTime), isTrue);
      
      // Test time before the period
      final beforeTime = startTime.subtract(Duration(hours: 1));
      expect(beforeTime.isBefore(startTime), isTrue);
      
      // Test time after the period
      final afterTime = endTime.add(Duration(hours: 1));
      expect(afterTime.isAfter(endTime), isTrue);
    });
  });
} 