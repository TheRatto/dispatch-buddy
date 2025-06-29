import 'package:dispatch_buddy/services/decoder_service.dart';
import '../models/decoded_weather_models.dart';

/// Handles detection and management of TAF forecast periods
class PeriodDetector {
  /// Finds active periods at a given time
  /// Returns a map with 'baseline' and 'concurrent' periods
  Map<String, dynamic> findActivePeriodsAtTime(
    List<DecodedForecastPeriod> periods,
    DateTime time,
  ) {
    DecodedForecastPeriod? activeBaseline;
    List<DecodedForecastPeriod> activeConcurrent = [];

    for (var period in periods) {
      if (_isPeriodActiveAtTime(period, time)) {
        if (!period.isConcurrent) {
          activeBaseline = period;
        } else {
          activeConcurrent.add(period);
        }
      }
    }

    return {
      'baseline': activeBaseline,
      'concurrent': activeConcurrent,
    };
  }

  /// Checks if a period is active at the given time
  bool _isPeriodActiveAtTime(DecodedForecastPeriod period, DateTime time) {
    if (period.startTime == null) return false;

    // For baseline periods (INITIAL, FM, BECMG)
    if (!period.isConcurrent) {
      if (period.endTime != null) {
        return (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
               time.isBefore(period.endTime!);
      } else {
        // If no end time, period continues until next baseline period
        return time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!);
      }
    }

    // For concurrent periods (TEMPO, INTER, PROB30, PROB40)
    if (period.endTime != null) {
      return (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) &&
             time.isBefore(period.endTime!);
    }

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