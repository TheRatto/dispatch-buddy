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
    final tafMatches = RegExp(r'TAF\s+(\w{4})\s+(\d{6})Z\s+(\d{4})/(\d{4})\s+([^\n]+(?:\n(?!\s*(?:SPECI|ATIS|NOTAM|$))[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in tafMatches) {
      final icao = match.group(1) ?? '';
      final issueTime = match.group(2) ?? '';
      final validityStart = match.group(3) ?? '';
      final validityEnd = match.group(4) ?? '';
      final tafText = match.group(5) ?? '';
      
      if (icao.isNotEmpty && tafText.isNotEmpty) {
        final fullTafText = 'TAF $icao ${issueTime}Z ${validityStart}/${validityEnd} $tafText';
        
        try {
          // Use existing decoder service
          final decoderService = decoder.DecoderService();
          final decodedWeather = decoderService.decodeTaf(fullTafText);
          
          final weather = Weather(
            icao: icao,
            timestamp: decodedWeather.timestamp,
            rawText: fullTafText,
            decodedText: _generateDecodedText(decodedWeather),
            windDirection: 0, // TAFs don't have current wind
            windSpeed: 0,
            visibility: 9999,
            cloudCover: decodedWeather.cloudCover ?? '',
            temperature: 0.0, // TAFs don't have current temperature
            dewPoint: 0.0,
            qnh: 0,
            conditions: decodedWeather.conditions ?? '',
            type: 'TAF',
            decodedWeather: decodedWeather,
          );
          
          tafs.add(weather);
          debugPrint('DEBUG: NAIPSParser - Parsed TAF for $icao');
        } catch (e) {
          debugPrint('DEBUG: NAIPSParser - Error parsing TAF for $icao: $e');
        }
      }
    }
    
    return tafs;
  }
  
  /// Parse METARs from briefing content
  static List<Weather> _parseMETARs(String content) {
    final List<Weather> metars = [];
    
    // Find METAR sections (including SPECI)
    final metarMatches = RegExp(r'(?:SPECI\s+)?(\w{4})\s+(\d{6})Z\s+([^\n]+(?:\n(?!\s*(?:TAF|ATIS|NOTAM|$))[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in metarMatches) {
      final icao = match.group(1) ?? '';
      final issueTime = match.group(2) ?? '';
      final metarText = match.group(3) ?? '';
      
      if (icao.isNotEmpty && metarText.isNotEmpty) {
        // Check if this is a SPECI
        final isSpeci = content.contains('SPECI $icao');
        final fullMetarText = isSpeci ? 'SPECI $icao ${issueTime}Z $metarText' : '$icao ${issueTime}Z $metarText';
        
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
    
    // Find ATIS sections
    final atisMatches = RegExp(r'ATIS\s+(\w{4})\s+([A-Z])\s+(\d{6})\s+([^\n]+(?:\n(?!\s*(?:TAF|METAR|NOTAM|$))[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in atisMatches) {
      final icao = match.group(1) ?? '';
      final atisCode = match.group(2) ?? '';
      final issueTime = match.group(3) ?? '';
      final atisText = match.group(4) ?? '';
      
      if (icao.isNotEmpty && atisText.isNotEmpty) {
        final fullAtisText = 'ATIS $icao $atisCode $issueTime $atisText';
        
        try {
          // Create a simple decoded weather object for ATIS
          final decodedWeather = DecodedWeather(
            icao: icao,
            timestamp: DateTime.now().toUtc(), // ATIS doesn't have standard timestamp format
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
            timestamp: DateTime.now().toUtc(),
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
    
    // Find NOTAM sections
    final notamMatches = RegExp(r'([A-Z]\d{3}/\d{2})\s+([^\n]+(?:\n(?!\s*[A-Z]\d{3}/\d{2})[^\n]+)*)', dotAll: true).allMatches(content);
    
    for (final match in notamMatches) {
      final notamId = match.group(1) ?? '';
      final notamText = match.group(2) ?? '';
      
      if (notamId.isNotEmpty && notamText.isNotEmpty) {
        try {
          final notam = Notam(
            id: notamId,
            icao: '', // Extract from text if needed
            type: NotamType.other, // Default type
            validFrom: DateTime.now(), // Parse from text if needed
            validTo: DateTime.now().add(const Duration(days: 30)), // Parse from text if needed
            rawText: notamText.trim(),
            decodedText: notamText.trim(),
            affectedSystem: 'NAIPS',
            isCritical: false,
            group: NotamGroup.other,
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