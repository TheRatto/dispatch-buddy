import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Units { feet, meters }

class SettingsProvider extends ChangeNotifier {
  static const String _unitsKey = 'runway_units';
  static const String _naipsEnabledKey = 'naips_enabled';
  
  Units _runwayUnits = Units.feet; // Default to feet
  bool _isInitialized = false;
  
  // NAIPS settings
  bool _naipsEnabled = true;

  Units get runwayUnits => _runwayUnits;
  bool get isInitialized => _isInitialized;
  
  // NAIPS getters
  bool get naipsEnabled => _naipsEnabled;

  // Initialize settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load existing runway units setting
      final unitsString = prefs.getString(_unitsKey);
      if (unitsString != null) {
        _runwayUnits = Units.values.firstWhere(
          (unit) => unit.name == unitsString,
          orElse: () => Units.feet,
        );
      }
      
      // Load NAIPS settings
      _naipsEnabled = prefs.getBool(_naipsEnabledKey) ?? true;
      
      debugPrint('DEBUG: 🔧 SettingsProvider.initialize() - Loaded NAIPS settings: enabled=$_naipsEnabled (using rotating test accounts)');
      
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
  
  // Update NAIPS enabled setting
  Future<void> setNaipsEnabled(bool enabled) async {
    if (_naipsEnabled == enabled) return;
    
    debugPrint('DEBUG: 🔧 SettingsProvider.setNaipsEnabled() - Setting NAIPS enabled to: $enabled');
    
    _naipsEnabled = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_naipsEnabledKey, enabled);
      debugPrint('DEBUG: 🔧 SettingsProvider.setNaipsEnabled() - Successfully saved NAIPS enabled setting to storage');
    } catch (e) {
      debugPrint('Error saving NAIPS enabled setting: $e');
    }
  }

  // Get the appropriate unit symbol
  String get unitSymbol => _runwayUnits == Units.feet ? 'ft' : 'm';

  // Convert length from feet to the selected unit
  String formatLength(double lengthFeet) {
    if (lengthFeet <= 0) return '';
    
    if (_runwayUnits == Units.feet) {
      // Show feet as-is (from JSON)
      final feet = lengthFeet.round();
      return feet.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    } else {
      // Convert feet to meters
      final meters = (lengthFeet * 0.3048).round();
      return meters.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
    }
  }

  // Convert width from meters to the selected unit
  String formatWidth(double widthMeters) {
    if (widthMeters <= 0) return '';
    
    // Width always stays in meters, regardless of runway length units setting
    final meters = widthMeters.round();
    return meters.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }
} 