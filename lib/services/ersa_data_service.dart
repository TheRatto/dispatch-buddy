import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/airport_infrastructure.dart';

/// Service for handling ERSA (En Route Supplement Australia) data
/// Provides airport infrastructure data for Australian airports (ICAO starting with Y)
class ERSADataService {
  static const String _ersaDataPath = 'assets/airport_data/250612_ersa/';
  static Map<String, dynamic>? _ersaCache;
  static bool _isLoadingCache = false;
  
  /// Get airport infrastructure data from ERSA
  /// Returns null for non-Australian airports or if data not available
  static Future<AirportInfrastructure?> getAirportInfrastructure(String icao) async {
    final upperIcao = icao.toUpperCase();
    
    print('ERSADataService: getAirportInfrastructure called for $upperIcao');
    
    // Only handle Australian airports (ICAO starting with Y)
    if (!upperIcao.startsWith('Y')) {
      print('ERSADataService: Not an Australian airport, returning null');
      return null;
    }
    
    try {
      // Load ERSA data if not already cached
      if (_ersaCache == null && !_isLoadingCache) {
        print('ERSADataService: Loading ERSA cache...');
        _isLoadingCache = true;
        await _loadERSACache();
        _isLoadingCache = false;
        print('ERSADataService: Cache loading completed, cache size: ${_ersaCache?.length}');
      }
      
      // Wait if cache is currently loading
      while (_isLoadingCache) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // Ensure cache is loaded before checking
      if (_ersaCache == null) {
        print('ERSADataService: Cache failed to load');
        return null;
      }
      
      // Get airport data from cache (after ensuring cache is loaded)
      final airportData = _ersaCache![upperIcao];
      if (airportData == null) {
        print('ERSADataService: No data found for $upperIcao in cache');
        return null;
      }
      
      print('ERSADataService: Found data for $upperIcao, converting...');
      
      // Convert ERSA data to AirportInfrastructure format
      return _convertERSADataToInfrastructure(airportData);
      
    } catch (e) {
      print('ERSADataService: Error loading airport $upperIcao: $e');
      return null;
    }
  }
  
  /// Load ERSA data cache from JSON files
  static Future<void> _loadERSACache() async {
    try {
      _ersaCache = {};
      
      // Get list of all ERSA JSON files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for ERSA airport files
      final ersaFiles = manifestMap.keys
          .where((key) => key.startsWith(_ersaDataPath) && key.endsWith('.json'))
          .toList();
      
      // Load each airport file
      for (final filePath in ersaFiles) {
        try {
          final fileContent = await rootBundle.loadString(filePath);
          final airportData = json.decode(fileContent);
          
          // Extract ICAO from filename or data
          final icao = _extractICAOFromPath(filePath) ?? airportData['data']['icao'];
          if (icao != null) {
            _ersaCache![icao] = airportData;
          }
        } catch (e) {
          print('ERSADataService: Error loading file $filePath: $e');
        }
      }
      
      print('ERSADataService: Loaded ${_ersaCache!.length} airports from ERSA data');
      
    } catch (e) {
      print('ERSADataService: Error loading ERSA cache: $e');
      _ersaCache = {};
    }
  }
  
  /// Extract ICAO code from file path
  static String? _extractICAOFromPath(String filePath) {
    final fileName = filePath.split('/').last;
    if (fileName.endsWith('.json')) {
      return fileName.substring(0, fileName.length - 5); // Remove .json
    }
    return null;
  }
  
  /// Convert ERSA data format to AirportInfrastructure
  static AirportInfrastructure _convertERSADataToInfrastructure(Map<String, dynamic> ersaData) {
    final data = ersaData['data'];
    final icao = data['icao'];
    
    print('ERSADataService: Converting airport $icao');
    print('ERSADataService: Navaids data: ${data['navaids']}');
    
    // Convert runways
    final List<Runway> runways = [];
    if (data['runways'] != null) {
      for (final runwayData in data['runways']) {
        runways.add(_convertERSARunway(runwayData));
      }
    }
    
    // Convert navaids
    final List<Navaid> navaids = [];
    if (data['navaids'] != null) {
      for (final navaidData in data['navaids']) {
        navaids.add(_convertERSANavaid(navaidData));
      }
    }
    
    print('ERSADataService: Converted ${navaids.length} navaids');
    
    // Convert lighting
    final List<Lighting> lighting = [];
    if (data['lighting'] != null) {
      for (final lightingData in data['lighting']) {
        lighting.add(_convertERSALighting(lightingData));
      }
    }
    
    print('ERSADataService: Converted ${lighting.length} lighting systems');
    
    return AirportInfrastructure(
      icao: icao,
      runways: runways,
      taxiways: [], // ERSA doesn't provide taxiway data
      navaids: navaids,
      approaches: [], // Will be derived from navaids
      routes: [], // ERSA doesn't provide route data
      lighting: lighting,
      facilityStatus: {}, // Will be populated from NOTAMs
    );
  }
  
  /// Convert ERSA runway data to Runway model
  static Runway _convertERSARunway(Map<String, dynamic> runwayData) {
    final designation = runwayData['designation'];
    final lengthFeet = runwayData['length']?.toDouble() ?? 0.0; // JSON length is in feet
    final widthMeters = runwayData['width']?.toDouble() ?? 0.0; // JSON width is in meters
    final surface = runwayData['surface'] ?? 'Unknown';
    final lighting = runwayData['lighting'] as List<dynamic>? ?? [];
    
    // Convert lighting list to boolean
    final hasLighting = lighting.isNotEmpty;
    
    // Create approaches from navaids (will be populated later)
    final approaches = <Approach>[];
    
    return Runway(
      identifier: designation,
      length: lengthFeet, // Store as feet (from JSON)
      width: widthMeters, // Store as meters (from JSON)
      surface: surface,
      approaches: approaches,
      hasLighting: hasLighting,
      status: 'OPERATIONAL', // Default status
    );
  }
  
  /// Convert ERSA navaid data to Navaid model
  static Navaid _convertERSANavaid(Map<String, dynamic> navaidData) {
    final type = navaidData['type'] ?? 'Unknown';
    final ident = navaidData['ident'] ?? '';
    final freq = navaidData['freq']?.toDouble() ?? 0.0;
    final runway = navaidData['runway'];
    
    print('ERSADataService: Converting navaid - Type: $type, Ident: $ident, Freq: $freq, Runway: $runway');
    
    return Navaid(
      identifier: ident,
      type: type,
      frequency: freq.toString(),
      runway: runway ?? '',
      status: 'OPERATIONAL', // Default status
    );
  }

  /// Convert ERSA lighting data to Lighting model
  static Lighting _convertERSALighting(Map<String, dynamic> lightingData) {
    final type = lightingData['type'] ?? 'Unknown';
    final runway = lightingData['runway'] ?? '';
    final end = lightingData['end'] ?? 'both';
    
    // Extract category from type if it contains a dash (e.g., "HIAL-CAT I")
    String? category;
    if (type.contains('-')) {
      final parts = type.split('-');
      if (parts.length > 1) {
        category = parts.sublist(1).join('-'); // "CAT I", "CAT II", etc.
      }
    }
    
    // Clean up the type (remove category part)
    final cleanType = type.contains('-') ? type.split('-')[0] : type;
    
    print('ERSADataService: Converting lighting - Type: $cleanType, Runway: $runway, Category: $category');
    
    return Lighting(
      type: cleanType,
      runway: runway,
      end: end,
      status: 'OPERATIONAL', // Default status
      category: category,
    );
  }
  
  /// Integrate lighting data into runways
  static void _integrateLightingIntoRunways(List<Runway> runways, List<dynamic>? lightingData) {
    if (lightingData == null) return;
    
    // Note: Runway.hasLighting is final, so we can't modify it after creation
    // The lighting status is already set during runway creation based on the lighting array
    // This method is kept for future use if we need to process lighting data differently
  }
  
  /// Check if airport data is available in ERSA
  static bool isAirportAvailable(String icao) {
    final upperIcao = icao.toUpperCase();
    return upperIcao.startsWith('Y') && _ersaCache?.containsKey(upperIcao) == true;
  }
  
  /// Get parsing confidence for an airport
  static double? getParsingConfidence(String icao) {
    final upperIcao = icao.toUpperCase();
    final airportData = _ersaCache?[upperIcao];
    if (airportData != null) {
      return airportData['metadata']['parsingConfidence']?.toDouble();
    }
    return null;
  }
  
  /// Get validity period for an airport
  static Map<String, DateTime>? getValidityPeriod(String icao) {
    final upperIcao = icao.toUpperCase();
    final airportData = _ersaCache?[upperIcao];
    if (airportData != null) {
      final validityPeriod = airportData['metadata']['validityPeriod'];
      return {
        'start': DateTime.parse(validityPeriod['start']),
        'end': DateTime.parse(validityPeriod['end']),
      };
    }
    return null;
  }
  
  /// Get list of all available Australian airports
  static List<String> getAvailableAirports() {
    if (_ersaCache == null) return [];
    return _ersaCache!.keys.toList();
  }
  
  /// Check if data is still valid
  static bool isDataValid(String icao) {
    final validityPeriod = getValidityPeriod(icao);
    if (validityPeriod == null) return false;
    
    final now = DateTime.now();
    return now.isAfter(validityPeriod['start']!) && 
           now.isBefore(validityPeriod['end']!);
  }
} 