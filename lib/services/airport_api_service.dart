import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airport.dart';

class AirportApiService {
  static const String _baseUrl = 'https://aviationweather.gov/api/data/airport';
  static const Duration _cacheDuration = Duration(hours: 24);
  static final Map<String, Airport> _cache = {};
  
  // Utility function to convert ALL CAPS to Title Case
  static String _convertToTitleCase(String text) {
    if (text.isEmpty) return text;
    
    // Handle common aviation abbreviations that should stay uppercase
    final aviationAbbreviations = [
      'INTL', 'INT', 'MUNI', 'MUN', 'REG', 'CTR', 'CTY', 'CO', 'COUNTRY',
      'AIRPORT', 'AIR', 'FIELD', 'FLD', 'BASE', 'AFB', 'NAS', 'NAF', 'NAVAL',
      'ARMY', 'MIL', 'MILITARY', 'CIV', 'IVILIAN', 'PRIVATE', 'PVT'
    ];
    
    // Split by slashes first, then process each part
    final slashParts = text.split('/');
    final processedSlashParts = slashParts.map((slashPart) {
      // Split into words and process each
      final words = slashPart.split(' ');
      final processedWords = words.map((word) {
        // Keep aviation abbreviations in uppercase
        if (aviationAbbreviations.contains(word.toUpperCase())) {
          return word.toUpperCase();
        }
        
        // Convert to title case
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).toList();
      
      return processedWords.join(' ');
    }).toList();
    
    return processedSlashParts.join('/');
  }
  
  // Extract city name from airport data, focusing on city only
  static String _extractCityName(String airportName, String? state, String? country) {
    // Remove common airport suffixes from the name
    final cleanName = airportName
        .replaceAll(RegExp(r'\s+(INTL|INT|MUNI|MUN|REG|CTR|AIRPORT|AIR|FIELD|FLD|BASE|AFB|NAS|NAF)\s*$', caseSensitive: false), '')
        .trim();
    
    // If we have a state/country that looks like a city name, use it
    if (state != null && state.isNotEmpty && state != '-' && state.length > 2) {
      // Check if state looks like a city name (not a 2-letter code)
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(state)) {
        return _convertToTitleCase(state);
      }
    }
    
    // Extract city from airport name (usually the first part before a slash or comma)
    final parts = cleanName.split(RegExp(r'[/,]+'));
    if (parts.isNotEmpty) {
      final cityPart = parts[0].trim();
      if (cityPart.isNotEmpty) {
        return _convertToTitleCase(cityPart);
      }
    }
    
    // Fallback: use the cleaned airport name
    return _convertToTitleCase(cleanName);
  }

  static Future<Airport?> fetchAirportData(String icaoCode) async {
    // Check cache first
    if (_cache.containsKey(icaoCode)) {
      print('DEBUG: Using cached airport data for $icaoCode');
      return _cache[icaoCode];
    }
    
    print('DEBUG: Fetching airport data for $icaoCode from API');
    try {
      final url = Uri.parse('$_baseUrl?ids=$icaoCode&format=json');
      print('DEBUG: API URL: $url');
      
      final response = await http.get(url);
      print('DEBUG: API response status: ${response.statusCode}');
      print('DEBUG: API response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: API response data length: ${data.length}');
        
        if (data.isNotEmpty) {
          final airport = data.first;
          print('DEBUG: API response for $icaoCode: $airport');
          
          // Extract and clean the data
          final name = airport['name'] as String? ?? '';
          final state = airport['state'] as String?;
          final country = airport['country'] as String?;
          
          print('DEBUG: Raw data - name: "$name", state: "$state", country: "$country"');
          
          // Convert name to title case and extract city
          final cleanName = _convertToTitleCase(name);
          final city = _extractCityName(name, state, country);
          print('DEBUG: Extracted city for $icaoCode: "$city" from name: "$name", state: "$state", country: "$country"');
          
          final latitude = double.tryParse(airport['lat']?.toString() ?? '0') ?? 0.0;
          final longitude = double.tryParse(airport['lon']?.toString() ?? '0') ?? 0.0;
          final airportObj = Airport(
            icao: icaoCode,
            name: cleanName,
            city: city,
            latitude: latitude,
            longitude: longitude,
            systems: {
              'runways': SystemStatus.green,
              'navaids': SystemStatus.green,
              'taxiways': SystemStatus.green,
              'lighting': SystemStatus.green,
            },
            runways: [],
            navaids: [],
          );
          print('DEBUG: Created Airport object for $icaoCode with city: "$city"');
          _cache[icaoCode] = airportObj;
          return airportObj;
        } else {
          print('DEBUG: API returned empty data for $icaoCode');
        }
      } else {
        print('DEBUG: API call failed for $icaoCode. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching airport data for $icaoCode: $e');
    }
    
    print('DEBUG: Returning null for $icaoCode');
    return null;
  }

  /// Get cached airport data
  static Airport? getCachedAirport(String icao) {
    return _cache[icao];
  }

  /// Clear cache (useful for testing or memory management)
  static void clearCache() {
    _cache.clear();
  }

  /// Get cache size for debugging
  static int getCacheSize() {
    return _cache.length;
  }
} 