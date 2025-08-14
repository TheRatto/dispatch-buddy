import 'package:flutter/foundation.dart';
import '../models/weather.dart';
import '../models/notam.dart';
import '../models/decoded_weather_models.dart';
import '../services/decoder_service.dart' as decoder;

class NAIPSParser {
  /// Parse weather data from NAIPS HTML response
  static List<Weather> parseWeatherFromHTML(String html) {
    final List<Weather> weatherList = [];
    
    try {
      // Extract content from <pre> tags
      final preMatches = RegExp(r'<pre[^>]*>(.*?)</pre>', dotAll: true).allMatches(html);
      
      for (final match in preMatches) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isEmpty) continue;
        
        debugPrint('DEBUG: NAIPSParser - Processing pre content: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
        
        // Parse TAFs
        final tafs = _parseTAFs(content);
        weatherList.addAll(tafs);
        
        // Parse METARs
        final metars = _parseMETARs(content);
        weatherList.addAll(metars);
        
        // Parse ATIS
        final atis = _parseATIS(content);
        weatherList.addAll(atis);
        debugPrint('DEBUG: NAIPSParser - Added ${atis.length} ATIS items to weather list');
      }
      
      debugPrint('DEBUG: NAIPSParser - Parsed ${weatherList.length} weather items');
      return weatherList;
    } catch (e) {
      debugPrint('DEBUG: NAIPSParser - Error parsing weather from HTML: $e');
      return [];
    }
  }
  
  /// Parse NOTAMs from NAIPS HTML response
  static List<Notam> parseNOTAMsFromHTML(String html) {
    final List<Notam> notamList = [];
    
    try {
      // Extract content from <pre> tags
      final preMatches = RegExp(r'<pre[^>]*>(.*?)</pre>', dotAll: true).allMatches(html);
      
      for (final match in preMatches) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isEmpty) continue;
        
        // Look for NOTAM section
        if (content.contains('NOTAM INFORMATION')) {
          final notams = _parseNOTAMs(content);
          notamList.addAll(notams);
        }
      }
      
      debugPrint('DEBUG: NAIPSParser - Parsed ${notamList.length} NOTAMs');
      return notamList;
    } catch (e) {
      debugPrint('DEBUG: NAIPSParser - Error parsing NOTAMs from HTML: $e');
      return [];
    }
  }
  
  /// Parse TAFs from briefing content
  static List<Weather> _parseTAFs(String content) {
    final List<Weather> tafs = [];
    
    // Find TAF sections
    // Allow indentation before TAF and optional AMD/COR marker; capture until next section
    final tafRegex = RegExp(
      r'(?:^|\n)\s*TAF(?:\s+(?:AMD|COR|TAF3))?\s+([A-Z]{4})\s+(\d{6})\s*Z\s+(\d{4})/(\d{4})\s+([\s\S]*?)(?=\n\s*(?:TAF\s|METAR|SPECI|ATIS|NOTAM|$))',
      dotAll: true,
    );
    final tafMatches = tafRegex.allMatches(content);
    debugPrint('DEBUG: NAIPSParser - TAF regex found ${taMatchesCount(tafMatches)} matches');
    
    for (final match in tafMatches) {
      final icao = match.group(1) ?? '';
      final issueTime = match.group(2) ?? '';
      final validityStart = match.group(3) ?? '';
      final validityEnd = match.group(4) ?? '';
      final tafText = match.group(5) ?? '';
      
      if (icao.isNotEmpty && tafText.isNotEmpty) {
        // Normalize body text to avoid \r and excessive blank lines
        final normalizedBody = _normalizeMultiline(tafText);

        // Create compact TAF string for decoding only
        final compactTafText = _createCompactTafText(icao, issueTime, validityStart, validityEnd, normalizedBody);

        // Preserve full multi-line TAF for display; ensure 'TAF3' marker is retained at end if present
        final bodyLines = normalizedBody.trim().split('\n');
        String joined = normalizedBody.trim();
        // If the first body line looks like initial weather, join to header for readability
        if (bodyLines.isNotEmpty && !bodyLines.first.startsWith(RegExp(r'(FM\d{6}|TEMPO|BECMG|PROB(30|40)|INTER|RMK|TAF3)'))) {
          joined = bodyLines.first + (bodyLines.length > 1 ? '\n' + bodyLines.sublist(1).join('\n') : '');
        }
        // Build display with potential trailing TAF3 on its own line
        String displayTafText = 'TAF ' + icao + ' ' + issueTime + 'Z ' + validityStart + '/' + validityEnd + '\n' + joined;

        try {
          final decoderService = decoder.DecoderService();
          final decodedWeather = decoderService.decodeTaf(compactTafText);

          final weather = Weather(
            icao: icao,
            timestamp: decodedWeather.timestamp,
            rawText: displayTafText,
            decodedText: _generateDecodedText(decodedWeather),
            windDirection: 0,
            windSpeed: 0,
            visibility: 9999,
            cloudCover: decodedWeather.cloudCover ?? '',
            temperature: 0.0,
            dewPoint: 0.0,
            qnh: 0,
            conditions: decodedWeather.conditions ?? '',
            type: 'TAF',
            decodedWeather: decodedWeather,
            source: 'naips',
          );

          tafs.add(weather);
          debugPrint('DEBUG: NAIPSParser - Parsed TAF for ' + icao);
        } catch (e) {
          debugPrint('DEBUG: NAIPSParser - Error parsing TAF for ' + icao + ': ' + e.toString());
        }
      }
    }
    
    return tafs;
  }

  // Helper: count iterable without consuming
  static int taMatchesCount(Iterable<RegExpMatch> matches) {
    int c = 0; for (final _ in matches) { c++; } return c;
  }

  // Normalize newlines and collapse multiple blank lines
  static String _normalizeMultiline(String input) {
    var s = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Trim trailing spaces on lines
    s = s.split('\n').map((line) => line.trimRight()).join('\n');
    // Collapse 2+ blank lines to a single blank line
    s = s.replaceAll(RegExp(r'\n{2,}'), '\n');
    return s;
  }
  
  /// Create compact TAF text format similar to aviationweather.gov
  static String _createCompactTafText(String icao, String issueTime, String validityStart, String validityEnd, String tafText) {
    // Split the TAF text into lines and process each line
    final lines = tafText.split('\n');
    final processedLines = <String>[];
    
    // Extract RMK section if present
    String? rmkSection;
    String? tafVersion;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      if (trimmedLine.startsWith('RMK')) {
        // Start collecting RMK section
        rmkSection = trimmedLine;
      } else if (trimmedLine.startsWith('TAF') && trimmedLine != 'TAF') {
        // TAF version indicator (like TAF3)
        tafVersion = trimmedLine;
      } else if (rmkSection != null) {
        // Continue RMK section
        rmkSection += ' $trimmedLine';
      } else {
        // Regular TAF line - make it compact
        final compactLine = trimmedLine.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (compactLine.isNotEmpty) {
          processedLines.add(compactLine);
        }
      }
    }
    
    // Build the compact TAF text
    final compactText = processedLines.join(' ');
    
    // Create the final TAF text with RMK at the bottom
    final fullTafText = 'TAF $icao ${issueTime}Z $validityStart/$validityEnd $compactText';
    
    // Add RMK section at the bottom if present
    if (rmkSection != null) {
      final tafWithRmk = '$fullTafText\n$rmkSection';
      
      // Add TAF version if present
      if (tafVersion != null) {
        return '$tafWithRmk\n$tafVersion';
      }
      
      return tafWithRmk;
    }
    
    // Add TAF version if present
    if (tafVersion != null) {
      return '$fullTafText\n$tafVersion';
    }
    
    return fullTafText;
  }
  
  /// Parse METARs from briefing content
  static List<Weather> _parseMETARs(String content) {
    final List<Weather> metars = [];
    
    // Find METAR sections (explicit METAR or SPECI only). Avoid matching inside TAF headers
    final metarMatches = RegExp(r'(METAR|SPECI)\s+(\w{4})\s+(\d{6})\s*Z\s+([^\n]+(?:\n(?!\s*(?:TAF|ATIS|NOTAM|$))[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in metarMatches) {
      final label = match.group(1) ?? '';
      final icao = match.group(2) ?? '';
      final issueTime = match.group(3) ?? '';
      final metarText = match.group(4) ?? '';
      
      if (icao.isNotEmpty && metarText.isNotEmpty) {
        // Build full METAR/SPECI line preserving the label
        final fullMetarText = '$label $icao ${issueTime}Z $metarText';
        
        try {
          // Use existing decoder service
          final decoderService = decoder.DecoderService();
          final decodedWeather = decoderService.decodeMetar(fullMetarText);
          
          final weather = Weather(
            icao: icao,
            timestamp: decodedWeather.timestamp,
            rawText: fullMetarText,
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
            source: 'naips',
          );
          
          metars.add(weather);
          debugPrint('DEBUG: NAIPSParser - Parsed METAR for $icao');
        } catch (e) {
          debugPrint('DEBUG: NAIPSParser - Error parsing METAR for $icao: $e');
        }
      }
    }
    
    return metars;
  }
  
  /// Parse ATIS from briefing content
  static List<Weather> _parseATIS(String content) {
    final List<Weather> atis = [];
    
    debugPrint('DEBUG: NAIPSParser - Parsing ATIS from content length: ${content.length}');
    debugPrint('DEBUG: NAIPSParser - Content preview: ${content.substring(0, content.length > 500 ? 500 : content.length)}');
    
    // Look for ATIS in the content
    if (content.contains('ATIS')) {
      debugPrint('DEBUG: NAIPSParser - Found "ATIS" in content');
      final atisIndex = content.indexOf('ATIS');
      final atisContext = content.substring(atisIndex, atisIndex + 200);
      debugPrint('DEBUG: NAIPSParser - ATIS context: $atisContext');
    } else {
      debugPrint('DEBUG: NAIPSParser - No "ATIS" found in content');
    }
    
    // Find ATIS sections - try multiple patterns
    final patterns = [
      // Pattern 1: ATIS YSSY I 100634 (standard format)
      RegExp(r'ATIS\s+(\w{4})\s+([A-Z])\s+(\d{6})\s*([^\n]+(?:\n(?!\s*(?:TAF|METAR|NOTAM|$))[^\n]+)*)', dotAll: true),
      // Pattern 2: ATIS YSSY I100634 (without space before time)
      RegExp(r'ATIS\s+(\w{4})\s+([A-Z])(\d{6})\s*([^\n]+(?:\n(?!\s*(?:TAF|METAR|NOTAM|$))[^\n]+)*)', dotAll: true),
      // Pattern 3: ATIS YSSY I   100634 (with multiple spaces)
      RegExp(r'ATIS\s+(\w{4})\s+([A-Z])\s+(\d{6})\s*([^\n]+(?:\n(?!\s*(?:TAF|METAR|NOTAM|$))[^\n]+)*)', dotAll: true),
      // Pattern 4: Most flexible - any ATIS with ICAO and code
      RegExp(r'ATIS\s+(\w{4})\s+([A-Z])\s*(\d{6})\s*([^\n]+(?:\n(?!\s*(?:TAF|METAR|NOTAM|$))[^\n]+)*)', dotAll: true),
      // Pattern 5: Fallback - just find ATIS with ICAO and any content
      RegExp(r'ATIS\s+(\w{4})\s+([A-Z])\s*(.*?)(?=\n\s*(?:TAF|METAR|NOTAM|$))', dotAll: true),
    ];
    
    final allMatches = <RegExpMatch>[];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(content);
      allMatches.addAll(matches);
      debugPrint('DEBUG: NAIPSParser - Pattern found ${matches.length} ATIS matches');
    }
    
    debugPrint('DEBUG: NAIPSParser - Total ATIS matches found: ${allMatches.length}');
    
    for (final match in allMatches) {
      final icao = match.group(1) ?? '';
      final atisCode = match.group(2) ?? '';
      final issueTime = match.group(3) ?? '';
      final atisText = match.group(4) ?? '';
      
      if (icao.isNotEmpty && atisText.isNotEmpty) {
        final fullAtisText = 'ATIS $icao $atisCode $issueTime $atisText';
        
        // Derive true ATIS timestamp (UTC) from ddhhmm string
        DateTime atisTimestampUtc;
        try {
          final nowUtc = DateTime.now().toUtc();
          final day = int.parse(issueTime.substring(0, 2));
          final hour = int.parse(issueTime.substring(2, 4));
          final minute = int.parse(issueTime.substring(4, 6));
          var ts = DateTime.utc(nowUtc.year, nowUtc.month, day, hour, minute);
          // If constructed time is in the future, roll back a month/day window
          if (ts.isAfter(nowUtc)) {
            final yesterday = nowUtc.subtract(const Duration(days: 1));
            ts = DateTime.utc(yesterday.year, yesterday.month, day, hour, minute);
          }
          atisTimestampUtc = ts;
        } catch (_) {
          atisTimestampUtc = DateTime.now().toUtc();
        }
        
        debugPrint('DEBUG: NAIPSParser - Extracted ATIS: ICAO=$icao, Code=$atisCode, Time=$issueTime');
        debugPrint('DEBUG: NAIPSParser - Full ATIS text: $fullAtisText');
        
        try {
          // Create a simple decoded weather object for ATIS
          final decodedWeather = DecodedWeather(
            icao: icao,
            timestamp: atisTimestampUtc,
            rawText: fullAtisText,
            type: 'ATIS',
            windDirection: null,
            windSpeed: null,
            visibility: null,
            cloudCover: '',
            temperature: null,
            dewPoint: null,
            qnh: null,
            conditions: '',
            remarks: atisText.trim(),
            windDescription: '',
            visibilityDescription: '',
            cloudDescription: '',
            temperatureDescription: '',
            pressureDescription: '',
            conditionsDescription: '',
            rvrDescription: '',
            timeline: [],
          );
          
          final weather = Weather(
            icao: icao,
            timestamp: atisTimestampUtc,
            rawText: fullAtisText,
            decodedText: 'ATIS Information: $atisText',
            windDirection: 0,
            windSpeed: 0,
            visibility: 9999,
            cloudCover: '',
            temperature: 0.0,
            dewPoint: 0.0,
            qnh: 0,
            conditions: '',
            type: 'ATIS',
            decodedWeather: decodedWeather,
            source: 'naips',
            atisCode: atisCode,
            atisType: 'ATIS',
          );
          
          atis.add(weather);
          debugPrint('DEBUG: NAIPSParser - Parsed ATIS for $icao');
        } catch (e) {
          debugPrint('DEBUG: NAIPSParser - Error parsing ATIS for $icao: $e');
        }
      }
    }
    
    return atis;
  }
  
  /// Parse NOTAMs from briefing content
  static List<Notam> _parseNOTAMs(String content) {
    final List<Notam> notams = [];
    
    // Determine ICAO context from header like "CITY (YSCB)"
    String currentIcao = '';
    final headerMatch = RegExp(r'\(([A-Z]{4})\)').firstMatch(content);
    if (headerMatch != null) {
      currentIcao = headerMatch.group(1) ?? '';
    }
    
    // Find NOTAM sections
    final notamMatches = RegExp(r'([A-Z]\d{3}/\d{2})\s+([^\n]+(?:\n(?!\s*[A-Z]\d{3}/\d{2})[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in notamMatches) {
      final notamId = match.group(1) ?? '';
      final notamText = match.group(2) ?? '';
      
      if (notamId.isNotEmpty && notamText.isNotEmpty) {
        // Attempt to parse validity window: FROM DD HHMM TO DD HHMM (EST/UTC)
        DateTime? validFrom;
        DateTime? validTo;
        final validMatch = RegExp(r'FROM\s+(\d{2})\s+(\d{4})\s+TO\s+(\d{2})\s+(\d{4})', caseSensitive: false)
            .firstMatch(notamText);
        if (validMatch != null) {
          try {
            final nowUtc = DateTime.now().toUtc();
            final fromDay = int.parse(validMatch.group(1)!);
            final fromHm = validMatch.group(2)!;
            final toDay = int.parse(validMatch.group(3)!);
            final toHm = validMatch.group(4)!;
            final fromHour = int.parse(fromHm.substring(0, 2));
            final fromMin = int.parse(fromHm.substring(2, 4));
            final toHour = int.parse(toHm.substring(0, 2));
            final toMin = int.parse(toHm.substring(2, 4));
            // Assume current month/year; adjust if day wraps
            var from = DateTime.utc(nowUtc.year, nowUtc.month, fromDay, fromHour, fromMin);
            var to = DateTime.utc(nowUtc.year, nowUtc.month, toDay, toHour, toMin);
            if (to.isBefore(from)) {
              // likely crosses month boundary
              to = DateTime.utc(nowUtc.year, nowUtc.month + 1, toDay, toHour, toMin);
            }
            validFrom = from;
            validTo = to;
          } catch (_) {
            validFrom = null;
            validTo = null;
          }
        }
        
        // Require ICAO context; if missing, skip NAIPS NOTAM to avoid misassignment
        if (currentIcao.isEmpty) {
          debugPrint('DEBUG: NAIPSParser - Skipping NOTAM $notamId due to missing ICAO context');
          continue;
        }
        
        try {
          final notam = Notam(
            id: notamId,
            icao: currentIcao,
            type: NotamType.other, // Default type
            validFrom: validFrom ?? DateTime.now().toUtc(),
            validTo: validTo ?? DateTime.now().toUtc().add(const Duration(days: 30)),
            rawText: notamText.trim(),
            decodedText: notamText.trim(),
            affectedSystem: 'NAIPS',
            isCritical: false,
            group: NotamGroup.other,
            source: 'naips',
          );
          
          notams.add(notam);
          debugPrint('DEBUG: NAIPSParser - Parsed NOTAM $notamId');
        } catch (e) {
          debugPrint('DEBUG: NAIPSParser - Error parsing NOTAM $notamId: $e');
        }
      }
    }
    
    return notams;
  }
  
  /// Generate decoded text from DecodedWeather object
  static String _generateDecodedText(DecodedWeather decodedWeather) {
    final parts = <String>[];
    
    if (decodedWeather.windDirection != null && decodedWeather.windSpeed != null) {
      parts.add('Wind: ${decodedWeather.windDirection}° at ${decodedWeather.windSpeed}kt');
    }
    
    if (decodedWeather.visibility != null) {
      parts.add('Visibility: ${decodedWeather.visibility}m');
    }
    
    if (decodedWeather.cloudCover?.isNotEmpty == true) {
      parts.add('Cloud: ${decodedWeather.cloudCover}');
    }
    
    if (decodedWeather.temperature != null) {
      parts.add('Temperature: ${decodedWeather.temperature}°C');
    }
    
    if (decodedWeather.conditions?.isNotEmpty == true) {
      parts.add('Conditions: ${decodedWeather.conditions}');
    }
    
    return parts.join(', ');
  }
} 