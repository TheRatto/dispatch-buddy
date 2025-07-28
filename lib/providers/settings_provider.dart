import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Units { feet, meters }

class SettingsProvider extends ChangeNotifier {
  static const String _unitsKey = 'runway_units';
  
  Units _runwayUnits = Units.feet; // Default to feet
  bool _isInitialized = false;

  Units get runwayUnits => _runwayUnits;

  // Initialize settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final unitsString = prefs.getString(_unitsKey);
      if (unitsString != null) {
        _runwayUnits = Units.values.firstWhere(
          (unit) => unit.name == unitsString,
          orElse: () => Units.feet,
        );
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing settings: $e');
    }
  }

  // Update runway units preference
  Future<void> setRunwayUnits(Units units) async {
    if (_runwayUnits == units) return;
    
    _runwayUnits = units;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unitsKey, units.name);
    } catch (e) {
      debugPrint('Error saving runway units setting: $e');
    }
  }

  // Get the appropriate unit symbol
  String get unitSymbol => _runwayUnits == Units.feet ? 'ft' : 'm';

  // Convert length from meters to the selected unit
  String formatLength(double lengthMeters) {
    if (lengthMeters <= 0) return '';
    
    if (_runwayUnits == Units.feet) {
      final feet = (lengthMeters * 3.28084).round();
      return feet.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    } else {
      final meters = lengthMeters.round();
      return meters.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    }
  }

  // Convert width from meters to the selected unit
  String formatWidth(double widthMeters) {
    if (widthMeters <= 0) return '';
    
    if (_runwayUnits == Units.feet) {
      final feet = (widthMeters * 3.28084).round();
      return feet.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    } else {
      final meters = widthMeters.round();
      return meters.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    }
  }
} 