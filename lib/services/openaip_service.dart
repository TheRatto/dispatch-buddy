import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/airport.dart';
import '../models/airport_infrastructure.dart';

class OpenAIPService {
  static const String _baseUrl = 'https://api.core.openaip.net/api';
  
  /// Get API key from environment variables
  static String? get _apiKey => dotenv.env['OPENAIP_API_KEY'];
  
  /// Search for airports by name
  static Future<List<Airport>> searchAirports(String query, {int limit = 10}) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/airports?search=$query&limit=$limit'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseAirports(data['items'] ?? []);
      } else {
        throw Exception('Failed to search airports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching airports: $e');
    }
  }
  
  /// Get airport by ICAO code
  static Future<Airport?> getAirportByICAO(String icaoCode) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      // Search by ICAO code - OpenAIP uses exact match
      final response = await http.get(
        Uri.parse('$_baseUrl/airports?search=$icaoCode&limit=10'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final airports = _parseAirports(data['items'] ?? []);
        
        // Find exact ICAO match
        final exactMatch = airports.where((airport) => 
          airport.icao.toUpperCase() == icaoCode.toUpperCase()
        ).firstOrNull;
        
        return exactMatch;
      } else {
        throw Exception('Failed to get airport: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting airport: $e');
    }
  }
  
  /// Get multiple airports by ICAO codes (for flight planning)
  static Future<List<Airport>> getAirportsByICAOCodes(List<String> icaoCodes) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    final airports = <Airport>[];
    
    for (final icaoCode in icaoCodes) {
      try {
        final airport = await getAirportByICAO(icaoCode);
        if (airport != null) {
          airports.add(airport);
        }
      } catch (e) {
        print('Warning: Could not fetch airport $icaoCode: $e');
      }
    }
    
    return airports;
  }
  
  /// Get airports by geographic bounds
  static Future<List<Airport>> getAirportsByBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    int limit = 50,
  }) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/airports?north=$north&south=$south&east=$east&west=$west&limit=$limit'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseAirports(data['items'] ?? []);
      } else {
        throw Exception('Failed to get airports by bounds: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting airports by bounds: $e');
    }
  }
  
  /// Parse airport data from OpenAIP API response
  static List<Airport> _parseAirports(List<dynamic> items) {
    return items.map((item) {
      final runways = (item['runways'] as List<dynamic>?)?.map((runway) {
        return Runway(
          identifier: runway['designator'] ?? '',
          length: runway['dimension']?['length']?['value']?.toDouble() ?? 0.0,
          width: runway['dimension']?['width']?['value']?.toDouble() ?? 0.0,
          surface: _parseSurfaceType(runway['surface']?['mainComposite']),
          hasLighting: runway['pilotCtrlLighting'] ?? false,
          approaches: [], // OpenAIP doesn't provide approach data in basic response
        );
      }).toList() ?? [];
      
      final frequencies = (item['frequencies'] as List<dynamic>?)?.map((freq) {
        return Frequency(
          value: freq['value'] ?? '',
          type: freq['type']?.toString() ?? '',
          name: freq['name'] ?? '',
        );
      }).toList() ?? [];
      
      final coordinates = item['geometry']?['coordinates'] as List<dynamic>?;
      final latitude = coordinates?.isNotEmpty == true ? coordinates![1].toDouble() : 0.0;
      final longitude = coordinates?.isNotEmpty == true ? coordinates![0].toDouble() : 0.0;
      
      return Airport(
        name: item['name'] ?? '',
        icao: item['icaoCode'] ?? '',
        city: item['country'] ?? '', // Using country as city for now
        latitude: latitude,
        longitude: longitude,
        systems: {}, // OpenAIP doesn't provide system status
        runways: runways.map((r) => r.identifier).toList(), // Convert to string list
        navaids: [], // OpenAIP doesn't provide navaid list in basic response
      );
    }).toList();
  }
  
  /// Parse surface type from OpenAIP format
  static String _parseSurfaceType(dynamic surfaceType) {
    if (surfaceType == null) return 'Unknown';
    
    switch (surfaceType) {
      case 0: return 'Asphalt';
      case 1: return 'Concrete';
      case 2: return 'Grass';
      case 12: return 'Dirt';
      case 22: return 'Gravel';
      default: return 'Unknown';
    }
  }
  
  /// Parse airport type from OpenAIP format
  static String _parseAirportType(dynamic type) {
    if (type == null) return 'Unknown';
    
    switch (type) {
      case 0: return 'International';
      case 2: return 'Domestic';
      case 5: return 'Military';
      case 6: return 'Private';
      case 7: return 'Heliport';
      case 9: return 'Regional';
      case 13: return 'Ultralight';
      default: return 'Unknown';
    }
  }
}

/// Frequency model for radio frequencies
class Frequency {
  final String value;
  final String type;
  final String name;
  
  Frequency({
    required this.value,
    required this.type,
    required this.name,
  });
} 