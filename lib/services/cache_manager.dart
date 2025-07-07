import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Unified cache manager for UI-level caching across the app
/// 
/// This handles expensive UI calculations like:
/// - TAF decoding and period detection
/// - NOTAM filtering and sorting
/// - Weather parsing and formatting
/// 
/// IMPORTANT: This is separate from API/database caching which is disabled
/// for aviation safety. This only caches UI calculations to improve performance.
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache storage with automatic cleanup
  final Map<String, dynamic> _cache = HashMap();
  final Map<String, DateTime> _cacheTimestamps = HashMap();
  
  // Cache statistics
  int _hits = 0;
  int _misses = 0;
  
  // Cache configuration
  static const Duration _defaultTtl = Duration(minutes: 30);
  static const int _maxCacheSize = 1000;

  /// Get a value from cache
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) {
      _misses++;
      return null;
    }

    final timestamp = _cacheTimestamps[key];
    if (timestamp == null || DateTime.now().difference(timestamp) > _defaultTtl) {
      // Cache expired, remove it
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    if (kDebugMode && _hits % 50 == 0) {
      debugPrint('Cache hit #$_hits for key: $key');
    }
    
    return _cache[key] as T?;
  }

  /// Store a value in cache
  void set<T>(String key, T value, {Duration? ttl}) {
    // Cleanup if cache is too large
    if (_cache.length >= _maxCacheSize) {
      _cleanup();
    }

    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Check if a key exists and is not expired
  bool has(String key) {
    if (!_cache.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) <= _defaultTtl;
  }

  /// Remove a specific key
  void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
    _hits = 0;
    _misses = 0;
    if (kDebugMode) {
      debugPrint('Cache cleared');
    }
  }

  /// Clear cache for a specific prefix (e.g., all TAF-related cache)
  void clearPrefix(String prefix) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint('Cleared ${keysToRemove.length} cache entries with prefix: $prefix');
    }
  }

  /// Cleanup expired entries and old entries if cache is too large
  void _cleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    // Remove expired entries
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _defaultTtl) {
        keysToRemove.add(entry.key);
      }
    }

    // If still too large, remove oldest entries
    if (_cache.length - keysToRemove.length > _maxCacheSize) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final additionalToRemove = _cache.length - keysToRemove.length - _maxCacheSize;
      for (int i = 0; i < additionalToRemove; i++) {
        keysToRemove.add(sortedEntries[i].key);
      }
    }

    // Remove the keys
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint('Cache cleanup: removed ${keysToRemove.length} entries');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'hits': _hits,
      'misses': _misses,
      'size': _cache.length,
      'hitRate': _hits + _misses > 0 ? (_hits / (_hits + _misses) * 100).toStringAsFixed(1) : '0.0',
    };
  }

  /// Generate a cache key with consistent formatting
  static String generateKey(String prefix, Map<String, dynamic> params) {
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final paramString = sortedParams
        .map((e) => '${e.key}:${e.value}')
        .join('_');
    
    return '${prefix}_$paramString';
  }
} 