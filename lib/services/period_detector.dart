import 'package:flutter/foundation.dart';
import '../models/decoded_weather_models.dart';

/// Handles detection and management of TAF forecast periods
class PeriodDetector {
  /// Finds active periods at a given time
  /// Returns a map with 'baseline' and 'concurrent' periods
  static Map<String, dynamic> findActivePeriodsAtTime(
    List<DecodedForecastPeriod> periods,
    DateTime time,
  ) {
    debugPrint('DEBUG: 🔍 PeriodDetector.findActivePeriodsAtTime called with time: $time');
    debugPrint('DEBUG: 🔍 Checking ${periods.length} periods');
    
    DecodedForecastPeriod? activeBaseline;
    List<DecodedForecastPeriod> activeConcurrent = [];

    for (final period in periods) {
      debugPrint('DEBUG: 🔍 Checking period: ${period.type} (${period.time}) - concurrent: ${period.isConcurrent}');
      debugPrint('DEBUG: 🔍   Start time: ${period.startTime}');
      debugPrint('DEBUG: 🔍   End time: ${period.endTime}');
      
      if (_isPeriodActiveAtTime(period, time)) {
        debugPrint('DEBUG: 🔍   ✅ Period is ACTIVE at time $time');
        if (period.isConcurrent) {
          debugPrint('DEBUG: 🔍   ✅ Added to active concurrent');
          activeConcurrent.add(period);
        } else {
          debugPrint('DEBUG: 🔍   ✅ Set as active baseline');
          activeBaseline = period;
        }
      } else {
        debugPrint('DEBUG: 🔍   ❌ Period is NOT active at time $time');
      }
    }

    debugPrint('DEBUG: 🔍 Final result: baseline=${activeBaseline?.type}, concurrent=${activeConcurrent.map((p) => p.type).toList()}');
    return {
      'baseline': activeBaseline,
      'concurrent': activeConcurrent,
    };
  }

  /// Checks if a period is active at the given time
  static bool _isPeriodActiveAtTime(DecodedForecastPeriod period, DateTime time) {
    debugPrint('DEBUG: 🔍 _isPeriodActiveAtTime called for ${period.type} (${period.time})');
    debugPrint('DEBUG: 🔍   Checking time: $time');
    debugPrint('DEBUG: 🔍   Period startTime: ${period.startTime}');
    debugPrint('DEBUG: 🔍   Period endTime: ${period.endTime}');
    debugPrint('DEBUG: 🔍   Period isConcurrent: ${period.isConcurrent}');
    
    if (period.startTime == null) {
      debugPrint('DEBUG: 🔍   ❌ Period has no start time');
      return false;
    }

    if (period.isConcurrent) {
      // Concurrent periods need both start and end times
      if (period.endTime == null) {
        debugPrint('DEBUG: 🔍   ❌ Concurrent period has no end time');
        return false;
      }
      
      // Check if time is within the concurrent period range
      final isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
                      time.isBefore(period.endTime!);
      
      debugPrint('DEBUG: 🔍   Concurrent period check: time $time between ${period.startTime} and ${period.endTime} = $isActive');
      debugPrint('DEBUG: 🔍   Time comparison details:');
      debugPrint('DEBUG: 🔍     time.isAfter(startTime): ${time.isAfter(period.startTime!)}');
      debugPrint('DEBUG: 🔍     time.isAtSameMomentAs(startTime): ${time.isAtSameMomentAs(period.startTime!)}');
      debugPrint('DEBUG: 🔍     time.isBefore(endTime): ${time.isBefore(period.endTime!)}');
      
      return isActive;
    } else {
      // Baseline periods - check if time is after start time
      if (period.endTime != null) {
        // Has end time - check if within range
        final isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
                        time.isBefore(period.endTime!);
        
        debugPrint('DEBUG: 🔍   Baseline period check: time $time between ${period.startTime} and ${period.endTime} = $isActive');
        return isActive;
      } else {
        // No end time - check if after start time
        final isActive = time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!);
        
        debugPrint('DEBUG: 🔍   Baseline period (no end time) check: time $time after ${period.startTime} = $isActive');
        return isActive;
      }
    }
  }

  /// Gets all periods for a given TAF
  List<DecodedForecastPeriod> getAllPeriods(DecodedWeather taf) {
    return taf.forecastPeriods ?? [];
  }

  /// Gets baseline periods only
  List<DecodedForecastPeriod> getBaselinePeriods(DecodedWeather taf) {
    return taf.forecastPeriods?.where((p) => !p.isConcurrent).toList() ?? [];
  }

  /// Gets concurrent periods only
  List<DecodedForecastPeriod> getConcurrentPeriods(DecodedWeather taf) {
    return taf.forecastPeriods?.where((p) => p.isConcurrent).toList() ?? [];
  }
} 