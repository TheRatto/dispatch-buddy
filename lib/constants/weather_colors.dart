import 'package:flutter/material.dart';

/// Weather period color constants for consistent styling across the app
class WeatherColors {
  // Baseline periods (main forecast)
  static const Color initial = Color(0xFF3B82F6); // Sky Blue
  static const Color fm = Color(0xFF3B82F6); // Sky Blue (same as INITIAL)
  static const Color becmg = Color(0xFF6366F1); // Indigo (transition)
  
  // Concurrent periods (temporary/probabilistic)
  static const Color tempo = Color(0xFFF97316); // Orange
  static const Color inter = Color(0xFF8B5CF6); // Violet
  static const Color prob30 = Color(0xFFF59E0B); // Amber
  static const Color prob40 = Color(0xFFF59E0B); // Amber (same as PROB30)
  
  /// Get color for a period type
  static Color getColorForPeriodType(String periodType) {
    if (periodType.contains('INITIAL')) return initial;
    if (periodType.contains('FM')) return fm;
    if (periodType.contains('BECMG')) return becmg;
    if (periodType.contains('TEMPO')) return tempo;
    if (periodType.contains('INTER')) return inter;
    if (periodType.contains('PROB30')) return prob30;
    if (periodType.contains('PROB40')) return prob40;
    
    // Default fallback
    return Colors.black;
  }
  
  /// Get color for PROB + INTER/TEMPO combinations
  /// These use the INTER/TEMPO color, not the PROB color
  static Color getColorForProbCombination(String periodType) {
    if (periodType.contains('TEMPO')) return tempo;
    if (periodType.contains('INTER')) return inter;
    return getColorForPeriodType(periodType);
  }
} 