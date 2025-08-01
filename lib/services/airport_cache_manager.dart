import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/australian_airport_database.dart';
import '../models/airport_infrastructure.dart';
import 'openaip_service.dart';
import 'ersa_data_service.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Manages caching of airport infrastructure data
/// Fetches real data from OpenAIP API and caches it locally
class AirportCacheManager {
  static const String _cacheKey = 'airport_infrastructure_cache';
  static const Duration _cacheValidity = Duration(days: 28); // 4 weeks
  static const int _maxCacheSize = 100; // Maximum cached airports
  
  /// Get airport infrastructure data
  /// Clean fork: ERSA for Australian airports (Y), API for international airports
  static Future<AirportInfrastructure?> getAirportInfrastructure(String icao) async {
    final upperIcao = icao.toUpperCase();
    
    debugPrint('DEBUG: AirportCacheManager - getAirportInfrastructure called for $upperIcao');
    
    // Fork based on ICAO prefix
    if (upperIcao.startsWith('Y')) {
      // Australian airports: Use ERSA data only
      debugPrint('DEBUG: AirportCacheManager - Australian airport detected, using ERSA data for $upperIcao');
      return await _getERSAData(upperIcao);
    } else {
      // International airports: Use API data with cache
      debugPrint('DEBUG: AirportCacheManager - International airport detected, using API data for $upperIcao');
      return await _getAPIData(upperIcao);
    }
  }
  
  /// Get ERSA data for Australian airports
  static Future<AirportInfrastructure?> _getERSAData(String icao) async {
    debugPrint('DEBUG: AirportCacheManager - Loading ERSA data for $icao');
    final ersaData = await ERSADataService.getAirportInfrastructure(icao);
    
    if (ersaData != null) {
      debugPrint('DEBUG: AirportCacheManager - ERSA data loaded successfully for $icao');
      debugPrint('DEBUG: AirportCacheManager - ERSA navaids count: ${ersaData.navaids.length}');
      for (final navaid in ersaData.navaids) {
        debugPrint('DEBUG: AirportCacheManager - ERSA navaid: ${navaid.type} ${navaid.identifier} ${navaid.frequency}');
      }
      return ersaData;
    } else {
      debugPrint('DEBUG: AirportCacheManager - No ERSA data found for $icao');
      return null;
    }
  }
  
  /// Get API data for international airports
  static Future<AirportInfrastructure?> _getAPIData(String icao) async {
    // 1. Check cache first
    final cached = await _getCachedAirport(icao);
    if (cached != null) {
      debugPrint('DEBUG: AirportCacheManager - Using cached data for $icao');
      return cached;
    }
    
    // 2. Fetch from API
    debugPrint('DEBUG: AirportCacheManager - Fetching from API for $icao');
    return await _fetchAndCacheAirport(icao);
  }
  
  /// Fetch airport from API and cache it
  static Future<AirportInfrastructure?> _fetchAndCacheAirport(
    String icao, {
    bool isPriority = false,
  }) async {
    try {
      debugPrint('DEBUG: AirportCacheManager - Fetching airport $icao from OpenAIP API');
      
      // Get airport data from OpenAIP API
      final airport = await OpenAIPService.getAirportByICAO(icao);
      if (airport != null) {
        debugPrint('DEBUG: AirportCacheManager - Received airport data for $icao');
        debugPrint('DEBUG: AirportCacheManager - Airport name: ${airport.name}');
        debugPrint('DEBUG: AirportCacheManager - Runways count: ${airport.runways.length}');
        
        // Convert to infrastructure format
        final infrastructure = await _convertAirportToInfrastructure(airport);
        
        debugPrint('DEBUG: AirportCacheManager - Converted to infrastructure with ${infrastructure.runways.length} runways');
        
        // Cache the result
        await _cacheAirport(icao, infrastructure, isPriority: isPriority);
        
        return infrastructure;
      } else {
        debugPrint('DEBUG: AirportCacheManager - No airport data received for $icao');
      }
    } catch (e) {
      debugPrint('DEBUG: AirportCacheManager - Failed to fetch airport $icao: $e');
    }
    
    return null;
  }
  
  /// Convert Airport model to AirportInfrastructure
  static Future<AirportInfrastructure> _convertAirportToInfrastructure(dynamic airport) async {
    // Convert OpenAIP runway data to AirportInfrastructure format
    final List<Runway> runways = [];
    
    debugPrint('DEBUG: AirportCacheManager - Converting airport: ${airport.icao}');
    debugPrint('DEBUG: AirportCacheManager - Airport runways property: ${airport.runways}');
    debugPrint('DEBUG: AirportCacheManager - Airport runways type: ${airport.runways.runtimeType}');
    
    // Handle OpenAIP runway data
    if (airport.runways != null) {
      debugPrint('DEBUG: AirportCacheManager - Processing ${airport.runways.length} runways');
      
      for (int i = 0; i < airport.runways.length; i++) {
        final runway = airport.runways[i];
        debugPrint('DEBUG: AirportCacheManager - Runway $i: $runway');
        debugPrint('DEBUG: AirportCacheManager - Runway $i type: ${runway.runtimeType}');
        
        if (runway is String) {
          debugPrint('DEBUG: AirportCacheManager - Runway $i is String identifier: $runway');
          
          // Create a Runway object from the string identifier
          runways.add(Runway(
            identifier: runway,
            length: 0.0, // OpenAIP doesn't provide length in basic response
            surface: 'Unknown',
            approaches: [],
            hasLighting: false,
            width: 0.0,
            status: 'OPERATIONAL', // Default status
          ));
          debugPrint('DEBUG: AirportCacheManager - Added runway $i to list');
        } else if (runway is Runway) {
          debugPrint('DEBUG: AirportCacheManager - Runway $i is Runway object');
          debugPrint('DEBUG: AirportCacheManager - Runway $i identifier: ${runway.identifier}');
          debugPrint('DEBUG: AirportCacheManager - Runway $i length: ${runway.length}');
          
          // Use the Runway object directly
          runways.add(runway);
          debugPrint('DEBUG: AirportCacheManager - Added runway $i to list');
        } else {
          debugPrint('DEBUG: AirportCacheManager - Runway $i is unknown type, skipping');
        }
      }
    }
    
    debugPrint('DEBUG: AirportCacheManager - Final runways list length: ${runways.length}');
    
    // Fetch navaids from OpenAIP
    final navaids = await OpenAIPService.getNavaidsByICAO(airport.icao);
    debugPrint('DEBUG: AirportCacheManager - Fetched ${navaids.length} navaids from OpenAIP for ${airport.icao}');
    
    return AirportInfrastructure(
      icao: airport.icao,
      runways: runways,
      taxiways: [], // Will be populated from API data
      navaids: navaids, // Populated from OpenAIP
      approaches: [], // Will be populated from API data
      routes: [], // Will be populated from API data
      facilityStatus: {}, // Will be populated from API data
    );
  }
  
  /// Cache airport infrastructure data
  static Future<void> _cacheAirport(
    String icao,
    AirportInfrastructure infrastructure, {
    bool isPriority = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = _getCacheMap(prefs);
      
      // Add to cache
      cache[icao] = CachedAirportData(
        infrastructure: infrastructure,
        timestamp: DateTime.now(),
        isPriority: isPriority,
      );
      
      // Cleanup if cache is full
      _cleanupCache(cache);
      
      // Save updated cache
      await _saveCacheMap(prefs, cache);
    } catch (e) {
      developer.log('Failed to cache airport $icao: $e');
    }
  }
  
  /// Get cached airport data
  static Future<AirportInfrastructure?> _getCachedAirport(String icao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = _getCacheMap(prefs);
      
      final cached = cache[icao];
      if (cached != null && !cached.isExpired) {
        return cached.infrastructure;
      } else if (cached != null && cached.isExpired) {
        // Remove expired entry
        cache.remove(icao);
        await _saveCacheMap(prefs, cache);
      }
    } catch (e) {
      developer.log('Failed to get cached airport $icao: $e');
    }
    
    return null;
  }
  
  /// Cleanup cache if it's too large
  static void _cleanupCache(Map<String, CachedAirportData> cache) {
    if (cache.length <= _maxCacheSize) return;
    
    // Sort by timestamp (oldest first) and priority
    final sorted = cache.entries.toList()
      ..sort((a, b) {
        // Priority airports last
        if (a.value.isPriority && !b.value.isPriority) return 1;
        if (!a.value.isPriority && b.value.isPriority) return -1;
        // Then by timestamp
        return a.value.timestamp.compareTo(b.value.timestamp);
      });
    
    // Remove oldest non-priority entries
    final toRemove = sorted.take(cache.length - _maxCacheSize);
    for (final entry in toRemove) {
      if (!entry.value.isPriority) {
        cache.remove(entry.key);
      }
    }
  }
  
  /// Get cache map from SharedPreferences
  static Map<String, CachedAirportData> _getCacheMap(SharedPreferences prefs) {
    final cacheJson = prefs.getString(_cacheKey);
    if (cacheJson == null) return {};
    
    try {
      final cacheMap = json.decode(cacheJson) as Map<String, dynamic>;
      return cacheMap.map((key, value) {
        return MapEntry(key, CachedAirportData.fromJson(value));
      });
    } catch (e) {
      developer.log('Failed to parse cache: $e');
      return {};
    }
  }
  
  /// Save cache map to SharedPreferences
  static Future<void> _saveCacheMap(
    SharedPreferences prefs,
    Map<String, CachedAirportData> cache,
  ) async {
    try {
      final cacheJson = json.encode(cache.map((key, value) {
        return MapEntry(key, value.toJson());
      }));
      await prefs.setString(_cacheKey, cacheJson);
    } catch (e) {
      developer.log('Failed to save cache: $e');
    }
  }
  
  /// Clear expired cache entries
  static Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = _getCacheMap(prefs);
      
      final expiredKeys = cache.keys.where((key) {
        return cache[key]!.isExpired;
      }).toList();
      
      for (final key in expiredKeys) {
        cache.remove(key);
      }
      
      await _saveCacheMap(prefs, cache);
    } catch (e) {
      developer.log('Failed to cleanup expired cache: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = _getCacheMap(prefs);
      
      final total = cache.length;
      final expired = cache.values.where((data) => data.isExpired).length;
      final priority = cache.values.where((data) => data.isPriority).length;
      
      return {
        'total': total,
        'expired': expired,
        'priority': priority,
        'maxSize': _maxCacheSize,
        'validityWeeks': _cacheValidity.inDays ~/ 7,
      };
    } catch (e) {
      developer.log('Failed to get cache stats: $e');
      return {};
    }
  }
  
  /// Clear all cached airport data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('DEBUG: AirportCacheManager - Cache cleared');
    } catch (e) {
      debugPrint('DEBUG: AirportCacheManager - Error clearing cache: $e');
    }
  }
}

/// Cached airport data with timestamp and priority
class CachedAirportData {
  final AirportInfrastructure infrastructure;
  final DateTime timestamp;
  final bool isPriority;
  
  CachedAirportData({
    required this.infrastructure,
    required this.timestamp,
    this.isPriority = false,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > AirportCacheManager._cacheValidity;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'infrastructure': infrastructure.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'isPriority': isPriority,
    };
  }
  
  factory CachedAirportData.fromJson(Map<String, dynamic> json) {
    return CachedAirportData(
      infrastructure: AirportInfrastructure.fromJson(json['infrastructure']),
      timestamp: DateTime.parse(json['timestamp']),
      isPriority: json['isPriority'] ?? false,
    );
  }
} 