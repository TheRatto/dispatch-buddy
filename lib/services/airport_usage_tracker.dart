import 'package:flutter/foundation.dart';
import '../services/briefing_storage_service.dart';

/// Airport Usage Tracker Service
/// 
/// Analyzes briefing history to determine most frequently used airports.
/// Provides fallback to major Australian airports when no history exists.
class AirportUsageTracker {
  static const int _defaultLimit = 10;
  static const int _minUsageCount = 1; // Minimum times an airport must appear to be considered

  /// Get the most frequently used airports from briefing history
  /// 
  /// Returns up to [limit] airports, sorted by usage frequency.
  /// Falls back to major Australian airports if no history exists.
  static Future<List<String>> getMostUsedAirports({int limit = _defaultLimit}) async {
    try {
      debugPrint('AirportUsageTracker: Getting most used airports (limit: $limit)');
      
      // Load all briefings
      final briefings = await BriefingStorageService.loadAllBriefings();
      debugPrint('AirportUsageTracker: Loaded ${briefings.length} briefings');
      
      if (briefings.isEmpty) {
        debugPrint('AirportUsageTracker: No briefings found, using fallback airports');
        return _getFallbackAirports(limit);
      }
      
      // Count airport usage frequency
      final usageCounts = <String, int>{};
      for (final briefing in briefings) {
        for (final airport in briefing.airports) {
          usageCounts[airport] = (usageCounts[airport] ?? 0) + 1;
        }
      }
      
      debugPrint('AirportUsageTracker: Found ${usageCounts.length} unique airports');
      
      // Filter airports that meet minimum usage threshold
      final filteredCounts = usageCounts.entries
          .where((entry) => entry.value >= _minUsageCount)
          .toList();
      
      if (filteredCounts.isEmpty) {
        debugPrint('AirportUsageTracker: No airports meet minimum usage threshold, using fallback');
        return _getFallbackAirports(limit);
      }
      
      // Sort by usage count (descending) then by ICAO code (ascending)
      filteredCounts.sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) return countComparison;
        return a.key.compareTo(b.key);
      });
      
      // Take top N airports
      final result = filteredCounts
          .take(limit)
          .map((entry) => entry.key)
          .toList();
      
      debugPrint('AirportUsageTracker: Returning ${result.length} most used airports: $result');
      return result;
      
    } catch (e) {
      debugPrint('AirportUsageTracker: Error getting most used airports: $e');
      return _getFallbackAirports(limit);
    }
  }

  /// Get detailed usage counts for debugging
  static Future<Map<String, int>> getAirportUsageCounts() async {
    try {
      final briefings = await BriefingStorageService.loadAllBriefings();
      final usageCounts = <String, int>{};
      
      for (final briefing in briefings) {
        for (final airport in briefing.airports) {
          usageCounts[airport] = (usageCounts[airport] ?? 0) + 1;
        }
      }
      
      // Sort by usage count (descending)
      final sortedCounts = Map.fromEntries(
        usageCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
      );
      
      return sortedCounts;
    } catch (e) {
      debugPrint('AirportUsageTracker: Error getting usage counts: $e');
      return {};
    }
  }

  /// Get fallback airports when no briefing history exists
  /// 
  /// Returns major Australian airports in a sensible order for quick start.
  static List<String> _getFallbackAirports(int limit) {
    // Major Australian airports in order of importance for quick start
    const fallbackAirports = [
      'YSSY', // Sydney - most important
      'YMML', // Melbourne
      'YBBN', // Brisbane
      'YPPH', // Perth
      'YPAD', // Adelaide
      'YSCB', // Canberra
      'YBCS', // Cairns
      'YPDN', // Darwin
      'YMHB', // Hobart
      'YMAV', // Avalon
      'YBCG', // Gold Coast
      'YMLT', // Launceston
      'YCFS', // Coffs Harbour
      'YMAY', // Albury
      'YBLN', // Busselton
      'YAMB', // Amberley
      'YWLM', // Williamtown
      'YSRI', // Richmond
      'YPED', // Edinburgh
      'YPTN', // Tindal
    ];
    
    return fallbackAirports.take(limit).toList();
  }

  /// Check if an airport is commonly used (appears in multiple briefings)
  static Future<bool> isCommonlyUsed(String icao, {int minBriefings = 2}) async {
    try {
      final briefings = await BriefingStorageService.loadAllBriefings();
      int count = 0;
      
      for (final briefing in briefings) {
        if (briefing.airports.contains(icao)) {
          count++;
          if (count >= minBriefings) return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('AirportUsageTracker: Error checking if airport is commonly used: $e');
      return false;
    }
  }

  /// Get usage statistics for a specific airport
  static Future<Map<String, dynamic>> getAirportStats(String icao) async {
    try {
      final briefings = await BriefingStorageService.loadAllBriefings();
      int usageCount = 0;
      DateTime? firstUsed;
      DateTime? lastUsed;
      
      for (final briefing in briefings) {
        if (briefing.airports.contains(icao)) {
          usageCount++;
          if (firstUsed == null || briefing.timestamp.isBefore(firstUsed)) {
            firstUsed = briefing.timestamp;
          }
          if (lastUsed == null || briefing.timestamp.isAfter(lastUsed)) {
            lastUsed = briefing.timestamp;
          }
        }
      }
      
      return {
        'icao': icao,
        'usageCount': usageCount,
        'firstUsed': firstUsed,
        'lastUsed': lastUsed,
        'isUsed': usageCount > 0,
      };
    } catch (e) {
      debugPrint('AirportUsageTracker: Error getting airport stats: $e');
      return {
        'icao': icao,
        'usageCount': 0,
        'firstUsed': null,
        'lastUsed': null,
        'isUsed': false,
      };
    }
  }
}
