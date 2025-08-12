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
  
  /// Get navaids for a specific airport by ICAO code
  static Future<List<Navaid>> getNavaidsByICAO(String icaoCode) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      // First, get the airport's coordinates
      final airports = await getAirportsByICAOCodes([icaoCode]);
      if (airports.isEmpty) {
        print('DEBUG: Airport $icaoCode not found');
        return [];
      }
      
      final airport = airports.first;
      final lat = airport.latitude;
      final lon = airport.longitude;
      
      if (lat == 0.0 && lon == 0.0) {
        print('DEBUG: Airport $icaoCode has no valid coordinates');
        return [];
      }
      
      print('DEBUG: Searching navaids near $icaoCode at coordinates ($lat, $lon)');
      
      // Search for navaids within 10km of the airport (10000 meters)
      final response = await http.get(
        Uri.parse('$_baseUrl/navaids?pos=$lat,$lon&dist=10000&limit=50'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final navaids = _parseNavaids(data['items'] ?? []);
        
        print('DEBUG: Found ${navaids.length} navaids within 10km of $icaoCode');
        navaids.take(5).forEach((navaid) {
          print('DEBUG: - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency}');
        });
        
        return navaids;
      } else {
        print('DEBUG: Failed to get navaids for $icaoCode: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('DEBUG: Error fetching navaids for $icaoCode: $e');
      return [];
    }
  }
  
  /// Get navaids by geographic bounds
  static Future<List<Navaid>> getNavaidsByBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    int limit = 100,
  }) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/navaids?north=$north&south=$south&east=$east&west=$west&limit=$limit'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseNavaids(data['items'] ?? []);
      } else {
        throw Exception('Failed to get navaids by bounds: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting navaids by bounds: $e');
    }
  }
  
  /// Search navaids by type (VOR, ILS, TACAN, NDB, LOC, GLS)
  static Future<List<Navaid>> searchNavaidsByType(String type, {int limit = 50}) async {
    if (_apiKey == null) {
      throw Exception('OpenAIP API key not found in environment variables');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/navaids?type=$type&limit=$limit'),
        headers: {
          'x-openaip-api-key': _apiKey!,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseNavaids(data['items'] ?? []);
      } else {
        throw Exception('Failed to search navaids by type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching navaids by type: $e');
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
      
      // Parse navaids if available in the airport response
      final navaids = (item['navaids'] as List<dynamic>?)?.map((navaid) {
        return Navaid(
          identifier: navaid['identifier'] ?? navaid['name'] ?? '',
          frequency: parseNavaidFrequency(navaid['frequency']),
          runway: navaid['runway']?.toString() ?? '',
          type: parseNavaidType(navaid['type']),
          isPrimary: navaid['isPrimary'] ?? false,
          isBackup: navaid['isBackup'] ?? false,
          status: parseNavaidStatus(navaid['status']),
          notes: navaid['notes'] ?? navaid['description'] ?? '',
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
        runways: runways, // Keep runway objects with length data
        navaids: navaids, // Include navaid data if available
      );
    }).toList();
  }
  
  /// Parse navaid data from OpenAIP API response
  static List<Navaid> _parseNavaids(List<dynamic> items) {
    return items.map((item) {
      final originalType = parseNavaidType(item['type']);
      final frequency = parseNavaidFrequency(item['frequency']);
      final identifier = item['identifier'] ?? item['name'] ?? '';
      final runway = item['runway']?.toString() ?? '';
      
      // Apply corrections based on frequency and known issues
      final correctedType = correctNavaidType(originalType, frequency, identifier);
      
              return Navaid(
          identifier: identifier,
          frequency: frequency,
          runway: runway,
          type: correctedType,
          isPrimary: item['isPrimary'] ?? false,
          isBackup: item['isBackup'] ?? false,
          status: parseNavaidStatus(item['status']),
          notes: item['notes'] ?? item['description'] ?? '',
        );
    }).toList();
  }
  
  /// Parse navaid type from OpenAIP format
  static String parseNavaidType(dynamic type) {
    if (type == null) return '(Unknown)';
    
    // Convert to int if it's a string
    int typeInt;
    if (type is String) {
      typeInt = int.tryParse(type) ?? -1;
    } else if (type is int) {
      typeInt = type;
    } else {
      return '(Unknown)';
    }
    
    // Map integer types to readable names based on OpenAIP documentation
    switch (typeInt) {
      case 0: return 'NDB';
      case 1: return 'VOR';
      case 2: return 'DME';
      case 3: return 'TACAN';
      case 4: return 'ILS';
      case 5: return 'LOC';
      case 6: return 'GLS';
      case 7: return 'MLS';
      case 8: return 'VORTAC';
      default: return '(Unknown)';
    }
  }
  
  /// Correct navaid type based on known OpenAIP misclassifications
  static String correctNavaidType(String originalType, String frequency, String identifier) {
    // Known corrections for specific navaids where OpenAIP has wrong type codes
    if (identifier == 'SY' && frequency.contains('112.100')) {
      return 'DME'; // SY is actually a DME, not NDB
    }

    if (identifier == 'CB' && frequency.contains('116.700')) {
      return 'VOR/DME'; // CB 116.7 is VOR/DME, not ILS
    }

    if (identifier == 'CB' && frequency.contains('263.000')) {
      return 'NDB'; // CB 263.0 is NDB, not DME
    }

    return originalType;
  }

  static String parseNavaidStatus(dynamic status) {
    if (status == null) return 'UNKNOWN';
    
    if (status is String) {
      return status.toUpperCase();
    }
    
    return 'UNKNOWN';
  }

  static String parseNavaidFrequency(dynamic frequency) {
    if (frequency == null) return '';
    
    // Handle frequency object format from OpenAIP
    if (frequency is Map<String, dynamic>) {
      final value = frequency['value']?.toString() ?? '';
      final unit = frequency['unit'];
      
      // Unit 1 = MHz, Unit 2 = kHz, etc.
      if (unit == 1) {
        return '$value MHz';
      } else if (unit == 2) {
        return '$value kHz';
      } else {
        return value;
      }
    }
    
    // Fallback for string format
    return frequency.toString();
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