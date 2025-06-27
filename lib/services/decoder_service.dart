import 'dart:convert';
import '../models/weather.dart';

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

class DecoderService {
  // METAR Patterns
  static final _icaoPattern = RegExp(r'^([A-Z]{4})');
  static final _timestampPattern = RegExp(r'(\d{6})Z');
  static final _windPattern = RegExp(r'(\d{3}|VRB)(\d{2,3})G?(\d{2,3})?KT');
  static final _visibilityPattern = RegExp(r'(\d{4})|CAVOK');
  static final _visibilitySMPattern = RegExp(r'(\d{1,2})SM');
  static final _rvrPattern = RegExp(r'R(\d{2})/([PM]?\d{4})FT'); // RVR pattern
  static final _cloudPattern = RegExp(r'(FEW|SCT|BKN|OVC)(\d{3})');
  static final _cloudLayerPattern = RegExp(r'(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?');
  static final _cavokPattern = RegExp(r'\bCAVOK\b');
  static final _tempDewPattern = RegExp(r'(M?\d{2})/(M?\d{2})');
  static final _pressurePattern = RegExp(r'Q(\d{4})');
  static final _pressureInHgPattern = RegExp(r'A(\d{4})');
  
  // Weather codes for TAF/METAR parsing
  static const List<String> _weatherCodes = [
    'DZ', 'RA', 'SN', 'SG', 'IC', 'PL', 'GR', 'GS', 'UP', 'BR', 'FG', 'FU', 
    'VA', 'DU', 'SA', 'HZ', 'PY', 'PO', 'SQ', 'FC', 'SS', 'DS', 'TS', 'FZ', 
    'MI', 'BC', 'DR', 'BL', 'SH', 'VCSH', 'SHRA', 'VC', 'NSW'
  ];

  // Simple weather pattern that works
  static final _weatherPattern = RegExp(r'(?<!\w)(-|\+)?(DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS|TS|FZ|MI|BC|DR|BL|SH|VCSH|SHRA|TSRA|VCTS|VC|NSW)\b(?!\d{3})');
  
  static final _remarksPattern = RegExp(r'RMK(.+)');
  static final _peakWindPattern = RegExp(r'PK WND (\d{3})(\d{2})/(\d{2})'); // Peak wind pattern
  static final _windShiftPattern = RegExp(r'WSHFT (\d{4})'); // Wind shift pattern
  
  // Additional remarks patterns
  static final _variableVisibilityPattern = RegExp(r'VIS (\d+)/(\d+)V(\d+)'); // Variable visibility
  static final _rainBeginPattern = RegExp(r'RA(\d{2})'); // Rain began at XX past hour
  static final _ceilingVariablePattern = RegExp(r'CIG (\d{3})V(\d{3})'); // Ceiling variable
  static final _pressureTrendPattern = RegExp(r'(PRESFR|PRESRR|PRESFA|PRESRA)'); // Pressure trends
  static final _seaLevelPressurePattern = RegExp(r'SLP(\d{3})'); // Sea-level pressure
  static final _precipitationAmountPattern = RegExp(r'P(\d{4})'); // Precipitation amount
  static final _sixHourPrecipPattern = RegExp(r'6(\d{4})'); // 6-hour precipitation total
  static final _temperatureDewpointPattern = RegExp(r'T(\d{4})(\d{4})'); // Temp/dewpoint extremes
  static final _sixHourMaxTempPattern = RegExp(r'1(\d{3})'); // 6-hour max temp
  static final _sixHourMinTempPattern = RegExp(r'2(\d{3})'); // 6-hour min temp
  static final _automatedStationPattern = RegExp(r'(AO1|AO2)'); // Automated station type
  static final _cloudCoveragePattern = RegExp(r'([A-Z]{2})(\d)([A-Z]{2})(\d)'); // Cloud coverage like CU1SC5
  static final _densityAltitudePattern = RegExp(r'DENSITY ALT (\d+)FT'); // Density altitude

  // TAF Patterns
  static final _tafHeaderPattern = RegExp(r'TAF\s+(?:AMD\s+)?([A-Z]{4})\s+(\d{6})Z\s+(\d{4})/(\d{4})');
  static final _tafForecastPattern = RegExp(r'(FM\d{6}|BECMG|PROB30\s+TEMPO|PROB30\s+INTER|PROB40\s+TEMPO|PROB40\s+INTER|PROB30|PROB40|INTER|TEMPO)');
  static final _tafVisibilityPattern = RegExp(r'\b(P?\d{4})\b(?![/]\d{2})|CAVOK'); // Exclude time ranges like 2500/2503
  static final _tafVisibilitySMPattern = RegExp(r'\b(P?\d{1,2})SM\b');

  DecodedWeather decodeMetar(String rawText) {
    final icao = _icaoPattern.firstMatch(rawText)?.group(1) ?? '';
    final timestamp = _parseTimestamp(rawText);
    
    // Parse wind
    final windMatch = _windPattern.firstMatch(rawText);
    String? windDirectionStr;
    int? windSpeed;
    int? windGust;
    if (windMatch != null) {
      windDirectionStr = windMatch.group(1);
      windSpeed = int.tryParse(windMatch.group(2) ?? '');
      windGust = windMatch.group(3) != null ? int.tryParse(windMatch.group(3)!) : null;
    }

    // The rest of the string after the wind group, or the whole string if no wind
    final textAfterWind = windMatch != null ? rawText.substring(windMatch.end) : rawText;
    
    // Parse visibility from the remaining string to avoid capturing time elements
    final visibilityMatch = _visibilityPattern.firstMatch(textAfterWind);
    final visibilitySM_match = _visibilitySMPattern.firstMatch(textAfterWind);

    int? visibility;
    String visibilityUnit = 'm';

    if (visibilitySM_match != null) {
      visibility = int.parse(visibilitySM_match.group(1)!);
      visibilityUnit = 'SM';
    } else if (visibilityMatch != null) {
      visibility = visibilityMatch.group(1) != null ? int.tryParse(visibilityMatch.group(1)!) : null;
    }
    
    // Parse RVR (Runway Visual Range)
    final rvrMatches = _rvrPattern.allMatches(rawText);
    String? rvr;
    if (rvrMatches.isNotEmpty) {
      rvr = rvrMatches.map((m) {
        final runway = m.group(1)!;
        final value = m.group(2)!;
        String prefix = '';
        if (value.startsWith('P')) {
          prefix = '> ';
        } else if (value.startsWith('M')) {
          prefix = '< ';
        }
        final distance = value.replaceAll(RegExp(r'^[PM]'), '');
        return 'R${runway}: ${prefix}${distance}ft';
      }).join(', ');
    }
    
    final isCavok = rawText.contains('CAVOK');
    final isNcd = rawText.contains('NCD');
    
    // Parse clouds
    final cloudMatches = _cloudPattern.allMatches(rawText);
    final cloudCover = cloudMatches.isNotEmpty ? cloudMatches.map((m) => '${m.group(1)}${m.group(2)}').join(' ') : null;
    
    // Parse temperature/dew point
    final tempMatch = _tempDewPattern.firstMatch(rawText);
    final temperature = tempMatch != null ? _parseTemp(tempMatch.group(1)!) : null;
    final dewPoint = tempMatch != null ? _parseTemp(tempMatch.group(2)!) : null;
    
    // Parse pressure
    final pressureMatch = _pressurePattern.firstMatch(rawText);
    final pressureInHgMatch = _pressureInHgPattern.firstMatch(rawText);
    int? qnh;
    String qnhUnit = 'hPa';

    if (pressureInHgMatch != null) {
      qnh = int.parse(pressureInHgMatch.group(1)!);
      qnhUnit = 'inHg';
    } else if (pressureMatch != null) {
      qnh = int.parse(pressureMatch.group(1)!);
    }
    
    // Parse weather conditions only if not CAVOK
    String? conditions;
    String? conditionsDescription;

    if (!isCavok) {
    final weatherMatches = _weatherPattern.allMatches(rawText);
      if (weatherMatches.isNotEmpty) {
        final rawCodes = weatherMatches.map((m) => m.group(0)!).toList();
        conditions = rawCodes.join(' ');
        conditionsDescription = rawCodes.map((code) => _describeConditions(code)).join(', ');
      }
    }
    
    // Parse remarks
    final remarksMatch = _remarksPattern.firstMatch(rawText);
    var remarks = remarksMatch?.group(1)?.trim();

    // Parse comprehensive remarks
    final parsedRemarks = <String>[];
    
    if (remarks != null) {
      // Peak winds
      final peakWindMatch = _peakWindPattern.firstMatch(remarks);
      if (peakWindMatch != null) {
        final direction = peakWindMatch.group(1)!;
        final speed = peakWindMatch.group(2)!;
        final time = peakWindMatch.group(3)!;
        parsedRemarks.add('Peak wind ${direction}° at ${speed}kt at ${time} past hour');
      }
      
      // Wind shifts
      final windShiftMatch = _windShiftPattern.firstMatch(remarks);
      if (windShiftMatch != null) {
        final time = windShiftMatch.group(1)!;
        parsedRemarks.add('Wind shift at ${time.substring(0, 2)}:${time.substring(2)}Z');
      }
      
      // Variable visibility
      final varVisMatch = _variableVisibilityPattern.firstMatch(remarks);
      if (varVisMatch != null) {
        final from = varVisMatch.group(1)!;
        final to = varVisMatch.group(2)!;
        final unit = varVisMatch.group(3)!;
        parsedRemarks.add('Variable visibility from $from to $to $unit');
      }
      
      // Rain begin
      final rainBeginMatch = _rainBeginPattern.firstMatch(remarks);
      if (rainBeginMatch != null) {
        final time = rainBeginMatch.group(1)!;
        parsedRemarks.add('Rain began at $time past hour');
      }
      
      // Ceiling variable
      final ceilingVarMatch = _ceilingVariablePattern.firstMatch(remarks);
      if (ceilingVarMatch != null) {
        final from = int.parse(ceilingVarMatch.group(1)!) * 100;
        final to = int.parse(ceilingVarMatch.group(2)!) * 100;
        parsedRemarks.add('Ceiling variable between ${from}ft and ${to}ft');
      }
      
      // Pressure trends
      final pressureTrendMatch = _pressureTrendPattern.firstMatch(remarks);
      if (pressureTrendMatch != null) {
        final trend = pressureTrendMatch.group(1)!;
        final trendDesc = {
          'PRESFR': 'Pressure falling rapidly',
          'PRESRR': 'Pressure rising rapidly',
          'PRESFA': 'Pressure falling slowly',
          'PRESRA': 'Pressure rising slowly',
        }[trend] ?? trend;
        parsedRemarks.add(trendDesc);
      }
      
      // Sea-level pressure
      final slpMatch = _seaLevelPressurePattern.firstMatch(remarks);
      if (slpMatch != null) {
        final slp = slpMatch.group(1)!;
        final pressure = (1000 + int.parse(slp) / 10).toStringAsFixed(1);
        parsedRemarks.add('Sea-level pressure: ${pressure}hPa');
      }
      
      // Precipitation amounts
      final precipMatch = _precipitationAmountPattern.firstMatch(remarks);
      if (precipMatch != null) {
        final amount = int.parse(precipMatch.group(1)!) / 100;
        parsedRemarks.add('${amount.toStringAsFixed(2)} inches of rain since last METAR');
      }
      
      // 6-hour precipitation
      final sixHourPrecipMatch = _sixHourPrecipPattern.firstMatch(remarks);
      if (sixHourPrecipMatch != null) {
        final amount = int.parse(sixHourPrecipMatch.group(1)!) / 100;
        parsedRemarks.add('6-hour precipitation total: ${amount.toStringAsFixed(2)} inches');
      }
      
      // Temperature/dewpoint extremes
      final tempDewMatch = _temperatureDewpointPattern.firstMatch(remarks);
      if (tempDewMatch != null) {
        final temp = _parseTempExtreme(tempDewMatch.group(1)!);
        final dew = _parseTempExtreme(tempDewMatch.group(2)!);
        parsedRemarks.add('Temperature extremes: ${temp}°C / ${dew}°C');
      }
      
      // 6-hour max temp
      final maxTempMatch = _sixHourMaxTempPattern.firstMatch(remarks);
      if (maxTempMatch != null) {
        final temp = _parseTempExtreme(maxTempMatch.group(1)!);
        parsedRemarks.add('6-hour maximum temperature: ${temp}°C');
      }
      
      // 6-hour min temp
      final minTempMatch = _sixHourMinTempPattern.firstMatch(remarks);
      if (minTempMatch != null) {
        final temp = _parseTempExtreme(minTempMatch.group(1)!);
        parsedRemarks.add('6-hour minimum temperature: ${temp}°C');
      }
      
      // Automated station type
      final autoStationMatch = _automatedStationPattern.firstMatch(remarks);
      if (autoStationMatch != null) {
        final type = autoStationMatch.group(1)!;
        final desc = type == 'AO1' ? 'Automated station without precipitation discriminator' : 'Automated station with precipitation discriminator';
        parsedRemarks.add(desc);
      }
      
      // Cloud coverage (e.g., CU1SC5)
      final cloudCoverageMatch = _cloudCoveragePattern.firstMatch(remarks);
      if (cloudCoverageMatch != null) {
        final cloud1 = cloudCoverageMatch.group(1)!;
        final oktas1 = cloudCoverageMatch.group(2)!;
        final cloud2 = cloudCoverageMatch.group(3)!;
        final oktas2 = cloudCoverageMatch.group(4)!;
        
        final cloud1Desc = _describeCloudType(cloud1);
        final cloud2Desc = _describeCloudType(cloud2);
        
        parsedRemarks.add('Cloud coverage: $oktas1 okta of $cloud1Desc, $oktas2 oktas of $cloud2Desc');
      }
      
      // Density altitude
      final densityAltMatch = _densityAltitudePattern.firstMatch(remarks);
      if (densityAltMatch != null) {
        final altitude = densityAltMatch.group(1)!;
        parsedRemarks.add('Density altitude: ${altitude}ft');
      }
    }

    if (rawText.contains('NOSIG')) {
      parsedRemarks.add('No significant change expected in the next 2 hours');
    }
    
    final finalRemarks = parsedRemarks.isNotEmpty ? parsedRemarks.join('\n') : null;
    
    return DecodedWeather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      type: 'METAR',
      windDirection: windDirectionStr != null && windDirectionStr != 'VRB' ? int.tryParse(windDirectionStr) : null,
      windSpeed: windSpeed,
      visibility: visibility,
      cloudCover: cloudCover,
      temperature: temperature,
      dewPoint: dewPoint,
      qnh: qnh,
      conditions: conditions,
      remarks: finalRemarks,
      rvr: rvr,
      windDescription: _describeWind(windDirectionStr, windSpeed, windGust),
      visibilityDescription: _describeVisibility(visibility, isCavok, visibilityUnit),
      cloudDescription: _describeClouds(cloudCover, isCavok, isNcd),
      temperatureDescription: _describeTemperature(temperature, dewPoint),
      pressureDescription: _describePressure(qnh, qnhUnit),
      conditionsDescription: conditionsDescription ?? 'No significant weather',
      rvrDescription: _describeRvr(rvr),
      timeline: [],
    );
  }

  DecodedWeather decodeTaf(String rawText) {
    print('DEBUG: 🚀 decodeTaf called with rawText: \"$rawText\"');
    
    // Check if this is EGLL TAF
    if (rawText.contains('EGLL')) {
      print('DEBUG: 🎯 EGLL TAF detected!');
      print('DEBUG: EGLL raw text: \"$rawText\"');
    }
    
    final decoder = DecoderService();
    
    // Parse TAF header
    final headerMatch = _tafHeaderPattern.firstMatch(rawText);
    if (headerMatch == null) {
      print('DEBUG: No TAF header found in: \"$rawText\"');
      return _createEmptyDecodedWeather('', DateTime.now(), rawText, 'TAF');
    }
    
    final icao = headerMatch.group(1) ?? '';
    final timestamp = _parseTafTimestamp(rawText);
    
    if (rawText.contains('EGLL')) {
      print('DEBUG: EGLL TAF header parsed - ICAO: $icao, timestamp: $timestamp');
    }
    
    // Parse forecast periods
    final periods = _parseTafPeriods(rawText);
    
    if (rawText.contains('EGLL')) {
      print('DEBUG: EGLL TAF periods parsed: ${periods.length} periods');
      for (int i = 0; i < periods.length; i++) {
        final period = periods[i];
        print('DEBUG: EGLL period $i: ${period.type} - ${period.time} - weather: ${period.weather}');
      }
    }
    
    // Debug each period
    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      print('DEBUG: Period $i: ${period.type} - ${period.time} - isConcurrent: ${period.isConcurrent} - startTime: ${period.startTime} - endTime: ${period.endTime}');
    }
    
    // Create timeline from TAF validity period
    final timeline = createTimelineFromTaf(rawText);
    
    // Create decoded weather with timeline
    return DecodedWeather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      type: 'TAF',
      windDescription: 'TAF forecast periods available',
      visibilityDescription: 'See forecast periods below',
      cloudDescription: 'See forecast periods below',
      temperatureDescription: 'See forecast periods below',
      pressureDescription: 'See forecast periods below',
      conditionsDescription: 'See forecast periods below',
      rvrDescription: 'See forecast periods below',
      forecastPeriods: periods,
      timeline: timeline,
    );
  }

  DecodedWeather _createEmptyDecodedWeather(String icao, DateTime timestamp, String rawText, String type) {
    return DecodedWeather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      type: type,
      windDescription: 'No wind data available',
      visibilityDescription: 'No visibility data available',
      cloudDescription: 'No cloud data available',
      temperatureDescription: 'No temperature data available',
      pressureDescription: 'No pressure data available',
      conditionsDescription: 'No weather conditions available',
      rvrDescription: 'No RVR data available',
      forecastPeriods: [],
      timeline: [],
    );
  }

  List<DecodedForecastPeriod> _parseTafPeriods(String rawText) {
    print('DEBUG: 🔍 _parseTafPeriods called with rawText: "$rawText"');
    final sections = <Map<String, dynamic>>[];
    
    // Find all period start positions - ORDER MATTERS: longer patterns first
    final periodMatches = RegExp(r'\b(FM\d{6}|BECMG|PROB30\s+TEMPO|PROB30\s+INTER|PROB40\s+TEMPO|PROB40\s+INTER|PROB30|PROB40|INTER|TEMPO)\b').allMatches(rawText);
    
    print('DEBUG: 🔍 Found ${periodMatches.length} period matches:');
    for (final match in periodMatches) {
      print('DEBUG:   - "${match.group(0)}" at position ${match.start}');
    }
    
    if (periodMatches.isEmpty) {
      // No periods found, entire text is initial section
      sections.add({
        'start': 0,
        'end': rawText.length,
        'text': rawText,
        'type': 'baseline',
        'periodType': 'INITIAL',
      });
    } else {
      // Create initial section (from start to first period)
      final firstPeriod = periodMatches.first;
      if (firstPeriod.start > 0) {
        final initialText = rawText.substring(0, firstPeriod.start).trim();
        if (initialText.isNotEmpty) {
          sections.add({
            'start': 0,
            'end': firstPeriod.start,
            'text': initialText,
            'type': 'baseline',
            'periodType': 'INITIAL',
          });
        }
      }
      
      // Create sections for each period
      for (int i = 0; i < periodMatches.length; i++) {
        final currentMatch = periodMatches.elementAt(i);
        final nextMatch = i + 1 < periodMatches.length ? periodMatches.elementAt(i + 1) : null;
        
        final start = currentMatch.start;
        final end = nextMatch?.start ?? rawText.length;
        final periodText = rawText.substring(start, end).trim();
        
        // Determine period type
        String periodType = 'UNKNOWN';
        final matchedText = currentMatch.group(0)!;
        
        if (matchedText.startsWith('FM')) {
          periodType = 'FM';
        } else if (matchedText.startsWith('BECMG')) {
          periodType = 'BECMG';
        } else if (matchedText.startsWith('PROB30 TEMPO')) {
          periodType = 'PROB30 TEMPO';
        } else if (matchedText.startsWith('PROB30 INTER')) {
          periodType = 'PROB30 INTER';
        } else if (matchedText.startsWith('PROB40 TEMPO')) {
          periodType = 'PROB40 TEMPO';
        } else if (matchedText.startsWith('PROB40 INTER')) {
          periodType = 'PROB40 INTER';
        } else if (matchedText.startsWith('PROB30')) {
          periodType = 'PROB30';
        } else if (matchedText.startsWith('PROB40')) {
          periodType = 'PROB40';
        } else if (matchedText.startsWith('TEMPO')) {
          periodType = 'TEMPO';
        } else if (matchedText.startsWith('INTER')) {
          periodType = 'INTER';
        }
        
        print('DEBUG: 🔍 Creating section for period: $periodType');
        print('DEBUG:   - Matched text: "$matchedText"');
        print('DEBUG:   - Period text: "${periodText.substring(0, periodText.length > 100 ? 100 : periodText.length)}..."');
        
        // Determine if it's baseline or concurrent
        final isBaseline = periodType == 'FM' || periodType == 'BECMG' || periodType == 'INITIAL';
        
        sections.add({
          'start': start,
          'end': end,
          'text': periodText,
          'type': isBaseline ? 'baseline' : 'concurrent',
          'periodType': periodType,
        });
      }
    }
    
    print('DEBUG: 🔍 Final sections created: ${sections.map((s) => s['periodType']).toList()}');
    
    // Convert sections to DecodedForecastPeriod objects
    final periods = <DecodedForecastPeriod>[];
    final tafStartTime = _parseTafCommencementTime(rawText);
    final tafEndTime = _parseTafEndTime(rawText);
    
    for (final section in sections) {
      final periodType = section['periodType'] as String;
      final sectionText = section['text'] as String;
      final isBaseline = section['type'] == 'baseline';
      
      // Parse time information from the section
      DateTime? startTime;
      DateTime? endTime;
      String timeString = '';
      
      if (periodType == 'INITIAL') {
        // Initial period uses TAF validity period
        startTime = tafStartTime;
        endTime = _findNextBaselinePeriodStartFromText(
          sections.map((s) => s['text'] as String).toList(),
          sections.indexOf(section),
          tafStartTime,
          tafEndTime
        );
        timeString = 'INITIAL';
      } else if (periodType.startsWith('FM')) {
        // FM periods have time in format FMddhhmm
        final timeMatch = RegExp(r'FM(\d{2})(\d{2})(\d{2})').firstMatch(sectionText);
        if (timeMatch != null) {
          final day = int.parse(timeMatch.group(1)!);
          final hour = int.parse(timeMatch.group(2)!);
          final minute = int.parse(timeMatch.group(3)!);
          startTime = DateTime(DateTime.now().year, DateTime.now().month, day, hour, minute);
          endTime = _findNextBaselinePeriodStartFromText(
            sections.map((s) => s['text'] as String).toList(),
            sections.indexOf(section),
            startTime,
            tafEndTime
          );
          timeString = 'FM${day.toString().padLeft(2, '0')}${hour.toString().padLeft(2, '0')}';
        }
      } else if (periodType == 'BECMG') {
        // BECMG periods have transition time
        final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(sectionText);
        if (timeMatch != null) {
          final fromDay = int.parse(timeMatch.group(1)!);
          final fromHour = int.parse(timeMatch.group(2)!);
          final toDay = int.parse(timeMatch.group(3)!);
          final toHour = int.parse(timeMatch.group(4)!);
          startTime = DateTime(DateTime.now().year, DateTime.now().month, fromDay, fromHour, 0);
          // BECMG periods persist until the next baseline period starts
          endTime = _findNextBaselinePeriodStartFromText(
            sections.map((s) => s['text'] as String).toList(),
            sections.indexOf(section),
            startTime,
            tafEndTime
          );
          timeString = 'BECMG ${fromDay.toString().padLeft(2, '0')}${fromHour.toString().padLeft(2, '0')}/${toDay.toString().padLeft(2, '0')}${toHour.toString().padLeft(2, '0')}';
        }
      } else if (periodType.contains('PROB30') || periodType.contains('PROB40')) {
        // PROB30/40 periods have time range
        final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(sectionText);
        if (timeMatch != null) {
          final fromDay = int.parse(timeMatch.group(1)!);
          final fromHour = int.parse(timeMatch.group(2)!);
          final toDay = int.parse(timeMatch.group(3)!);
          final toHour = int.parse(timeMatch.group(4)!);
          startTime = DateTime(DateTime.now().year, DateTime.now().month, fromDay, fromHour, 0);
          endTime = DateTime(DateTime.now().year, DateTime.now().month, toDay, toHour, 0);
          timeString = '${fromDay.toString().padLeft(2, '0')}${fromHour.toString().padLeft(2, '0')}/${toDay.toString().padLeft(2, '0')}${toHour.toString().padLeft(2, '0')}';
        }
      } else if (periodType == 'TEMPO' || periodType == 'INTER') {
        // TEMPO/INTER periods have time range
        final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(sectionText);
        if (timeMatch != null) {
          final fromDay = int.parse(timeMatch.group(1)!);
          final fromHour = int.parse(timeMatch.group(2)!);
          final toDay = int.parse(timeMatch.group(3)!);
          final toHour = int.parse(timeMatch.group(4)!);
          startTime = DateTime(DateTime.now().year, DateTime.now().month, fromDay, fromHour, 0);
          endTime = DateTime(DateTime.now().year, DateTime.now().month, toDay, toHour, 0);
          timeString = '${fromDay.toString().padLeft(2, '0')}${fromHour.toString().padLeft(2, '0')}/${toDay.toString().padLeft(2, '0')}${toHour.toString().padLeft(2, '0')}';
        }
      }
      
      // Parse weather from the section
      final weather = _parseWeatherFromTafSegment(sectionText);
      
      print('DEBUG: 🔍 Parsed weather for ${periodType}: $weather');
      
      // Calculate changed elements for concurrent periods
      Set<String> changedElements = {};
      if (!isBaseline && periods.isNotEmpty) {
        // Find the most recent baseline period to compare against
        final baselinePeriod = periods.lastWhere((p) => !p.isConcurrent, orElse: () => periods.first);
        final baselineWeather = baselinePeriod.weather;
        
        print('DEBUG: 🔍 Comparing with baseline period: ${baselinePeriod.type}');
        print('DEBUG: 🔍 Baseline weather: $baselineWeather');
        print('DEBUG: 🔍 Concurrent weather: $weather');
        
        // Compare each weather element
        for (final entry in weather.entries) {
          final key = entry.key;
          final value = entry.value;
          final baselineValue = baselineWeather[key];
          
          // Consider it changed if the value is present and not empty/null
          if (value != null && value.isNotEmpty && value != '-') {
            // For concurrent periods, include ALL weather elements that are present
            // (not just those that are different from baseline)
            changedElements.add(key);
            print('DEBUG: 🔍 Added $key to changedElements: "$value" (baseline: "$baselineValue")');
          }
        }
        
        print('DEBUG: 🔍 Final changed elements: $changedElements');
      }
      
      final period = DecodedForecastPeriod(
        type: periodType,
        time: timeString,
        description: _generatePeriodDescription(periodType, timeString, startTime, endTime),
        weather: weather,
        changedElements: changedElements,
        startTime: startTime,
        endTime: endTime,
        isConcurrent: !isBaseline,
        rawSection: sectionText,
      );
      
      print('DEBUG: 🔍 Created period: ${period.type} (${period.time}) - concurrent: ${period.isConcurrent}');
      periods.add(period);
    }
    
    print('DEBUG: 🔍 Final periods created: ${periods.map((p) => '${p.type} (${p.time})').toList()}');
    return periods;
  }

  DateTime? _findNextBaselinePeriodStartFromText(List<String> periodStrings, int currentIndex, DateTime currentStartTime, [DateTime? tafEndTime]) {
    // Find the next FM or BECMG period in the text
    for (int i = currentIndex + 1; i < periodStrings.length; i++) {
      final periodStr = periodStrings[i].trim();
      final typeMatch = RegExp(r'^(FM|BECMG)').firstMatch(periodStr);
      if (typeMatch != null) {
        final type = typeMatch.group(1)!;
        
        if (type == 'FM') {
          final timeMatch = RegExp(r'FM(\d{2})(\d{2})(\d{2})').firstMatch(periodStr);
          final day = timeMatch?.group(1);
          final hour = timeMatch?.group(2);
          final minute = timeMatch?.group(3);
          
          if (day != null && hour != null && minute != null) {
            return DateTime(DateTime.now().year, DateTime.now().month, int.parse(day), int.parse(hour), int.parse(minute));
          }
        } else if (type == 'BECMG') {
          final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(periodStr);
          final fromDay = timeMatch?.group(1);
          final fromHour = timeMatch?.group(2);
          
          if (fromDay != null && fromHour != null) {
            return DateTime(DateTime.now().year, DateTime.now().month, int.parse(fromDay), int.parse(fromHour), 0);
          }
        }
      }
    }
    
    // If no next baseline period, use the TAF validity period end time
    return tafEndTime ?? currentStartTime.add(Duration(hours: 24));
  }

  DateTime _parseTafCommencementTime(String rawText) {
    // Parse TAF validity period from header (e.g., "2512/2618")
    final validityMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(rawText);
    if (validityMatch != null) {
      final startDay = int.parse(validityMatch.group(1)!);
      final startHour = int.parse(validityMatch.group(2)!);
      
      // Use current year and month, but parse day and hour from TAF
      final now = DateTime.now();
      return DateTime(now.year, now.month, startDay, startHour, 0);
    }
    
    // Fallback to current time if parsing fails
    return DateTime.now();
  }

  DateTime? _parseTafEndTime(String rawText) {
    // Parse TAF validity period end time from header (e.g., "2512/2618")
    final validityMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(rawText);
    if (validityMatch != null) {
      final endDay = int.parse(validityMatch.group(3)!);
      final endHour = int.parse(validityMatch.group(4)!);
      
      // Use current year and month, but parse day and hour from TAF
      final now = DateTime.now();
      return DateTime(now.year, now.month, endDay, endHour, 0);
    }
    
    return null;
  }

  DateTime _parseTimestamp(String rawText) {
    final match = _timestampPattern.firstMatch(rawText);
    if (match != null) {
      final timeStr = match.group(1)!;
      final day = int.parse(timeStr.substring(0, 2));
      final hour = int.parse(timeStr.substring(2, 4));
      final minute = int.parse(timeStr.substring(4, 6));
      
      // Assume current month/year for now
      final now = DateTime.now();
      return DateTime(now.year, now.month, day, hour, minute);
    }
    return DateTime.now();
  }

  DateTime _parseTafTimestamp(String rawText) {
    final match = _tafHeaderPattern.firstMatch(rawText);
    if (match != null) {
      final timeStr = match.group(2)!;
      final day = int.parse(timeStr.substring(0, 2));
      final hour = int.parse(timeStr.substring(2, 4));
      final minute = int.parse(timeStr.substring(4, 6));
      
      final now = DateTime.now();
      return DateTime(now.year, now.month, day, hour, minute);
    }
    return DateTime.now();
  }

  String _describeWind(String? directionStr, int? speed, int? gustSpeed) {
    if (speed == null || directionStr == null) return 'Wind data unavailable';

    // Handle calm wind case
    final dirInt = int.tryParse(directionStr);
    if (dirInt == 0 && speed == 0 && gustSpeed == null) return 'Wind Calm';

    String directionDisplay;
    if (directionStr == 'VRB') {
        directionDisplay = 'Variable';
    } else {
        directionDisplay = '${directionStr.padLeft(3, '0')}°';
    }

    String baseWind = 'Wind $directionDisplay at ${speed}kt';
    if (gustSpeed != null) {
      baseWind += '\nMax gust ${gustSpeed}kt';
    }
    return baseWind;
  }

  String _describeVisibility(int? visibility, bool isCavok, String unit, {bool isGreaterThan = false}) {
    if (isCavok) return 'CAVOK - Ceiling and Visibility OK';
    if (visibility == null) return 'Visibility data unavailable';
    
    String prefix = isGreaterThan ? '>' : '';
    if (unit == 'SM') return 'Visibility ${prefix}${visibility}SM';
    if (visibility == 9999) return '>10km';
    return 'Visibility ${prefix}${visibility}m';
  }

  String _describeClouds(String? cloudCover, bool isCavok, bool isNcd) {
    if (isNcd) return 'No cloud detected';
    if (isCavok) return 'CAVOK';
    if (cloudCover == null || cloudCover.isEmpty) return '-';
    
    final clouds = cloudCover.split(' ').map((cloud) {
      final type = cloud.substring(0, 3);
      final height = int.parse(cloud.substring(3)) * 100;
      
      final typeNames = {
        'FEW': 'Few',
        'SCT': 'Scattered',
        'BKN': 'Broken',
        'OVC': 'Overcast'
      };
      
      return '${typeNames[type]} at ${height}ft';
    }).join('\n');
    
    return clouds;
  }

  String _describeTemperature(double? temp, double? dewPoint) {
    if (temp == null) return 'Temperature data unavailable';
    final tempDesc = 'Temperature ${temp.round()}°C';
    if (dewPoint != null) {
      return '$tempDesc, Dew point ${dewPoint.round()}°C';
    }
    return tempDesc;
  }

  String _describePressure(int? qnh, String unit) {
    if (qnh == null) return 'Pressure data unavailable';
    if (unit == 'inHg') return '${qnh!/100} inHg';
    return 'QNH ${qnh}hPa';
  }

  String _describeConditions(String? conditionCode) {
    print('DEBUG: 🎯 _describeConditions called with: "$conditionCode"');
    if (conditionCode == null || conditionCode.isEmpty) return 'No significant weather';

    String intensity = '';
    String code = conditionCode;

    if (code.startsWith('-')) {
        intensity = 'Light ';
        code = code.substring(1);
        print('DEBUG: Found "-" prefix, intensity: "$intensity", code: "$code"');
    } else if (code.startsWith('+')) {
        intensity = 'Heavy ';
        code = code.substring(1);
        print('DEBUG: Found "+" prefix, intensity: "$intensity", code: "$code"');
    } else {
        print('DEBUG: No intensity prefix, code: "$code"');
    }
    
    final weatherNames = {
      // Descriptors
      'MI': 'Shallow',
      'BC': 'Patches',
      'DR': 'Low Drifting',
      'BL': 'Blowing',
      'SH': 'Showers',
      'TS': 'Thunderstorm',
      'FZ': 'Freezing',
      'VC': 'In Vicinity',

      // Precipitation
      'DZ': 'Drizzle',
      'RA': 'Rain',
      'SN': 'Snow',
      'SG': 'Snow Grains',
      'IC': 'Ice Crystals',
      'PL': 'Ice Pellets',
      'GR': 'Hail',
      'GS': 'Small Hail',
      'UP': 'Unknown Precipitation',
      
      // Obscuration
      'BR': 'Mist',
      'FG': 'Fog',
      'FU': 'Smoke',
      'VA': 'Volcanic Ash',
      'DU': 'Widespread Dust',
      'SA': 'Sand',
      'HZ': 'Haze',
      'PY': 'Spray',

      // Other
      'PO': 'Dust/Sand Whirls',
      'SQ': 'Squalls',
      'FC': 'Funnel Cloud',
      'SS': 'Sandstorm',
      'DS': 'Duststorm',

      // Combined
      'SHRA': 'Showers of Rain',
      'VCSH': 'Showers in Vicinity',
      'VCTS': 'Vicinity Thunderstorms',
      'TSRA': 'Thunderstorms and Rain',
    };
    
    String description = weatherNames[code] ?? code;
    
    final result = intensity + description;
    print('DEBUG: Final weather description: "$result" (intensity: "$intensity", description: "$description")');
    return result;
  }

  double? _parseTemp(String tempStr) {
    if (tempStr.startsWith('M')) {
      return double.parse(tempStr.substring(1)) * -1;
    }
    return double.tryParse(tempStr);
  }

  String _describeRvr(String? rvr) {
    if (rvr == null || rvr.isEmpty) return '';
    return 'Runway Visual Range: $rvr';
  }

  String _parseTempExtreme(String tempStr) {
    // Temperature extremes in remarks are encoded as 4 digits
    // First digit: 0 = positive, 1 = negative
    // Last 3 digits: temperature in tenths of degrees
    final isNegative = tempStr.startsWith('1');
    final tempValue = int.parse(tempStr.substring(1));
    final temp = tempValue / 10.0;
    return isNegative ? '-${temp.toStringAsFixed(1)}' : temp.toStringAsFixed(1);
  }

  String _describeCloudType(String cloudType) {
    final typeNames = {
      'CU': 'Cumulus',
      'CB': 'Cumulonimbus',
      'CI': 'Cirrus',
      'CS': 'Cirrostratus',
      'AS': 'Altostratus',
      'SC': 'Stratocumulus',
      'ST': 'Stratus',
      'SN': 'Snow',
      'SS': 'Snow',
    };
    
    return typeNames[cloudType] ?? cloudType;
  }

  void _establishPeriodRelationships(List<DecodedForecastPeriod> baselinePeriods, List<DecodedForecastPeriod> concurrentPeriods) {
    // For each concurrent period, find which baseline periods it overlaps with
    for (final concurrentPeriod in concurrentPeriods) {
      if (concurrentPeriod.startTime == null || concurrentPeriod.endTime == null) continue;
      
      final concurrentStart = concurrentPeriod.startTime!;
      final concurrentEnd = concurrentPeriod.endTime!;
      
      for (final baselinePeriod in baselinePeriods) {
        // Check if concurrent period overlaps with baseline period
        bool overlaps = false;
        
        if (baselinePeriod.startTime != null && baselinePeriod.endTime != null) {
          // Baseline period has both start and end times (BECMG periods)
          overlaps = (concurrentStart.isBefore(baselinePeriod.endTime!) || concurrentStart.isAtSameMomentAs(baselinePeriod.endTime!)) &&
                     (concurrentEnd.isAfter(baselinePeriod.startTime!) || concurrentEnd.isAtSameMomentAs(baselinePeriod.startTime!));
        } else if (baselinePeriod.startTime != null) {
          // Baseline period only has start time (FM periods)
          // Find the next FM period to determine the end time of this FM period
          final nextFmPeriod = baselinePeriods.where((p) => 
            p.type == 'FM' && 
            p.startTime != null && 
            p.startTime!.isAfter(baselinePeriod.startTime!)
          ).firstOrNull;
          
          if (nextFmPeriod != null) {
            // This FM period ends when the next FM period starts
            final fmEndTime = nextFmPeriod.startTime!;
            overlaps = (concurrentStart.isAfter(baselinePeriod.startTime!) || concurrentStart.isAtSameMomentAs(baselinePeriod.startTime!)) &&
                       (concurrentEnd.isBefore(fmEndTime) || concurrentEnd.isAtSameMomentAs(fmEndTime));
          } else {
            // No next FM period, so this FM period continues to the end of the TAF
            overlaps = concurrentStart.isAfter(baselinePeriod.startTime!) || concurrentStart.isAtSameMomentAs(baselinePeriod.startTime!);
          }
        }
        
        if (overlaps) {
          // Add bidirectional relationship
          concurrentPeriod.relatedBaselinePeriods.add(baselinePeriod.time);
          baselinePeriod.concurrentPeriods.add(concurrentPeriod.time);
        }
      }
    }
  }

  // Helper method to get weather for a specific time including concurrent periods
  Map<String, dynamic> getWeatherForTime(List<DecodedForecastPeriod> periods, DateTime time) {
    DecodedForecastPeriod? baselinePeriod;
    List<DecodedForecastPeriod> activeConcurrentPeriods = [];
    
    // Find the active baseline period
    for (final period in periods) {
      if (!period.isConcurrent) {
        if (period.startTime != null && period.endTime != null) {
          // Period with both start and end times
          if (time.isAfter(period.startTime!) && time.isBefore(period.endTime!)) {
            baselinePeriod = period;
            break;
          }
        } else if (period.startTime != null) {
          // Period with only start time (FM periods)
          if (time.isAfter(period.startTime!) || time.isAtSameMomentAs(period.startTime!)) {
            baselinePeriod = period;
            break;
          }
        }
      }
    }
    
    // Find active concurrent periods
    for (final period in periods) {
      if (period.isConcurrent && period.startTime != null && period.endTime != null) {
        if (time.isAfter(period.startTime!) && time.isBefore(period.endTime!)) {
          activeConcurrentPeriods.add(period);
        }
      }
    }
    
    return {
      'baseline': baselinePeriod,
      'concurrent': activeConcurrentPeriods,
    };
  }

  // Helper method to get all slider points including TEMPO/INTER periods
  List<DateTime> getAllSliderPoints(List<DecodedForecastPeriod> periods) {
    final points = <DateTime>{};
    
    for (final period in periods) {
      if (period.startTime != null) {
        points.add(period.startTime!);
      }
      if (period.endTime != null) {
        points.add(period.endTime!);
      }
    }
    
    return points.toList()..sort();
  }

  // Create simple timeline based on TAF validity period
  List<DateTime> createTimelineFromTaf(String rawText) {
    print('DEBUG: Creating timeline from TAF validity period');
    
    // Extract validity period from TAF header
    final validityMatch = RegExp(r'(\d{4})/(\d{4})').firstMatch(rawText);
    if (validityMatch == null) {
      print('DEBUG: No validity period found in TAF');
      return [];
    }
    
    final startDate = validityMatch.group(1)!;
    final endDate = validityMatch.group(2)!;
    
    // Parse start date (DDHH format)
    final startDay = int.parse(startDate.substring(0, 2));
    final startHour = int.parse(startDate.substring(2, 4));
    
    // Parse end date (DDHH format)
    final endDay = int.parse(endDate.substring(0, 2));
    final endHour = int.parse(endDate.substring(2, 4));
    
    // Create DateTime objects (assuming current month/year)
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, startDay, startHour);
    final endTime = DateTime(now.year, now.month, endDay, endHour);
    
    // Handle month/year rollover
    DateTime adjustedStartTime = startTime;
    DateTime adjustedEndTime = endTime;
    
    if (endTime.isBefore(startTime)) {
      // End time is in next month
      if (now.month == 12) {
        adjustedEndTime = DateTime(now.year + 1, 1, endDay, endHour);
      } else {
        adjustedEndTime = DateTime(now.year, now.month + 1, endDay, endHour);
      }
    }
    
    print('DEBUG: TAF validity period: ${adjustedStartTime} to ${adjustedEndTime}');
    
    // Create hourly timeline
    final timeline = <DateTime>[];
    DateTime currentTime = adjustedStartTime;
    
    while (currentTime.isBefore(adjustedEndTime) || currentTime.isAtSameMomentAs(adjustedEndTime)) {
      timeline.add(currentTime);
      currentTime = currentTime.add(Duration(hours: 1));
    }
    
    print('DEBUG: Created timeline with ${timeline.length} hourly points');
    return timeline;
  }

  // Find active periods at a given time
  Map<String, dynamic> findActivePeriodsAtTime(DateTime time, List<DecodedForecastPeriod> periods) {
    print('DEBUG: Finding active periods at ${time}');
    print('DEBUG: Checking ${periods.length} periods: ${periods.map((p) => '${p.type} (concurrent: ${p.isConcurrent}, start: ${p.startTime}, end: ${p.endTime})').toList()}');
    
    DecodedForecastPeriod? activeBaseline;
    List<DecodedForecastPeriod> activeConcurrent = [];
    
    for (final period in periods) {
      if (period.startTime == null || period.endTime == null) {
        print('DEBUG: Skipping ${period.type} - missing start/end time');
        continue;
      }
      
      // Check if period is active at this time
      final isActive = (period.startTime!.isBefore(time) || period.startTime!.isAtSameMomentAs(time)) &&
                      (period.endTime!.isAfter(time) || period.endTime!.isAtSameMomentAs(time));
      
      print('DEBUG: ${period.type} (${period.isConcurrent ? 'concurrent' : 'baseline'}) - start: ${period.startTime}, end: ${period.endTime}, isActive: $isActive');
      
      if (isActive) {
        if (period.isConcurrent) {
          activeConcurrent.add(period);
          print('DEBUG: Active concurrent period: ${period.type}');
        } else {
          activeBaseline = period;
          print('DEBUG: Active baseline period: ${period.type}');
        }
      }
    }
    
    print('DEBUG: Final result - baseline: ${activeBaseline?.type}, concurrent: ${activeConcurrent.map((p) => p.type).toList()}');
    
    return {
      'baseline': activeBaseline,
      'concurrent': activeConcurrent,
    };
  }

  // Get raw TAF sections for active periods - NEW 5-STEP APPROACH
  List<Map<String, dynamic>> getRawSectionsForActivePeriods(
    Map<String, dynamic> activePeriods, 
    String rawText
  ) {
    final sections = <Map<String, dynamic>>[];
    
    // Step 1: Break raw TAF into sections using period boundaries
    final tafSections = _breakTafIntoSections(rawText);
    print('DEBUG: TAF sections: ${tafSections.map((s) => '${s['type']}: "${s['text']}"').toList()}');
    
    // Step 2: Find which sections are active at the current time
    final baseline = activePeriods['baseline'] as DecodedForecastPeriod?;
    final concurrent = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
    
    // Find baseline section
    if (baseline != null) {
      final baselineSection = _findSectionForPeriod(baseline, tafSections);
      if (baselineSection != null) {
        sections.add(baselineSection);
      }
    }
    
    // Find concurrent sections
    for (final period in concurrent) {
      final concurrentSection = _findSectionForPeriod(period, tafSections);
      if (concurrentSection != null) {
        sections.add(concurrentSection);
      }
    }
    
    // Step 3: Convert to formatted text positions
    final textProcessor = TafTextProcessor(rawText);
    final formattedSections = sections.map((section) {
      final originalStart = section['start'] as int;
      final originalEnd = section['end'] as int;
      final formattedBounds = textProcessor.getFormattedSectionBounds(originalStart, originalEnd);
      
      return {
        'start': formattedBounds['start'],
        'end': formattedBounds['end'],
        'text': section['text'],
        'type': section['type'],
        'periodType': section['periodType'],
        'formattedText': textProcessor.formattedText.substring(
          formattedBounds['start']!, 
          formattedBounds['end']!
        ),
      };
    }).toList();
    
    // Sort by start position
    formattedSections.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    return formattedSections;
  }

  // Step 1: Break TAF into sections using period boundaries
  List<Map<String, dynamic>> _breakTafIntoSections(String rawText) {
    final sections = <Map<String, dynamic>>[];
    
    // Find all period start positions - ORDER MATTERS: longer patterns first
    final periodMatches = RegExp(r'\b(FM\d{6}|BECMG|PROB30\s+TEMPO|PROB30\s+INTER|PROB40\s+TEMPO|PROB40\s+INTER|PROB30|PROB40|INTER|TEMPO)\b').allMatches(rawText);
    
    if (periodMatches.isEmpty) {
      // No periods found, entire text is initial section
      sections.add({
        'start': 0,
        'end': rawText.length,
        'text': rawText,
        'type': 'baseline',
        'periodType': 'INITIAL',
      });
    } else {
      // Create initial section (from start to first period)
      final firstPeriod = periodMatches.first;
      if (firstPeriod.start > 0) {
        final initialText = rawText.substring(0, firstPeriod.start).trim();
        if (initialText.isNotEmpty) {
          sections.add({
            'start': 0,
            'end': firstPeriod.start,
            'text': initialText,
            'type': 'baseline',
            'periodType': 'INITIAL',
          });
        }
      }
      
      // Create sections for each period
      for (int i = 0; i < periodMatches.length; i++) {
        final currentMatch = periodMatches.elementAt(i);
        final nextMatch = i + 1 < periodMatches.length ? periodMatches.elementAt(i + 1) : null;
        
        final start = currentMatch.start;
        final end = nextMatch?.start ?? rawText.length;
        final periodText = rawText.substring(start, end).trim();
        
        // Determine period type
        String periodType = 'UNKNOWN';
        final matchedText = currentMatch.group(0)!;
        
        if (matchedText.startsWith('FM')) {
          periodType = 'FM';
        } else if (matchedText.startsWith('BECMG')) {
          periodType = 'BECMG';
        } else if (matchedText.startsWith('PROB30 TEMPO')) {
          periodType = 'PROB30 TEMPO';
        } else if (matchedText.startsWith('PROB30 INTER')) {
          periodType = 'PROB30 INTER';
        } else if (matchedText.startsWith('PROB40 TEMPO')) {
          periodType = 'PROB40 TEMPO';
        } else if (matchedText.startsWith('PROB40 INTER')) {
          periodType = 'PROB40 INTER';
        } else if (matchedText.startsWith('PROB30')) {
          periodType = 'PROB30';
        } else if (matchedText.startsWith('PROB40')) {
          periodType = 'PROB40';
        } else if (matchedText.startsWith('TEMPO')) {
          periodType = 'TEMPO';
        } else if (matchedText.startsWith('INTER')) {
          periodType = 'INTER';
        }
        
        // Determine if it's baseline or concurrent
        final isBaseline = periodType == 'FM' || periodType == 'BECMG' || periodType == 'INITIAL';
        
        sections.add({
          'start': start,
          'end': end,
          'text': periodText,
          'type': isBaseline ? 'baseline' : 'concurrent',
          'periodType': periodType,
        });
      }
    }
    
    return sections;
  }

  // Helper to find section for a given period
  Map<String, dynamic>? _findSectionForPeriod(DecodedForecastPeriod period, List<Map<String, dynamic>> tafSections) {
    print('DEBUG: Finding section for period: ${period.type} - ${period.time}');
    print('DEBUG: Available sections: ${tafSections.map((s) => '${s['periodType']}: "${s['text'].substring(0, s['text'].length > 50 ? 50 : s['text'].length)}..."').toList()}');
    
    // For INITIAL periods, find the initial section
    if (period.type == 'INITIAL') {
      final initialSection = tafSections.firstWhere(
        (section) => section['periodType'] == 'INITIAL',
        orElse: () => tafSections.first,
      );
      print('DEBUG: Found INITIAL section: ${initialSection['periodType']}');
      return initialSection;
    }
    
    // For other periods, try to match by period type
    for (final section in tafSections) {
      if (section['periodType'] == period.type) {
        print('DEBUG: Found exact match for ${period.type}: ${section['periodType']}');
        return section;
      }
    }
    
    // Try partial matching for combined periods
    if (period.type.contains('PROB30') || period.type.contains('PROB40')) {
      for (final section in tafSections) {
        if (section['periodType'].contains('PROB30') || section['periodType'].contains('PROB40')) {
          print('DEBUG: Found PROB match for ${period.type}: ${section['periodType']}');
          return section;
        }
      }
    }
    
    // Fallback: try to find by raw section content
    if (period.rawSection != null) {
      for (final section in tafSections) {
        if (section['text'].contains(period.rawSection!)) {
          print('DEBUG: Found section by raw content match: ${section['periodType']}');
          return section;
        }
      }
    }
    
    print('DEBUG: No section found for period: ${period.type}');
    return null;
  }

  Map<String, String> _parseWeatherFromTafSegment(String segment) {
    final weather = <String, String>{};
    final isCavok = _cavokPattern.hasMatch(segment);
    
    // Check if this is EGLL segment
    final isEgll = segment.contains('EGLL');
    if (isEgll) {
      print('DEBUG: 🎯 EGLL segment parsing: "$segment"');
    }
    
    // Check if this is a TEMPO/INTER/PROB segment
    final isConcurrent = segment.contains('TEMPO') || segment.contains('INTER') || segment.contains('PROB');
    if (isConcurrent) {
      print('DEBUG: 🎯 Concurrent segment parsing: "$segment"');
    }
    
    print('DEBUG: Parsing segment: $segment');
    print('DEBUG: CAVOK detected: $isCavok');
    
    // Test for -RA specifically
    if (segment.contains('-RA')) {
      print('DEBUG: 🚨 FOUND -RA in segment!');
      print('DEBUG: Segment contains -RA: ${segment.contains('-RA')}');
      print('DEBUG: Weather pattern test: ${_weatherPattern.hasMatch(segment)}');
      final raMatch = _weatherPattern.firstMatch(segment);
      if (raMatch != null) {
        print('DEBUG: -RA match found: ${raMatch.group(0)}');
        print('DEBUG: -RA groups: ${raMatch.groups([0, 1, 2])}');
      } else {
        print('DEBUG: No -RA match found!');
      }
    }

    // Parse wind
    final windMatch = _windPattern.firstMatch(segment);
    if (windMatch != null) {
      final dir = windMatch.group(1);
      final spd = int.tryParse(windMatch.group(2) ?? '');
      final gust = windMatch.group(3) != null ? int.tryParse(windMatch.group(3)!) : null;
      if (spd != null) {
        weather['Wind'] = _describeWind(dir, spd, gust).replaceFirst('Wind ', '');
        if (isEgll) {
          print('DEBUG: EGLL wind parsed: ${weather['Wind']}');
        }
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL wind not found in segment!');
    }

    // Parse visibility - search in the segment after wind
    final searchSegment = windMatch != null ? segment.substring(windMatch.end) : segment;
    print('DEBUG: 🔍 Searching for visibility in: "$searchSegment"');
    
    // For concurrent periods, try to exclude time ranges more aggressively
    String visibilitySearchText = searchSegment;
    if (isConcurrent) {
      // Remove time patterns like "2802/2805" before searching for visibility
      visibilitySearchText = searchSegment.replaceAll(RegExp(r'\d{4}/\d{4}'), '');
      print('DEBUG: 🔍 After removing time patterns: "$visibilitySearchText"');
    }
    
    final visibilityMatch = _tafVisibilityPattern.firstMatch(visibilitySearchText);
    final visibilitySMMatch = _tafVisibilitySMPattern.firstMatch(visibilitySearchText);
    
    print('DEBUG: 🔍 Visibility match: ${visibilityMatch?.group(0)}');
    print('DEBUG: 🔍 Visibility SM match: ${visibilitySMMatch?.group(0)}');
    
    if (visibilityMatch != null) {
      final visibility = visibilityMatch.group(1);
      print('DEBUG: 🔍 Parsed visibility: $visibility');
      if (visibility == 'CAVOK') {
        weather['Visibility'] = 'CAVOK';
      } else if (visibility != null) {
        final visMeters = int.tryParse(visibility);
        if (visMeters != null) {
          if (visMeters >= 9999) {
            weather['Visibility'] = '>10km';
          } else {
            // For TAF periods, show meters instead of kilometers
            weather['Visibility'] = '${visMeters}m';
          }
        }
      }
      if (isEgll) {
        print('DEBUG: EGLL visibility parsed: ${weather['Visibility']}');
      }
    } else if (visibilitySMMatch != null) {
      final visibility = visibilitySMMatch.group(1);
      if (visibility != null) {
        weather['Visibility'] = '${visibility}SM';
      }
      if (isEgll) {
        print('DEBUG: EGLL visibility (SM) parsed: ${weather['Visibility']}');
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL visibility not found in segment!');
    }

    // Parse clouds
    final cloudMatches = _cloudLayerPattern.allMatches(segment);
    if (cloudMatches.isNotEmpty) {
      final cloudDescriptions = <String>[];
      for (final match in cloudMatches) {
        final type = match.group(1);
        final height = match.group(2);
        final cb = match.group(3);
        if (type != null && height != null) {
          final heightFt = int.parse(height) * 100;
          final description = '$type at ${heightFt}ft${cb != null ? ' $cb' : ''}';
          cloudDescriptions.add(description);
        }
      }
      weather['Cloud'] = cloudDescriptions.join('\n');
      if (isEgll) {
        print('DEBUG: EGLL cloud parsed: ${weather['Cloud']}');
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL cloud not found in segment!');
    }

    // Parse weather phenomena - exclude cloud information from search
    final searchForWeather = segment.replaceAll(RegExp(r'\b(FEW|SCT|BKN|OVC)\d{3}\b'), '');
    if (isEgll) {
      print('DEBUG: EGLL searching for weather in: "$searchForWeather"');
    }
    print('DEBUG: 🔍 Searching for weather in: "$searchForWeather"');
    final weatherMatches = _weatherPattern.allMatches(searchForWeather);
    print('DEBUG: Weather pattern matches found: ${weatherMatches.length}');
    for (final match in weatherMatches) {
      print('DEBUG: Weather match groups: ${match.groups([0, 1, 2])}');
      print('DEBUG: Full match: "${match.group(0)}"');
      print('DEBUG: Group 1 (intensity): "${match.group(1)}"');
      print('DEBUG: Group 2 (weather code): "${match.group(2)}"');
    }
    if (weatherMatches.isNotEmpty) {
      final weatherDescriptions = <String>[];
      for (final match in weatherMatches) {
        final intensity = match.group(1) ?? '';
        final weatherCode = match.group(2) ?? '';
        final fullCode = intensity + weatherCode;
        final description = _describeConditions(fullCode);
        weatherDescriptions.add(description);
        print('DEBUG: Weather code: "$fullCode" -> "$description"');
      }
      weather['Weather'] = weatherDescriptions.join(', ');
    } else if (segment.contains('NSW')) {
      weather['Weather'] = 'No Significant Weather';
      print('DEBUG: Found explicit NSW');
    } else {
      weather['Weather'] = '-';
      print('DEBUG: No weather phenomena found, setting to "-"');
    }

    // Set CAVOK visibility if detected (this overrides any other visibility)
    if (isCavok) {
      weather['Visibility'] = 'CAVOK';
      weather['Cloud'] = 'CAVOK';
      print('DEBUG: Set CAVOK visibility and cloud');
    }

    if (isEgll) {
      print('DEBUG: EGLL final weather: $weather');
    }
    print('DEBUG: Final weather for segment: $weather');
    return weather;
  }

  // Simple method to format TAF text with line breaks for display
  String formatTafForDisplay(String rawText) {
    // Add line breaks before forecast elements for better readability
    String formatted = rawText;
    
    // Add line breaks before TAF forecast elements
    formatted = formatted.replaceAll(' FM', '\nFM');
    formatted = formatted.replaceAll(' TEMPO', '\nTEMPO');
    formatted = formatted.replaceAll(' BECMG', '\nBECMG');
    formatted = formatted.replaceAll(' PROB30', '\nPROB30');
    formatted = formatted.replaceAll(' PROB40', '\nPROB40');
    formatted = formatted.replaceAll(' INTER', '\nINTER');
    formatted = formatted.replaceAll(' RMK', '\nRMK');
    
    // Fix: Remove newline before TEMPO/INTER if immediately after PROB30/40
    formatted = formatted.replaceAll('\nPROB30\nTEMPO', '\nPROB30 TEMPO');
    formatted = formatted.replaceAll('\nPROB30\nINTER', '\nPROB30 INTER');
    formatted = formatted.replaceAll('\nPROB40\nTEMPO', '\nPROB40 TEMPO');
    formatted = formatted.replaceAll('\nPROB40\nINTER', '\nPROB40 INTER');
    
    return formatted;
  }

  // Simple method to find text positions for highlighting
  List<Map<String, dynamic>> getHighlightingPositions(
    Map<String, dynamic> activePeriods, 
    String rawText
  ) {
    print('DEBUG: getHighlightingPositions called with activePeriods: $activePeriods');
    final positions = <Map<String, dynamic>>[];
    final formattedText = formatTafForDisplay(rawText);
    print('DEBUG: Formatted text: $formattedText');
    
    final baseline = activePeriods['baseline'] as DecodedForecastPeriod?;
    final concurrent = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
    
    print('DEBUG: Baseline period: ${baseline?.type}');
    print('DEBUG: Concurrent periods: ${concurrent.map((p) => p.type).toList()}');
    
    // Find baseline period position
    if (baseline != null) {
      final baselinePos = findPeriodPositionInText(baseline, rawText, formattedText);
      if (baselinePos != null) {
        print('DEBUG: Found baseline position: ${baselinePos['start']}-${baselinePos['end']} for ${baselinePos['text']}');
        positions.add(baselinePos);
      } else {
        print('DEBUG: No baseline position found');
      }
    }
    
    // Find concurrent period positions
    for (final period in concurrent) {
      final concurrentPos = findPeriodPositionInText(period, rawText, formattedText);
      if (concurrentPos != null) {
        print('DEBUG: Found concurrent position: ${concurrentPos['start']}-${concurrentPos['end']} for ${concurrentPos['text']}');
        positions.add(concurrentPos);
      } else {
        print('DEBUG: No concurrent position found for ${period.type}');
      }
    }
    
    // Sort by start position
    positions.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    print('DEBUG: Final positions: ${positions.map((p) => '${p['periodType']}: ${p['start']}-${p['end']}').toList()}');
    return positions;
  }

  // Helper to find a period's position in formatted text
  Map<String, dynamic>? findPeriodPositionInText(
    DecodedForecastPeriod period, 
    String rawText, 
    String formattedText
  ) {
    print('DEBUG: 🔥🔥🔥 NEW findPeriodPositionInText called for ${period.type} 🔥🔥🔥');
    print('DEBUG: findPeriodPositionInText called for ${period.type}');
    print('DEBUG: Formatted text: "$formattedText"');
    
    // For INITIAL period, find the section before the first period indicator
    if (period.type == 'INITIAL') {
      print('DEBUG: Looking for INITIAL period in formatted text');
      final firstPeriodMatch = RegExp(r'\n(FM\d{6}|TEMPO|BECMG|PROB30|PROB40|INTER)').firstMatch(formattedText);
      print('DEBUG: First period match in formatted: ${firstPeriodMatch?.group(0)} at position ${firstPeriodMatch?.start}');
      
      if (firstPeriodMatch != null) {
        final formattedStart = 0;
        final formattedEnd = firstPeriodMatch.start;
        final formattedSection = formattedText.substring(formattedStart, formattedEnd).trim();
        print('DEBUG: Formatted INITIAL section: "$formattedSection"');
        
        if (formattedSection.isNotEmpty) {
          print('DEBUG: Found INITIAL position: $formattedStart-$formattedEnd');
          return {
            'start': formattedStart,
            'end': formattedEnd,
            'text': formattedSection,
            'type': 'baseline',
            'periodType': 'INITIAL',
          };
        }
      } else {
        print('DEBUG: No first period match found - entire text is INITIAL');
        // If no period indicators found, entire text is INITIAL
        return {
          'start': 0,
          'end': formattedText.length,
          'text': formattedText,
          'type': 'baseline',
          'periodType': 'INITIAL',
        };
      }
      return null;
    }
    
    // For other periods, find the period start in formatted text
    String periodStartPattern;
    if (period.type.startsWith('PROB30') || period.type.startsWith('PROB40')) {
      // Handle combined PROB30/40 TEMPO/INTER
      periodStartPattern = period.type;
    } else if (period.type == 'FM') {
      // FM periods have numbers after them (like FM260000)
      periodStartPattern = r'FM\d{6}';
    } else {
      periodStartPattern = period.type;
    }
    
    // Look for the period in formatted text (with newline prefix)
    final periodMatch = RegExp(r'\n${periodStartPattern}').firstMatch(formattedText);
    if (periodMatch == null) {
      // Try without newline (in case it's at the start)
      final periodMatchStart = RegExp(r'^${periodStartPattern}').firstMatch(formattedText);
      if (periodMatchStart == null) {
        print('DEBUG: No match found for ${period.type} in formatted text');
        return null;
      }
      // Handle period at start of text
      final originalStart = periodMatchStart.start;
      final nextPeriodMatch = RegExp(r'\n(FM\d{6}|TEMPO|BECMG|PROB30|PROB40|INTER)').firstMatch(formattedText.substring(originalStart + periodMatchStart.group(0)!.length));
      final originalEnd = nextPeriodMatch != null 
          ? originalStart + periodMatchStart.group(0)!.length + nextPeriodMatch.start
          : formattedText.length;
      
      final formattedSection = formattedText.substring(originalStart, originalEnd).trim();
      if (formattedSection.isNotEmpty) {
        return {
          'start': originalStart,
          'end': originalEnd,
          'text': formattedSection,
          'type': period.isConcurrent ? 'concurrent' : 'baseline',
          'periodType': period.type,
        };
      }
      return null;
    }
    
    final originalStart = periodMatch.start;
    
    // Find the next period start or end of text
    final nextPeriodMatch = RegExp(r'\n(FM\d{6}|TEMPO|BECMG|PROB30|PROB40|INTER)').firstMatch(formattedText.substring(originalStart + periodMatch.group(0)!.length));
    final originalEnd = nextPeriodMatch != null 
        ? originalStart + periodMatch.group(0)!.length + nextPeriodMatch.start
        : formattedText.length;
    
    final formattedSection = formattedText.substring(originalStart, originalEnd).trim();
    
    if (formattedSection.isNotEmpty) {
      print('DEBUG: Found ${period.type} position: $originalStart-$originalEnd');
      return {
        'start': originalStart,
        'end': originalEnd,
        'text': formattedSection,
        'type': period.isConcurrent ? 'concurrent' : 'baseline',
        'periodType': period.type,
      };
    }
    
    return null;
  }

  // After parsing all periods, print them for debugging
  void debugPrintParsedPeriods(List<DecodedForecastPeriod> periods) {
    print('DEBUG: ===== ALL PARSED PERIODS =====');
    for (final p in periods) {
      print('DEBUG: Period type: \'${p.type}\', time: \'${p.time}\', start: \'${p.startTime}\', end: \'${p.endTime}\', concurrent: ${p.isConcurrent}');
    }
    print('DEBUG: =============================');
  }

  // Helper method to generate period descriptions
  String _generatePeriodDescription(String periodType, String timeString, DateTime? startTime, DateTime? endTime) {
    switch (periodType) {
      case 'INITIAL':
        return 'Initial conditions';
      case 'FM':
        return 'From ${timeString.replaceFirst('FM', '')}Z';
      case 'BECMG':
        return 'Becoming conditions from ${timeString.replaceFirst('BECMG ', '')}Z';
      case 'TEMPO':
        return 'Temporary conditions from ${timeString}Z';
      case 'INTER':
        return 'Intermittent conditions from ${timeString}Z';
      case 'PROB30':
        return '30% probability from ${timeString}Z';
      case 'PROB40':
        return '40% probability from ${timeString}Z';
      case 'PROB30 TEMPO':
        return '30% probability temporary from ${timeString}Z';
      case 'PROB30 INTER':
        return '30% probability intermittent from ${timeString}Z';
      case 'PROB40 TEMPO':
        return '40% probability temporary from ${timeString}Z';
      case 'PROB40 INTER':
        return '40% probability intermittent from ${timeString}Z';
      default:
        return 'Period from ${timeString}Z';
    }
  }
} 