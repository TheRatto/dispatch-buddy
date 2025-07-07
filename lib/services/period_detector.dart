import '../models/decoded_weather_models.dart';

/// Handles detection and management of TAF forecast periods
class PeriodDetector {
  /// Finds active periods at a given time
  /// Returns a map with 'baseline' and 'concurrent' periods
  Map<String, dynamic> findActivePeriodsAtTime(
    List<DecodedForecastPeriod> periods,
    DateTime time,
  ) {
    print('DEBUG: 🔍 PeriodDetector.findActivePeriodsAtTime called with time: $time');
    print('DEBUG: 🔍 Checking ${periods.length} periods');
    
    DecodedForecastPeriod? activeBaseline;
    List<DecodedForecastPeriod> activeConcurrent = [];

    for (var period in periods) {
      print('DEBUG: 🔍 Checking period: ${period.type} (${period.time}) - concurrent: ${period.isConcurrent}');
      print('DEBUG: 🔍   Start time: ${period.startTime}');
      print('DEBUG: 🔍   End time: ${period.endTime}');
      
      if (_isPeriodActiveAtTime(period, time)) {
        print('DEBUG: 🔍   ✅ Period is ACTIVE at time $time');
        if (!period.isConcurrent) {
          activeBaseline = period;
          print('DEBUG: 🔍   ✅ Set as active baseline');
        } else {
          activeConcurrent.add(period);
          print('DEBUG: 🔍   ✅ Added to active concurrent');
        }
      } else {
        print('DEBUG: 🔍   ❌ Period is NOT active at time $time');
      }
    }

    final result = {
      'baseline': activeBaseline,
      'concurrent': activeConcurrent,
    };
    
    print('DEBUG: 🔍 Final result: baseline=${activeBaseline?.type}, concurrent=${activeConcurrent.map((p) => p.type).toList()}');
    return result;
  }

  /// Checks if a period is active at the given time
  bool _isPeriodActiveAtTime(DecodedForecastPeriod period, DateTime time) {
    print('DEBUG: 🔍 _isPeriodActiveAtTime called for ${period.type} (${period.time})');
    print('DEBUG: 🔍   Checking time: $time');
    print('DEBUG: 🔍   Period startTime: ${period.startTime}');
    print('DEBUG: 🔍   Period endTime: ${period.endTime}');
    print('DEBUG: 🔍   Period isConcurrent: ${period.isConcurrent}');
    
    if (period.startTime == null) {
      print('DEBUG: 🔍   ❌ Period has no start time');
      return false;
    }

    // For baseline periods (INITIAL, FM, BECMG)
    if (!period.isConcurrent) {
      if (period.endTime != null) {
        final isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
               time.isBefore(period.endTime!);
        print('DEBUG: 🔍   Baseline period check: time $time between ${period.startTime} and ${period.endTime} = $isActive');
        return isActive;
      } else {
        // If no end time, period continues until next baseline period
        final isActive = time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!);
        print('DEBUG: 🔍   Baseline period (no end time) check: time $time after ${period.startTime} = $isActive');
        return isActive;
      }
    }

    // For concurrent periods (TEMPO, INTER, PROB30, PROB40)
    if (period.endTime != null) {
      final isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
             time.isBefore(period.endTime!);
      print('DEBUG: 🔍   Concurrent period check: time $time between ${period.startTime} and ${period.endTime} = $isActive');
      print('DEBUG: 🔍   Time comparison details:');
      print('DEBUG: 🔍     time.isAfter(startTime): ${time.isAfter(period.startTime!)}');
      print('DEBUG: 🔍     time.isAtSameMomentAs(startTime): ${time.isAtSameMomentAs(period.startTime!)}');
      print('DEBUG: 🔍     time.isBefore(endTime): ${time.isBefore(period.endTime!)}');
      return isActive;
    }

    print('DEBUG: 🔍   ❌ Concurrent period has no end time');
    return false;
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