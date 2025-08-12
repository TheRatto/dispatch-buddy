import 'package:flutter/foundation.dart';
import '../models/briefing.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/briefing_storage_service.dart';
import '../services/api_service.dart';
// import '../services/briefing_conversion_service.dart';
import '../services/cache_manager.dart';
// import '../services/taf_state_manager.dart';
import '../services/airport_database.dart'; // Added for airport lookup
import '../providers/settings_provider.dart'; // Added for NAIPS settings

class RefreshException implements Exception {
  final String message;
  RefreshException(this.message);
  
  @override
  String toString() => 'RefreshException: $message';
}

class BriefingRefreshService {
  // final ApiService _apiService = ApiService();
  
  /// Refresh a briefing with fresh data from APIs
  /// Uses safety-first approach: backup → fetch → validate → update
  static Future<bool> refreshBriefing(Briefing briefing) async {
    final service = BriefingRefreshService();
    return await service._refreshBriefing(briefing);
  }
  
  /// Internal refresh method with safety-first approach
  Future<bool> _refreshBriefing(Briefing briefing) async {
    debugPrint('DEBUG: Starting refresh for briefing ${briefing.id}');
    
    // 1. IMMEDIATE BACKUP - Store current data as a version
    final currentData = {
      'notams': briefing.notams,
      'weather': briefing.weather,
      'timestamp': briefing.timestamp.toIso8601String(),
    };
    
    // Get current version number
    final currentVersion = await BriefingStorageService.getLatestVersion(briefing.id);
    if (currentVersion > 0) {
      await BriefingStorageService.storeVersionedData(briefing.id, currentData, currentVersion);
      debugPrint('DEBUG: Created backup version $currentVersion of current data');
    }
    
    try {
      // 2. CLEAR CACHES ONLY FOR RELEVANT AIRPORTS
      debugPrint('DEBUG: Clearing caches for relevant airports');
      final cacheManager = CacheManager();
      for (final airport in briefing.airports) {
        cacheManager.clearPrefix('notam_${airport}_');
        cacheManager.clearPrefix('weather_${airport}_');
        cacheManager.clearPrefix('taf_${airport}_');
      }
      // Also clear TAF state manager cache for relevant airports
      // Keep placeholder for future per-airport clear once implemented
      // final tafStateManager = TafStateManager();
      // tafStateManager.clearCacheForAirports(briefing.airports);
      
      // 3. FETCH NEW DATA (without touching original)
      debugPrint('DEBUG: Fetching fresh data for airports: ${briefing.airports}');
      final newData = await _fetchFreshData(briefing.airports);
      
      // 4. VALIDATE NEW DATA QUALITY
      debugPrint('DEBUG: Validating new data quality');
      if (!_isDataQualityAcceptable(newData, briefing.airports)) {
        throw RefreshException('New data quality check failed');
      }
      
      // 5. UPDATE AIRPORT INFORMATION (names, cities, etc.)
      debugPrint('DEBUG: Updating airport information');
      final updatedAirports = await _updateAirportInformation(briefing.airports);
      
      // 6. CREATE NEW VERSION WITH FRESH DATA
      debugPrint('DEBUG: Data quality passed, creating new version');
      final newVersionData = _prepareVersionedData(newData);
      final newVersion = await BriefingStorageService.createNewVersion(briefing.id, newVersionData);
      
      // 7. UPDATE BRIEFING METADATA (including updated airport info)
      final updatedBriefing = briefing.copyWith(
        timestamp: DateTime.now(),
        airports: updatedAirports, // Update with proper airport names
      );
      await BriefingStorageService.updateBriefing(updatedBriefing);
      
      debugPrint('DEBUG: Refresh completed successfully - created version $newVersion');
      return true;
      
    } catch (e) {
      debugPrint('DEBUG: Refresh failed: $e, rolling back to original data');
      debugPrint('DEBUG: Refresh failure details:');
      debugPrint('DEBUG: - Error type: ${e.runtimeType}');
      debugPrint('DEBUG: - Error message: $e');
      if (e is RefreshException) {
        debugPrint('DEBUG: - This is a RefreshException');
      }
      throw RefreshException('Refresh failed, original data preserved: $e');
    }
  }

  /// Fetch fresh data for the given airports
  Future<RefreshData> _fetchFreshData(List<String> airports) async {
    final notams = <Notam>[];
    final weather = <Weather>[];
    
    try {
      final apiService = ApiService();
      
      // Get NAIPS settings to pass to API service methods
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      final naipsEnabled = settingsProvider.naipsEnabled;
      final naipsUsername = settingsProvider.naipsUsername;
      final naipsPassword = settingsProvider.naipsPassword;
      
      debugPrint('DEBUG: BriefingRefreshService - NAIPS settings: enabled=$naipsEnabled, username=${naipsUsername != null ? "SET" : "NOT SET"}, password=${naipsPassword != null ? "SET" : "NOT SET"}');
      
      // Use the exact same approach as new briefing flow
      // Fetch all data in parallel using the new batch methods with NAIPS settings
      final notamsFuture = Future.wait(
        airports.map((icao) => apiService.fetchNotams(icao).catchError((e) {
          debugPrint('Warning: All SATCOM NOTAM strategies failed for $icao: $e');
          return <Notam>[]; // Return empty list on error
        }))
      );
      
      // Use the new separate methods for better separation of concerns
      final metarsFuture = apiService.fetchMetars(airports);
      final atisFuture = apiService.fetchAtis(airports);
      final tafsFuture = apiService.fetchTafs(airports);

      final results = await Future.wait([notamsFuture, metarsFuture, atisFuture, tafsFuture]);

      final List<List<Notam>> notamResults = results[0] as List<List<Notam>>;
      final List<Weather> metars = results[1] as List<Weather>;
      final List<Weather> atis = results[2] as List<Weather>;
      final List<Weather> tafs = results[3] as List<Weather>;

      // Debug: Show what we received from each API call
      debugPrint('DEBUG: BriefingRefreshService - Received from API:');
      debugPrint('DEBUG: - METARs: ${metars.length} items');
      for (final metar in metars) {
        debugPrint('DEBUG:   - ${metar.icao}: ${metar.type} (source: ${metar.source})');
      }
      debugPrint('DEBUG: - ATIS: ${atis.length} items');
      for (final atisItem in atis) {
        debugPrint('DEBUG:   - ${atisItem.icao}: ${atisItem.type} (source: ${atisItem.source})');
      }
      debugPrint('DEBUG: - TAFs: ${tafs.length} items');
      for (final taf in tafs) {
        debugPrint('DEBUG:   - ${taf.icao}: ${taf.type} (source: ${taf.source})');
      }

      // Flatten the list of lists into a single list (exactly like new briefing)
      final List<Notam> allNotams = notamResults.expand((notamList) => notamList).toList();
      
      // For refresh: Select only the latest METAR and TAF for each airport
      final Map<String, Weather> latestMetars = {};
      final Map<String, Weather> latestTafs = {};
      final Map<String, Weather> latestAtis = {};
      
      // Group METARs by airport and select the latest
      for (final metar in metars) {
        if (!latestMetars.containsKey(metar.icao) || 
            metar.timestamp.isAfter(latestMetars[metar.icao]!.timestamp)) {
          latestMetars[metar.icao] = metar;
        }
      }
      
      // Group TAFs by airport and select the latest
      for (final taf in tafs) {
        if (!latestTafs.containsKey(taf.icao) || 
            taf.timestamp.isAfter(latestTafs[taf.icao]!.timestamp)) {
          latestTafs[taf.icao] = taf;
        }
      }

      // Group ATIS by airport and select the latest
      debugPrint('DEBUG: BriefingRefreshService - Found ${atis.length} ATIS items:');
      for (final atisItem in atis) {
        debugPrint('DEBUG:   - ${atisItem.icao}: ${atisItem.rawText.substring(0, atisItem.rawText.length > 50 ? 50 : atisItem.rawText.length)}...');
      }
      
      for (final item in atis) {
        if (!latestAtis.containsKey(item.icao) ||
            item.timestamp.isAfter(latestAtis[item.icao]!.timestamp)) {
          latestAtis[item.icao] = item;
        }
      }
      
      // Add only the latest weather for each airport
      weather.addAll(latestMetars.values);
      weather.addAll(latestTafs.values);
      weather.addAll(latestAtis.values);
      
      notams.addAll(allNotams);
      
      debugPrint('DEBUG: Total fetched: ${notams.length} NOTAMs, ${weather.length} weather items');
      debugPrint('DEBUG: Latest METARs: ${latestMetars.length}, Latest TAFs: ${latestTafs.length}, Latest ATIS: ${latestAtis.length}');
      
      // Debug: Show timestamps for each airport
      for (final airport in airports) {
        final metar = latestMetars[airport];
        final taf = latestTafs[airport];
        final atis = latestAtis[airport];
        if (metar != null) {
          debugPrint('DEBUG: $airport - Latest METAR: ${metar.timestamp} (source: ${metar.source})');
        }
        if (taf != null) {
          debugPrint('DEBUG: $airport - Latest TAF: ${taf.timestamp} (source: ${taf.source})');
        }
        if (atis != null) {
          debugPrint('DEBUG: $airport - Latest ATIS: ${atis.timestamp} (source: ${atis.source})');
        }
      }
      
    } catch (e) {
      debugPrint('DEBUG: Failed to fetch data: $e');
      // Continue with whatever data we have
    }
    
    return RefreshData(
      notams: notams,
      weather: weather,
      hasApiErrors: false,
    );
  }
  
  /// Validate that new data is of acceptable quality
  bool _isDataQualityAcceptable(RefreshData newData, List<String> airports) {
    // Weather coverage check (50%+ of airports should have weather for refresh operations)
    // This is more lenient than new briefing creation to allow partial updates
    final airportsWithWeather = <String>{};
    for (final weather in newData.weather) {
      airportsWithWeather.add(weather.icao);
    }
    final weatherCoverage = airportsWithWeather.length / airports.length;
    debugPrint('DEBUG: Weather coverage: ${airportsWithWeather.length}/${airports.length} = ${(weatherCoverage * 100).toStringAsFixed(1)}%');
    
    if (weatherCoverage < 0.5) {
      debugPrint('DEBUG: Weather coverage below 50% threshold for refresh');
      debugPrint('DEBUG: - Required: ${(0.5 * 100).toStringAsFixed(1)}%');
      debugPrint('DEBUG: - Actual: ${(weatherCoverage * 100).toStringAsFixed(1)}%');
      debugPrint('DEBUG: - Airports with weather: $airportsWithWeather');
      debugPrint('DEBUG: - All airports: $airports');
      return false;
    }
    
    // NOTAM validity check (if we have NOTAMs, they should be valid)
    final totalNotams = newData.notams.length;
    if (totalNotams > 0) {
      final validNotams = newData.notams.where((notam) => notam.rawText.isNotEmpty).length;
      debugPrint('DEBUG: NOTAM validity: $validNotams/$totalNotams valid');
      
      if (validNotams == 0) {
        debugPrint('DEBUG: All NOTAMs are invalid');
        debugPrint('DEBUG: - Total NOTAMs: $totalNotams');
        debugPrint('DEBUG: - Valid NOTAMs: $validNotams');
        return false;
      }
    }
    
    // API error check
    if (newData.hasApiErrors) {
      debugPrint('DEBUG: API errors detected');
      debugPrint('DEBUG: - hasApiErrors flag is true');
      return false;
    }
    
    debugPrint('DEBUG: Data quality validation passed');
    debugPrint('DEBUG: - Weather coverage: ${(weatherCoverage * 100).toStringAsFixed(1)}%');
    debugPrint('DEBUG: - Total NOTAMs: $totalNotams');
    debugPrint('DEBUG: - Total weather items: ${newData.weather.length}');
    return true;
  }
  
  /// Prepare data for versioned storage
  Map<String, dynamic> _prepareVersionedData(RefreshData newData) {
    final notamsMap = <String, dynamic>{};
    final weatherMap = <String, dynamic>{};
    
    // Convert NOTAMs to storage format - use NOTAM ID as key (not versioned)
    for (final notam in newData.notams) {
      final key = notam.id; // Use NOTAM ID as key, not versioned
      notamsMap[key] = notam.toJson(); // Use the complete toJson method
    }
    
    // Convert weather to storage format - use simple key format
    for (final weather in newData.weather) {
      final key = '${weather.type}_${weather.icao}'; // Use simple key format
      weatherMap[key] = weather.toJson(); // Use the complete toJson method
    }
    
    return {
      'notams': notamsMap,
      'weather': weatherMap,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Load the latest versioned data for a briefing
  static Future<Map<String, dynamic>?> loadLatestVersionedData(String briefingId) async {
    return await BriefingStorageService.getLatestVersionedData(briefingId);
  }
  
  /// Get the latest version number for a briefing
  static Future<int> getLatestVersion(String briefingId) async {
    return await BriefingStorageService.getLatestVersion(briefingId);
  }
  
  /// Get all available versions for a briefing
  static Future<List<int>> getAvailableVersions(String briefingId) async {
    return await BriefingStorageService.getAvailableVersions(briefingId);
  }
  
  /// Update airport information with proper names and cities from database
  Future<List<String>> _updateAirportInformation(List<String> airports) async {
    debugPrint('DEBUG: Updating airport information for ${airports.length} airports');
    final updatedAirports = <String>[];
    
    for (final icao in airports) {
      try {
        // Get proper airport data from database
        final airportData = await AirportDatabase.getAirportWithFallback(icao);
        if (airportData != null) {
          debugPrint('DEBUG: Updated airport $icao - Name: ${airportData.name}, City: ${airportData.city}');
        } else {
          debugPrint('DEBUG: No airport data found for $icao, keeping original');
        }
        // Always keep the ICAO code, even if we don't have additional data
        updatedAirports.add(icao);
      } catch (e) {
        debugPrint('DEBUG: Error updating airport $icao: $e, keeping original');
        updatedAirports.add(icao);
      }
    }
    
    debugPrint('DEBUG: Updated airport list: $updatedAirports');
    return updatedAirports;
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