import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airport_infrastructure.dart';

/// Service to fetch navaid data from OurAirports database
/// OurAirports provides comprehensive, community-maintained aviation data
class OurAirportsService {
  static const String _baseUrl = 'https://davidmegginson.github.io/ourairports-data';
  static const String _navaidsUrl = '$_baseUrl/navaids.csv';
  
  /// Get navaids for a specific airport by ICAO code
  static Future<List<Navaid>> getNavaidsByICAO(String icaoCode) async {
    try {
      print('DEBUG: Fetching navaids from OurAirports for $icaoCode');
      
      final response = await http.get(Uri.parse(_navaidsUrl));
      
      if (response.statusCode == 200) {
        final csvData = response.body;
        final navaids = _parseCsvNavaids(csvData, icaoCode);
        
        print('DEBUG: Found ${navaids.length} navaids for $icaoCode from OurAirports');
        navaids.take(5).forEach((navaid) {
          print('DEBUG: - ${navaid.identifier} (${navaid.type}) - ${navaid.frequency}');
        });
        
        return navaids;
      } else {
        print('DEBUG: Failed to fetch OurAirports data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('DEBUG: Error fetching OurAirports navaids for $icaoCode: $e');
      return [];
    }
  }
  
  /// Parse CSV navaid data for a specific airport
  static List<Navaid> _parseCsvNavaids(String csvData, String icaoCode) {
    final lines = csvData.split('\n');
    final navaids = <Navaid>[];
    
    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      try {
        final fields = _parseCsvLine(line);
        if (fields.length < 15) continue; // Need at least 15 fields
        
        final associatedAirport = fields[19]; // associated_airport field (index 19)
        if (associatedAirport != icaoCode.toUpperCase()) continue;
        
        final identifier = fields[2]; // ident field
        final name = fields[3]; // name field
        final type = fields[4]; // type field
        final frequencyKhz = fields[5]; // frequency_khz field
        final latitude = double.tryParse(fields[6]) ?? 0.0; // latitude_deg
        final longitude = double.tryParse(fields[7]) ?? 0.0; // longitude_deg
        final elevation = fields[8]; // elevation_ft
        final country = fields[9]; // iso_country
        final usageType = fields[16]; // usageType
        final power = fields[17]; // power
        
        // Convert frequency from kHz to readable format
        final frequency = _formatFrequency(frequencyKhz);
        
        // Parse navaid type
        final navaidType = _parseNavaidType(type);
        
        // Determine status based on usage and power
        final status = _determineStatus(usageType, power);
        
        final navaid = Navaid(
          identifier: identifier,
          frequency: frequency,
          runway: '', // OurAirports doesn't provide runway association
          type: navaidType,
          isPrimary: usageType == 'BOTH' || usageType == 'HIGH',
          isBackup: usageType == 'LOW',
          status: status,
          notes: 'Elevation: ${elevation}ft, Power: $power',
        );
        
        navaids.add(navaid);
      } catch (e) {
        print('DEBUG: Error parsing CSV line $i: $e');
        continue;
      }
    }
    
    return navaids;
  }
  
  /// Parse a CSV line, handling quoted fields
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    String currentField = '';
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    // Add the last field
    fields.add(currentField);
    
    return fields;
  }
  
  /// Format frequency from kHz to readable format
  static String _formatFrequency(String frequencyKhz) {
    final khz = double.tryParse(frequencyKhz);
    if (khz == null) return '';
    
    if (khz >= 1000) {
      return '${(khz / 1000).toStringAsFixed(3)} MHz';
    } else {
      return '${khz.toStringAsFixed(0)} kHz';
    }
  }
  
  /// Parse navaid type from OurAirports format
  static String _parseNavaidType(String type) {
    switch (type.toUpperCase()) {
      case 'NDB':
        return 'NDB';
      case 'VOR':
        return 'VOR';
      case 'VOR-DME':
        return 'VOR/DME';
      case 'DME':
        return 'DME';
      case 'ILS':
        return 'ILS';
      case 'LOC':
        return 'LOC';
      case 'GLS':
        return 'GLS';
      case 'MLS':
        return 'MLS';
      case 'TACAN':
        return 'TACAN';
      case 'VORTAC':
        return 'VORTAC';
      default:
        return type.toUpperCase();
    }
  }
  
  /// Determine navaid status based on usage and power
  static String _determineStatus(String usageType, String power) {
    if (usageType == 'BOTH' || usageType == 'HIGH') {
      return 'OPERATIONAL';
    } else if (usageType == 'LOW') {
      return 'MAINTENANCE';
    } else {
      return 'UNKNOWN';
    }
  }
} 