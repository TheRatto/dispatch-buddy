import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for fetching airport timezone information
/// Uses multiple APIs for comprehensive coverage
class AirportTimezoneService {
  static const String _baseUrl = 'https://api.aviationapi.com/v1';
  static const String _fallbackUrl = 'https://api.flightapi.io/airport';
  static const Duration _cacheValidity = Duration(hours: 24);
  
  // In-memory cache for timezone data
  static final Map<String, AirportTimezone> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Get timezone information for an airport
  static Future<AirportTimezone?> getAirportTimezone(String icao) async {
    final upperIcao = icao.toUpperCase();
    
    // Check cache first
    if (_cache.containsKey(upperIcao)) {
      final cacheTime = _cacheTimestamps[upperIcao]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidity) {
        debugPrint('DEBUG: AirportTimezoneService - Using cached timezone for $upperIcao');
        return _cache[upperIcao];
      }
    }
    
    debugPrint('DEBUG: AirportTimezoneService - Fetching timezone for $upperIcao');
    
    try {
      // Try primary API first
      final timezone = await _fetchFromAviationApi(upperIcao);
      if (timezone != null) {
        _cache[upperIcao] = timezone;
        _cacheTimestamps[upperIcao] = DateTime.now();
        return timezone;
      }
      
      // Try fallback API
      final fallbackTimezone = await _fetchFromFallbackApi(upperIcao);
      if (fallbackTimezone != null) {
        _cache[upperIcao] = fallbackTimezone;
        _cacheTimestamps[upperIcao] = DateTime.now();
        return fallbackTimezone;
      }
      
      // If no API data, try to infer from ICAO code patterns
      final inferredTimezone = _inferTimezoneFromIcao(upperIcao);
      if (inferredTimezone != null) {
        debugPrint('DEBUG: AirportTimezoneService - Inferred timezone for $upperIcao: ${inferredTimezone.timezone}');
        _cache[upperIcao] = inferredTimezone;
        _cacheTimestamps[upperIcao] = DateTime.now();
        return inferredTimezone;
      }
      
      debugPrint('DEBUG: AirportTimezoneService - No timezone data found for $upperIcao');
      return null;
    } catch (e) {
      debugPrint('ERROR: AirportTimezoneService - Failed to fetch timezone for $upperIcao: $e');
      return null;
    }
  }
  
  /// Fetch timezone from primary aviation API
  static Future<AirportTimezone?> _fetchFromAviationApi(String icao) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/airports/$icao'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DispatchBuddy/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse the response based on API structure
        if (data is Map<String, dynamic>) {
          final timezoneStr = data['timezone'] as String?;
          final country = data['country'] as String?;
          final city = data['city'] as String?;
          
          if (timezoneStr != null) {
            return AirportTimezone(
              icao: icao,
              timezone: timezoneStr,
              country: country ?? '',
              city: city ?? '',
              source: 'aviation_api',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: AirportTimezoneService - Aviation API failed for $icao: $e');
    }
    
    return null;
  }
  
  /// Fetch timezone from fallback API
  static Future<AirportTimezone?> _fetchFromFallbackApi(String icao) async {
    try {
      final response = await http.get(
        Uri.parse('$_fallbackUrl/$icao'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DispatchBuddy/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is Map<String, dynamic>) {
          final timezoneStr = data['timezone'] as String?;
          final country = data['country'] as String?;
          final city = data['city'] as String?;
          
          if (timezoneStr != null) {
            return AirportTimezone(
              icao: icao,
              timezone: timezoneStr,
              country: country ?? '',
              city: city ?? '',
              source: 'fallback_api',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: AirportTimezoneService - Fallback API failed for $icao: $e');
    }
    
    return null;
  }
  
  /// Infer timezone from ICAO code patterns for common regions
  static AirportTimezone? _inferTimezoneFromIcao(String icao) {
    // Common timezone patterns based on ICAO prefixes
    final timezoneMap = {
      // Australia (Y) - Multiple timezones
      'YSSY': 'Australia/Sydney',    // Sydney
      'YMML': 'Australia/Melbourne', // Melbourne
      'YBBN': 'Australia/Brisbane',  // Brisbane
      'YPPH': 'Australia/Perth',     // Perth
      'YSCB': 'Australia/Sydney',    // Canberra
      'YBRK': 'Australia/Brisbane',  // Rockhampton
      'YPDN': 'Australia/Darwin',    // Darwin
      
      // New Zealand (NZ)
      'NZAA': 'Pacific/Auckland',    // Auckland
      'NZWN': 'Pacific/Auckland',    // Wellington
      
      // United States (K) - Eastern
      'KJFK': 'America/New_York',    // New York JFK
      'KLGA': 'America/New_York',    // New York LaGuardia
      'KORD': 'America/Chicago',     // Chicago
      'KLAX': 'America/Los_Angeles', // Los Angeles
      'KDFW': 'America/Chicago',     // Dallas
      
      // United Kingdom (EG)
      'EGLL': 'Europe/London',       // London Heathrow
      'EGKK': 'Europe/London',       // London Gatwick
      
      // Europe (ED, LF, etc.)
      'EDDF': 'Europe/Berlin',       // Frankfurt
      'LFPG': 'Europe/Paris',        // Paris
      'EHAM': 'Europe/Amsterdam',    // Amsterdam
      
      // Asia
      'RJTT': 'Asia/Tokyo',          // Tokyo
      'VHHH': 'Asia/Hong_Kong',      // Hong Kong
      'WSSS': 'Asia/Singapore',      // Singapore
    };
    
    // Direct lookup
    if (timezoneMap.containsKey(icao)) {
      return AirportTimezone(
        icao: icao,
        timezone: timezoneMap[icao]!,
        country: '',
        city: '',
        source: 'inferred',
      );
    }
    
    // Pattern-based inference for common prefixes
    if (icao.startsWith('Y')) {
      // Australia - default to Sydney timezone
      return AirportTimezone(
        icao: icao,
        timezone: 'Australia/Sydney',
        country: 'Australia',
        city: '',
        source: 'inferred_australia',
      );
    } else if (icao.startsWith('NZ')) {
      // New Zealand
      return AirportTimezone(
        icao: icao,
        timezone: 'Pacific/Auckland',
        country: 'New Zealand',
        city: '',
        source: 'inferred_newzealand',
      );
    } else if (icao.startsWith('K')) {
      // United States - default to Eastern
      return AirportTimezone(
        icao: icao,
        timezone: 'America/New_York',
        country: 'United States',
        city: '',
        source: 'inferred_usa',
      );
    } else if (icao.startsWith('EG')) {
      // United Kingdom
      return AirportTimezone(
        icao: icao,
        timezone: 'Europe/London',
        country: 'United Kingdom',
        city: '',
        source: 'inferred_uk',
      );
    }
    
    return null;
  }
  
  /// Clear cache for a specific airport
  static void clearCache(String icao) {
    final upperIcao = icao.toUpperCase();
    _cache.remove(upperIcao);
    _cacheTimestamps.remove(upperIcao);
  }
  
  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_airports': _cache.length,
      'cache_keys': _cache.keys.toList(),
    };
  }
}

/// Data class for airport timezone information
class AirportTimezone {
  final String icao;
  final String timezone;
  final String country;
  final String city;
  final String source;
  
  const AirportTimezone({
    required this.icao,
    required this.timezone,
    required this.country,
    required this.city,
    required this.source,
  });
  
  @override
  String toString() {
    return 'AirportTimezone(icao: $icao, timezone: $timezone, country: $country, city: $city, source: $source)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirportTimezone &&
        other.icao == icao &&
        other.timezone == timezone;
  }
  
  @override
  int get hashCode => icao.hashCode ^ timezone.hashCode;
}
