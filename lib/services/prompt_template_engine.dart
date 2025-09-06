import '../models/notam.dart';
import '../models/weather.dart';
import '../models/airport.dart';

/// Prompt Template Engine for AI Briefing Generation
/// 
/// This service creates sophisticated, aviation-specific prompts that integrate
/// weather data, NOTAMs, airport facilities, and flight context to generate
/// professional flight briefings using Apple's Foundation Models framework.
class PromptTemplateEngine {
  
  /// Generate a comprehensive aviation briefing prompt
  String buildAviationPrompt({
    required String departureIcao,
    required String destinationIcao,
    required List<String> alternateIcaos,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required String aircraftType,
    required String flightRules,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
    required String briefingStyle,
    required String pilotExperience,
  }) {
    final now = DateTime.now().toUtc();
    final briefingTime = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}Z';
    
    return '''
# AVIATION BRIEFING GENERATION REQUEST

## SYSTEM INSTRUCTIONS
You are an expert aviation briefing AI with extensive knowledge of:
- Weather analysis and interpretation for flight operations
- NOTAM impact assessment and operational implications
- Airport operations, procedures, and facility status
- Flight safety, risk management, and decision-making
- Regulatory compliance and operational requirements
- Crosswind calculations, performance planning, and fuel considerations

Generate a professional, concise flight briefing that prioritizes:
1. **SAFETY-CRITICAL INFORMATION** - Any conditions that could affect flight safety
2. **OPERATIONAL IMPACTS** - How conditions affect normal operations
3. **ALTERNATIVE OPTIONS** - Backup plans and recommendations
4. **CLEAR RECOMMENDATIONS** - Specific, actionable guidance

## FLIGHT CONTEXT
- **Route**: $departureIcao → $destinationIcao
- **Alternates**: ${alternateIcaos.join(', ')}
- **Departure Time**: ${_formatDateTime(departureTime)}
- **Arrival Time**: ${_formatDateTime(arrivalTime)}
- **Aircraft**: $aircraftType
- **Flight Rules**: $flightRules
- **Pilot Experience**: $pilotExperience
- **Briefing Style**: $briefingStyle
- **Generated**: $briefingTime

## WEATHER DATA
${_formatWeatherData(weatherData)}

## NOTAM INFORMATION
${_formatNotamData(notams)}

## AIRPORT FACILITIES
${_formatAirportData(airports)}

## BRIEFING REQUIREMENTS
Generate a briefing in the following format:

### EXECUTIVE SUMMARY
- 2-3 sentences summarizing key operational considerations
- Highlight any critical safety items or significant changes

### WEATHER OVERVIEW
- Current conditions at departure and destination
- Wind analysis (including crosswind components)
- Visibility and ceiling conditions
- Weather trends and forecast confidence
- Any significant weather hazards

### OPERATIONAL STATUS
- Runway availability and status
- NAVAID operational status
- Lighting systems status
- Ground services availability
- Any operational restrictions

### NOTAM SUMMARY
- Critical NOTAMs affecting the flight
- Runway closures or restrictions
- NAVAID outages or limitations
- Airspace restrictions or TFRs
- Construction or maintenance activities

### SAFETY CONSIDERATIONS
- Crosswind limitations and calculations
- Performance considerations
- Weather-related hazards
- NOTAM-related safety impacts
- Any special procedures required

### RECOMMENDATIONS
- Departure runway recommendations
- Route planning considerations
- Alternate airport planning
- Timing recommendations
- Pre-flight preparation items

### ADDITIONAL INFORMATION
- Fuel availability
- Ground services status
- Regulatory requirements (PPR, etc.)
- Any other operational considerations

## OUTPUT FORMAT
- Use professional aviation terminology
- Include specific runway numbers, frequencies, and procedures
- Provide quantitative data (wind speeds, visibility, etc.)
- Use clear, actionable language
- Prioritize safety-critical information
- Keep recommendations specific and practical

Generate the briefing now:
''';
  }

  /// Format weather data for AI processing
  String _formatWeatherData(List<Weather> weatherData) {
    if (weatherData.isEmpty) {
      return 'No weather data available';
    }

    final buffer = StringBuffer();
    
    // Group weather by type
    final metars = weatherData.where((w) => w.type == 'METAR').toList();
    final tafs = weatherData.where((w) => w.type == 'TAF').toList();
    final atis = weatherData.where((w) => w.type == 'ATIS').toList();

    if (metars.isNotEmpty) {
      buffer.writeln('### METAR DATA');
      for (final metar in metars) {
        buffer.writeln('- **${metar.icao}**: ${metar.rawText}');
        buffer.writeln('  - Age: ${_getWeatherAge(metar.timestamp)} minutes');
      }
      buffer.writeln();
    }

    if (tafs.isNotEmpty) {
      buffer.writeln('### TAF DATA');
      for (final taf in tafs) {
        buffer.writeln('- **${taf.icao}**: ${taf.rawText}');
        buffer.writeln('  - Generated: ${_formatDateTime(taf.timestamp)}');
      }
      buffer.writeln();
    }

    if (atis.isNotEmpty) {
      buffer.writeln('### ATIS DATA');
      for (final atisItem in atis) {
        buffer.writeln('- **${atisItem.icao}**: ${atisItem.rawText}');
        buffer.writeln('  - Letter: ${atisItem.atisCode ?? 'Unknown'}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Format NOTAM data for AI processing
  String _formatNotamData(List<Notam> notams) {
    if (notams.isEmpty) {
      return 'No NOTAMs affecting this flight';
    }

    final buffer = StringBuffer();
    
    // Group NOTAMs by type
    final runwayNotams = notams.where((n) => _isRunwayNotam(n)).toList();
    final navaidNotams = notams.where((n) => _isNavaidNotam(n)).toList();
    final lightingNotams = notams.where((n) => _isLightingNotam(n)).toList();
    final otherNotams = notams.where((n) => !_isRunwayNotam(n) && !_isNavaidNotam(n) && !_isLightingNotam(n)).toList();

    if (runwayNotams.isNotEmpty) {
      buffer.writeln('### RUNWAY NOTAMs');
      for (final notam in runwayNotams) {
        buffer.writeln('- **${notam.icao}**: ${notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText}');
        buffer.writeln('  - Valid: ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}');
        buffer.writeln('  - Impact: ${_assessNotamImpact(notam)}');
      }
      buffer.writeln();
    }

    if (navaidNotams.isNotEmpty) {
      buffer.writeln('### NAVAID NOTAMs');
      for (final notam in navaidNotams) {
        buffer.writeln('- **${notam.icao}**: ${notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText}');
        buffer.writeln('  - Valid: ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}');
        buffer.writeln('  - Impact: ${_assessNotamImpact(notam)}');
      }
      buffer.writeln();
    }

    if (lightingNotams.isNotEmpty) {
      buffer.writeln('### LIGHTING NOTAMs');
      for (final notam in lightingNotams) {
        buffer.writeln('- **${notam.icao}**: ${notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText}');
        buffer.writeln('  - Valid: ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}');
        buffer.writeln('  - Impact: ${_assessNotamImpact(notam)}');
      }
      buffer.writeln();
    }

    if (otherNotams.isNotEmpty) {
      buffer.writeln('### OTHER NOTAMs');
      for (final notam in otherNotams) {
        buffer.writeln('- **${notam.icao}**: ${notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText}');
        buffer.writeln('  - Valid: ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}');
        buffer.writeln('  - Impact: ${_assessNotamImpact(notam)}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Format airport data for AI processing
  String _formatAirportData(List<Airport> airports) {
    if (airports.isEmpty) {
      return 'No airport data available';
    }

    final buffer = StringBuffer();
    
    for (final airport in airports) {
      buffer.writeln('### ${airport.icao} - ${airport.name}');
      buffer.writeln('- **Location**: ${airport.city}');
      buffer.writeln('- **Coordinates**: ${airport.latitude.toStringAsFixed(4)}, ${airport.longitude.toStringAsFixed(4)}');
      buffer.writeln('- **Runways**: ${airport.runways.length} available');
      buffer.writeln('- **NAVAIDs**: ${airport.navaids.length} available');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Helper methods for NOTAM classification
  bool _isRunwayNotam(Notam notam) {
    final text = notam.fieldE.toLowerCase();
    return text.contains('runway') || text.contains('rw') || text.contains('rwy');
  }

  bool _isNavaidNotam(Notam notam) {
    final text = notam.fieldE.toLowerCase();
    return text.contains('ils') || text.contains('vor') || text.contains('dme') || 
           text.contains('ndb') || text.contains('tacan') || text.contains('navaid');
  }

  bool _isLightingNotam(Notam notam) {
    final text = notam.fieldE.toLowerCase();
    return text.contains('light') || text.contains('papi') || text.contains('vasi') || 
           text.contains('hirl') || text.contains('mirl') || text.contains('reil');
  }

  /// Assess NOTAM impact level
  String _assessNotamImpact(Notam notam) {
    final text = notam.fieldE.toLowerCase();
    
    if (text.contains('closed') || text.contains('unserviceable') || text.contains('out of service')) {
      return 'HIGH - Service unavailable';
    } else if (text.contains('limited') || text.contains('restricted') || text.contains('reduced')) {
      return 'MEDIUM - Limited service';
    } else if (text.contains('maintenance') || text.contains('work in progress')) {
      return 'LOW - Maintenance activity';
    } else {
      return 'UNKNOWN - Review required';
    }
  }

  /// Get weather data age in minutes
  int _getWeatherAge(DateTime timestamp) {
    final now = DateTime.now().toUtc();
    return now.difference(timestamp).inMinutes;
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.day}/${utc.month}/${utc.year} ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}Z';
  }
}
