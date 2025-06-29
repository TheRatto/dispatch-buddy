import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import 'decoder_service.dart';

/// Manages TAF state and business logic, separating concerns from UI components.
/// Handles weather inheritance, active period management, caching, and data processing.
class TafStateManager {
  // Cache for weather calculations
  final Map<String, Map<String, String>> _weatherCache = {};
  final Map<String, Map<String, dynamic>> _activePeriodsCache = {};
  
  // Performance tracking
  String? _lastProcessedAirport;
  double? _lastProcessedSliderValue;
  String? _lastTafHash;
  String? _lastTimelineHash;
  
  // Cache size management
  static const int _maxCacheSize = 50;
  
  /// Generates a cache key for weather calculations
  String _getCacheKey(String airport, double sliderValue, String periodType) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}_$periodType';
  }
  
  /// Generates a cache key for active periods
  String _getActivePeriodsCacheKey(String airport, double sliderValue) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}';
  }
  
  /// Generates hash for TAF data to detect changes
  String _generateTafHash(Weather taf) {
    return '${taf.rawText.hashCode}_${taf.decodedWeather?.forecastPeriods?.length ?? 0}';
  }
  
  /// Generates hash for timeline to detect changes
  String _generateTimelineHash(List<DateTime> timeline) {
    return '${timeline.length}_${timeline.isNotEmpty ? timeline.first.hashCode : 0}_${timeline.isNotEmpty ? timeline.last.hashCode : 0}';
  }
  
  /// Clears all caches
  void clearCache() {
    _weatherCache.clear();
    _activePeriodsCache.clear();
    _lastProcessedAirport = null;
    _lastProcessedSliderValue = null;
    _lastTafHash = null;
    _lastTimelineHash = null;
  }
  
  /// Smart cache clearing based on data changes
  void clearCacheIfDataChanged(Weather taf, List<DateTime> timeline) {
    final currentTafHash = _generateTafHash(taf);
    final currentTimelineHash = _generateTimelineHash(timeline);
    
    if (_lastTafHash != currentTafHash || _lastTimelineHash != currentTimelineHash) {
      debugPrint('DEBUG: Data changed, clearing cache');
      _weatherCache.clear();
      _activePeriodsCache.clear();
      _lastTafHash = currentTafHash;
      _lastTimelineHash = currentTimelineHash;
    }
  }
  
  /// Limits cache size to prevent memory issues
  void _limitCacheSize() {
    if (_weatherCache.length > _maxCacheSize) {
      final keysToRemove = _weatherCache.keys.take(_weatherCache.length - _maxCacheSize).toList();
      for (final key in keysToRemove) {
        _weatherCache.remove(key);
      }
    }
    
    if (_activePeriodsCache.length > _maxCacheSize) {
      final keysToRemove = _activePeriodsCache.keys.take(_activePeriodsCache.length - _maxCacheSize).toList();
      for (final key in keysToRemove) {
        _activePeriodsCache.remove(key);
      }
    }
  }
  
  /// Logs performance statistics
  void logPerformanceStats() {
    debugPrint('DEBUG: Performance Stats - Weather Cache: ${_weatherCache.length} entries');
    debugPrint('DEBUG: Performance Stats - Active Periods Cache: ${_activePeriodsCache.length} entries');
    debugPrint('DEBUG: Performance Stats - Last Airport: $_lastProcessedAirport');
    debugPrint('DEBUG: Performance Stats - Last Slider Value: $_lastProcessedSliderValue');
  }
  
  /// Gets active periods for a given time, with caching
  Map<String, dynamic>? getActivePeriods(
    String airport,
    double sliderValue,
    List<DateTime> timeline,
    List<DecodedForecastPeriod> forecastPeriods,
  ) {
    final cacheKey = _getActivePeriodsCacheKey(airport, sliderValue);
    
    // Check if we can use cached activePeriods
    if (_activePeriodsCache.containsKey(cacheKey) && 
        _lastProcessedAirport == airport && 
        _lastProcessedSliderValue == sliderValue) {
      final activePeriods = _activePeriodsCache[cacheKey];
      debugPrint('DEBUG: Main build - Using CACHED activePeriods: $activePeriods');
      debugPrint('DEBUG: Main build - Object ID: ${activePeriods?.hashCode}');
      return activePeriods;
    }
    
    // Calculate activePeriods and cache it
    DateTime? currentTime;
    final timelineLength = timeline.length;
    
    if (timelineLength > 1) {
      final timeIndex = (sliderValue * (timelineLength - 1)).round().clamp(0, timelineLength - 1);
      currentTime = timeline[timeIndex];
    } else if (timelineLength == 1) {
      currentTime = timeline.first;
    }
    
    if (currentTime != null) {
      final decoder = DecoderService();
      final activePeriods = decoder.findActivePeriodsAtTime(currentTime, forecastPeriods);
      
      // Cache the result
      _activePeriodsCache[cacheKey] = activePeriods;
      _lastProcessedAirport = airport;
      _lastProcessedSliderValue = sliderValue;
      _limitCacheSize();
      
      debugPrint('DEBUG: Main build - Calculated and CACHED activePeriods: $activePeriods');
      debugPrint('DEBUG: Main build - Object ID: ${activePeriods?.hashCode}');
      
      return activePeriods;
    }
    
    return null;
  }
  
  /// Gets complete weather for a period, including inheritance logic
  Map<String, String> getCompleteWeatherForPeriod(
    DecodedForecastPeriod period,
    String airport,
    double sliderValue,
    List<DecodedForecastPeriod> allPeriods,
  ) {
    // Performance optimization: Check cache first
    final cacheKey = _getCacheKey(airport, sliderValue, period.type);
    
    if (_weatherCache.containsKey(cacheKey)) {
      debugPrint('DEBUG: Using CACHED weather for ${period.type}: ${_weatherCache[cacheKey]}');
      return _weatherCache[cacheKey]!;
    }
    
    Map<String, String> completeWeather = Map.from(period.weather);
    debugPrint('DEBUG: Period ${period.type} - Original weather: ${period.weather}');
    
    if (allPeriods.isNotEmpty) {
      DecodedForecastPeriod? sourcePeriod;
      
      if (period.type == 'BECMG') {
        // BECMG periods inherit missing elements from the most recent period that has them
        // This ensures baseline weather persists until specifically replaced
        for (final key in ['Wind', 'Visibility', 'Cloud', 'Weather']) {
          if (completeWeather[key] == null || completeWeather[key]!.isEmpty || completeWeather[key] == '-') {
            // Find the most recent period that has this element
            for (final p in allPeriods.reversed) {
              if (p.startTime != null && p.startTime!.isBefore(period.startTime!)) {
                if (p.weather[key] != null && p.weather[key]!.isNotEmpty && p.weather[key] != '-') {
                  sourcePeriod = p;
                  break;
                }
              }
            }
            
            if (sourcePeriod != null) {
              completeWeather[key] = sourcePeriod.weather[key]!;
              debugPrint('DEBUG: BECMG inherited $key from ${sourcePeriod.type}: ${sourcePeriod.weather[key]}');
            }
          }
        }
        debugPrint('DEBUG: BECMG period - inheritance complete');
      } else if (period.type == 'FM') {
        // FM periods inherit from the previous FM period
        sourcePeriod = allPeriods
          .where((p) => p.type == 'FM' && p.startTime != null && p.startTime!.isBefore(period.startTime!))
          .fold<DecodedForecastPeriod?>(null, (prev, p) => prev == null || p.startTime!.isAfter(prev.startTime!) ? p : prev);
        debugPrint('DEBUG: FM period - inheriting from previous FM period: ${sourcePeriod?.type}');
      } else if (period.type != 'INITIAL') {
        // Concurrent periods (TEMPO/INTER) inherit from the current baseline period
        // Find the baseline period that is active during this concurrent period
        sourcePeriod = allPeriods
          .where((p) => !p.isConcurrent && p.startTime != null && p.endTime != null &&
                       p.startTime!.isBefore(period.startTime!) && p.endTime!.isAfter(period.startTime!))
          .firstOrNull;
        debugPrint('DEBUG: Concurrent period - inheriting from baseline period: ${sourcePeriod?.type}');
      }
      
      if (sourcePeriod != null) {
        for (final key in ['Wind', 'Visibility', 'Cloud', 'Weather']) {
          if (completeWeather[key] == null || completeWeather[key]!.isEmpty || completeWeather[key] == '-') {
            completeWeather[key] = sourcePeriod.weather[key] ?? '-';
            debugPrint('DEBUG: Inherited $key: ${sourcePeriod.weather[key]}');
          }
        }
      }
    }
    
    debugPrint('DEBUG: Complete weather for ${period.type}: $completeWeather');
    
    // Cache the result
    _weatherCache[cacheKey] = completeWeather;
    _limitCacheSize();
    
    return completeWeather;
  }
  
  /// Gets active baseline period for a given time
  DecodedForecastPeriod? getActiveBaselinePeriod(List<DecodedForecastPeriod> periods, DateTime time) {
    // Find the baseline period that is active at the given time
    DecodedForecastPeriod? activePeriod;
    
    for (final period in periods) {
      if (!period.isConcurrent) {
        bool isActive = false;
        
        if (period.startTime != null && period.endTime != null) {
          // Period with both start and end times (BECMG periods)
          isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) && 
                     time.isBefore(period.endTime!);
        } else if (period.startTime != null) {
          // Period with only start time (FM periods)
          // Find the next FM period to determine the end time
          final nextFmPeriod = periods.where((p) => 
            p.type == 'FM' && 
            p.startTime != null && 
            p.startTime!.isAfter(period.startTime!)
          ).firstOrNull;
          
          if (nextFmPeriod != null) {
            // This FM period ends when the next FM period starts
            isActive = (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) && 
                       time.isBefore(nextFmPeriod.startTime!);
          } else {
            // No next FM period, so this FM period continues to the end
            isActive = time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!);
          }
        }
        
        if (isActive) {
          activePeriod = period;
          break; // Found the active period, no need to continue
        }
      }
    }
    
    // If no active period found, find the most recent period that started before this time
    if (activePeriod == null) {
      DecodedForecastPeriod? mostRecentPeriod;
      DateTime? mostRecentTime;
      
      for (final period in periods) {
        if (!period.isConcurrent && period.startTime != null) {
          if (period.startTime!.isBefore(time) || period.startTime!.isAtSameMomentAs(time)) {
            if (mostRecentTime == null || period.startTime!.isAfter(mostRecentTime!)) {
              mostRecentTime = period.startTime!;
              mostRecentPeriod = period;
            }
          }
        }
      }
      
      activePeriod = mostRecentPeriod;
    }
    
    // If still no period found, return the first period
    return activePeriod ?? (periods.isNotEmpty ? periods.first : null);
  }
} 