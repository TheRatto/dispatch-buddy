import 'package:flutter/foundation.dart';
import '../models/briefing.dart';
import '../models/flight.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/briefing_storage_service.dart';
import '../services/api_service.dart';
import '../services/briefing_conversion_service.dart';

class RefreshException implements Exception {
  final String message;
  RefreshException(this.message);
  
  @override
  String toString() => 'RefreshException: $message';
}

class BriefingRefreshService {
  final ApiService _apiService = ApiService();
  
  /// Refresh a briefing with fresh data from APIs
  /// Uses safety-first approach: backup → fetch → validate → update
  static Future<bool> refreshBriefing(Briefing briefing) async {
    final service = BriefingRefreshService();
    return await service._refreshBriefing(briefing);
  }
  
  /// Internal refresh method with safety-first approach
  Future<bool> _refreshBriefing(Briefing briefing) async {
    debugPrint('DEBUG: Starting refresh for briefing ${briefing.id}');
    
    // 1. IMMEDIATE BACKUP
    final originalBriefing = briefing.copyWith();
    debugPrint('DEBUG: Created backup of original briefing data');
    
    try {
      // 2. FETCH NEW DATA (without touching original)
      debugPrint('DEBUG: Fetching fresh data for airports: ${briefing.airports}');
      final newData = await _fetchFreshData(briefing.airports);
      
      // 3. VALIDATE NEW DATA QUALITY
      debugPrint('DEBUG: Validating new data quality');
      if (!_isDataQualityAcceptable(newData, briefing.airports)) {
        throw RefreshException('New data quality check failed');
      }
      
      // 4. ONLY THEN UPDATE STORAGE
      debugPrint('DEBUG: Data quality passed, updating briefing');
      final updatedBriefing = _mergeNewData(briefing, newData);
      await BriefingStorageService.updateBriefing(updatedBriefing);
      
      debugPrint('DEBUG: Refresh completed successfully');
      return true;
      
    } catch (e) {
      // 5. AUTOMATIC ROLLBACK ON ANY FAILURE
      debugPrint('DEBUG: Refresh failed: $e, rolling back to original data');
      await BriefingStorageService.updateBriefing(originalBriefing);
      throw RefreshException('Refresh failed, original data preserved: $e');
    }
  }
  
  /// Fetch fresh data for the given airports
  Future<RefreshData> _fetchFreshData(List<String> airports) async {
    final notams = <Notam>[];
    final weather = <Weather>[];
    
    for (final airport in airports) {
      try {
        // Fetch NOTAMs
        final airportNotams = await _apiService.fetchNotams(airport);
        notams.addAll(airportNotams);
        
        // Fetch METARs (using fetchWeather for single airport)
        final metars = await _apiService.fetchWeather([airport]);
        weather.addAll(metars);
        
        // Fetch TAFs (using fetchTafs for single airport)
        final tafs = await _apiService.fetchTafs([airport]);
        weather.addAll(tafs);
        
        debugPrint('DEBUG: Fetched data for $airport: ${airportNotams.length} NOTAMs, ${metars.length} METARs, ${tafs.length} TAFs');
        
      } catch (e) {
        debugPrint('DEBUG: Failed to fetch data for $airport: $e');
        // Continue with other airports even if one fails
      }
    }
    
    return RefreshData(
      notams: notams,
      weather: weather,
      hasApiErrors: false, // Will be set based on overall success
    );
  }
  
  /// Validate that new data is of acceptable quality
  bool _isDataQualityAcceptable(RefreshData newData, List<String> airports) {
    // Weather coverage check (80%+ of airports should have weather)
    final airportsWithWeather = <String>{};
    for (final weather in newData.weather) {
      airportsWithWeather.add(weather.icao);
    }
    final weatherCoverage = airportsWithWeather.length / airports.length;
    debugPrint('DEBUG: Weather coverage: ${airportsWithWeather.length}/${airports.length} = ${(weatherCoverage * 100).toStringAsFixed(1)}%');
    
    if (weatherCoverage < 0.8) {
      debugPrint('DEBUG: Weather coverage below 80% threshold');
      return false;
    }
    
    // NOTAM validity check (if we have NOTAMs, they should be valid)
    final totalNotams = newData.notams.length;
    if (totalNotams > 0) {
      final validNotams = newData.notams.where((notam) => notam.rawText.isNotEmpty).length;
      debugPrint('DEBUG: NOTAM validity: $validNotams/$totalNotams valid');
      
      if (validNotams == 0) {
        debugPrint('DEBUG: All NOTAMs are invalid');
        return false;
      }
    }
    
    // API error check
    if (newData.hasApiErrors) {
      debugPrint('DEBUG: API errors detected');
      return false;
    }
    
    debugPrint('DEBUG: Data quality validation passed');
    return true;
  }
  
  /// Merge new data into the briefing
  Briefing _mergeNewData(Briefing briefing, RefreshData newData) {
    // Convert new data to storage format
    final newNotamsMap = <String, dynamic>{};
    final newWeatherMap = <String, dynamic>{};
    
    // Convert NOTAMs to storage format
    for (final notam in newData.notams) {
      final key = '${notam.id}_${briefing.id}';
      newNotamsMap[key] = {
        'id': notam.id,
        'type': notam.type.toString(),
        'icao': notam.icao,
        'rawText': notam.rawText,
        'validFrom': notam.validFrom.toIso8601String(),
        'validTo': notam.validTo.toIso8601String(),
      };
    }
    
    // Convert weather to storage format
    for (final weather in newData.weather) {
      final key = '${weather.type}_${weather.icao}_${briefing.id}';
      newWeatherMap[key] = {
        'type': weather.type,
        'icao': weather.icao,
        'rawText': weather.rawText,
        'timestamp': weather.timestamp.toIso8601String(),
      };
    }
    
    // Create updated briefing with new data
    return briefing.copyWith(
      notams: newNotamsMap,
      weather: newWeatherMap,
      timestamp: DateTime.now(), // Update timestamp to now
    );
  }
}

/// Data class for refresh results
class RefreshData {
  final List<Notam> notams;
  final List<Weather> weather;
  final bool hasApiErrors;
  
  RefreshData({
    required this.notams,
    required this.weather,
    required this.hasApiErrors,
  });
} 