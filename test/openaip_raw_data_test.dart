import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  setUpAll(() async {
    // Load environment variables for testing
    await dotenv.load(fileName: '.env');
  });

  group('OpenAIP Raw Data Structure', () {
    test('should show complete raw data structure for YSSY', () async {
      final apiKey = dotenv.env['OPENAIP_API_KEY'];
      if (apiKey == null) {
        fail('OpenAIP API key not found in environment variables');
      }

      try {
        // Make direct API call to see raw response
        final response = await http.get(
          Uri.parse('https://api.core.openaip.net/api/airports?search=YSSY&limit=1'),
          headers: {
            'x-openaip-api-key': apiKey,
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data['items'] as List<dynamic>?;
          
          if (items != null && items.isNotEmpty) {
            final airport = items.first;
            
            print('\n🔍 COMPLETE OPENAIP RAW DATA STRUCTURE FOR YSSY:');
            print('=' * 80);
            
            // Show all top-level fields
            print('\n📋 TOP-LEVEL FIELDS:');
            airport.keys.forEach((key) {
              final value = airport[key];
              if (value is Map || value is List) {
                print('  - $key: ${value.runtimeType} (${value is Map ? value.length : value.length} items)');
              } else {
                print('  - $key: $value');
              }
            });

            // Show detailed runway information
            if (airport['runways'] != null) {
              print('\n🛫 RUNWAY DETAILS:');
              final runways = airport['runways'] as List<dynamic>;
              for (int i = 0; i < runways.length; i++) {
                final runway = runways[i];
                print('  Runway ${i + 1}:');
                runway.keys.forEach((key) {
                  final value = runway[key];
                  if (value is Map) {
                    print('    - $key: ${value.runtimeType} (${value.length} items)');
                  } else {
                    print('    - $key: $value');
                  }
                });
                
                // Show detailed runway structure for first runway
                if (i == 0) {
                  print('    📋 First runway complete structure:');
                  _printNestedMap(runway, '      ');
                }
              }
            }

            // Show frequency information
            if (airport['frequencies'] != null) {
              print('\n📻 FREQUENCY DETAILS:');
              final frequencies = airport['frequencies'] as List<dynamic>;
              for (int i = 0; i < frequencies.length; i++) {
                final freq = frequencies[i];
                print('  Frequency ${i + 1}:');
                freq.keys.forEach((key) {
                  print('    - $key: ${freq[key]}');
                });
              }
            }

            // Show geometry information
            if (airport['geometry'] != null) {
              print('\n📍 GEOMETRY DETAILS:');
              final geometry = airport['geometry'] as Map<String, dynamic>;
              geometry.keys.forEach((key) {
                final value = geometry[key];
                if (value is List) {
                  print('  - $key: List (${value.length} items)');
                  if (key == 'coordinates' && value.isNotEmpty) {
                    print('    - Coordinates: ${value.first}');
                  }
                } else {
                  print('  - $key: $value');
                }
              });
            }

            // Show any other important fields
            print('\n📊 OTHER IMPORTANT FIELDS:');
            final importantFields = ['type', 'status', 'elevation', 'magneticVariation'];
            for (final field in importantFields) {
              if (airport.containsKey(field)) {
                print('  - $field: ${airport[field]}');
              }
            }

            print('\n' + '=' * 80);
            
          } else {
            print('❌ No airport data found for YSSY');
          }
        } else {
          print('❌ API request failed: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        
      } catch (e) {
        print('❌ Error fetching raw data: $e');
      }
    });

    test('should show data structure for multiple airports', () async {
      final apiKey = dotenv.env['OPENAIP_API_KEY'];
      if (apiKey == null) {
        fail('OpenAIP API key not found in environment variables');
      }

      try {
        // Get multiple airports to compare data structures
        final airports = ['YSSY', 'YMML', 'YPPH'];
        
        for (final icao in airports) {
          final response = await http.get(
            Uri.parse('https://api.core.openaip.net/api/airports?search=$icao&limit=1'),
            headers: {
              'x-openaip-api-key': apiKey,
              'Accept': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final items = data['items'] as List<dynamic>?;
            
            if (items != null && items.isNotEmpty) {
              final airport = items.first;
              
              print('\n🔍 DATA STRUCTURE FOR $icao:');
              print('  - Name: ${airport['name']}');
              print('  - ICAO: ${airport['icaoCode']}');
              print('  - Country: ${airport['country']}');
              print('  - Type: ${airport['type']}');
              print('  - Status: ${airport['status']}');
              print('  - Runways: ${(airport['runways'] as List<dynamic>?)?.length ?? 0}');
              print('  - Frequencies: ${(airport['frequencies'] as List<dynamic>?)?.length ?? 0}');
              
              // Show coordinates if available
              final coordinates = airport['geometry']?['coordinates'] as List<dynamic>?;
              if (coordinates != null && coordinates.isNotEmpty) {
                print('  - Coordinates: [${coordinates[0]}, ${coordinates[1]}]');
              }
            }
          }
        }
        
      } catch (e) {
        print('❌ Error fetching multiple airports: $e');
      }
    });
  });
}

void _printNestedMap(Map<dynamic, dynamic> map, String indent) {
  map.forEach((key, value) {
    if (value is Map) {
      print('$indent$key: Map (${value.length} items)');
      _printNestedMap(value as Map<dynamic, dynamic>, '$indent  ');
    } else if (value is List) {
      print('$indent$key: List (${value.length} items)');
      if (value.isNotEmpty && value.first is Map) {
        print('$indent  First item structure:');
        _printNestedMap(value.first as Map<dynamic, dynamic>, '$indent    ');
      }
    } else {
      print('$indent$key: $value');
    }
  });
} 