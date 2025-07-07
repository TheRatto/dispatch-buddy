import 'package:flutter/foundation.dart';

class DecodedForecastPeriod {
  final String type; // BECMG, TEMPO, FM, INTER
  final String time; // e.g., "FM1200", "TEMPO 1418"
  final String description; // "From 12:00Z" or "Temporary from 14:00Z to 18:00Z"
  final Map<String, String> weather;
  final Set<String> changedElements;
  final String? rawSection; // Raw TAF text segment for this period
  
  // New fields for concurrent periods
  final DateTime? startTime; // Parsed start time for slider integration
  final DateTime? endTime; // Parsed end time for slider integration
  final bool isConcurrent; // True for TEMPO/INTER, false for FM/BECMG
  final List<String> relatedBaselinePeriods; // Which baseline periods this TEMPO/INTER applies to
  final List<String> concurrentPeriods; // Which TEMPO/INTER periods run during this baseline period

  DecodedForecastPeriod({
    required this.type,
    required this.time,
    required this.description,
    required this.weather,
    this.changedElements = const {},
    this.rawSection,
    this.startTime,
    this.endTime,
    this.isConcurrent = false,
    List<String>? relatedBaselinePeriods,
    List<String>? concurrentPeriods,
  }) : relatedBaselinePeriods = relatedBaselinePeriods ?? [],
       concurrentPeriods = concurrentPeriods ?? [];

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'time': time,
      'description': description,
      'weather': weather,
      'changedElements': changedElements.toList(),
      'rawSection': rawSection,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isConcurrent': isConcurrent,
      'relatedBaselinePeriods': relatedBaselinePeriods,
      'concurrentPeriods': concurrentPeriods,
    };
  }

  factory DecodedForecastPeriod.fromJson(Map<String, dynamic> json) {
    return DecodedForecastPeriod(
      type: json['type'] ?? '',
      time: json['time'] ?? '',
      description: json['description'] ?? '',
      weather: Map.from(json['weather']),
      changedElements: Set.from(json['changedElements']),
      rawSection: json['rawSection'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isConcurrent: json['isConcurrent'] ?? false,
      relatedBaselinePeriods: List.from(json['relatedBaselinePeriods']),
      concurrentPeriods: List.from(json['concurrentPeriods']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DecodedForecastPeriod &&
        other.type == type &&
        other.time == time &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        _mapEquals(other.weather, weather) &&
        other.rawSection == rawSection &&
        other.isConcurrent == isConcurrent &&
        setEquals(other.changedElements, changedElements);
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      time,
      description,
      startTime,
      endTime,
      _hashMap(weather),
      rawSection,
      isConcurrent,
      _hashSet(changedElements),
    );
  }

  // Helper methods for deep equality
  bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  int _hashMap(Map<String, String> map) {
    int hash = 0;
    for (final entry in map.entries) {
      hash = Object.hash(hash, entry.key, entry.value);
    }
    return hash;
  }

  int _hashSet(Set<String> set) {
    int hash = 0;
    for (final item in set) {
      hash = Object.hash(hash, item);
    }
    return hash;
  }
}

class DecodedWeather {
  final String icao;
  final DateTime timestamp;
  final String rawText;
  final String type; // 'METAR' or 'TAF'
  
  // Decoded fields
  final int? windDirection;
  final int? windSpeed;
  final int? visibility;
  final String? cloudCover;
  final double? temperature;
  final double? dewPoint;
  final int? qnh;
  final String? conditions;
  final String? remarks;
  final String? rvr; // New field for Runway Visual Range
  
  // Human-readable descriptions
  final String windDescription;
  final String visibilityDescription;
  final String cloudDescription;
  final String temperatureDescription;
  final String pressureDescription;
  final String conditionsDescription;
  final String rvrDescription; // New field for RVR description
  final List<DecodedForecastPeriod>? forecastPeriods;
  final List<DateTime> timeline;

  DecodedWeather({
    required this.icao,
    required this.timestamp,
    required this.rawText,
    required this.type,
    this.windDirection,
    this.windSpeed,
    this.visibility,
    this.cloudCover,
    this.temperature,
    this.dewPoint,
    this.qnh,
    this.conditions,
    this.remarks,
    this.rvr,
    required this.windDescription,
    required this.visibilityDescription,
    required this.cloudDescription,
    required this.temperatureDescription,
    required this.pressureDescription,
    required this.conditionsDescription,
    required this.rvrDescription,
    this.forecastPeriods,
    required this.timeline,
  });

  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'timestamp': timestamp.toIso8601String(),
      'rawText': rawText,
      'type': type,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'visibility': visibility,
      'cloudCover': cloudCover,
      'temperature': temperature,
      'dewPoint': dewPoint,
      'qnh': qnh,
      'conditions': conditions,
      'remarks': remarks,
      'rvr': rvr,
      'windDescription': windDescription,
      'visibilityDescription': visibilityDescription,
      'cloudDescription': cloudDescription,
      'temperatureDescription': temperatureDescription,
      'pressureDescription': pressureDescription,
      'conditionsDescription': conditionsDescription,
      'rvrDescription': rvrDescription,
      'forecastPeriods': forecastPeriods?.map((p) => p.toJson()).toList(),
      'timeline': timeline.map((t) => t.toIso8601String()).toList(),
    };
  }

  factory DecodedWeather.fromJson(Map<String, dynamic> json) {
    return DecodedWeather(
      icao: json['icao'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      rawText: json['rawText'] ?? '',
      type: json['type'] ?? 'METAR',
      windDirection: json['windDirection'],
      windSpeed: json['windSpeed'],
      visibility: json['visibility'],
      cloudCover: json['cloudCover'],
      temperature: json['temperature']?.toDouble(),
      dewPoint: json['dewPoint']?.toDouble(),
      qnh: json['qnh'],
      conditions: json['conditions'],
      remarks: json['remarks'],
      rvr: json['rvr'],
      windDescription: json['windDescription'] ?? '',
      visibilityDescription: json['visibilityDescription'] ?? '',
      cloudDescription: json['cloudDescription'] ?? '',
      temperatureDescription: json['temperatureDescription'] ?? '',
      pressureDescription: json['pressureDescription'] ?? '',
      conditionsDescription: json['conditionsDescription'] ?? '',
      rvrDescription: json['rvrDescription'] ?? '',
      forecastPeriods: json['forecastPeriods'] != null 
        ? (json['forecastPeriods'] as List).map((p) => DecodedForecastPeriod.fromJson(p)).toList()
        : null,
      timeline: (json['timeline'] as List).map((t) => DateTime.parse(t)).toList(),
    );
  }
}

class TafTextProcessor {
  final String originalText;
  final String formattedText;

  TafTextProcessor(this.originalText) 
    : formattedText = _formatRawTaf(originalText);

  static String _formatRawTaf(String rawText) {
    // Simple approach: add line breaks before TAF forecast elements
    String formatted = rawText;

    // Add line breaks before key TAF elements (simple string replacement)
    formatted = formatted.replaceAll(' FM', '\nFM');
    formatted = formatted.replaceAll(' TEMPO', '\nTEMPO');
    formatted = formatted.replaceAll(' BECMG', '\nBECMG');
    formatted = formatted.replaceAll(' PROB30', '\nPROB30');
    formatted = formatted.replaceAll(' PROB40', '\nPROB40');
    formatted = formatted.replaceAll(' INTER', '\nINTER');
    
    // Fix: Remove newline before TEMPO/INTER if immediately after PROB30/40
    formatted = formatted.replaceAll('\nPROB30\nTEMPO', '\nPROB30 TEMPO');
    formatted = formatted.replaceAll('\nPROB30\nINTER', '\nPROB30 INTER');
    formatted = formatted.replaceAll('\nPROB40\nTEMPO', '\nPROB40 TEMPO');
    formatted = formatted.replaceAll('\nPROB40\nINTER', '\nPROB40 INTER');
    
    return formatted;
  }

  /// Get formatted section boundaries from original section boundaries
  Map<String, int> getFormattedSectionBounds(int originalStart, int originalEnd) {
    // Simple approach: format the original section and find it in the formatted text
    final originalSection = originalText.substring(originalStart, originalEnd);
    final formattedSection = _formatRawTaf(originalSection);
    
    // Find the formatted section in the full formatted text
    final start = formattedText.indexOf(formattedSection);
    
    if (start >= 0) {
      final end = start + formattedSection.length;
      return {
        'start': start,
        'end': end,
      };
    } else {
      // Fallback: if exact match not found, try to find a partial match
      // This can happen if the section contains special characters or formatting
      print('DEBUG: Exact formatted section not found, using fallback');
      
      // Find the closest match by looking for the first few characters
      final firstWords = formattedSection.split(' ').take(3).join(' ');
      final fallbackStart = formattedText.indexOf(firstWords);
      
      if (fallbackStart >= 0) {
        final fallbackEnd = fallbackStart + firstWords.length;
        return {
          'start': fallbackStart,
          'end': fallbackEnd,
        };
      } else {
        // Last resort: use the original positions (this might not be perfect but prevents crashes)
        print('DEBUG: Using original positions as fallback');
        return {
          'start': originalStart,
          'end': originalEnd,
        };
      }
    }
  }

  /// Validate and sanitize section boundaries
  List<Map<String, dynamic>> validateSections(List<Map<String, dynamic>> sections) {
    final validatedSections = <Map<String, dynamic>>[];
    
    // Sort sections by start position
    sections.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final start = section['start'] as int;
      final end = section['end'] as int;
      
      // Validate bounds
      if (start < 0 || end < 0 || start >= originalText.length || end > originalText.length) {
        print('DEBUG: Invalid section bounds: start=$start, end=$end, textLength=${originalText.length}');
        continue;
      }
      
      // Ensure start < end
      if (start >= end) {
        print('DEBUG: Invalid section: start >= end: start=$start, end=$end');
        continue;
      }
      
      // Check for overlap with previous section
      if (validatedSections.isNotEmpty) {
        final lastSection = validatedSections.last;
        final lastEnd = lastSection['end'] as int;
        
        if (start < lastEnd) {
          print('DEBUG: Overlapping sections detected: lastEnd=$lastEnd, start=$start');
          // Merge overlapping sections
          lastSection['end'] = end;
          lastSection['text'] = originalText.substring(lastSection['start'] as int, end);
          continue;
        }
      }
      
      validatedSections.add(section);
    }
    
    return validatedSections;
  }
} 