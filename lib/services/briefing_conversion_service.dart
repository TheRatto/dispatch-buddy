import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/briefing.dart';
import '../models/flight.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/airport.dart';

/// Service for converting between Briefing storage format and Flight objects
/// 
/// This service handles the conversion between:
/// - Briefing storage format (Map<String, dynamic>) 
/// - Flight model (with List<Notam> and List<Weather>)
/// 
/// This enables loading saved briefings into the existing FlightProvider workflow
/// without breaking the current API-based functionality.
class BriefingConversionService {
  
  /// Convert a Briefing object to a Flight object
  /// 
  /// This reconstructs the Flight object with all its associated data
  /// (NOTAMs, weather, airports) from the stored briefing data.
  static Flight briefingToFlight(Briefing briefing) {
    try {
      debugPrint('DEBUG: Converting briefing ${briefing.id} to Flight object');
      debugPrint('DEBUG: Briefing has ${briefing.airports.length} airports: ${briefing.airports}');
      debugPrint('DEBUG: Briefing has ${briefing.notams.length} NOTAM entries');
      debugPrint('DEBUG: Briefing has ${briefing.weather.length} weather entries');
      
      // Convert stored data back to proper objects
      final notams = _convertNotamsMapToList(briefing.notams);
      final weather = _convertWeatherMapToList(briefing.weather);
      final airports = _reconstructAirports(briefing.airports, notams, weather);
      
      debugPrint('DEBUG: Converted ${notams.length} NOTAMs, ${weather.length} weather reports, ${airports.length} airports');
      
      // Debug: Log some details about the converted data
      if (notams.isNotEmpty) {
        debugPrint('DEBUG: Sample NOTAM - ID: ${notams.first.id}, ICAO: ${notams.first.icao}, Type: ${notams.first.type}');
      }
      if (weather.isNotEmpty) {
        debugPrint('DEBUG: Sample Weather - ICAO: ${weather.first.icao}, Type: ${weather.first.type}, Raw: ${weather.first.rawText.substring(0, weather.first.rawText.length > 50 ? 50 : weather.first.rawText.length)}...');
      }
      
      return Flight(
        id: briefing.id,
        route: briefing.airports.join(' → '),
        departure: airports.first.icao,
        destination: airports.last.icao,
        etd: briefing.timestamp,
        flightLevel: 'FL100', // Default value
        alternates: airports.length > 2 ? [airports[2].icao] : [],
        createdAt: briefing.timestamp,
        airports: airports,
        notams: notams,
        weather: weather,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to convert briefing to flight: $e');
      rethrow;
    }
  }
  
  /// Convert a Flight object to a Briefing object for storage
  /// 
  /// This converts the Flight's complex objects to simple storage format
  /// that can be serialized to JSON and stored in SharedPreferences.
  static Briefing flightToBriefing(Flight flight) {
    try {
      debugPrint('DEBUG: Converting flight ${flight.id} to Briefing object');
      
      // Convert complex objects to simple storage format
      final notamsMap = _convertNotamsListToMap(flight.notams);
      final weatherMap = _convertWeatherListToMap(flight.weather);
      final airportsList = _extractAirportCodes(flight);
      
      debugPrint('DEBUG: Converted ${flight.notams.length} NOTAMs, ${flight.weather.length} weather reports, ${airportsList.length} airports');
      
      return Briefing.create(
        airports: airportsList,
        notams: notamsMap,
        weather: weatherMap,
      );
    } catch (e) {
      debugPrint('ERROR: Failed to convert flight to briefing: $e');
      rethrow;
    }
  }
  
  /// Convert stored NOTAMs Map back to List<Notam> objects
  static List<Notam> _convertNotamsMapToList(Map<String, dynamic> notamsMap) {
    try {
      final List<Notam> notams = [];
      
      // The storage format is Map<String, dynamic> where key is NOTAM ID
      // and value is the NOTAM data object
      for (final entry in notamsMap.entries) {
        final notamId = entry.key;
        final notamData = entry.value as Map<String, dynamic>;
        
          try {
          final notam = Notam.fromJson(notamData);
            notams.add(notam);
          } catch (e) {
          debugPrint('WARNING: Failed to convert NOTAM $notamId: $e');
            // Continue with other NOTAMs
        }
      }
      
      return notams;
    } catch (e) {
      debugPrint('ERROR: Failed to convert NOTAMs map to list: $e');
      return [];
    }
  }
  
  /// Convert stored Weather Map back to List<Weather> objects
  static List<Weather> _convertWeatherMapToList(Map<String, dynamic> weatherMap) {
    try {
      debugPrint('DEBUG: Converting weather map with ${weatherMap.length} entries');
      final List<Weather> weather = [];
      
      for (final entry in weatherMap.entries) {
        final weatherKey = entry.key;
        final weatherData = entry.value as Map<String, dynamic>;
        
        // Extract ICAO from the key (format: "TYPE_ICAO_briefingId")
        final icao = weatherData['icao'] as String? ?? '';
        
        debugPrint('DEBUG: Converting weather for $weatherKey (ICAO: $icao) - Type: ${weatherData['type']}, Raw: ${weatherData['rawText']?.toString().substring(0, 30)}...');
        
        try {
          final weatherObj = Weather.fromJson(weatherData);
          weather.add(weatherObj);
          debugPrint('DEBUG: Successfully converted weather for $icao');
        } catch (e) {
          debugPrint('WARNING: Failed to convert weather for $icao: $e');
          // Continue with other weather
        }
      }
      
      debugPrint('DEBUG: Converted ${weather.length} weather objects');
      return weather;
    } catch (e) {
      debugPrint('ERROR: Failed to convert weather map to list: $e');
      return [];
    }
  }
  
  /// Reconstruct Airport objects from stored data
  static List<Airport> _reconstructAirports(
    List<String> airportCodes, 
    List<Notam> notams, 
    List<Weather> weather
  ) {
    try {
      final List<Airport> airports = [];
      
      for (final code in airportCodes) {
        // Find NOTAMs for this airport
        final airportNotams = notams.where((n) => n.icao == code).toList();
        
        // Find weather for this airport
        final airportWeather = weather.where((w) => w.icao == code).toList();
        
        // Create airport object
        final airport = Airport(
          icao: code,
          name: _getAirportName(code), // We'll need to implement this
          city: '', // Placeholder
          latitude: 0.0, // Placeholder
          longitude: 0.0, // Placeholder
          systems: {}, // Placeholder
          runways: [], // Placeholder
          navaids: [], // Placeholder
        );
        
        airports.add(airport);
      }
      
      return airports;
    } catch (e) {
      debugPrint('ERROR: Failed to reconstruct airports: $e');
      return [];
    }
  }
  
  /// Convert List<Notam> to storage Map format
  static Map<String, dynamic> _convertNotamsListToMap(List<Notam> notams) {
    try {
      final Map<String, Map<String, dynamic>> notamsMap = {};
      
      for (final notam in notams) {
        // Store by NOTAM ID as key, not by ICAO code
        notamsMap[notam.id] = notam.toJson();
      }
      
      return notamsMap;
    } catch (e) {
      debugPrint('ERROR: Failed to convert NOTAMs list to map: $e');
      return {};
    }
  }
  
  /// Convert List<Weather> to storage Map format
  static Map<String, dynamic> _convertWeatherListToMap(List<Weather> weather) {
    try {
      final Map<String, Map<String, dynamic>> weatherMap = {};
      
      // Generate a unique briefing ID for weather keys
      final briefingId = 'briefing_${DateTime.now().millisecondsSinceEpoch}';
      
      for (final weatherObj in weather) {
        weatherMap['${weatherObj.icao}_$briefingId'] = weatherObj.toJson();
      }
      
      return weatherMap;
    } catch (e) {
      debugPrint('ERROR: Failed to convert weather list to map: $e');
      return {};
    }
  }
  
  /// Extract airport codes from Flight object
  static List<String> _extractAirportCodes(Flight flight) {
    final List<String> codes = [];
    
    if (flight.departure.isNotEmpty) {
      codes.add(flight.departure);
    }
    
    if (flight.destination.isNotEmpty) {
      codes.add(flight.destination);
    }
    
    if (flight.alternates.isNotEmpty) {
      codes.addAll(flight.alternates);
    }
    
    return codes;
  }
  
  /// Get airport name from code (placeholder - will need airport database)
  static String _getAirportName(String code) {
    // TODO: Implement airport name lookup from database
    // For now, return the code as a placeholder
    return code;
  }
  
  /// Validate that a briefing has sufficient data quality
  /// 
  /// Returns true if the briefing has at least:
  /// - 1 airport
  /// - At least 1 NOTAM or weather report per airport (if available)
  static bool validateBriefingDataQuality(Briefing briefing) {
    try {
      // Must have at least 1 airport
      if (briefing.airports.isEmpty) {
        debugPrint('WARNING: Briefing has no airports');
        return false;
      }
      
      // Check data completeness per airport
      for (final airportCode in briefing.airports) {
        final hasNotams = briefing.notams.containsKey(airportCode) && 
                         (briefing.notams[airportCode] as List).isNotEmpty;
        final hasWeather = briefing.weather.containsKey(airportCode);
        
        // It's okay if an airport has no NOTAMs (small airports often don't)
        // But we should have weather data for major airports
        if (!hasWeather) {
          debugPrint('WARNING: Airport $airportCode has no weather data');
          // Don't fail validation for missing weather, just warn
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('ERROR: Failed to validate briefing data quality: $e');
      return false;
    }
  }
} 