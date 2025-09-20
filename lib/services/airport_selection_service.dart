import 'package:flutter/foundation.dart';
import '../providers/flight_provider.dart';
import '../services/briefing_storage_service.dart';
import '../models/briefing.dart';
import '../models/flight.dart';
import '../models/airport.dart';

/// Airport Selection Service
/// 
/// Handles airport selection business logic and integration with briefing generation.
class AirportSelectionService {
  static const int _maxAirports = 10;

  /// Validate airport selections
  /// 
  /// Returns true if selections are valid, false otherwise.
  static bool validateSelections(List<String> airports) {
    if (airports.isEmpty) {
      debugPrint('AirportSelectionService: No airports selected');
      return false;
    }
    
    if (airports.length > _maxAirports) {
      debugPrint('AirportSelectionService: Too many airports selected (${airports.length} > $_maxAirports)');
      return false;
    }
    
    // Check for duplicates
    final uniqueAirports = airports.toSet();
    if (uniqueAirports.length != airports.length) {
      debugPrint('AirportSelectionService: Duplicate airports found');
      return false;
    }
    
    // Check for valid ICAO codes (basic validation)
    for (final airport in airports) {
      if (airport.length != 4 || !airport.startsWith(RegExp(r'[A-Z]'))) {
        debugPrint('AirportSelectionService: Invalid ICAO code: $airport');
        return false;
      }
    }
    
    return true;
  }

  /// Format selected airports for briefing generation
  /// 
  /// Returns a formatted string representation of the selected airports.
  static String formatAirportsForBriefing(List<String> airports) {
    if (airports.isEmpty) return '';
    
    // Sort airports alphabetically for consistency
    final sortedAirports = List<String>.from(airports)..sort();
    
    // Format as space-separated ICAO codes
    return sortedAirports.join(' ');
  }

  /// Generate briefing from selected airports
  /// 
  /// Integrates with existing FlightProvider to generate a briefing.
  static Future<bool> generateBriefingFromAirports(
    List<String> airports,
    FlightProvider flightProvider,
  ) async {
    try {
      debugPrint('AirportSelectionService: Generating briefing for airports: $airports');
      
      // Validate selections
      if (!validateSelections(airports)) {
        debugPrint('AirportSelectionService: Invalid airport selections');
        return false;
      }
      
      // Format airports for briefing
      final formattedAirports = formatAirportsForBriefing(airports);
      debugPrint('AirportSelectionService: Formatted airports: $formattedAirports');
      
      // Create a new flight with the selected airports
      final flight = Flight(
        id: 'quick_start_${DateTime.now().millisecondsSinceEpoch}',
        route: airports.join(' '),
        departure: airports.isNotEmpty ? airports.first : 'UNKNOWN',
        destination: airports.length > 1 ? airports.last : 'UNKNOWN',
        etd: DateTime.now().add(const Duration(hours: 1)),
        flightLevel: 'FL350',
        alternates: airports.length > 2 ? airports.skip(1).take(airports.length - 2).toList() : [],
        createdAt: DateTime.now(),
        airports: airports.map((icao) => Airport(
          icao: icao,
          name: '$icao Airport',
          city: 'Unknown City',
          latitude: 0.0,
          longitude: 0.0,
          systems: {},
          runways: [],
          navaids: [],
        )).toList(),
        notams: [],
        weather: [],
      );
      
      // Set the current flight
      flightProvider.setCurrentFlight(flight);
      
      // Refresh flight data to fetch NOTAMs and weather
      await flightProvider.refreshFlightData();
      
      debugPrint('AirportSelectionService: Briefing generated successfully');
      
      // Auto-save the briefing
      await _autoSaveBriefing(airports, flightProvider);
      
      return true;
      
    } catch (e) {
      debugPrint('AirportSelectionService: Error generating briefing: $e');
      return false;
    }
  }

  /// Auto-save the generated briefing
  static Future<void> _autoSaveBriefing(
    List<String> airports,
    FlightProvider flightProvider,
  ) async {
    try {
      debugPrint('AirportSelectionService: Auto-saving briefing...');
      
      // Get current flight data from provider
      final currentFlight = flightProvider.currentFlight;
      if (currentFlight == null) {
        debugPrint('AirportSelectionService: No current flight data to save');
        return;
      }
      
      // Create briefing name from airports
      final name = _generateBriefingName(airports);
      
      // Convert flight data to briefing format
      final briefing = Briefing.create(
        name: name,
        airports: airports,
        notams: {
          for (int i = 0; i < currentFlight.notams.length; i++)
            'notam_$i': currentFlight.notams[i].toJson()
        },
        weather: {
          for (int i = 0; i < currentFlight.weather.length; i++)
            'weather_$i': currentFlight.weather[i].toJson()
        },
        firstLastLight: {
          // Include first/last light data from FlightProvider
          for (final entry in flightProvider.firstLastLightByIcao.entries)
            'firstlastlight_${entry.key}': entry.value.toJson()
        },
      );
      
      // Save briefing
      final success = await BriefingStorageService.saveBriefing(briefing);
      
      if (success) {
        debugPrint('AirportSelectionService: Briefing saved successfully: $name');
      } else {
        debugPrint('AirportSelectionService: Failed to save briefing');
      }
      
    } catch (e) {
      debugPrint('AirportSelectionService: Error auto-saving briefing: $e');
    }
  }

  /// Generate a user-friendly name for the briefing
  static String _generateBriefingName(List<String> airports) {
    if (airports.isEmpty) return 'Quick Start Briefing';
    
    if (airports.length == 1) {
      return '${airports.first} Briefing';
    }
    
    if (airports.length <= 3) {
      return airports.join(' → ');
    }
    
    // For more than 3 airports, show first and last with count
    return '${airports.first} → ... → ${airports.last} (${airports.length} airports)';
  }

  /// Get selection summary for display
  static String getSelectionSummary(List<String> airports) {
    if (airports.isEmpty) {
      return 'No airports selected';
    }
    
    if (airports.length == 1) {
      return '1 airport selected: ${airports.first}';
    }
    
    return '${airports.length} airports selected: ${airports.take(3).join(', ')}${airports.length > 3 ? '...' : ''}';
  }

  /// Check if selections are at maximum limit
  static bool isAtMaxLimit(List<String> airports) {
    return airports.length >= _maxAirports;
  }

  /// Get remaining selection count
  static int getRemainingSelections(List<String> airports) {
    return _maxAirports - airports.length;
  }

  /// Get maximum selection limit
  static int get maxSelections => _maxAirports;
}
