import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import 'cache_manager.dart';
import 'package:collection/collection.dart';

/// Manages TAF state and business logic, separating concerns from UI components.
/// Handles weather inheritance, active period management, caching, and data processing.
class TafStateManager {
  // Unified cache manager instance
  final CacheManager _cacheManager = CacheManager();
  
  // Performance tracking
  String? _lastProcessedAirport;
  double? _lastProcessedSliderValue;
  String? _lastTafHash;
  String? _lastTimelineHash;
  DateTime? _lastMetricsReset;
  

  
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
    _cacheManager.clearPrefix('taf_');
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
      _cacheManager.clearPrefix('taf_');
      _lastTafHash = currentTafHash;
      _lastTimelineHash = currentTimelineHash;
    }
  }
  
  /// Logs performance statistics
  void logPerformanceStats() {
    final stats = _cacheManager.getStats();
    debugPrint('DEBUG: Performance Stats - Cache: ${stats['size']} entries, ${stats['hitRate']}% hit rate');
    debugPrint('DEBUG: Performance Stats - Last Airport: $_lastProcessedAirport');
    debugPrint('DEBUG: Performance Stats - Last Slider Value: $_lastProcessedSliderValue');
  }
  
  /// Get active periods for a given time with caching
  Map<String, dynamic>? getActivePeriods(
    String airport,
    double sliderValue,
    List<DateTime> timeline,
    List<DecodedForecastPeriod> forecastPeriods,
  ) {
    // Generate a unique TAF identifier from the forecast periods
    final tafHash = forecastPeriods.isNotEmpty 
        ? (forecastPeriods.first.rawSection?.hashCode ?? forecastPeriods.hashCode)
        : timeline.hashCode;
    
    final cacheKey = CacheManager.generateKey('taf_active_periods', {
      'airport': airport,
      'sliderValue': sliderValue.toStringAsFixed(3),
      'tafHash': tafHash.toString(),
    });
    
    // Check cache first
    final cachedResult = _cacheManager.get<Map<String, dynamic>>(cacheKey);
    if (cachedResult != null) {
      debugPrint('DEBUG: Using cached active periods for $airport at $sliderValue');
      return cachedResult;
    }
    
    debugPrint('DEBUG: Calculating active periods for $airport at $sliderValue (cache miss)');
    
    if (timeline.isEmpty || forecastPeriods.isEmpty) {
      return null;
    }
    
    // Only log parsed periods occasionally to reduce console spam
    print('DEBUG: 🔍 === PARSED PERIODS FOR $airport ===');
    for (int i = 0; i < forecastPeriods.length; i++) {
      final period = forecastPeriods[i];
      print('DEBUG: 🔍 Period $i: ${period.type} (${period.time})');
      print('DEBUG: 🔍   Start time: ${period.startTime}');
      print('DEBUG: 🔍   End time: ${period.endTime}');
      print('DEBUG: 🔍   Is concurrent: ${period.isConcurrent}');
    }
    print('DEBUG: 🔍 === END PARSED PERIODS ===');
    
    // Calculate the current time based on slider position
    final currentTime = timeline[(sliderValue * (timeline.length - 1)).round()];
    
    print('DEBUG: 🔍 TafStateManager - Slider value: $sliderValue');
    print('DEBUG: 🔍 TafStateManager - Timeline length: ${timeline.length}');
    print('DEBUG: 🔍 TafStateManager - Timeline index: ${(sliderValue * (timeline.length - 1)).round()}');
    print('DEBUG: 🔍 TafStateManager - Current time: $currentTime');
    
    // Find active baseline period
    final activeBaseline = getActiveBaselinePeriod(forecastPeriods, currentTime);
    
    // Find active concurrent periods with reduced logging
    final activeConcurrent = <DecodedForecastPeriod>[];
    for (final period in forecastPeriods) {
      if (period.isConcurrent) {
        if (period.startTime != null && period.endTime != null) {
          final isActive = (period.startTime!.isBefore(currentTime) || period.startTime!.isAtSameMomentAs(currentTime)) && 
                          period.endTime!.isAfter(currentTime);
          
          if (isActive) {
            activeConcurrent.add(period);
          }
        }
      }
    }
    
    final result = {
      'baseline': activeBaseline,
      'concurrent': activeConcurrent,
    };
    
    // Cache the result
    _cacheManager.set(cacheKey, result);
    
    debugPrint('DEBUG: Calculated active periods: baseline=${activeBaseline?.type}, concurrent=${activeConcurrent.length}');
    return result;
  }
  
  /// Gets complete weather for a period, including inheritance logic
  Map<String, String> getCompleteWeatherForPeriod(
    DecodedForecastPeriod period,
    String airport,
    double sliderValue,
    List<DecodedForecastPeriod> allPeriods,
  ) {
    // Generate a unique TAF identifier from the period's raw section
    final tafHash = period.rawSection?.hashCode ?? allPeriods.hashCode;
    
    final cacheKey = CacheManager.generateKey('taf_weather', {
      'airport': airport,
      'sliderValue': sliderValue.toStringAsFixed(3),
      'periodType': period.type,
      'tafHash': tafHash.toString(),
    });
    
    // Check cache first
    final cachedWeather = _cacheManager.get<Map<String, String>>(cacheKey);
    if (cachedWeather != null) {
      debugPrint('DEBUG: Using cached weather for ${period.type}');
      return cachedWeather;
    }
    
    debugPrint('DEBUG: Calculating weather for ${period.type} (cache miss)');
    
    // Calculate complete weather with inheritance
    final completeWeather = Map<String, String>.from(period.weather);

    // Special logic for POST_BECMG: inherit from previous baseline, then apply only changed elements
    if (period.type == 'POST_BECMG') {
      // Find the corresponding BECMG period (same time window)
      final becmgPeriod = allPeriods.firstWhereOrNull(
        (p) => p.type == 'BECMG' &&
          p.endTime == period.startTime,
      );
      // Find the previous baseline period
      final prevBaseline = allPeriods.lastWhereOrNull(
        (p) => !p.isConcurrent && p.endTime != null && p.endTime!.isAtSameMomentAs(period.startTime!),
      );
      if (prevBaseline != null) {
        // Start with previous baseline's weather
        completeWeather.clear();
        completeWeather.addAll(prevBaseline.weather);
      }
      if (becmgPeriod != null) {
        // Overwrite only changed elements
        for (final key in becmgPeriod.changedElements) {
          if (becmgPeriod.weather[key] != null && becmgPeriod.weather[key] != '-') {
            completeWeather[key] = becmgPeriod.weather[key]!;
          }
        }
      }
    } else {
      // For each weather element, search back through all previous periods for the most recent non-missing value
      for (final key in ['Wind', 'Visibility', 'Cloud', 'Weather']) {
        if (completeWeather[key] == null || completeWeather[key]!.isEmpty || completeWeather[key] == '-') {
          // Search back through all previous periods
          for (final p in allPeriods.reversed) {
            if (p.startTime != null && p.startTime!.isBefore(period.startTime!)) {
              if (p.weather[key] != null && p.weather[key]!.isNotEmpty && p.weather[key] != '-') {
                completeWeather[key] = p.weather[key]!;
                debugPrint('DEBUG: Inherited $key from ${p.type}: ${p.weather[key]}');
                break;
              }
            }
          }
        }
      }
    }
    
    // Cache the result
    _cacheManager.set(cacheKey, completeWeather);
    
    debugPrint('DEBUG: Complete weather for ${period.type}: $completeWeather');
    return completeWeather;
  }
  
  /// Gets dual weather for BECMG periods showing both previous and new conditions
  Map<String, dynamic>? getBecmgDualWeather(
    DecodedForecastPeriod becmgPeriod,
    String airport,
    double sliderValue,
    List<DecodedForecastPeriod> allPeriods,
  ) {
    if (becmgPeriod.type != 'BECMG') {
      return null;
    }

    // Find the previous baseline period (what conditions are ending)
    DecodedForecastPeriod? previousBaseline;
    for (final p in allPeriods.reversed) {
      if (!p.isConcurrent && p.type != 'BECMG' && p.startTime != null && p.startTime!.isBefore(becmgPeriod.startTime!)) {
        previousBaseline = p;
        break;
      }
    }

    if (previousBaseline == null) {
      return null;
    }

    // Get complete weather for both periods
    final previousWeather = getCompleteWeatherForPeriod(previousBaseline, airport, sliderValue, allPeriods);
    final newWeather = getCompleteWeatherForPeriod(becmgPeriod, airport, sliderValue, allPeriods);

    // Parse BECMG transition time
    final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(becmgPeriod.time);
    String transitionTime = 'Unknown';
    if (timeMatch != null) {
      final fromDay = timeMatch.group(1)!;
      final fromHour = timeMatch.group(2)!;
      final toDay = timeMatch.group(3)!;
      final toHour = timeMatch.group(4)!;
      transitionTime = '$fromDay$fromHour/$toDay${toHour}Z';
    }

    return {
      'previous': {
        'period': previousBaseline.type,
        'weather': previousWeather,
        'description': 'Ending conditions',
      },
      'new': {
        'period': 'BECMG',
        'weather': newWeather,
        'description': 'Becoming conditions',
      },
      'transition': {
        'time': transitionTime,
        'description': 'Both conditions possible during transition',
      },
    };
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
            if (mostRecentTime == null || period.startTime!.isAfter(mostRecentTime)) {
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
  
  /// Get performance metrics for monitoring
  Map<String, dynamic> getPerformanceMetrics() {
    final now = DateTime.now();
    final stats = _cacheManager.getStats();
    
    return {
      'cacheSize': stats['size'],
      'cacheHitRate': '${stats['hitRate']}%',
      'cacheHits': stats['hits'],
      'cacheMisses': stats['misses'],
      'lastMetricsReset': _lastMetricsReset?.toIso8601String(),
      'uptime': _lastMetricsReset != null ? now.difference(_lastMetricsReset!).inMinutes : 0,
    };
  }
  
  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _cacheManager.clear();
    _lastMetricsReset = DateTime.now();
  }
} 