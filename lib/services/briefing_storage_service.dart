import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/briefing.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Briefing Storage Service
/// 
/// Handles saving, loading, updating, and managing briefings
/// in SharedPreferences storage with automatic cleanup.
class BriefingStorageService {
  static const String _storageKey = 'saved_briefings';
  static const int _maxBriefings = 20;

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
      print('Error loading briefings: $e');
      return [];
    }
  }

  /// Load a specific briefing by ID
  static Future<Briefing?> loadBriefing(String id) async {
    try {
      final briefings = await _loadAllBriefings();
      return briefings.firstWhere((b) => b.id == id);
    } catch (e) {
      print('Error loading briefing $id: $e');
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
        print('Briefing ${updatedBriefing.id} not found for update');
        return false;
      }
      
      // Update the briefing while preserving its position
      briefings[index] = updatedBriefing;
      
      // Save back to storage
      final jsonList = briefings.map((b) => b.toJson()).toList();
      return await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error updating briefing: $e');
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
        print('Briefing $briefingId not found for flag toggle');
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
      print('Error toggling flag: $e');
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
      print('Error deleting briefing: $e');
      return false;
    }
  }

  /// Rename a briefing
  static Future<bool> renameBriefing(String id, String newName) async {
    try {
      final briefing = await loadBriefing(id);
      if (briefing == null) {
        print('Briefing $id not found for rename');
        return false;
      }
      
      final updatedBriefing = briefing.copyWith(name: newName);
      return await updateBriefing(updatedBriefing);
    } catch (e) {
      print('Error renaming briefing $id: $e');
      return false;
    }
  }

  /// Add user notes to a briefing
  static Future<bool> addUserNotes(String id, String notes) async {
    try {
      final briefing = await loadBriefing(id);
      if (briefing == null) {
        print('Briefing $id not found for adding notes');
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
      print('Error getting briefing count: $e');
      return 0;
    }
  }

  /// Clear all saved briefings
  static Future<bool> clearAllBriefings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing briefings: $e');
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
      print('Error getting storage stats: $e');
      return {
        'totalBriefings': 0,
        'flaggedBriefings': 0,
        'totalNotams': 0,
        'maxBriefings': _maxBriefings,
      };
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