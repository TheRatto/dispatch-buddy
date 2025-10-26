import '../models/weather.dart';
import '../models/notam.dart';
import '../models/airport.dart';
import '../models/flight_context.dart';

/// Aviation-specific prompt template for AI briefing generation
/// 
/// This service creates structured prompts that include all relevant aviation data
/// in a format that the AI can effectively process for flight briefings.
class AviationPromptTemplate {
  static const String _baseSystemPrompt = '''
You are an AI assistant specialized in aviation data analysis and flight briefing generation.

CORE CAPABILITIES:
- Analyze weather data (METAR, TAF, ATIS) and identify operational impacts
- Process NOTAM information and assess runway/NAVAID availability
- Evaluate airport facilities and operational status
- Provide safety-focused recommendations and alternatives
- Generate clear, actionable briefings for pilots

RESPONSE APPROACH:
- Be professional, concise, and safety-focused
- Use standard aviation terminology when appropriate
- Prioritize safety-critical information
- Provide clear recommendations with reasoning
- Include quantitative data when relevant
- Structure information logically and clearly

BRIEFING FORMAT:
Structure responses with:
1. EXECUTIVE SUMMARY (key points)
2. SAFETY CONSIDERATIONS (hazards, restrictions)
3. OPERATIONAL STATUS (runway/NAVAID availability)
4. WEATHER ANALYSIS (current/forecast conditions)
5. RECOMMENDATIONS (specific actions)
6. ADDITIONAL INFO (alternatives, contingencies)
''';

  /// Generate a comprehensive aviation briefing prompt
  /// 
  /// This method creates a structured prompt that includes all relevant aviation data
  /// in a format optimized for AI processing and briefing generation.
  static String generateBriefingPrompt({
    required FlightContext flightContext,
    required List<Weather> weatherData,
    required List<Notam> notams,
    required List<Airport> airports,
    String? briefingStyle,
  }) {
    final buffer = StringBuffer();
    
    // System prompt
    buffer.writeln(_baseSystemPrompt);
    buffer.writeln();
    
    // Flight context
    buffer.writeln('=== FLIGHT CONTEXT ===');
    buffer.writeln('Route: ${flightContext.departureIcao} → ${flightContext.destinationIcao}');
    buffer.writeln('Aircraft: ${flightContext.aircraftType}');
    buffer.writeln('Flight Rules: ${flightContext.flightRules}');
    buffer.writeln('Departure Time: ${_formatDateTime(flightContext.departureTime)}');
    buffer.writeln('Arrival Time: ${_formatDateTime(flightContext.arrivalTime)}');
    if (flightContext.alternateIcaos.isNotEmpty) {
      buffer.writeln('Alternate Airports: ${flightContext.alternateIcaos.join(', ')}');
    }
    buffer.writeln();
    
    // Airport information
    buffer.writeln('=== AIRPORT INFORMATION ===');
    for (final airport in airports) {
      buffer.writeln('${airport.icao} - ${airport.name}');
      buffer.writeln('  Location: ${airport.city}');
      buffer.writeln('  Coordinates: ${airport.latitude}, ${airport.longitude}');
      if (airport.runways.isNotEmpty) {
        buffer.writeln('  Runways: ${airport.runways.map((r) => '${r.identifier} (${(r.length * 3.28084).round()}ft)').join(', ')}');
      }
      buffer.writeln();
    }
    
    // Weather data
    buffer.writeln('=== WEATHER DATA ===');
    final metars = weatherData.where((w) => w.type == 'METAR').toList();
    final tafs = weatherData.where((w) => w.type == 'TAF').toList();
    final atis = weatherData.where((w) => w.type == 'ATIS').toList();
    
    if (metars.isNotEmpty) {
      buffer.writeln('CURRENT METARs:');
      for (final metar in metars) {
        buffer.writeln('${metar.icao}: ${metar.rawText}');
        buffer.writeln('  Time: ${_formatDateTime(metar.timestamp)}');
        buffer.writeln();
      }
    }
    
    if (tafs.isNotEmpty) {
      buffer.writeln('TAF FORECASTS:');
      for (final taf in tafs) {
        buffer.writeln('${taf.icao}: ${taf.rawText}');
        buffer.writeln('  Valid: ${_formatTafValidity(taf)}');
        buffer.writeln();
      }
    }
    
    if (atis.isNotEmpty) {
      buffer.writeln('ATIS INFORMATION:');
      for (final atisData in atis) {
        buffer.writeln('${atisData.icao}: ${atisData.rawText}');
        buffer.writeln('  Time: ${_formatDateTime(atisData.timestamp)}');
        buffer.writeln();
      }
    }
    
    // NOTAMs
    buffer.writeln('=== NOTAMs ===');
    if (notams.isEmpty) {
      buffer.writeln('No active NOTAMs');
    } else {
      // Group NOTAMs by type for better organization
      final runwayNotams = notams.where((n) => n.group == NotamGroup.runways).toList();
      final navaidNotams = notams.where((n) => n.group == NotamGroup.instrumentProcedures).toList();
      final lightingNotams = notams.where((n) => n.group == NotamGroup.lighting).toList();
      final hazardNotams = notams.where((n) => n.group == NotamGroup.hazards).toList();
      
      if (runwayNotams.isNotEmpty) {
        buffer.writeln('RUNWAY NOTAMs:');
        for (final notam in runwayNotams) {
          buffer.writeln('${notam.id}: ${notam.rawText}');
          buffer.writeln('  Valid: ${_formatNotamValidity(notam)}');
          buffer.writeln('  Critical: ${notam.isCritical ? 'YES' : 'NO'}');
          buffer.writeln();
        }
      }
      
      if (navaidNotams.isNotEmpty) {
        buffer.writeln('NAVAID NOTAMs:');
        for (final notam in navaidNotams) {
          buffer.writeln('${notam.id}: ${notam.rawText}');
          buffer.writeln('  Valid: ${_formatNotamValidity(notam)}');
          buffer.writeln();
        }
      }
      
      if (lightingNotams.isNotEmpty) {
        buffer.writeln('LIGHTING NOTAMs:');
        for (final notam in lightingNotams) {
          buffer.writeln('${notam.id}: ${notam.rawText}');
          buffer.writeln('  Valid: ${_formatNotamValidity(notam)}');
          buffer.writeln();
        }
      }
      
      if (hazardNotams.isNotEmpty) {
        buffer.writeln('HAZARD NOTAMs:');
        for (final notam in hazardNotams) {
          buffer.writeln('${notam.id}: ${notam.rawText}');
          buffer.writeln('  Valid: ${_formatNotamValidity(notam)}');
          buffer.writeln();
        }
      }
    }
    
    // Briefing request
    buffer.writeln('=== BRIEFING REQUEST ===');
    buffer.writeln('Generate a comprehensive flight briefing for the above route and conditions.');
    if (briefingStyle != null) {
      buffer.writeln('Briefing Style: $briefingStyle');
    }
    buffer.writeln();
    buffer.writeln('Focus on:');
    buffer.writeln('- Safety-critical information');
    buffer.writeln('- Operational impacts and limitations');
    buffer.writeln('- Weather trends and forecasts');
    buffer.writeln('- Alternative options and recommendations');
    buffer.writeln('- Clear, actionable guidance for the pilot');
    
    return buffer.toString();
  }
  
  /// Generate a quick briefing prompt for simple queries
  static String generateQuickPrompt({
    required String query,
    List<Weather>? weatherData,
    List<Notam>? notams,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln(_baseSystemPrompt);
    buffer.writeln();
    buffer.writeln('=== QUICK QUERY ===');
    buffer.writeln('Query: $query');
    buffer.writeln();
    
    if (weatherData != null && weatherData.isNotEmpty) {
      buffer.writeln('CURRENT WEATHER:');
      for (final weather in weatherData) {
        buffer.writeln('${weather.icao}: ${weather.rawText}');
      }
      buffer.writeln();
    }
    
    if (notams != null && notams.isNotEmpty) {
      buffer.writeln('RELEVANT NOTAMs:');
      for (final notam in notams.take(5)) { // Limit to 5 most recent
        buffer.writeln('${notam.id}: ${notam.rawText}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('Provide a concise, helpful response to the query above.');
    
    return buffer.toString();
  }
  
  /// Format datetime for display
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }
  
  /// Format TAF validity period
  static String _formatTafValidity(Weather taf) {
    // This would need to be implemented based on your TAF parsing logic
    return 'Valid period extracted from TAF';
  }
  
  /// Format NOTAM validity period
  static String _formatNotamValidity(Notam notam) {
    final start = _formatDateTime(notam.validFrom);
    final end = _formatDateTime(notam.validTo);
    return '$start to $end';
  }
}

/// Briefing style options
enum BriefingStyle {
  quick,        // Executive summary only
  standard,     // Essential information
  comprehensive, // Full detailed analysis
  safetyFocus,  // Emphasize safety-critical items
  operational,  // Focus on operational impacts
}

/// Extension to get display names for briefing styles
extension BriefingStyleExtension on BriefingStyle {
  String get displayName {
    switch (this) {
      case BriefingStyle.quick:
        return 'Quick Brief';
      case BriefingStyle.standard:
        return 'Standard Brief';
      case BriefingStyle.comprehensive:
        return 'Comprehensive Brief';
      case BriefingStyle.safetyFocus:
        return 'Safety Focus Brief';
      case BriefingStyle.operational:
        return 'Operational Brief';
    }
  }
  
  String get description {
    switch (this) {
      case BriefingStyle.quick:
        return 'Executive summary with key points only';
      case BriefingStyle.standard:
        return 'Essential information for flight planning';
      case BriefingStyle.comprehensive:
        return 'Full detailed analysis with all considerations';
      case BriefingStyle.safetyFocus:
        return 'Emphasize safety-critical items and hazards';
      case BriefingStyle.operational:
        return 'Focus on operational impacts and procedures';
    }
  }
}
