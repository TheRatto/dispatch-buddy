import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/period_detector.dart';
import 'package:briefing_buddy/models/decoded_weather_models.dart';

void main() {
  group('PeriodDetector Tests', () {
    late PeriodDetector periodDetector;

    setUp(() {
      periodDetector = PeriodDetector();
    });

    group('findActivePeriodsAtTime', () {
      test('should find active baseline period', () {
        final periods = [
          DecodedForecastPeriod(
            type: 'FM',
            time: 'FM1200',
            description: 'From 12:00Z',
            weather: {'Wind': '120° at 10kt'},
            startTime: DateTime(2025, 1, 27, 12, 0),
            endTime: DateTime(2025, 1, 27, 18, 0),
            isConcurrent: false,
          ),
        ];

        final result = PeriodDetector.findActivePeriodsAtTime(
          periods,
          DateTime(2025, 1, 27, 14, 0), // 14:00Z - should be active
        );

        expect(result['baseline'], isNotNull);
        expect(result['baseline'].type, equals('FM'));
        expect(result['concurrent'], isEmpty);
      });

      test('should find active concurrent period', () {
        final periods = [
          DecodedForecastPeriod(
            type: 'TEMPO',
            time: 'TEMPO 1200/1400',
            description: 'Temporary from 12:00Z to 14:00Z',
            weather: {'Visibility': '4SM'},
            startTime: DateTime(2025, 1, 27, 12, 0),
            endTime: DateTime(2025, 1, 27, 14, 0),
            isConcurrent: true,
          ),
        ];

        final result = PeriodDetector.findActivePeriodsAtTime(
          periods,
          DateTime(2025, 1, 27, 13, 0), // 13:00Z - should be active
        );

        expect(result['baseline'], isNull);
        expect(result['concurrent'], hasLength(1));
        expect(result['concurrent'][0].type, equals('TEMPO'));
      });

      test('should find both baseline and concurrent periods', () {
        final periods = [
          DecodedForecastPeriod(
            type: 'FM',
            time: 'FM1200',
            description: 'From 12:00Z',
            weather: {'Wind': '120° at 10kt'},
            startTime: DateTime(2025, 1, 27, 12, 0),
            endTime: DateTime(2025, 1, 27, 18, 0),
            isConcurrent: false,
          ),
          DecodedForecastPeriod(
            type: 'TEMPO',
            time: 'TEMPO 1200/1400',
            description: 'Temporary from 12:00Z to 14:00Z',
            weather: {'Visibility': '4SM'},
            startTime: DateTime(2025, 1, 27, 12, 0),
            endTime: DateTime(2025, 1, 27, 14, 0),
            isConcurrent: true,
          ),
        ];

        final result = PeriodDetector.findActivePeriodsAtTime(
          periods,
          DateTime(2025, 1, 27, 13, 0), // 13:00Z - both should be active
        );

        expect(result['baseline'], isNotNull);
        expect(result['baseline'].type, equals('FM'));
        expect(result['concurrent'], hasLength(1));
        expect(result['concurrent'][0].type, equals('TEMPO'));
      });

      test('should handle periods outside time range', () {
        final periods = [
          DecodedForecastPeriod(
            type: 'FM',
            time: 'FM1200',
            description: 'From 12:00Z',
            weather: {'Wind': '120° at 10kt'},
            startTime: DateTime(2025, 1, 27, 12, 0),
            endTime: DateTime(2025, 1, 27, 18, 0),
            isConcurrent: false,
          ),
        ];

        final result = PeriodDetector.findActivePeriodsAtTime(
          periods,
          DateTime(2025, 1, 27, 20, 0), // 20:00Z - should not be active
        );

        expect(result['baseline'], isNull);
        expect(result['concurrent'], isEmpty);
      });
    });

    group('getBaselinePeriods', () {
      test('should return only baseline periods', () {
        final taf = DecodedWeather(
          icao: 'WSSS',
          timestamp: DateTime.now(),
          rawText: 'TAF WSSS...',
          type: 'TAF',
          windDescription: '',
          visibilityDescription: '',
          cloudDescription: '',
          temperatureDescription: '',
          pressureDescription: '',
          conditionsDescription: '',
          rvrDescription: '',
          timeline: [],
          forecastPeriods: [
            DecodedForecastPeriod(
              type: 'FM',
              time: 'FM1200',
              description: 'From 12:00Z',
              weather: {'Wind': '120° at 10kt'},
              isConcurrent: false,
            ),
            DecodedForecastPeriod(
              type: 'TEMPO',
              time: 'TEMPO 1200/1400',
              description: 'Temporary from 12:00Z to 14:00Z',
              weather: {'Visibility': '4SM'},
              isConcurrent: true,
            ),
          ],
        );

        final baselinePeriods = periodDetector.getBaselinePeriods(taf);
        expect(baselinePeriods, hasLength(1));
        expect(baselinePeriods[0].type, equals('FM'));
      });
    });

    group('getConcurrentPeriods', () {
      test('should return only concurrent periods', () {
        final taf = DecodedWeather(
          icao: 'WSSS',
          timestamp: DateTime.now(),
          rawText: 'TAF WSSS...',
          type: 'TAF',
          windDescription: '',
          visibilityDescription: '',
          cloudDescription: '',
          temperatureDescription: '',
          pressureDescription: '',
          conditionsDescription: '',
          rvrDescription: '',
          timeline: [],
          forecastPeriods: [
            DecodedForecastPeriod(
              type: 'FM',
              time: 'FM1200',
              description: 'From 12:00Z',
              weather: {'Wind': '120° at 10kt'},
              isConcurrent: false,
            ),
            DecodedForecastPeriod(
              type: 'TEMPO',
              time: 'TEMPO 1200/1400',
              description: 'Temporary from 12:00Z to 14:00Z',
              weather: {'Visibility': '4SM'},
              isConcurrent: true,
            ),
          ],
        );

        final concurrentPeriods = periodDetector.getConcurrentPeriods(taf);
        expect(concurrentPeriods, hasLength(1));
        expect(concurrentPeriods[0].type, equals('TEMPO'));
      });
    });
  });
} 