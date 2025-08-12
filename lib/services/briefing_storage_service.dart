import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/briefing.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Briefing Storage Service
/// 
/// Handles saving, loading, updating, and managing briefings
/// in SharedPreferences storage with automatic cleanup.
/// Now includes versioned data storage with incremental versioning.
class BriefingStorageService {
  static const String _storageKey = 'saved_briefings';
  static const int _maxBriefings = 20;
  static const int _maxVersions = 3; // Keep last 3 versions

  /// Save a briefing to storage
  static Future<bool> saveBriefing(Briefing briefing) async {
    try {
      debugPrint('DEBUG: Saving briefing ${briefing.id} to storage...');
      final prefs = await SharedPreferences.getInstance();
      final briefings = await _loadAllBriefings();
      
      debugPrint('DEBUG: Current briefings in storage: ${briefings.length}');
      
      // Add new briefing to the beginning (most recent first)
      briefings.insert(0, briefing);
      
      // Keep only the most recent briefings
      if (briefings.length > _maxBriefings) {
        briefings.removeRange(_maxBriefings, briefings.length);
      }
      
      // Save back to storage
      final jsonList = briefings.map((b) => b.toJson()).toList();
      final success = await prefs.setString(_storageKey, jsonEncode(jsonList));
      
      debugPrint('DEBUG: Save operation ${success ? 'SUCCESS' : 'FAILED'} - Total briefings: ${briefings.length}');
      return success;
    } catch (e) {
      debugPrint('DEBUG: Error saving briefing: $e');
      return false;
    }
  }

  /// Load all saved briefings
  static Future<List<Briefing>> loadAllBriefings() async {
    try {
      final briefings = await _loadAllBriefings();
      
      // Sort by flagged status first, then by timestamp (newest first)
      briefings.sort((a, b) {
        if (a.isFlagged && !b.isFlagged) return -1;
        if (!a.isFlagged && b.isFlagged) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
      
      return briefings;
    } catch (e) {
      debugPrint('Error loading briefings: $e');
      return [];
    }
  }

  /// Load a specific briefing by ID
  static Future<Briefing?> loadBriefing(String id) async {
    try {
      final briefings = await _loadAllBriefings();
      return briefings.firstWhere((b) => b.id == id);
    } catch (e) {
      debugPrint('Error loading briefing $id: $e');
      return null;
    }
  }

  /// Update an existing briefing
  static Future<bool> updateBriefing(Briefing updatedBriefing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final briefings = await _loadAllBriefings();
      
      final index = briefings.indexWhere((b) => b.id == updatedBriefing.id);
      if (index == -1) {
        debugPrint('Briefing ${updatedBriefing.id} not found for update');
        return false;
      }
      
      // Update the briefing while preserving its position
      briefings[index] = updatedBriefing;
      
      // Save back to storage
      final jsonList = briefings.map((b) => b.toJson()).toList();
      return await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error updating briefing: $e');
      return false;
    }
  }

  /// Replace an existing briefing with a new one (atomic operation)
  /// This is used for refresh operations to ensure data consistency
  static Future<bool> replaceBriefing(Briefing newBriefing) async {
    try {
      debugPrint('DEBUG: Replacing briefing ${newBriefing.id} with fresh data');
      final prefs = await SharedPreferences.getInstance();
      final briefings = await _loadAllBriefings();
      
      final index = briefings.indexWhere((b) => b.id == newBriefing.id);
      if (index == -1) {
        debugPrint('DEBUG: Briefing ${newBriefing.id} not found for replacement');
        return false;
      }
      
      // Replace the briefing while preserving its position
      briefings[index] = newBriefing;
      
      // Save back to storage atomically
      final jsonList = briefings.map((b) => b.toJson()).toList();
      final success = await prefs.setString(_storageKey, jsonEncode(jsonList));
      
      if (success) {
        debugPrint('DEBUG: Successfully replaced briefing ${newBriefing.id}');
      } else {
        debugPrint('DEBUG: Failed to save replaced briefing ${newBriefing.id}');
      }
      
      return success;
    } catch (e) {
      debugPrint('DEBUG: Error replacing briefing ${newBriefing.id}: $e');
      return false;
    }
  }

  /// Toggle the flag status of a briefing
  static Future<bool> toggleFlag(String briefingId) async {
    try {
      final briefings = await _loadAllBriefings();
      
      // Find and update the briefing
      final index = briefings.indexWhere((b) => b.id == briefingId);
      if (index == -1) {
        debugPrint('Briefing $briefingId not found for flag toggle');
        return false;
      }
      
      // Toggle the flag
      final updatedBriefing = briefings[index].copyWith(
        isFlagged: !briefings[index].isFlagged,
      );
      briefings[index] = updatedBriefing;
      
      // Save back to storage
      final prefs = await SharedPreferences.getInstance();
      final jsonList = briefings.map((b) => b.toJson()).toList();
      return await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error toggling flag: $e');
      return false;
    }
  }

  /// Delete a briefing by ID
  static Future<bool> deleteBriefing(String briefingId) async {
    try {
      final briefings = await _loadAllBriefings();
      
      // Remove the briefing
      final updatedBriefings = briefings.where((b) => b.id != briefingId).toList();
      
      // Save back to storage
      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedBriefings.map((b) => b.toJson()).toList();
      return await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error deleting briefing: $e');
      return false;
    }
  }

  /// Rename a briefing
  static Future<bool> renameBriefing(String id, String newName) async {
    try {
      final briefing = await loadBriefing(id);
      if (briefing == null) {
        debugPrint('Briefing $id not found for rename');
        return false;
      }
      
      final updatedBriefing = briefing.copyWith(name: newName);
      return await updateBriefing(updatedBriefing);
    } catch (e) {
      debugPrint('Error renaming briefing $id: $e');
      return false;
    }
  }

  /// Add user notes to a briefing
  static Future<bool> addUserNotes(String id, String notes) async {
    try {
      final briefing = await loadBriefing(id);
      if (briefing == null) {
        debugPrint('Briefing $id not found for adding notes');
        return false;
      }
      
      final updatedBriefing = briefing.copyWith(userNotes: notes);
      return await updateBriefing(updatedBriefing);
    } catch (e) {
      print('Error adding notes to briefing $id: $e');
      return false;
    }
  }

  /// Get count of saved briefings
  static Future<int> getBriefingCount() async {
    try {
      final briefings = await _loadAllBriefings();
      return briefings.length;
    } catch (e) {
      debugPrint('Error getting briefing count: $e');
      return 0;
    }
  }

  /// Clear all saved briefings
  static Future<bool> clearAllBriefings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing briefings: $e');
      return false;
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final briefings = await _loadAllBriefings();
      final flaggedCount = briefings.where((b) => b.isFlagged).length;
      final totalNotams = briefings.fold(0, (sum, b) => sum + b.totalNotams);
      
      return {
        'totalBriefings': briefings.length,
        'flaggedBriefings': flaggedCount,
        'totalNotams': totalNotams,
        'maxBriefings': _maxBriefings,
      };
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
      return {
        'totalBriefings': 0,
        'flaggedBriefings': 0,
        'totalNotams': 0,
        'maxBriefings': _maxBriefings,
      };
    }
  }

  // ===== VERSIONED DATA STORAGE METHODS =====

  /// Get the latest version number for a briefing's data
  static Future<int> getLatestVersion(String briefingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionKey = '${briefingId}_latest_version';
      return prefs.getInt(versionKey) ?? 0;
    } catch (e) {
      debugPrint('DEBUG: Error getting latest version for $briefingId: $e');
      return 0;
    }
  }

  /// Set the latest version number for a briefing's data
  static Future<bool> setLatestVersion(String briefingId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionKey = '${briefingId}_latest_version';
      return await prefs.setInt(versionKey, version);
    } catch (e) {
      debugPrint('DEBUG: Error setting latest version for $briefingId: $e');
      return false;
    }
  }

  /// Store versioned data for a briefing
  static Future<bool> storeVersionedData(String briefingId, Map<String, dynamic> data, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataKey = '${briefingId}_v$version';
      final jsonData = jsonEncode(data);
      final success = await prefs.setString(dataKey, jsonData);
      
      if (success) {
        debugPrint('DEBUG: Stored version $version data for briefing $briefingId');
        await setLatestVersion(briefingId, version);
      }
      
      return success;
    } catch (e) {
      debugPrint('DEBUG: Error storing versioned data for $briefingId v$version: $e');
      return false;
    }
  }

  /// Load versioned data for a briefing
  static Future<Map<String, dynamic>?> loadVersionedData(String briefingId, int version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataKey = '${briefingId}_v$version';
      final jsonData = prefs.getString(dataKey);
      
      if (jsonData == null) {
        debugPrint('DEBUG: No data found for briefing $briefingId v$version');
        return null;
      }
      
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      debugPrint('DEBUG: Loaded version $version data for briefing $briefingId');
      return data;
    } catch (e) {
      debugPrint('DEBUG: Error loading versioned data for $briefingId v$version: $e');
      return null;
    }
  }

  /// Get the latest versioned data for a briefing
  static Future<Map<String, dynamic>?> getLatestVersionedData(String briefingId) async {
    try {
      final latestVersion = await getLatestVersion(briefingId);
      if (latestVersion == 0) {
        debugPrint('DEBUG: No versioned data found for briefing $briefingId');
        return null;
      }
      
      return await loadVersionedData(briefingId, latestVersion);
    } catch (e) {
      debugPrint('DEBUG: Error getting latest versioned data for $briefingId: $e');
      return null;
    }
  }

  /// Create a new version of data for a briefing
  static Future<int> createNewVersion(String briefingId, Map<String, dynamic> newData) async {
    try {
      final latestVersion = await getLatestVersion(briefingId);
      final newVersion = latestVersion + 1;
      
      // Store the new version
      final success = await storeVersionedData(briefingId, newData, newVersion);
      if (!success) {
        throw Exception('Failed to store new version data');
      }
      
      // Cleanup old versions if we exceed max versions
      await _cleanupOldVersions(briefingId, newVersion);
      
      debugPrint('DEBUG: Created version $newVersion for briefing $briefingId');
      return newVersion;
    } catch (e) {
      debugPrint('DEBUG: Error creating new version for $briefingId: $e');
      rethrow;
    }
  }

  /// Cleanup old versions, keeping only the last 3
  static Future<void> _cleanupOldVersions(String briefingId, int currentVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionsToDelete = <int>[];
      
      // Find versions to delete (older than the last 3)
      for (int version = 1; version <= currentVersion - _maxVersions; version++) {
        versionsToDelete.add(version);
      }
      
      // Delete old versions
      for (final version in versionsToDelete) {
        final dataKey = '${briefingId}_v$version';
        await prefs.remove(dataKey);
        debugPrint('DEBUG: Deleted old version $version for briefing $briefingId');
      }
    } catch (e) {
      debugPrint('DEBUG: Error cleaning up old versions for $briefingId: $e');
    }
  }

  /// Get all available versions for a briefing
  static Future<List<int>> getAvailableVersions(String briefingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versions = <int>[];
      
      // Check for versions 1 through current
      final latestVersion = await getLatestVersion(briefingId);
      for (int version = 1; version <= latestVersion; version++) {
        final dataKey = '${briefingId}_v$version';
        if (prefs.containsKey(dataKey)) {
          versions.add(version);
        }
      }
      
      return versions;
    } catch (e) {
      debugPrint('DEBUG: Error getting available versions for $briefingId: $e');
      return [];
    }
  }

  /// Migrate existing briefing to versioned data system
  /// This creates an initial version (v1) for briefings that don't have versioned data
  static Future<bool> migrateBriefingToVersioned(String briefingId) async {
    try {
      debugPrint('DEBUG: Migrating briefing $briefingId to versioned data system');
      
      // Check if briefing already has versioned data
      final latestVersion = await getLatestVersion(briefingId);
      if (latestVersion > 0) {
        debugPrint('DEBUG: Briefing $briefingId already has versioned data (v$latestVersion)');
        return true;
      }
      
      // Load the briefing metadata
      final briefing = await loadBriefing(briefingId);
      if (briefing == null) {
        debugPrint('DEBUG: Briefing $briefingId not found for migration');
        return false;
      }
      
      // Create initial version data from briefing metadata
      final initialData = {
        'notams': briefing.notams,
        'weather': briefing.weather,
        'timestamp': briefing.timestamp.toIso8601String(),
      };
      
      // Store as version 1
      final success = await storeVersionedData(briefingId, initialData, 1);
      if (success) {
        debugPrint('DEBUG: Successfully migrated briefing $briefingId to versioned data (v1)');
      } else {
        debugPrint('DEBUG: Failed to migrate briefing $briefingId to versioned data');
      }
      
      return success;
    } catch (e) {
      debugPrint('DEBUG: Error migrating briefing $briefingId: $e');
      return false;
    }
  }

  /// Migrate all existing briefings to versioned data system
  static Future<void> migrateAllBriefingsToVersioned() async {
    try {
      debugPrint('DEBUG: Starting migration of all briefings to versioned data system');
      
      final briefings = await loadAllBriefings();
      int migratedCount = 0;
      int failedCount = 0;
      
      for (final briefing in briefings) {
        final success = await migrateBriefingToVersioned(briefing.id);
        if (success) {
          migratedCount++;
        } else {
          failedCount++;
        }
      }
      
      debugPrint('DEBUG: Migration completed - $migratedCount successful, $failedCount failed');
    } catch (e) {
      debugPrint('DEBUG: Error during migration: $e');
    }
  }

  /// Internal method to load all briefings from storage
  static Future<List<Briefing>> _loadAllBriefings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      debugPrint('DEBUG: Raw storage data: ${jsonString?.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...');
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('DEBUG: No briefings found in storage');
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final briefings = jsonList.map((json) => Briefing.fromJson(json as Map<String, dynamic>)).toList();
      
      debugPrint('DEBUG: Successfully loaded ${briefings.length} briefings from storage');
      return briefings;
    } catch (e) {
      debugPrint('DEBUG: Error loading briefings from storage: $e');
      return [];
    }
  }
} 