import 'package:flutter/material.dart';

/// Data Freshness Service
/// 
/// Handles calculation of data freshness and provides color coding
/// for UI display based on data age.
class DataFreshnessService {
  /// Fresh data threshold (12 hours)
  static const int freshThresholdHours = 12;
  
  /// Stale data threshold (24 hours)
  static const int staleThresholdHours = 24;
  
  /// Expired data threshold (36 hours)
  static const int expiredThresholdHours = 36;

  /// Calculate data age in hours from timestamp
  static int calculateAgeInHours(DateTime timestamp) {
    final now = DateTime.now();
    return now.difference(timestamp).inHours;
  }

  /// Get data freshness status based on age
  static DataFreshness getFreshnessStatus(DateTime timestamp) {
    final ageInHours = calculateAgeInHours(timestamp);
    
    if (ageInHours < freshThresholdHours) {
      return DataFreshness.fresh;
    } else if (ageInHours < staleThresholdHours) {
      return DataFreshness.stale;
    } else if (ageInHours < expiredThresholdHours) {
      return DataFreshness.expired;
    } else {
      return DataFreshness.veryExpired;
    }
  }

  /// Get color for data freshness status
  static Color getFreshnessColor(DateTime timestamp) {
    final status = getFreshnessStatus(timestamp);
    
    switch (status) {
      case DataFreshness.fresh:
        return Colors.green;
      case DataFreshness.stale:
        return Colors.orange;
      case DataFreshness.expired:
        return Colors.red;
      case DataFreshness.veryExpired:
        return Colors.red.shade900;
    }
  }

  /// Get icon for data freshness status
  static IconData getFreshnessIcon(DateTime timestamp) {
    final status = getFreshnessStatus(timestamp);
    
    switch (status) {
      case DataFreshness.fresh:
        return Icons.check_circle;
      case DataFreshness.stale:
        return Icons.warning;
      case DataFreshness.expired:
      case DataFreshness.veryExpired:
        return Icons.error;
    }
  }

  /// Get human-readable age string
  static String getAgeString(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final totalMinutes = difference.inMinutes;
    final totalHours = difference.inHours;
    final totalDays = difference.inDays;
    
    if (totalMinutes < 1) {
      return 'Just now';
    } else if (totalMinutes < 60) {
      return '$totalMinutes minutes ago';
    } else if (totalHours == 1) {
      return '1 hour ago';
    } else if (totalHours < 24) {
      return '$totalHours hours ago';
    } else if (totalDays == 1) {
      final remainingHours = totalHours % 24;
      return remainingHours == 0 ? '1 day ago' : '1 day, $remainingHours hours ago';
    } else {
      final remainingHours = totalHours % 24;
      return remainingHours == 0 ? '$totalDays days ago' : '$totalDays days, $remainingHours hours ago';
    }
  }

  /// Get freshness description for UI
  static String getFreshnessDescription(DateTime timestamp) {
    final status = getFreshnessStatus(timestamp);
    
    switch (status) {
      case DataFreshness.fresh:
        return 'Fresh';
      case DataFreshness.stale:
        return 'Stale';
      case DataFreshness.expired:
        return 'Expired';
      case DataFreshness.veryExpired:
        return 'Very Expired';
    }
  }

  /// Check if data should show warning
  static bool shouldShowWarning(DateTime timestamp) {
    final status = getFreshnessStatus(timestamp);
    return status == DataFreshness.expired || status == DataFreshness.veryExpired;
  }

  /// Get warning message for expired data
  static String getWarningMessage(DateTime timestamp) {
    final ageInHours = calculateAgeInHours(timestamp);
    
    if (ageInHours >= expiredThresholdHours) {
      return 'Data is over 36 hours old. Consider refreshing for latest information.';
    } else if (ageInHours >= staleThresholdHours) {
      return 'Data is over 24 hours old. Some information may be outdated.';
    } else {
      return '';
    }
  }

  /// Check if data is considered reliable for offline use
  static bool isReliableForOffline(DateTime timestamp) {
    final ageInHours = calculateAgeInHours(timestamp);
    // Consider data reliable if less than 48 hours old
    return ageInHours < 48;
  }
}

/// Data freshness status enum
enum DataFreshness {
  fresh,      // < 12h - Green
  stale,      // 12-24h - Orange
  expired,    // 24-36h - Red
  veryExpired // > 36h - Dark Red
} 