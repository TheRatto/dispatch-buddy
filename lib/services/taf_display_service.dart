import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import 'decoder_service.dart';

/// Service for managing TAF display state and caching.
/// 
/// This service handles:
/// - Active period calculations
/// - Weather data caching
/// - Performance monitoring
/// - UI state management
class TafDisplayService {
  // Performance optimization: Cache for weather calculations
  final Map<String, Map<String, String>> _weatherCache = {};
  final Map<String, Map<String, dynamic>> _activePeriodsCache = {};
  
  // Data change tracking for better cache management
  String? _lastTafHash;
  String? _lastTimelineHash;
  
  // Performance monitoring
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  /// Gets active periods for a specific time, using cache when possible.
  /// 
  /// [taf] - The TAF data containing forecast periods
  /// [time] - The time to find active periods for
  /// [airport] - The airport ICAO code for cache key generation
  /// [sliderValue] - The slider position for cache key generation
  /// 
  /// Returns a map with 'baseline' and 'concurrent' periods
  Map<String, dynamic>? getActivePeriods(
    Weather taf, 
    DateTime time, 
    String airport, 
    double sliderValue
  ) {
    final cacheKey = _getActivePeriodsCacheKey(airport, sliderValue);
    
    // Check if we can use cached activePeriods
    if (_activePeriodsCache.containsKey(cacheKey)) {
      _cacheHits++;
      print('DEBUG: TafDisplayService - Using CACHED activePeriods: ${_activePeriodsCache[cacheKey]}');
      return _activePeriodsCache[cacheKey];
    }
    
    _cacheMisses++;
    
    // Calculate activePeriods and cache it
    final decoder = DecoderService();
    final forecastPeriods = taf.decodedWeather?.forecastPeriods ?? [];
    final activePeriods = decoder.findActivePeriodsAtTime(time, forecastPeriods);
    
    // Cache the result
    _activePeriodsCache[cacheKey] = activePeriods;
    _limitCacheSize();
    
    print('DEBUG: TafDisplayService - Calculated and CACHED activePeriods: $activePeriods');
    return activePeriods;
  }
  
  /// Gets complete weather for a period, using cache when possible.
  /// 
  /// [period] - The forecast period to get weather for
  /// [timeline] - The timeline for context
  /// [allPeriods] - All forecast periods for inheritance logic
  /// [airport] - The airport ICAO code for cache key generation
  /// [sliderValue] - The slider position for cache key generation
  /// 
  /// Returns a map of weather data with inherited values
  Map<String, String> getCompleteWeatherForPeriod(
    DecodedForecastPeriod period,
    List<DateTime> timeline,
    List<DecodedForecastPeriod>? allPeriods,
    String airport,
    double sliderValue
  ) {
    // Performance optimization: Check cache first
    final cacheKey = _getCacheKey(airport, sliderValue, period.type);
    
    if (_weatherCache.containsKey(cacheKey)) {
      _cacheHits++;
      print('DEBUG: TafDisplayService - Using CACHED weather for ${period.type}: ${_weatherCache[cacheKey]}');
      return _weatherCache[cacheKey]!;
    }
    
    _cacheMisses++;
    
    Map<String, String> completeWeather = Map.from(period.weather);
    print('DEBUG: TafDisplayService - Period ${period.type} - Original weather: ${period.weather}');
    
    if (period.type != 'INITIAL' && allPeriods != null && allPeriods.isNotEmpty) {
      DecodedForecastPeriod? sourcePeriod;
      
      if (period.type == 'BECMG') {
        // BECMG periods inherit from the immediately preceding baseline period
        // Find the most recent baseline period that starts before or at this BECMG period
        final baselinePeriods = allPeriods.where((p) => !p.isConcurrent && p.type != 'BECMG').toList();
        sourcePeriod = baselinePeriods
          .where((p) => p.startTime != null && !p.startTime!.isAfter(period.startTime!))
          .fold<DecodedForecastPeriod?>(null, (prev, p) =>
            prev == null || p.startTime!.isAfter(prev.startTime!) ? p : prev);
        print('DEBUG: TafDisplayService - BECMG period - inheriting from previous baseline period: ${sourcePeriod?.type}');
      } else if (period.type == 'FM') {
        // FM periods inherit from the previous FM period
        sourcePeriod = allPeriods
          .where((p) => p.type == 'FM' && p.endTime != null && p.endTime!.isBefore(period.startTime!))
          .fold<DecodedForecastPeriod?>(null, (prev, p) => prev == null || p.endTime!.isAfter(prev.endTime!) ? p : prev);
        print('DEBUG: TafDisplayService - FM period - inheriting from previous FM period: ${sourcePeriod?.type}');
      } else {
        // Concurrent periods (TEMPO/INTER) inherit from the current baseline period
        sourcePeriod = allPeriods
          .where((p) => !p.isConcurrent && p.startTime != null && p.endTime != null &&
                       p.startTime!.isBefore(period.startTime!) && p.endTime!.isAfter(period.startTime!))
          .firstOrNull;
        print('DEBUG: TafDisplayService - Concurrent period - inheriting from baseline period: ${sourcePeriod?.type}');
      }
      
      if (sourcePeriod != null) {
        for (final key in ['Wind', 'Visibility', 'Cloud', 'Weather']) {
          if (completeWeather[key] == null || completeWeather[key]!.isEmpty || completeWeather[key] == '-') {
            completeWeather[key] = sourcePeriod.weather[key] ?? '-';
            print('DEBUG: TafDisplayService - Inherited $key: ${sourcePeriod.weather[key]}');
          }
        }
      }
    }
    
    print('DEBUG: TafDisplayService - Complete weather for ${period.type}: $completeWeather');
    
    // Cache the result
    _weatherCache[cacheKey] = completeWeather;
    _limitCacheSize();
    
    return completeWeather;
  }
  
  /// Clears cache when switching airports or when data changes.
  void clearCache() {
    _weatherCache.clear();
    _activePeriodsCache.clear();
    _lastTafHash = null;
    _lastTimelineHash = null;
    _cacheHits = 0;
    _cacheMisses = 0;
    print('DEBUG: TafDisplayService - Cache cleared');
  }
  
  /// Smart cache clearing based on data changes.
  void clearCacheIfDataChanged(Weather taf, List<DateTime> timeline) {
    final currentTafHash = _generateTafHash(taf);
    final currentTimelineHash = _generateTimelineHash(timeline);
    
    if (_lastTafHash != currentTafHash || _lastTimelineHash != currentTimelineHash) {
      print('DEBUG: TafDisplayService - Data changed, clearing cache');
      _weatherCache.clear();
      _activePeriodsCache.clear();
      _lastTafHash = currentTafHash;
      _lastTimelineHash = currentTimelineHash;
      // Reset cache counters when data changes
      _cacheHits = 0;
      _cacheMisses = 0;
    }
  }
  
  /// Logs performance statistics.
  void logPerformanceStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;
    
    print('DEBUG: TafDisplayService - Performance Stats:');
    print('DEBUG: TafDisplayService - Weather Cache: ${_weatherCache.length} entries');
    print('DEBUG: TafDisplayService - Active Periods Cache: ${_activePeriodsCache.length} entries');
    print('DEBUG: TafDisplayService - Cache Hit Rate: ${hitRate.toStringAsFixed(1)}%');
    print('DEBUG: TafDisplayService - Total Requests: $totalRequests');
  }
  
  /// Gets the current cache hit rate.
  double get cacheHitRate {
    final totalRequests = _cacheHits + _cacheMisses;
    return totalRequests > 0 ? _cacheHits / totalRequests : 0.0;
  }
  
  // Private helper methods
  
  /// Generate cache key for weather calculations.
  String _getCacheKey(String airport, double sliderValue, String periodType) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}_$periodType';
  }
  
  /// Generate cache key for active periods.
  String _getActivePeriodsCacheKey(String airport, double sliderValue) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}';
  }
  
  /// Generate hash for TAF data to detect changes.
  String _generateTafHash(Weather taf) {
    return '${taf.rawText.hashCode}_${taf.decodedWeather?.forecastPeriods?.length ?? 0}';
  }
  
  /// Generate hash for timeline to detect changes.
  String _generateTimelineHash(List<DateTime> timeline) {
    return '${timeline.length}_${timeline.isNotEmpty ? timeline.first.hashCode : 0}_${timeline.isNotEmpty ? timeline.last.hashCode : 0}';
  }
  
  /// Limit cache size to prevent memory issues.
  void _limitCacheSize() {
    const maxCacheSize = 50; // Maximum number of cached entries
    
    if (_weatherCache.length > maxCacheSize) {
      final keysToRemove = _weatherCache.keys.take(_weatherCache.length - maxCacheSize).toList();
      for (final key in keysToRemove) {
        _weatherCache.remove(key);
      }
    }
    
    if (_activePeriodsCache.length > maxCacheSize) {
      final keysToRemove = _activePeriodsCache.keys.take(_activePeriodsCache.length - maxCacheSize).toList();
      for (final key in keysToRemove) {
        _activePeriodsCache.remove(key);
      }
    }
  }
} 