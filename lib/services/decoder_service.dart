import 'package:flutter/foundation.dart';
import '../models/decoded_weather_models.dart';
import 'period_detector.dart';
import 'weather_parser.dart';
import 'metar_parser.dart';

class DecoderService {
  final PeriodDetector _periodDetector = PeriodDetector();
  final MetarParser _metarParser = MetarParser();

  // TAF Patterns
  static final _tafHeaderPattern = RegExp(r'(?:TAF\s+(?:AMD\s+)?)?([A-Z]{4})\s+(\d{6})\s*Z\s+(\d{4})/(\d{4})');


  DecodedWeather decodeMetar(String rawText) {
    return _metarParser.decodeMetar(rawText);
  }

  DecodedWeather decodeTaf(String rawText) {
    debugPrint('DEBUG: 🚀 decodeTaf called with rawText: "$rawText"');
    
    // Check if this is YPPH TAF
    if (rawText.contains('YPPH')) {
      debugPrint('DEBUG: 🎯 YPPH TAF detected!');
      debugPrint('DEBUG: YPPH raw text: "$rawText"');
      debugPrint('DEBUG: YPPH TAF length: ${rawText.length}');
      debugPrint('DEBUG: YPPH TAF first 200 chars: "${rawText.substring(0, rawText.length > 200 ? 200 : rawText.length)}"');
    }
    
    // Check if this is KJFK TAF
    if (rawText.contains('KJFK')) {
      debugPrint('DEBUG: 🎯 KJFK TAF detected!');
      debugPrint('DEBUG: KJFK raw text: "$rawText"');
      debugPrint('DEBUG: KJFK TAF length: ${rawText.length}');
      debugPrint('DEBUG: KJFK TAF first 100 chars: "${rawText.substring(0, rawText.length > 100 ? 100 : rawText.length)}"');
    }
    
    // Check if this is EGLL TAF
    if (rawText.contains('EGLL')) {
      debugPrint('DEBUG: 🎯 EGLL TAF detected!');
      debugPrint('DEBUG: EGLL raw text: "$rawText"');
    }
    

    
    // Parse TAF header
    final headerMatch = _tafHeaderPattern.firstMatch(rawText);
    if (headerMatch == null) {
      debugPrint('DEBUG: No TAF header found in: "$rawText"');
      return _createEmptyDecodedWeather('', DateTime.now(), rawText, 'TAF');
    }
    
    final icao = headerMatch.group(1) ?? '';
    final timestamp = _parseTafTimestamp(rawText);
    
    if (rawText.contains('EGLL')) {
      debugPrint('DEBUG: EGLL TAF header parsed - ICAO: $icao, timestamp: $timestamp');
    }
    
    // Parse forecast periods
    final periods = _parseTafPeriods(rawText);
    
    if (rawText.contains('EGLL')) {
      debugPrint('DEBUG: EGLL TAF periods parsed: ${periods.length} periods');
      for (int i = 0; i < periods.length; i++) {
        final period = periods[i];
        debugPrint('DEBUG: EGLL period $i: ${period.type} - ${period.time} - weather: ${period.weather}');
      }
    }
    
    // Debug each period
    for (int i = 0; i < periods.length; i++) {
      final period = periods[i];
      debugPrint('DEBUG: Period $i: ${period.type} - ${period.time} - isConcurrent: ${period.isConcurrent} - startTime: ${period.startTime} - endTime: ${period.endTime}');
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
    debugPrint('DEBUG: 🔍 _parseTafPeriods called with rawText: "$rawText"');
    
    // Add debug logging for YPPH
    if (rawText.contains('YPPH')) {
      debugPrint('DEBUG: 🔍 Starting YPPH TAF period parsing...');
      debugPrint('DEBUG: YPPH TAF raw text: "$rawText"');
    }
    
    // Add debug logging for KJFK
    if (rawText.contains('KJFK')) {
      debugPrint('DEBUG: 🔍 Starting KJFK TAF period parsing...');
    }
    
    try {
      // Find all period indicators in the TAF
      final periodPattern = RegExp(r'\b(FM|BECMG|TEMPO|INTER|PROB30|PROB40)\b');
      final matches = periodPattern.allMatches(rawText);
      
      if (rawText.contains('KJFK')) {
        debugPrint('DEBUG: 🔍 KJFK period matches found: ${matches.length}');
        for (final match in matches) {
          debugPrint('DEBUG: 🔍   - "${match.group(0)}" at position ${match.start}');
        }
      }
      
      final sections = <Map<String, dynamic>>[];
      
      // Find all period start positions - ORDER MATTERS: longer patterns first
      final periodMatches = RegExp(r'\b(FM\d{6}|BECMG|PROB30\s+TEMPO|PROB30\s+INTER|PROB40\s+TEMPO|PROB40\s+INTER|PROB30|PROB40|INTER|TEMPO)\b').allMatches(rawText);
      
      debugPrint('DEBUG: 🔍 Found ${periodMatches.length} period matches:');
      for (final match in periodMatches) {
        debugPrint('DEBUG:   - "${match.group(0)}" at position ${match.start}');
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
        } else {
          // No explicit initial text, but we need to create an INITIAL period
          // to preserve the weather conditions from the TAF header
          // Extract weather from the TAF header (before the first period)
          final tafHeaderMatch = RegExp(r'^TAF\s+[A-Z]{4}\s+\d{6}Z\s+\d{4}/\d{4}\s+(.+?)(?=\s+(?:FM|BECMG|TEMPO|INTER|PROB30|PROB40))', dotAll: true).firstMatch(rawText);
          if (tafHeaderMatch != null) {
            final headerWeather = tafHeaderMatch.group(1)?.trim();
            if (headerWeather != null && headerWeather.isNotEmpty) {
              sections.add({
                'start': 0,
                'end': firstPeriod.start,
                'text': headerWeather,
                'type': 'baseline',
                'periodType': 'INITIAL',
              });
              debugPrint('DEBUG: 🔍 Created INITIAL period from TAF header: "$headerWeather"');
            }
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
          
          debugPrint('DEBUG: 🔍 Creating section for period: $periodType');
          debugPrint('DEBUG:   - Matched text: "$matchedText"');
          debugPrint('DEBUG:   - Period text: "${periodText.substring(0, periodText.length > 100 ? 100 : periodText.length)}..."');
          
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
      
      debugPrint('DEBUG: 🔍 Final sections created: ${sections.map((s) => s['periodType']).toList()}');
      
      // Add debug logging for KJFK
      if (rawText.contains('KJFK')) {
        debugPrint('DEBUG: 🔍 KJFK sections created:');
        for (int i = 0; i < sections.length; i++) {
          final section = sections[i];
          debugPrint('DEBUG:   Section $i: ${section['periodType']} - "${section['text'].substring(0, section['text'].length > 50 ? 50 : section['text'].length)}..."');
        }
      }
      
      // Convert sections to DecodedForecastPeriod objects
      final periods = <DecodedForecastPeriod>[];
      final tafStartTime = _parseTafCommencementTime(rawText);
      final tafEndTime = _parseTafEndTime(rawText);
      
      for (final section in sections) {
        final periodType = section['periodType'] as String;
        final sectionText = section['text'] as String;
        var isBaseline = section['type'] == 'baseline';
        
        // Parse time information from the section
        DateTime? startTime;
        DateTime? endTime;
        String timeString = '';
        
        if (periodType == 'INITIAL') {
          // Initial period uses TAF validity period
          startTime = tafStartTime;
          DateTime? endTimeCandidate;
          for (int i = 1; i < sections.length; i++) {
            final nextSection = sections[i];
            final nextType = nextSection['periodType'] as String;
            if (nextType == 'FM') {
              // FM: end at FM start
              final timeMatch = RegExp(r'FM(\d{2})(\d{2})(\d{2})').firstMatch(nextSection['text'] as String);
              if (timeMatch != null) {
                final day = int.parse(timeMatch.group(1)!);
                final hour = int.parse(timeMatch.group(2)!);
                final minute = int.parse(timeMatch.group(3)!);
                endTimeCandidate = createDateTimeWithMonthTransition(day, hour, minute);
                break;
              }
            } else if (nextType == 'BECMG') {
              // BECMG: end at BECMG END
              final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(nextSection['text'] as String);
              if (timeMatch != null) {
                final toDay = int.parse(timeMatch.group(3)!);
                final toHour = int.parse(timeMatch.group(4)!);
                endTimeCandidate = createDateTimeWithMonthTransition(toDay, toHour);
                break;
              }
            }
          }
          endTime = endTimeCandidate ?? tafEndTime;
          timeString = 'INITIAL';
          debugPrint('DEBUG: 🔍 INITIAL period: $startTime to $endTime');
          if (endTime != null && startTime.isAtSameMomentAs(endTime)) {
            endTime = startTime.add(const Duration(hours: 1));
            debugPrint('DEBUG: 🔍 Extended INITIAL period to: $startTime to $endTime');
          }
        } else if (periodType.startsWith('FM')) {
          // FM periods have time in format FMddhhmm
          final timeMatch = RegExp(r'FM(\d{2})(\d{2})(\d{2})').firstMatch(sectionText);
          if (timeMatch != null) {
            final day = int.parse(timeMatch.group(1)!);
            final hour = int.parse(timeMatch.group(2)!);
            final minute = int.parse(timeMatch.group(3)!);
            
            // Add debug logging for KJFK
            if (rawText.contains('KJFK')) {
              debugPrint('DEBUG: 🔍 KJFK FM period parsing:');
              debugPrint('DEBUG:   Section text: "$sectionText"');
              debugPrint('DEBUG:   Day: $day, Hour: $hour, Minute: $minute');
            }
            
            startTime = createDateTimeWithMonthTransition(day, hour, minute);
            endTime = _findNextBaselinePeriodStartFromText(
              sections.map((s) => s['text'] as String).toList(),
              sections.indexOf(section),
              startTime,
              tafEndTime
            );
            timeString = 'FM${day.toString().padLeft(2, '0')}${hour.toString().padLeft(2, '0')}';
            
            // Add debug logging for KJFK
            if (rawText.contains('KJFK')) {
              debugPrint('DEBUG:   Start time: $startTime');
              debugPrint('DEBUG:   End time: $endTime');
              debugPrint('DEBUG:   Time string: $timeString');
            }
          } else {
            // Add debug logging for KJFK when FM parsing fails
            if (rawText.contains('KJFK')) {
              debugPrint('DEBUG: ❌ KJFK FM period parsing failed!');
              debugPrint('DEBUG:   Section text: "$sectionText"');
              debugPrint('DEBUG:   No time match found for FM pattern');
            }
          }
        } else if (periodType == 'BECMG') {
          // BECMG periods are concurrent (transitional)
          final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(sectionText);
          if (timeMatch != null) {
            final fromDay = int.parse(timeMatch.group(1)!);
            final fromHour = int.parse(timeMatch.group(2)!);
            final toDay = int.parse(timeMatch.group(3)!);
            final toHour = int.parse(timeMatch.group(4)!);
            startTime = createDateTimeWithMonthTransition(fromDay, fromHour);
            endTime = createEndDateTimeWithMonthTransition(startTime, toDay, toHour);
            timeString = 'BECMG ${fromDay.toString().padLeft(2, '0')}${fromHour.toString().padLeft(2, '0')}/${toDay.toString().padLeft(2, '0')}${toHour.toString().padLeft(2, '0')}';
            debugPrint('DEBUG: 🔍 BECMG transition period: $startTime to $endTime');
          }
          isBaseline = false; // Mark BECMG as concurrent
        } else if (periodType.contains('PROB30') || periodType.contains('PROB40')) {
          // PROB30/40 periods have time range
          final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(sectionText);
          if (timeMatch != null) {
            final fromDay = int.parse(timeMatch.group(1)!);
            final fromHour = int.parse(timeMatch.group(2)!);
            final toDay = int.parse(timeMatch.group(3)!);
            final toHour = int.parse(timeMatch.group(4)!);
            startTime = createDateTimeWithMonthTransition(fromDay, fromHour);
            endTime = createEndDateTimeWithMonthTransition(startTime, toDay, toHour);
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
            startTime = createDateTimeWithMonthTransition(fromDay, fromHour);
            endTime = createEndDateTimeWithMonthTransition(startTime, toDay, toHour);
            timeString = '${fromDay.toString().padLeft(2, '0')}${fromHour.toString().padLeft(2, '0')}/${toDay.toString().padLeft(2, '0')}${toHour.toString().padLeft(2, '0')}';
            
            debugPrint('DEBUG: 🔍 Parsed $periodType time: $timeString');
            debugPrint('DEBUG: 🔍   From day: $fromDay, hour: $fromHour');
            debugPrint('DEBUG: 🔍   To day: $toDay, hour: $toHour');
            debugPrint('DEBUG: 🔍   Start time: $startTime');
            debugPrint('DEBUG: 🔍   End time: $endTime');
            debugPrint('DEBUG: 🔍   Section text: "$sectionText"');
          }
        }
        
        // Parse weather from the section
        final weather = _parseWeatherFromTafSegment(sectionText);
        
        debugPrint('DEBUG: 🔍 Parsed weather for $periodType: $weather');
        
        // Calculate changed elements for concurrent periods
        Set<String> changedElements = {};
        if (!isBaseline && periods.isNotEmpty) {
          // Find the most recent baseline period to compare against
          final baselinePeriod = periods.lastWhere((p) => !p.isConcurrent, orElse: () => periods.first);
          final baselineWeather = baselinePeriod.weather;
          
          debugPrint('DEBUG: 🔍 Comparing with baseline period: ${baselinePeriod.type}');
          debugPrint('DEBUG: 🔍 Baseline weather: $baselineWeather');
          debugPrint('DEBUG: 🔍 Concurrent weather: $weather');
          
          // Compare each weather element
          for (final entry in weather.entries) {
            final key = entry.key;
            final value = entry.value;
            final baselineValue = baselineWeather[key];
            
            // Consider it changed if the value is present and not empty/null
            if (value.isNotEmpty && value != '-') {
              // For concurrent periods, include ALL weather elements that are present
              // (not just those that are different from baseline)
              changedElements.add(key);
              debugPrint('DEBUG: 🔍 Added $key to changedElements: "$value" (baseline: "$baselineValue")');
            }
          }
          
          debugPrint('DEBUG: 🔍 Final changed elements: $changedElements');
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
      
        debugPrint('DEBUG: 🔍 Created period: ${period.type} (${period.time}) - concurrent: ${period.isConcurrent}');
      periods.add(period);
      }
      
      debugPrint('DEBUG: 🔍 Final periods created: ${periods.map((p) => '${p.type} (${p.time})').toList()}');
      
      // After all periods are created, create new baseline periods after BECMG transitions
      final postBecmgPeriods = <DecodedForecastPeriod>[];
      for (final period in periods) {
        if (period.type == 'BECMG' && period.endTime != null) {
          // Find the next baseline period start time
          DateTime? nextBaselineStart;
          for (final nextPeriod in periods) {
            if (!nextPeriod.isConcurrent && nextPeriod.startTime != null && nextPeriod.startTime!.isAfter(period.endTime!)) {
              nextBaselineStart = nextPeriod.startTime;
              break;
            }
          }
          final postBecmgEndTime = nextBaselineStart ?? tafEndTime;
          if (postBecmgEndTime != null && period.endTime!.isBefore(postBecmgEndTime)) {
                      // Find the previous baseline period to inherit from
          DecodedForecastPeriod? previousBaseline;
          for (final p in periods.reversed) {
            if (!p.isConcurrent && p.endTime != null && p.endTime!.isAtSameMomentAs(period.endTime!)) {
              previousBaseline = p;
              break;
            }
          }
          
          // If no exact match found, find the most recent baseline that was active before this BECMG
          if (previousBaseline == null) {
            for (final p in periods.reversed) {
              if (!p.isConcurrent && p.endTime != null && p.endTime!.isBefore(period.endTime!)) {
                previousBaseline = p;
                break;
              }
            }
          }
          
          // Create weather map starting with previous baseline
          Map<String, String> postBecmgWeather = {};
          if (previousBaseline != null) {
            postBecmgWeather.addAll(previousBaseline.weather);
            debugPrint('DEBUG: 🔍 POST_BECMG inheriting from ${previousBaseline.type}: ${previousBaseline.weather}');
          }
          
          // Apply only the changes from BECMG
          for (final key in period.changedElements) {
            if (period.weather[key] != null && period.weather[key]!.isNotEmpty && period.weather[key] != '-') {
              postBecmgWeather[key] = period.weather[key]!;
              debugPrint('DEBUG: 🔍 POST_BECMG applying change: $key = ${period.weather[key]}');
            }
          }
          
          final postBecmgPeriod = DecodedForecastPeriod(
            type: 'POST_BECMG',
            time: 'POST_${period.time}',
            description: 'Conditions after ${period.time}',
            weather: postBecmgWeather,
            changedElements: period.changedElements, // Keep the same changed elements
            startTime: period.endTime,
            endTime: postBecmgEndTime,
            isConcurrent: false,
            rawSection: period.rawSection,
          );
            postBecmgPeriods.add(postBecmgPeriod);
            debugPrint('DEBUG: 🔍 Created post-BECMG period: ${postBecmgPeriod.startTime} to ${postBecmgPeriod.endTime}');
          }
        }
      }
      periods.addAll(postBecmgPeriods);
      periods.sort((a, b) => (a.startTime ?? DateTime.now()).compareTo(b.startTime ?? DateTime.now()));

    return periods;
    } catch (e) {
      debugPrint('DEBUG: ❌ Error parsing TAF periods: $e');
      return [];
    }
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
            return createDateTimeWithMonthTransition(int.parse(day), int.parse(hour), int.parse(minute));
          }
        } else if (type == 'BECMG') {
          final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(periodStr);
          final fromDay = timeMatch?.group(1);
          final fromHour = timeMatch?.group(2);
          final toDay = timeMatch?.group(3);
          final toHour = timeMatch?.group(4);
          
          if (fromDay != null && fromHour != null && toDay != null && toHour != null) {
            // For BECMG periods, return the END time (not start time)
            // This ensures baseline periods end when BECMG ends, not when it starts
            // Create a temporary start time to use for month transition logic
            final tempStartTime = createDateTimeWithMonthTransition(int.parse(fromDay), int.parse(fromHour));
            return createEndDateTimeWithMonthTransition(tempStartTime, int.parse(toDay), int.parse(toHour));
          }
        }
      }
    }
    
    // If no next baseline period, use the TAF validity period end time
    return tafEndTime ?? currentStartTime.add(const Duration(hours: 24));
  }

  DateTime _parseTafCommencementTime(String rawText) {
    // Parse TAF validity period from header (e.g., "2512/2618")
    final validityMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(rawText);
    if (validityMatch != null) {
      final startDay = int.parse(validityMatch.group(1)!);
      final startHour = int.parse(validityMatch.group(2)!);
      
      // Use helper method for proper month transition handling
      return createDateTimeWithMonthTransition(startDay, startHour);
    }
    
    // Fallback to current time if parsing fails
    return DateTime.now();
  }

  DateTime? _parseTafEndTime(String rawText) {
    // Parse TAF issue time first to get the correct month reference
    final issueTime = _parseTafTimestamp(rawText);
    
    // Parse TAF validity period end time from header (e.g., "2512/2618")
    final validityMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(rawText);
    if (validityMatch != null) {
      final endDay = int.parse(validityMatch.group(3)!);
      final endHour = int.parse(validityMatch.group(4)!);
      
      // Use TAF issue time as reference for month transition handling
      final startTime = _parseTafCommencementTime(rawText);
      return _createEndDateTimeWithTafReference(startTime, endDay, endHour);
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
      
      // Use helper method for proper month transition handling
      return createDateTimeWithMonthTransition(day, hour, minute);
    }
    return DateTime.now();
  }

  // Update the weather parsing method to use WeatherParser
  Map<String, String> _parseWeatherFromTafSegment(String segment) {
    return WeatherParser.parseWeatherFromSegment(segment);
  }

  // Create simple timeline based on TAF validity period
  List<DateTime> createTimelineFromTaf(String rawText) {
    debugPrint('DEBUG: Creating timeline from TAF validity period');
    
    // Extract validity period from TAF header
    final validityMatch = RegExp(r'(\d{4})/(\d{4})').firstMatch(rawText);
    if (validityMatch == null) {
      debugPrint('DEBUG: No validity period found in TAF');
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
    
    // Use helper methods for proper month transition handling
    final startTime = createDateTimeWithMonthTransition(startDay, startHour);
    final endTime = createEndDateTimeWithMonthTransition(startTime, endDay, endHour);
    
    debugPrint('DEBUG: TAF validity period: $startTime to $endTime');
    
    // Subtract one hour from end time to avoid showing the exact end time
    // where there's no weather data
    final effectiveEndTime = endTime.subtract(const Duration(hours: 1));
    
    debugPrint('DEBUG: TAF validity period: $startTime to $endTime (effective end: $effectiveEndTime)');
    
    // Create hourly timeline
    final timeline = <DateTime>[];
    DateTime currentTime = startTime;
    
    while (currentTime.isBefore(effectiveEndTime) || currentTime.isAtSameMomentAs(effectiveEndTime)) {
      timeline.add(currentTime);
      currentTime = currentTime.add(const Duration(hours: 1));
    }
    
    debugPrint('DEBUG: Created timeline with ${timeline.length} hourly points');
    return timeline;
  }

  // Simple method to format TAF text with line breaks for display
  String formatTafForDisplay(String rawText) {
    // Add line breaks before forecast elements for better readability
    String formatted = rawText;
    
    // Normalize line endings and trim trailing spaces
    formatted = formatted.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    formatted = formatted.split('\n').map((l) => l.trim()).join('\n');

    // Merge header and immediate next line for single-line initial when body is short/simple
    // This improves readability for cases like WSSS where the initial wind/vis is on the next line
    formatted = formatted.replaceFirstMapped(
      RegExp(r'^(TAF\s+[A-Z]{4}\s+\d{6}Z\s+\d{4}/\d{4})\s*\n\s*'),
      (m) => '${m.group(1)} ',
    );

    // Add line breaks before TAF forecast elements
    formatted = formatted.replaceAll(' FM', '\nFM');
    formatted = formatted.replaceAll(' TEMPO', '\nTEMPO');
    formatted = formatted.replaceAll(' BECMG', '\nBECMG');
    formatted = formatted.replaceAll(' PROB30', '\nPROB30');
    formatted = formatted.replaceAll(' PROB40', '\nPROB40');
    formatted = formatted.replaceAll(' INTER', '\nINTER');
    formatted = formatted.replaceAll(' RMK', '\nRMK');
    // Ensure TAF version markers like TAF3 are visible on their own line
    formatted = formatted.replaceAll(' TAF3', '\nTAF3');
    
    // Fix: Remove newline before TEMPO/INTER if immediately after PROB30/40
    formatted = formatted.replaceAll('\nPROB30\nTEMPO', '\nPROB30 TEMPO');
    formatted = formatted.replaceAll('\nPROB30\nINTER', '\nPROB30 INTER');
    formatted = formatted.replaceAll('\nPROB40\nTEMPO', '\nPROB40 TEMPO');
    formatted = formatted.replaceAll('\nPROB40\nINTER', '\nPROB40 INTER');
    
    // Collapse stray blank lines (including whitespace-only)
    formatted = formatted.replaceAll(RegExp(r'\n[ \t]*\n+'), '\n');
    
    return formatted;
  }

  // Simple method to find text positions for highlighting
  List<Map<String, dynamic>> getHighlightingPositions(
    Map<String, dynamic> activePeriods, 
    String rawText
  ) {
    debugPrint('DEBUG: getHighlightingPositions called with activePeriods: $activePeriods');
    final positions = <Map<String, dynamic>>[];
    final formattedText = formatTafForDisplay(rawText);
    debugPrint('DEBUG: Formatted text: $formattedText');
    
    final baseline = activePeriods['baseline'] as DecodedForecastPeriod?;
    final concurrent = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
    
    debugPrint('DEBUG: Baseline period: ${baseline?.type}');
    debugPrint('DEBUG: Concurrent periods: ${concurrent.map((p) => p.type).toList()}');
    
    // Find baseline period position
    if (baseline != null) {
      final baselinePos = findPeriodPositionInText(baseline, rawText, formattedText);
      if (baselinePos != null) {
        debugPrint('DEBUG: Found baseline position: ${baselinePos['start']}-${baselinePos['end']} for ${baselinePos['text']}');
        positions.add(baselinePos);
        } else {
        debugPrint('DEBUG: No baseline position found');
      }
    }
    
    // Find concurrent period positions
    for (final period in concurrent) {
      final concurrentPos = findPeriodPositionInText(period, rawText, formattedText);
      if (concurrentPos != null) {
        debugPrint('DEBUG: Found concurrent position: ${concurrentPos['start']}-${concurrentPos['end']} for ${concurrentPos['text']}');
        positions.add(concurrentPos);
      } else {
        debugPrint('DEBUG: No concurrent position found for ${period.type}');
      }
    }
    
    // Sort by start position
    positions.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    debugPrint('DEBUG: Final positions: ${positions.map((p) => '${p['periodType']}: ${p['start']}-${p['end']}').toList()}');
    return positions;
  }

  // Helper to find a period's position in formatted text
  Map<String, dynamic>? findPeriodPositionInText(
    DecodedForecastPeriod period, 
    String rawText, 
    String formattedText
  ) {
    debugPrint('DEBUG: ��🔥🔥 NEW findPeriodPositionInText called for ${period.type} 🔥🔥🔥');
    debugPrint('DEBUG: findPeriodPositionInText called for ${period.type}');
    debugPrint('DEBUG: Formatted text: "$formattedText"');
    
    // For INITIAL period, find the section after the TAF header and before the first period indicator
    if (period.type == 'INITIAL') {
      debugPrint('DEBUG: Looking for INITIAL period in formatted text');
      final firstPeriodMatch = RegExp(r'\n(FM\d{6}|TEMPO|BECMG|PROB30|PROB40|INTER)').firstMatch(formattedText);
      debugPrint('DEBUG: First period match in formatted: ${firstPeriodMatch?.group(0)} at position ${firstPeriodMatch?.start}');

      // Identify the end of the TAF header
      final headerMatch = RegExp(r'^TAF\s+[A-Z]{4}\s+\d{6}Z\s+\d{4}/\d{4}\s*').firstMatch(formattedText);
      final headerEnd = headerMatch?.end ?? 0;

      if (firstPeriodMatch != null) {
        final formattedStart = headerEnd;
        final formattedEnd = firstPeriodMatch.start;
        final formattedSection = formattedText.substring(formattedStart.clamp(0, formattedEnd), formattedEnd).trim();
        debugPrint('DEBUG: Formatted INITIAL section: "$formattedSection"');
        
        if (formattedSection.isNotEmpty) {
          debugPrint('DEBUG: Found INITIAL position: $formattedStart-$formattedEnd');
          return {
            'start': formattedStart,
            'end': formattedEnd,
            'text': formattedSection,
              'type': 'baseline',
              'periodType': 'INITIAL',
          };
          }
        } else {
        debugPrint('DEBUG: No first period match found - entire text is INITIAL');
        // If no period indicators found, entire text is INITIAL
        final formattedStart = headerEnd;
        return {
            'start': formattedStart,
          'end': formattedText.length,
          'text': formattedText.substring(formattedStart),
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
        debugPrint('DEBUG: No match found for ${period.type} in formatted text');
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
      debugPrint('DEBUG: Found ${period.type} position: $originalStart-$originalEnd');
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
    debugPrint('DEBUG: ===== ALL PARSED PERIODS =====');
    for (final p in periods) {
      debugPrint('DEBUG: Period type: \'${p.type}\', time: \'${p.time}\', start: \'${p.startTime}\', end: \'${p.endTime}\', concurrent: ${p.isConcurrent}');
    }
    debugPrint('DEBUG: =============================');
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
    return PeriodDetector.findActivePeriodsAtTime(periods, time);
  }

  /// Helper method to create DateTime with proper month transition handling
  /// For TAF time ranges like 3020/0100 (June 30 20:00 to July 1 00:00)
  /// Made public for testing purposes
  /// 
  /// CRITICAL: TAF validity periods are always relative to the current month.
  /// DO NOT compare days to determine month - this was the source of a major bug.
  /// 
  /// Example: TAF 2315/2500 means:
  /// - Start: 23rd day of current month at 15:00
  /// - End: 25th day of current month at 00:00 (or next month if 25 < 23)
  DateTime createDateTimeWithMonthTransition(int day, int hour, [int minute = 0]) {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    
    debugPrint('DEBUG: 🔍 _createDateTimeWithMonthTransition called with day: $day, hour: $hour, minute: $minute');
    debugPrint('DEBUG: 🔍   Current date: $now');
    debugPrint('DEBUG: 🔍   Using current year: $year, month: $month');
    
    // TAF validity periods are always relative to the current month
    // Don't try to determine month by comparing days - this was causing issues
    final result = DateTime(year, month, day, hour, minute);
    debugPrint('DEBUG: ��   Created DateTime: $result');
    return result;
  }

  /// Helper method to create end DateTime with proper month transition handling
  /// Takes the start DateTime as reference to determine if end time is in next month
  /// Made public for testing purposes
  /// 
  /// CRITICAL: Only increment month when end day < start day.
  /// This handles cases like 3020/0100 where end is in next month.
  DateTime createEndDateTimeWithMonthTransition(DateTime startTime, int endDay, int endHour, [int endMinute = 0]) {
    int year = startTime.year;
    int month = startTime.month;
    
    debugPrint('DEBUG: 🔍 _createEndDateTimeWithMonthTransition called with startTime: $startTime, endDay: $endDay, endHour: $endHour');
    debugPrint('DEBUG: 🔍   Initial year: $year, month: $month');
    
    // If end day is less than start day, assume it's next month
    if (endDay < startTime.day) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      debugPrint('DEBUG: 🔍   End day $endDay < start day ${startTime.day}, incrementing month to $month');
    }
    
    final result = DateTime(year, month, endDay, endHour, endMinute);
    debugPrint('DEBUG: 🔍   Created end DateTime: $result');
    return result;
  }

  /// Helper method to create end DateTime with proper month transition handling
  /// Takes the start DateTime as reference to determine if end time is in next month
  /// Made public for testing purposes
  /// 
  /// CRITICAL: Only increment month when end day < start day.
  /// This handles cases like 3020/0100 where end is in next month.
  DateTime _createEndDateTimeWithTafReference(DateTime startTime, int endDay, int endHour, [int endMinute = 0]) {
    int year = startTime.year;
    int month = startTime.month;
    
    debugPrint('DEBUG: 🔍 _createEndDateTimeWithTafReference called with startTime: $startTime, endDay: $endDay, endHour: $endHour');
    debugPrint('DEBUG: 🔍   Initial year: $year, month: $month');
    
    // If end day is less than start day, assume it's next month
    if (endDay < startTime.day) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      debugPrint('DEBUG: 🔍   End day $endDay < start day ${startTime.day}, incrementing month to $month');
    }
    
    final result = DateTime(year, month, endDay, endHour, endMinute);
    debugPrint('DEBUG: 🔍   Created end DateTime: $result');
    return result;
  }
} 