import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/australian_airport_database.dart';
import '../models/airport_infrastructure.dart';
import 'openaip_service.dart';

/// Manages caching of airport infrastructure data
/// Fetches real data from OpenAIP API and caches it locally
class AirportCacheManager {
  static const String _cacheKey = 'airport_infrastructure_cache';
  static const Duration _cacheValidity = Duration(days: 28); // 4 weeks
  static const int _maxCacheSize = 100; // Maximum cached airports
  
  /// Get airport infrastructure data
  /// Priority: Initial Australian airports → Cache → API → Fallback
  static Future<AirportInfrastructure?> getAirportInfrastructure(String icao) async {
    final upperIcao = icao.toUpperCase();
    
    // 1. Check if it's an initial Australian airport
    if (AustralianAirportDatabase.isInitialAirport(upperIcao)) {
      // For initial airports, we'll fetch from API but mark as priority
      return await _fetchAndCacheAirport(upperIcao, isPriority: true);
    }
    
    // 2. Check cache
    final cached = await _getCachedAirport(upperIcao);
    if (cached != null) {
      return cached;
    }
    
    // 3. Fetch from API
    return await _fetchAndCacheAirport(upperIcao);
  }
  
  /// Fetch airport from API and cache it
  static Future<AirportInfrastructure?> _fetchAndCacheAirport(
    String icao, {
    bool isPriority = false,
  }) async {
    try {
      // Get airport data from OpenAIP API
      final airport = await OpenAIPService.getAirportByICAO(icao);
      if (airport != null) {
        // Convert to infrastructure format
        final infrastructure = _convertAirportToInfrastructure(airport);
        
        // Cache the result
        await _cacheAirport(icao, infrastructure, isPriority: isPriority);
        
        return infrastructure;
      }
    } catch (e) {
      developer.log('Failed to fetch airport $icao: $e');
    }
    
    return null;
  }
  
  /// Convert Airport model to AirportInfrastructure
  static AirportInfrastructure _convertAirportToInfrastructure(dynamic airport) {
    // This will be implemented once we have the infrastructure models
    // For now, return a basic infrastructure object
    return AirportInfrastructure(
      icao: airport.icao,
      runways: [], // Will be populated from API data
      taxiways: [], // Will be populated from API data
      navaids: [], // Will be populated from API data
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