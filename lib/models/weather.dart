import 'decoded_weather_models.dart';
import '../services/decoder_service.dart' as decoder;
import 'package:flutter/foundation.dart';

class Weather {
  final String icao;
  final DateTime timestamp;
  final String rawText;
  final String decodedText;
  final int windDirection;
  final int windSpeed;
  final int visibility;
  final String cloudCover;
  final double temperature;
  final double dewPoint;
  final int qnh;
  final String conditions;
  final String type; // 'METAR', 'TAF', or 'ATIS'
  final DecodedWeather? decodedWeather; // New field for decoded data
  final String source; // 'aviationweather', 'naips', 'faa'
  
  // ATIS-specific fields
  final String? atisCode; // 'A', 'B', 'C', etc.
  final String? atisType; // 'ATIS', 'D-ATIS'

  Weather({
    required this.icao,
    required this.timestamp,
    required this.rawText,
    required this.decodedText,
    required this.windDirection,
    required this.windSpeed,
    required this.visibility,
    required this.cloudCover,
    required this.temperature,
    required this.dewPoint,
    required this.qnh,
    required this.conditions,
    this.type = 'METAR',
    this.decodedWeather,
    this.source = 'aviationweather',
    this.atisCode,
    this.atisType,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final icao = json['icao'] ?? '';
    final rawText = json['rawText'] ?? '';
    final type = json['type'] ?? 'METAR';
    
    // For TAF and METAR data, try to load decoded weather from JSON first, then re-decode if needed
    DecodedWeather? decodedWeather;
    if (rawText.isNotEmpty) {
      if (json['decodedWeather'] != null) {
        debugPrint('DEBUG: Weather.fromJson - loading decoded weather from JSON for $icao ($type)');
        try {
          decodedWeather = DecodedWeather.fromJson(json['decodedWeather']);
        } catch (e) {
          debugPrint('DEBUG: Weather.fromJson - failed to load from JSON, re-decoding for $icao ($type): $e');
          final decoderService = decoder.DecoderService();
          if (type == 'TAF') {
            decodedWeather = decoderService.decodeTaf(rawText);
          } else if (type == 'METAR') {
            decodedWeather = decoderService.decodeMetar(rawText);
          }
        }
      } else {
        debugPrint('DEBUG: Weather.fromJson - no decoded weather in JSON, calling decoder for $icao ($type)');
        final decoderService = decoder.DecoderService();
        if (type == 'TAF') {
          decodedWeather = decoderService.decodeTaf(rawText);
        } else if (type == 'METAR') {
          decodedWeather = decoderService.decodeMetar(rawText);
        }
      }
    }
    
    // Coerce sources on load for robustness
    final incomingSource = json['source'] as String?;
    String resolvedSource;
    if (type == 'ATIS') {
      resolvedSource = 'naips';
    } else if (type == 'TAF' && (rawText.contains('\nTAF3') || rawText.trim().endsWith('TAF3'))) {
      // TAF3 marker only appears in NAIPS content
      resolvedSource = 'naips';
    } else {
      resolvedSource = incomingSource ?? 'aviationweather';
    }

    return Weather(
      icao: icao,
      timestamp: DateTime.parse(json['timestamp']),
      rawText: rawText,
      decodedText: decodedWeather != null ? _generateDecodedText(decodedWeather) : (json['decodedText'] ?? ''),
      windDirection: json['windDirection'] ?? 0,
      windSpeed: json['windSpeed'] ?? 0,
      visibility: json['visibility'] ?? 0,
      cloudCover: json['cloudCover'] ?? '',
      temperature: json['temperature'] ?? 0.0,
      dewPoint: json['dewPoint'] ?? 0.0,
      qnh: json['qnh'] ?? 0,
      conditions: json['conditions'] ?? '',
      type: type,
      decodedWeather: decodedWeather,
      source: resolvedSource,
    );
  }

  factory Weather.fromMetar(Map<String, dynamic> json) {
    final icao = json['icaoId'] ?? '';
    final rawText = json['rawOb'] ?? '';
    final metarType = json['metarType'] ?? 'METAR';
    
    // Add SPECI prefix if it's a SPECI report
    String processedRawText = rawText;
    if (metarType == 'SPECI' && !rawText.startsWith('SPECI')) {
      processedRawText = 'SPECI $rawText';
    }
    
    // The decoder service is the source of truth for parsed data
    final decoderService = decoder.DecoderService();
    final decodedWeather = decoderService.decodeMetar(processedRawText);
    
    return Weather(
      icao: icao,
      timestamp: decodedWeather.timestamp,
      rawText: processedRawText,
      decodedText: _generateDecodedText(decodedWeather),
      windDirection: decodedWeather.windDirection ?? 0,
      windSpeed: decodedWeather.windSpeed ?? 0,
      visibility: decodedWeather.visibility ?? 9999,
      cloudCover: decodedWeather.cloudCover ?? '',
      temperature: decodedWeather.temperature ?? 0.0,
      dewPoint: decodedWeather.dewPoint ?? 0.0,
      qnh: decodedWeather.qnh ?? 0,
      conditions: decodedWeather.conditions ?? '',
      type: 'METAR',
      decodedWeather: decodedWeather,
      source: 'aviationweather',
    );
  }

  factory Weather.fromTaf(Map<String, dynamic> json) {
    // Parse TAF data from AviationWeather.gov API
    final icao = json['icaoId'] ?? '';
    final rawText = json['rawTAF'] ?? ''; // TAF uses 'rawTAF', not 'rawOb'
    
    // Debug logging for EGLL
    if (icao.contains('EGLL')) {
      debugPrint('DEBUG: 🎯 Weather.fromTaf called for EGLL');
      debugPrint('DEBUG: 🎯 EGLL rawTAF: "$rawText"');
    }
    
    // Debug logging for KJFK
    if (icao.contains('KJFK')) {
      debugPrint('DEBUG: 🎯 Weather.fromTaf called for KJFK');
      debugPrint('DEBUG: 🎯 KJFK rawTAF: "$rawText"');
      debugPrint('DEBUG: 🎯 KJFK rawTAF length: ${rawText.length}');
    }
    
    // TAFs don't have current wind/visibility like METARs, so use defaults
    const windDirection = 0;
    const windSpeed = 0;
    const visibility = 9999;
    
    // Parse temperature and dew point (if available in TAF)
    final temp = _parseDouble(json['temp']) ?? 0.0;
    final dewPoint = _parseDouble(json['dewp']) ?? 0.0;
    
    // Parse pressure (QNH)
    final pressure = _parseInt(json['altim']) ?? 0;
    
    // Parse cloud cover from TAF - check if there are forecasts
    final forecasts = json['fcsts'] as List<dynamic>? ?? [];
    String cloudCover = '';
    if (forecasts.isNotEmpty) {
      final firstForecast = forecasts.first;
      final clouds = firstForecast['clouds'] as List<dynamic>? ?? [];
      if (clouds.isNotEmpty) {
        cloudCover = clouds.map((cloud) {
          final type = cloud['type'] ?? '';
          final height = _parseInt(cloud['height']) ?? 0;
          return '$type${height.toString().padLeft(3, '0')}';
        }).join(' ');
      }
    }
    
    // Parse weather conditions
    final conditions = json['wxString'] ?? '';
    
    // Parse timestamp
    final issueTime = json['issueTime'];
    DateTime timestamp;
    if (issueTime is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(issueTime);
    } else if (issueTime is String) {
      timestamp = DateTime.parse(issueTime);
    } else {
      timestamp = DateTime.now();
    }
    
    // Create decoded weather object
    if (icao.contains('EGLL')) {
      debugPrint('DEBUG: 🎯 About to call decodeTaf for EGLL');
    }
    
    if (icao.contains('KJFK')) {
      debugPrint('DEBUG: 🎯 About to call decodeTaf for KJFK');
    }
    
    final decoderService = decoder.DecoderService();
    final decodedWeather = decoderService.decodeTaf(rawText);
    
    if (icao.contains('EGLL')) {
      debugPrint('DEBUG: 🎯 decodeTaf completed for EGLL');
    }
    
    if (icao.contains('KJFK')) {
      debugPrint('DEBUG: 🎯 decodeTaf completed for KJFK');
    }
    
    return Weather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      decodedText: _generateDecodedText(decodedWeather),
      windDirection: windDirection,
      windSpeed: windSpeed,
      visibility: visibility,
      cloudCover: cloudCover,
      temperature: temp,
      dewPoint: dewPoint,
      qnh: pressure,
      conditions: conditions,
      type: 'TAF',
      decodedWeather: decodedWeather,
      source: 'aviationweather',
    );
  }

  static String _generateDecodedText(DecodedWeather decoded) {
    final parts = [
      decoded.windDescription,
      decoded.visibilityDescription,
      decoded.cloudDescription,
      decoded.temperatureDescription,
      decoded.pressureDescription,
      if (decoded.conditionsDescription != 'No significant weather') 
        decoded.conditionsDescription,
    ];
    
    return parts.where((part) => part.isNotEmpty).join('. ');
  }

  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'timestamp': timestamp.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'visibility': visibility,
      'cloudCover': cloudCover,
      'temperature': temperature,
      'dewPoint': dewPoint,
      'qnh': qnh,
      'conditions': conditions,
      'type': type,
      'decodedWeather': decodedWeather?.toJson(),
      'source': source,
    };
  }

  Map<String, dynamic> toDbJson(String flightId) {
    return {
      'icao': icao,
      'flightId': flightId,
      'timestamp': timestamp.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'visibility': visibility,
      'cloudCover': cloudCover,
      'temperature': temperature,
      'dewPoint': dewPoint,
      'qnh': qnh,
      'conditions': conditions,
      'type': type,
      'decodedWeather': decodedWeather?.toJson(),
      'source': source,
      'atisCode': atisCode,
      'atisType': atisType,
    };
  }

  factory Weather.fromDbJson(Map<String, dynamic> json) {
    debugPrint('DEBUG: 🔧 fromDbJson called with type: ${json['type'] ?? 'unknown'}');
    final icao = json['icao'] ?? '';
    final rawText = json['rawText'] ?? '';
    final type = json['type'] ?? 'METAR';
    
    // For TAF data, try to load decoded weather from JSON first, then re-decode if needed
    DecodedWeather? decodedWeather;
    if (type == 'TAF' && rawText.isNotEmpty) {
      if (json['decodedWeather'] != null) {
        debugPrint('DEBUG: 🔧 fromDbJson - loading decoded weather from JSON');
        try {
          decodedWeather = DecodedWeather.fromJson(json['decodedWeather']);
        } catch (e) {
          debugPrint('DEBUG: 🔧 fromDbJson - failed to load from JSON, re-decoding: $e');
          final decoderService = decoder.DecoderService();
          decodedWeather = decoderService.decodeTaf(rawText);
        }
      } else {
        debugPrint('DEBUG: 🔧 fromDbJson - no decoded weather in JSON, calling decodeTaf');
        final decoderService = decoder.DecoderService();
        decodedWeather = decoderService.decodeTaf(rawText);
      }
    } else {
      debugPrint('DEBUG: 🔧 fromDbJson - not calling decodeTaf (type: $type, rawText empty: ${rawText.isEmpty})');
    }
    
    // Coerce sources on load for robustness (DB path)
    final incomingSource = json['source'] as String?;
    String resolvedSource;
    if (type == 'ATIS') {
      resolvedSource = 'naips';
    } else if (type == 'TAF' && (rawText.contains('\nTAF3') || rawText.trim().endsWith('TAF3'))) {
      resolvedSource = 'naips';
    } else {
      resolvedSource = incomingSource ?? 'aviationweather';
    }

    return Weather(
      icao: icao,
      timestamp: DateTime.parse(json['timestamp']),
      rawText: rawText,
      decodedText: decodedWeather != null ? _generateDecodedText(decodedWeather) : (json['decodedText'] ?? ''),
      windDirection: json['windDirection'] ?? 0,
      windSpeed: json['windSpeed'] ?? 0,
      visibility: json['visibility'] ?? 0,
      cloudCover: json['cloudCover'] ?? '',
      temperature: json['temperature'] ?? 0.0,
      dewPoint: json['dewPoint'] ?? 0.0,
      qnh: json['qnh'] ?? 0,
      conditions: json['conditions'] ?? '',
      type: type,
      decodedWeather: decodedWeather,
      source: resolvedSource,
    );
  }

  factory Weather.fromAtis(Map<String, dynamic> json) {
    final icao = json['icao'] ?? '';
    final rawText = json['rawText'] ?? '';
    final atisCode = json['atisCode'] ?? '?';
    final atisType = json['atisType'] ?? 'ATIS';
    
    // Parse timestamp
    final timestamp = DateTime.parse(json['timestamp']);
    
    return Weather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      decodedText: rawText, // ATIS uses raw text as decoded text initially
      windDirection: 0, // ATIS doesn't have current wind
      windSpeed: 0,
      visibility: 9999,
      cloudCover: '',
      temperature: 0.0,
      dewPoint: 0.0,
      qnh: 0,
      conditions: '',
      type: 'ATIS',
      decodedWeather: null, // No decoded weather for ATIS initially
      source: json['source'] ?? 'naips',
      atisCode: atisCode,
      atisType: atisType,
    );
  }

  // Helper methods for safe parsing
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class TimePeriod {
  final DateTime startTime;
  final DateTime endTime;
  final DecodedForecastPeriod baselinePeriod;
  final List<DecodedForecastPeriod> concurrentPeriods;
  final bool isTransition;
  final DecodedForecastPeriod? transitionPeriod;
  final String rawTafSection;
  
  TimePeriod({
    required this.startTime,
    required this.endTime,
    required this.baselinePeriod,
    required this.concurrentPeriods,
    this.isTransition = false,
    this.transitionPeriod,
    required this.rawTafSection,
  });
  
  @override
  String toString() {
    return 'TimePeriod(${startTime.day}/${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.day}/${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}, baseline: ${baselinePeriod.type}, concurrent: ${concurrentPeriods.length})';
  }
} 