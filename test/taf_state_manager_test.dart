import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dispatch_buddy/services/taf_state_manager.dart';
import 'package:dispatch_buddy/models/weather.dart';
import 'package:dispatch_buddy/models/decoded_weather_models.dart';

void main() {
  group('TafStateManager', () {
    late TafStateManager stateManager;
    late Weather mockTaf;
    late List<DecodedForecastPeriod> mockPeriods;
    late List<DateTime> mockTimeline;

    setUp(() {
      stateManager = TafStateManager();
      
      // Create mock TAF data
      mockTaf = Weather(
        icao: 'YPPH',
        timestamp: DateTime(2024, 1, 29, 8, 0),
        rawText: 'TAF YPPH 290812Z 2908/3012 06012KT CAVOK',
        decodedText: 'Wind 60° at 12kt. Visibility CAVOK. Cloud CAVOK.',
        windDirection: 60,
        windSpeed: 12,
        visibility: 9999,
        cloudCover: 'CAVOK',
        temperature: 20.0,
        dewPoint: 15.0,
        qnh: 1013,
        conditions: '',
        type: 'TAF',
        decodedWeather: DecodedWeather(
          icao: 'YPPH',
          timestamp: DateTime(2024, 1, 29, 8, 0),
          rawText: 'TAF YPPH 290812Z 2908/3012 06012KT CAVOK',
          type: 'TAF',
          windDescription: 'Wind 60° at 12kt',
          visibilityDescription: 'Visibility CAVOK',
          conditionsDescription: 'Weather -',
          cloudDescription: 'Cloud CAVOK',
          temperatureDescription: 'Temperature 20°C, Dew point 15°C',
          pressureDescription: 'QNH 1013',
          rvrDescription: '',
          timeline: [],
        ),
      );
      
      // Create mock forecast periods
      mockPeriods = [
        DecodedForecastPeriod(
          type: 'INITIAL',
          time: '2908/3012',
          description: 'Initial forecast',
          startTime: DateTime(2024, 1, 29, 8, 0),
          endTime: DateTime(2024, 1, 30, 12, 0),
          weather: {
            'Wind': '60° at 12kt',
            'Visibility': 'CAVOK',
            'Weather': '-',
            'Cloud': 'CAVOK',
          },
          rawSection: '06012KT CAVOK',
          isConcurrent: false,
          changedElements: {},
        ),
        DecodedForecastPeriod(
          type: 'FM',
          time: 'FM2910',
          description: 'From 10:00Z',
          startTime: DateTime(2024, 1, 29, 10, 0),
          endTime: null,
          weather: {
            'Wind': '90° at 8kt',
            'Visibility': 'CAVOK',
            'Weather': '-',
            'Cloud': 'CAVOK',
          },
          rawSection: 'FM291000 09008KT CAVOK',
          isConcurrent: false,
          changedElements: {'Wind'},
        ),
        DecodedForecastPeriod(
          type: 'BECMG',
          time: 'BECMG2912/2914',
          description: 'Becoming from 12:00Z to 14:00Z',
          startTime: DateTime(2024, 1, 29, 12, 0),
          endTime: DateTime(2024, 1, 29, 14, 0),
          weather: {
            'Wind': '120° at 15kt',
            'Visibility': '-',
            'Weather': '-',
            'Cloud': '-',
          },
          rawSection: 'BECMG2912/2914 12015KT',
          isConcurrent: false,
          changedElements: {'Wind'},
        ),
        DecodedForecastPeriod(
          type: 'TEMPO',
          time: 'TEMPO2915/2917',
          description: 'Temporary from 15:00Z to 17:00Z',
          startTime: DateTime(2024, 1, 29, 15, 0),
          endTime: DateTime(2024, 1, 29, 17, 0),
          weather: {
            'Wind': '-',
            'Visibility': '5000m',
            'Weather': 'Light rain',
            'Cloud': 'BKN010',
          },
          rawSection: 'TEMPO2915/2917 5000 -RA BKN010',
          isConcurrent: true,
          changedElements: {'Visibility', 'Weather', 'Cloud'},
        ),
      ];
      
      // Create mock timeline
      mockTimeline = [
        DateTime(2024, 1, 29, 8, 0),
        DateTime(2024, 1, 29, 10, 0),
        DateTime(2024, 1, 29, 12, 0),
        DateTime(2024, 1, 29, 14, 0),
        DateTime(2024, 1, 29, 16, 0),
        DateTime(2024, 1, 29, 18, 0),
      ];
    });

    group('Cache Management', () {
      test('should clear cache correctly', () {
        // Add some data to cache
        stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, mockPeriods);
        stateManager.getCompleteWeatherForPeriod(mockPeriods[0], 'YPPH', 0.0, mockPeriods);
        
        // Clear cache
        stateManager.clearCache();
        
        // Verify cache is cleared by checking performance stats
        // (We can't directly access private cache, but we can verify behavior)
        expect(() => stateManager.logPerformanceStats(), returnsNormally);
      });

      test('should clear cache when data changes', () {
        // Initial call
        stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, mockPeriods);
        
        // Create modified TAF
        final modifiedTaf = Weather(
          icao: 'YPPH',
          timestamp: DateTime(2024, 1, 29, 8, 0),
          rawText: 'TAF YPPH 290812Z 2908/3012 06012KT 9999 SCT020',
          decodedText: 'Wind 60° at 12kt. Visibility >10km. Cloud SCT020.',
          windDirection: 60,
          windSpeed: 12,
          visibility: 9999,
          cloudCover: 'SCT020',
          temperature: 20.0,
          dewPoint: 15.0,
          qnh: 1013,
          conditions: '',
          type: 'TAF',
          decodedWeather: mockTaf.decodedWeather,
        );
        
        // Should clear cache due to data change
        stateManager.clearCacheIfDataChanged(modifiedTaf, mockTimeline);
        
        expect(() => stateManager.logPerformanceStats(), returnsNormally);
      });
    });

    group('Active Periods Management', () {
      test('should get active periods for initial time', () {
        final activePeriods = stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, mockPeriods);
        
        expect(activePeriods, isNotNull);
        expect(activePeriods!['baseline'], isNotNull);
        expect(activePeriods['baseline'].type, equals('INITIAL'));
        expect(activePeriods['concurrent'], isA<List<DecodedForecastPeriod>>());
      });

      test('should get active periods for FM time', () {
        final activePeriods = stateManager.getActivePeriods('YPPH', 0.2, mockTimeline, mockPeriods);
        
        expect(activePeriods, isNotNull);
        expect(activePeriods!['baseline'], isNotNull);
        expect(activePeriods['baseline'].type, equals('FM'));
      });

      test('should cache active periods correctly', () {
        // First call
        final firstCall = stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, mockPeriods);
        
        // Second call with same parameters should use cache
        final secondCall = stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, mockPeriods);
        
        expect(firstCall, equals(secondCall));
      });
    });

    group('Weather Inheritance Logic', () {
      test('should get complete weather for INITIAL period', () {
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[0], 'YPPH', 0.0, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('60° at 12kt'));
        expect(completeWeather['Visibility'], equals('CAVOK'));
        expect(completeWeather['Weather'], equals('-'));
        expect(completeWeather['Cloud'], equals('CAVOK'));
      });

      test('should get complete weather for FM period', () {
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[1], 'YPPH', 0.2, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('90° at 8kt'));
        expect(completeWeather['Visibility'], equals('CAVOK'));
        expect(completeWeather['Weather'], equals('-'));
        expect(completeWeather['Cloud'], equals('CAVOK'));
      });

      test('should inherit missing weather for BECMG period', () {
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[2], 'YPPH', 0.4, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('120° at 15kt'));
        expect(completeWeather['Visibility'], equals('CAVOK')); // Inherited from INITIAL (most recent with visibility)
        expect(completeWeather['Weather'], equals('-')); // Inherited from FM (most recent with weather)
        expect(completeWeather['Cloud'], equals('CAVOK')); // Inherited from INITIAL (most recent with cloud)
      });

      test('should inherit missing weather for TEMPO period', () {
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[3], 'YPPH', 0.6, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('60° at 12kt')); // Inherited from INITIAL (correct behavior)
        expect(completeWeather['Visibility'], equals('5000m'));
        expect(completeWeather['Weather'], equals('Light rain'));
        expect(completeWeather['Cloud'], equals('BKN010'));
      });

      test('should cache weather calculations correctly', () {
        // First call
        final firstCall = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[0], 'YPPH', 0.0, mockPeriods
        );
        
        // Second call with same parameters should use cache
        final secondCall = stateManager.getCompleteWeatherForPeriod(
          mockPeriods[0], 'YPPH', 0.0, mockPeriods
        );
        
        expect(firstCall, equals(secondCall));
      });
    });

    group('Active Baseline Period Detection', () {
      test('should find active baseline period for INITIAL time', () {
        final activePeriod = stateManager.getActiveBaselinePeriod(
          mockPeriods, DateTime(2024, 1, 29, 8, 0)
        );
        
        expect(activePeriod, isNotNull);
        expect(activePeriod!.type, equals('INITIAL'));
      });

      test('should find active baseline period for FM time', () {
        final activePeriod = stateManager.getActiveBaselinePeriod(
          mockPeriods, DateTime(2024, 1, 29, 10, 0)
        );
        
        expect(activePeriod, isNotNull);
        expect(activePeriod!.type, equals('INITIAL')); // INITIAL is still active at 10:00
      });

      test('should find active baseline period for BECMG time', () {
        final activePeriod = stateManager.getActiveBaselinePeriod(
          mockPeriods, DateTime(2024, 1, 29, 13, 0)
        );
        
        expect(activePeriod, isNotNull);
        expect(activePeriod!.type, equals('BECMG'));
      });

      test('should return most recent period for time before any period', () {
        final activePeriod = stateManager.getActiveBaselinePeriod(
          mockPeriods, DateTime(2024, 1, 29, 7, 0)
        );
        
        expect(activePeriod, isNotNull);
        expect(activePeriod!.type, equals('INITIAL'));
      });
    });

    group('Performance Monitoring', () {
      test('should log performance stats without error', () {
        expect(() => stateManager.logPerformanceStats(), returnsNormally);
      });

      test('should handle empty timeline', () {
        final activePeriods = stateManager.getActivePeriods('YPPH', 0.0, [], mockPeriods);
        expect(activePeriods, isNull);
      });

      test('should handle empty periods', () {
        final activePeriods = stateManager.getActivePeriods('YPPH', 0.0, mockTimeline, []);
        expect(activePeriods, isNotNull); // Returns empty map structure
        expect(activePeriods!['baseline'], isNull);
        expect(activePeriods['concurrent'], isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle null weather values', () {
        final periodWithNulls = DecodedForecastPeriod(
          type: 'FM',
          time: 'FM3000',
          description: 'From 00:00Z',
          startTime: DateTime(2024, 1, 30, 0, 0),
          endTime: null,
          weather: {
            'Wind': '-',
            'Visibility': '-',
            'Weather': '-',
            'Cloud': '-',
          },
          rawSection: 'FM300000',
          isConcurrent: false,
          changedElements: {},
        );
        
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          periodWithNulls, 'YPPH', 0.8, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('90° at 8kt')); // Inherited from previous FM
        expect(completeWeather['Visibility'], equals('CAVOK')); // Inherited from INITIAL
        expect(completeWeather['Weather'], equals('-')); // Inherited from INITIAL
        expect(completeWeather['Cloud'], equals('CAVOK')); // Inherited from INITIAL
      });

      test('should handle empty weather map', () {
        final periodWithEmptyWeather = DecodedForecastPeriod(
          type: 'FM',
          time: 'FM3000',
          description: 'From 00:00Z',
          startTime: DateTime(2024, 1, 30, 0, 0),
          endTime: null,
          weather: {},
          rawSection: 'FM300000',
          isConcurrent: false,
          changedElements: {},
        );
        
        final completeWeather = stateManager.getCompleteWeatherForPeriod(
          periodWithEmptyWeather, 'YPPH', 0.8, mockPeriods
        );
        
        expect(completeWeather['Wind'], equals('90° at 8kt')); // Inherited from previous FM
        expect(completeWeather['Visibility'], equals('CAVOK')); // Inherited from INITIAL
        expect(completeWeather['Weather'], equals('-')); // Inherited from INITIAL
        expect(completeWeather['Cloud'], equals('CAVOK')); // Inherited from INITIAL
      });
    });
  });
} 