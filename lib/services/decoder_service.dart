import 'dart:convert';
import 'dart:math';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import 'period_detector.dart';
import 'weather_parser.dart';
import 'metar_parser.dart';

class DecoderService {
  final PeriodDetector _periodDetector = PeriodDetector();
  final MetarParser _metarParser = MetarParser();

  // TAF Patterns
  static final _tafHeaderPattern = RegExp(r'TAF\s+(?:AMD\s+)?([A-Z]{4})\s+(\d{6})Z\s+(\d{4})/(\d{4})');
  static final _tafForecastPattern = RegExp(r'(FM\d{6}|BECMG|PROB30\s+TEMPO|PROB30\s+INTER|PROB40\s+TEMPO|PROB40\s+INTER|PROB30|PROB40|INTER|TEMPO)');
  static final _tafVisibilityPattern = RegExp(r'\b(P?\d{4})\b(?![/]\d{2})|CAVOK'); // Exclude time ranges like 2500/2503
  static final _tafVisibilitySMPattern = RegExp(r'\b(P?\d{1,2})SM\b');

  DecodedWeather decodeMetar(String rawText) {
    return _metarParser.decodeMetar(rawText);
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

  // Update the weather parsing method to use WeatherParser
  Map<String, String> _parseWeatherFromTafSegment(String segment) {
    return WeatherParser.parseWeatherFromSegment(segment);
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

  // Find active periods at a given time
  Map<String, dynamic> findActivePeriodsAtTime(DateTime time, List<DecodedForecastPeriod> periods) {
    return _periodDetector.findActivePeriodsAtTime(periods, time);
  }
} 