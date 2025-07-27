import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/briefing.dart';
import '../models/flight.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/briefing_storage_service.dart';
import '../services/api_service.dart';
import '../services/briefing_conversion_service.dart';
import '../services/cache_manager.dart';
import '../services/taf_state_manager.dart';

class ReplaceException implements Exception {
  final String message;
  ReplaceException(this.message);
  
  @override
  String toString() => 'ReplaceException: $message';
}

/// Service for refreshing briefings by replacing them with fresh data
/// Uses atomic replacement instead of versioning for simpler, more reliable operation
class BriefingReplaceService {
  final ApiService _apiService = ApiService();
  
  /// Refresh a briefing by replacing it with fresh data from APIs
  /// Uses safety-first approach: backup → fetch → validate → replace
  static Future<bool> refreshBriefingByReplacement(Briefing briefing) async {
    final service = BriefingReplaceService();
    return await service._refreshBriefingByReplacement(briefing);
  }
  
  /// Internal refresh method with safety-first approach
  Future<bool> _refreshBriefingByReplacement(Briefing briefing) async {
    debugPrint('DEBUG: Starting refresh by replacement for briefing ${briefing.id}');
    
    // 1. IMMEDIATE BACKUP - Store current data as backup
    final backupId = await _createBackup(briefing);
    if (backupId == null) {
      debugPrint('DEBUG: Failed to create backup, aborting refresh');
      return false;
    }
    
    try {
      // 2. CLEAR CACHES TO FORCE FRESH DATA
      debugPrint('DEBUG: Clearing caches to force fresh data');
      final cacheManager = CacheManager();
      cacheManager.clearPrefix('notam_');
      cacheManager.clearPrefix('weather_');
      cacheManager.clearPrefix('taf_');
      
      // Also clear TAF state manager cache
      final tafStateManager = TafStateManager();
      tafStateManager.clearCache();
      
          // 3. FETCH NEW DATA (without touching original)
    debugPrint('DEBUG: Fetching fresh data for airports: ${briefing.airports}');
    debugPrint('DEBUG: About to call _fetchFreshData...');
    final newData = await _fetchFreshData(briefing.airports);
    debugPrint('DEBUG: _fetchFreshData completed. NOTAMs: ${newData.notams.length}, Weather items: ${newData.weather.length}');
      
      // 4. VALIDATE NEW DATA QUALITY
      debugPrint('DEBUG: Validating new data quality');
      if (!_isDataQualityAcceptable(newData, briefing.airports)) {
        throw ReplaceException('New data quality check failed');
      }
      
      // 5. CREATE NEW BRIEFING WITH FRESH DATA
      debugPrint('DEBUG: Data quality passed, creating new briefing');
      final newBriefing = _createNewBriefing(briefing, newData);
      
      // 6. ATOMICALLY REPLACE THE BRIEFING
      final success = await BriefingStorageService.replaceBriefing(newBriefing);
      if (!success) {
        throw ReplaceException('Failed to replace briefing in storage');
      }
      
      debugPrint('DEBUG: Refresh by replacement completed successfully');
      return true;
      
    } catch (e) {
      // 7. AUTOMATIC ROLLBACK ON ANY FAILURE
      debugPrint('DEBUG: Refresh failed: $e, rolling back to original data');
      await _rollbackToBackup(backupId);
      throw ReplaceException('Refresh failed, original data preserved: $e');
    }
  }
  
  /// Create a backup of the current briefing
  Future<String?> _createBackup(Briefing briefing) async {
    try {
      final backupId = 'backup_${briefing.id}_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = {
        'briefing': briefing.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Store backup in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(backupId, jsonEncode(backupData));
      
      if (success) {
        debugPrint('DEBUG: Created backup $backupId for briefing ${briefing.id}');
        return backupId;
      } else {
        debugPrint('DEBUG: Failed to create backup for briefing ${briefing.id}');
        return null;
      }
    } catch (e) {
      debugPrint('DEBUG: Error creating backup: $e');
      return null;
    }
  }
  
  /// Rollback to backup if refresh fails
  Future<void> _rollbackToBackup(String backupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(backupId);
      
      if (backupJson != null) {
        final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
        final originalBriefing = Briefing.fromJson(backupData['briefing']);
        
        // Restore the original briefing
        await BriefingStorageService.replaceBriefing(originalBriefing);
        debugPrint('DEBUG: Successfully rolled back to backup $backupId');
      } else {
        debugPrint('DEBUG: Backup $backupId not found for rollback');
      }
    } catch (e) {
      debugPrint('DEBUG: Error during rollback: $e');
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
        if (metars.isNotEmpty) {
          debugPrint('DEBUG: METAR timestamp for $airport: ${metars.first.timestamp}');
        }
        if (tafs.isNotEmpty) {
          debugPrint('DEBUG: TAF timestamp for $airport: ${tafs.first.timestamp}');
        }
        
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
  
  /// Create a new briefing with fresh data
  Briefing _createNewBriefing(Briefing oldBriefing, RefreshData newData) {
    // Convert data to storage format
    final notamsMap = <String, dynamic>{};
    final weatherMap = <String, dynamic>{};
    
    // Convert NOTAMs to storage format
    for (final notam in newData.notams) {
      final key = '${notam.id}_${DateTime.now().millisecondsSinceEpoch}';
      notamsMap[key] = {
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
      final key = '${weather.type}_${weather.icao}_${DateTime.now().millisecondsSinceEpoch}';
      weatherMap[key] = {
        'type': weather.type,
        'icao': weather.icao,
        'rawText': weather.rawText,
        'timestamp': weather.timestamp.toIso8601String(),
      };
    }
    
    // Create new briefing with fresh data but preserve metadata
    return oldBriefing.copyWith(
      notams: notamsMap,
      weather: weatherMap,
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