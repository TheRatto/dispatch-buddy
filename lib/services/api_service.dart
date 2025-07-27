import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import 'dart:async';

class ApiService {
  // Use CORS proxy for web development
  final String _corsProxy = 'https://cors-anywhere.herokuapp.com/';
  final String _notamBaseUrl = 'https://external-api.faa.gov/notamapi/v1/notams';
  final String _weatherBaseUrl = 'https://aviationweather.gov/api/data/metar';
  final String _tafBaseUrl = 'https://aviationweather.gov/api/data/taf';

  String _getUrl(String baseUrl, {Map<String, String>? queryParams}) {
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final url = uri.toString();
    
    // Use CORS proxy only for web platform
    if (kIsWeb) {
      return '$_corsProxy$url';
    }
    return url;
  }

  Future<http.Response> _makeRequestWithRetry(Uri uri, {Map<String, String>? headers, int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        // SATCOM-optimized timeout: shorter initial timeout, longer for retries
        final timeout = Duration(seconds: i == 0 ? 8 : 15);
        
        final response = await http.get(uri, headers: headers)
            .timeout(timeout);
            
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500) { // Server error, worth retrying
          print('Attempt ${i + 1} failed with status ${response.statusCode}. Retrying...');
          // Exponential backoff for SATCOM: 2s, 4s, 8s
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        } else { // Client error, don't retry
          return response;
        }
      } catch (e) {
        print('Attempt ${i + 1} failed with exception: $e. Retrying...');
        if (i < retries - 1) {
          // Exponential backoff for SATCOM: 2s, 4s, 8s
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        } else {
          rethrow; // Rethrow on the last attempt
        }
      }
    }
    throw Exception('Failed to fetch data after $retries retries');
  }

  Future<List<Notam>> fetchNotams(String icao) async {
    try {
      print('DEBUG: 🔍 Attempting to fetch NOTAMs for $icao with offset-based pagination...');
      
      final List<Notam> allNotams = [];
      final Set<String> seenNotamIds = {}; // Track NOTAM IDs to avoid duplicates
      const int pageSize = 50; // Use 50 as page size since that seems to be the limit
      int totalFetched = 0;
      int offset = 0;
      
      // Try multiple sorting strategies to get different NOTAMs
      final List<Map<String, String>> sortStrategies = [
        {'sortBy': 'effectiveStartDate', 'sortOrder': 'Desc'}, // Most recent first
        {'sortBy': 'effectiveStartDate', 'sortOrder': 'Asc'},  // Oldest first
        {'sortBy': 'effectiveEndDate', 'sortOrder': 'Desc'},   // Longest duration first
        {'sortBy': 'effectiveEndDate', 'sortOrder': 'Asc'},    // Shortest duration first
      ];
      
      for (int strategyIndex = 0; strategyIndex < sortStrategies.length; strategyIndex++) {
        final strategy = sortStrategies[strategyIndex];
        print('DEBUG: 🔍 Trying sort strategy ${strategyIndex + 1}: ${strategy['sortBy']} ${strategy['sortOrder']}');
        
        offset = 0; // Reset offset for each strategy
        int strategyFetched = 0;
        
        while (true) {
          print('DEBUG: 🔍 Fetching page for $icao (strategy ${strategyIndex + 1}): offset=$offset, limit=$pageSize');
          
          final Map<String, String> queryParams = {
            'icaoLocation': icao, 
            'sortBy': strategy['sortBy']!, 
            'sortOrder': strategy['sortOrder']!,
            'limit': pageSize.toString(),
            'offset': offset.toString(),
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(), // Ensure fresh data
          };
          
          final url = _getUrl(_notamBaseUrl, queryParams: queryParams);

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

          print('DEBUG: 🔍 API URL: $url');

      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Origin': 'https://localhost',
          'client_id': clientId,
          'client_secret': clientSecret,
              'Connection': 'close', // SATCOM optimization: close connection after request
              'Cache-Control': 'no-cache, no-store, must-revalidate', // NO CACHING for aviation safety
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
            print('DEBUG: ✅ Strategy ${strategyIndex + 1}, Page ${(offset / pageSize) + 1}: Fetched ${items.length} NOTAMs for $icao');
            print('DEBUG: 🔍 API response body length: ${response.body.length} characters');
            
            if (items.isEmpty) {
              print('DEBUG: 🔍 No more NOTAMs found for $icao in strategy ${strategyIndex + 1} (empty page)');
              break; // No more results for this strategy
            }
            
            // Process items and track unique NOTAMs
            final List<Notam> pageNotams = [];
            int newNotamsInPage = 0;
            
            for (final item in items) {
              final notam = Notam.fromFaaJson(item);
              // Debug: Print full JSON for H5496/25 or H4696/25
              if (notam.id == 'H5496/25' || notam.id == 'H4696/25') {
                print('DEBUG: FOUND TARGET NOTAM: ${notam.id}');
                print('DEBUG: FULL FAA JSON: ${jsonEncode(item)}');
                print('DEBUG: NOTAM TEXT: ${notam.rawText}');
                print('DEBUG: DECODED TEXT: ${notam.decodedText}');
                print('DEBUG: Q CODE: ${notam.qCode}');
                print('DEBUG: Q CODE SUBJECT: ${Notam.getQCodeSubjectDescription(notam.qCode)}');
                print('DEBUG: Q CODE STATUS: ${Notam.getQCodeStatusDescription(notam.qCode)}');
              }
              // Debug: Print all NOTAM IDs to see what we're getting
              print('DEBUG: Processing NOTAM: ${notam.id}');
              if (!seenNotamIds.contains(notam.id)) {
                seenNotamIds.add(notam.id);
                pageNotams.add(notam);
                newNotamsInPage++;
              } else {
                print('DEBUG: 🔍 Skipping duplicate NOTAM: ${notam.id}');
              }
            }
            
            // Only log sample NOTAMs occasionally to reduce console spam
            if (pageNotams.isNotEmpty && allNotams.length < 10) {
              for (int i = 0; i < math.min(3, pageNotams.length); i++) {
                final notam = pageNotams[i];
                print('DEBUG: 🔍 NEW NOTAM ${allNotams.length + i + 1}: ${notam.id} - Valid: ${notam.validFrom} to ${notam.validTo}');
              }
            }
            
            allNotams.addAll(pageNotams);
            totalFetched += items.length;
            strategyFetched += items.length;
            
            print('DEBUG: 🔍 Strategy ${strategyIndex + 1} summary: ${items.length} total fetched, $newNotamsInPage new unique NOTAMs');
            print('DEBUG: 🔍 Total unique NOTAMs so far: ${allNotams.length}');
            
            // Debug: Print all NOTAM IDs from this page
            final notamIds = pageNotams.map((n) => n.id).toList();
            print('DEBUG: 🔍 NOTAM IDs from this page: $notamIds');
            
            // If we got fewer items than requested, we've reached the end for this strategy
            if (items.length < pageSize) {
              print('DEBUG: 🔍 Reached end of NOTAMs for $icao in strategy ${strategyIndex + 1} (got ${items.length} < $pageSize)');
              break;
            }
            
            // If we're getting mostly duplicates, move to next strategy
            if (newNotamsInPage < items.length * 0.3) { // Less than 30% new NOTAMs
              print('DEBUG: 🔍 Strategy ${strategyIndex + 1} producing mostly duplicates (${newNotamsInPage}/${items.length} new). Moving to next strategy.');
              break;
            }
            
            offset += pageSize;
            
            // Safety check: don't go beyond 200 NOTAMs per strategy (4 pages)
            if (strategyFetched >= 200) {
              print('DEBUG: ⚠️ Reached safety limit of 200 NOTAMs for strategy ${strategyIndex + 1}');
              break;
            }
            
            // Small delay between requests to be respectful
            await Future.delayed(const Duration(milliseconds: 100));
            
      } else {
            print('Warning: NOTAM API returned status ${response.statusCode} for $icao strategy ${strategyIndex + 1}. Moving to next strategy.');
            break;
          }
        }
        
        // If we've found a good number of unique NOTAMs, we can stop
        if (allNotams.length >= 150) {
          print('DEBUG: ✅ Found sufficient NOTAMs (${allNotams.length}). Stopping pagination.');
          break;
        }
      }
      
      print('DEBUG: ✅ Successfully fetched ${allNotams.length} unique NOTAMs for $icao via multi-strategy pagination');
      print('DEBUG: 🔍 Total API responses: $totalFetched');
      print('DEBUG: 🔍 Total unique NOTAMs: ${allNotams.length}');
      
      // Debug: Print all NOTAM IDs that were fetched
      final allNotamIds = allNotams.map((n) => n.id).toList();
      print('DEBUG: 🔍 ALL NOTAM IDs fetched: $allNotamIds');
      
      return allNotams;
      
    } catch (e) {
      print('Warning: Failed to load NOTAMs for $icao: $e');
      print('This is likely due to SATCOM network limitations. Continuing with empty NOTAM list.');
      return [];
    }
  }

  Future<List<Weather>> fetchWeather(List<String> icaos) async {
    final stationString = icaos.map((e) => e.trim()).join(',');
    print('DEBUG: 🔍 fetchWeather called for ICAOs: $icaos');
    print('DEBUG: 🔍 Station string: $stationString');
    
    try {
      final url = _getUrl(_weatherBaseUrl, queryParams: {
        'ids': stationString,
        'format': 'json',
        'hours': '6' // Increased from 1 to 6 hours to get more recent METARs
      });
      
      print('DEBUG: 🔍 METAR API URL: $url');
      
      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
        },
      );

      print('DEBUG: 🔍 METAR API response status: ${response.statusCode}');
      print('DEBUG: 🔍 METAR API response body length: ${response.body.length}');
      print('DEBUG: 🔍 METAR API response body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: 🔍 METAR API returned ${data.length} records');
        
        // Debug: Print the first few records to see the structure
        if (data.isNotEmpty) {
          print('DEBUG: 🔍 First METAR record structure: ${data.first}');
          print('DEBUG: 🔍 METAR record keys: ${(data.first as Map<String, dynamic>).keys.toList()}');
          
          // Check if the expected fields exist
          final firstRecord = data.first as Map<String, dynamic>;
          print('DEBUG: 🔍 METAR icaoId field: ${firstRecord['icaoId']}');
          print('DEBUG: 🔍 METAR rawOb field: ${firstRecord['rawOb']}');
          print('DEBUG: 🔍 METAR icao field: ${firstRecord['icao']}');
          print('DEBUG: 🔍 METAR rawText field: ${firstRecord['rawText']}');
        }
        
        if (data.isNotEmpty) {
          final List<Weather> weatherList = data.map((item) {
            print('DEBUG: 🔍 Processing METAR item: $item');
            return Weather.fromMetar(item);
          }).toList();
          final receivedIcaos = weatherList.map((w) => w.icao).toSet();
          print('DEBUG: 🔍 METAR weather list created with ${weatherList.length} items');
          print('DEBUG: 🔍 Received ICAOs: $receivedIcaos');

          // Handle missing data by creating empty weather objects
          for (final icao in icaos) {
            if (!receivedIcaos.contains(icao)) {
              print('Warning: No METAR data received for $icao. Creating empty object.');
              weatherList.add(_createEmptyWeather(icao, 'METAR'));
            }
          }
          print('DEBUG: 🔍 Final METAR weather list: ${weatherList.length} items');
          return weatherList;
        } else {
          print('DEBUG: ⚠️ METAR API returned empty data array');
        }
      } else {
        print('DEBUG: ⚠️ METAR API returned status code: ${response.statusCode}');
      }
      // If call fails or returns empty, create empty data for all requested ICAOs
      print('DEBUG: 🔍 Creating empty METAR objects for all ICAOs: $icaos');
      return icaos.map((icao) => _createEmptyWeather(icao, 'METAR')).toList();
    } catch (e) {
      print('Error fetching METAR data: $e');
      print('DEBUG: 🔍 Creating empty METAR objects due to error for ICAOs: $icaos');
      return icaos.map((icao) => _createEmptyWeather(icao, 'METAR')).toList();
    }
  }

  Future<List<Weather>> fetchTafs(List<String> icaos) async {
    final stationString = icaos.map((e) => e.trim()).join(',');
    print('DEBUG: 🔍 fetchTafs called for ICAOs: $icaos');
    print('DEBUG: 🔍 Station string: $stationString');
    
    // Check if EGLL is in the list
    if (icaos.contains('EGLL')) {
      print('DEBUG: 🎯 EGLL is in the ICAO list for TAF fetching');
    }
    
    try {
      final url = _getUrl(_tafBaseUrl, queryParams: {
        'ids': stationString,
        'format': 'json',
        'hours': '24' // TAFs are typically valid for 24 hours
      });
      
      print('DEBUG: 🔍 TAF API URL: $url');
      
      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
        },
      );

      print('DEBUG: 🔍 TAF API response status: ${response.statusCode}');
      print('DEBUG: 🔍 TAF API response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('DEBUG: 🔍 TAF API returned ${data.length} records');
        
        // Check for EGLL in the response
        final egllData = data.where((item) => (item['icaoId'] ?? '').contains('EGLL')).toList();
        if (egllData.isNotEmpty) {
          print('DEBUG: 🎯 EGLL TAF data found in API response: ${egllData.length} records');
          for (int i = 0; i < egllData.length; i++) {
            final item = egllData[i];
            print('DEBUG: 🎯 EGLL TAF record $i: ICAO=${item['icaoId']}, rawTAF="${item['rawTAF']}"');
          }
        } else {
          print('DEBUG: ⚠️ No EGLL TAF data found in API response');
        }
        
        if (data.isNotEmpty) {
          final List<Weather> tafList = data.map((item) {
            final icao = item['icaoId'] ?? '';
            if (icao.contains('EGLL')) {
              print('DEBUG: 🎯 Creating Weather.fromTaf for EGLL');
            }
            return Weather.fromTaf(item);
          }).toList();
          
          final receivedIcaos = tafList.map((t) => t.icao).toSet();
          
          print('DEBUG: 🔍 Received TAFs for ICAOs: $receivedIcaos');

          // Handle missing data by creating empty weather objects
          for (final icao in icaos) {
            if (!receivedIcaos.contains(icao)) {
              print('DEBUG: ⚠️ No TAF data received for $icao. Creating empty object.');
              tafList.add(_createEmptyWeather(icao, 'TAF'));
            }
          }
          return tafList;
        }
      }
      
      print('DEBUG: ⚠️ TAF API returned empty or failed. Creating empty objects for all ICAOs.');
      return icaos.map((icao) => _createEmptyWeather(icao, 'TAF')).toList();
    } catch (e) {
      print('DEBUG: ❌ Error fetching TAF data: $e');
      return icaos.map((icao) => _createEmptyWeather(icao, 'TAF')).toList();
    }
  }

  // Convenience method to fetch both METAR and TAF for an airport - DEPRECATED
  Future<Map<String, Weather>> fetchWeatherAndTaf(String icao) async {
    // This method is no longer optimal. We will fetch in batches instead.
    // Kept for now to avoid breaking existing calls immediately.
    Weather? metar;
    Weather? taf;
    
    try {
      final metars = await fetchWeather([icao]);
      if (metars.isNotEmpty) metar = metars.first;
    } catch (e) {
      print('Warning: Failed to fetch METAR for $icao: $e');
    }
    
    try {
      final tafs = await fetchTafs([icao]);
      if (tafs.isNotEmpty) taf = tafs.first;
    } catch (e) {
      print('Warning: Failed to fetch TAF for $icao: $e');
    }
    
    if (metar == null && taf == null) {
      throw Exception('Failed to load any weather data for $icao');
    }
    
    return {
      'metar': metar ?? _createEmptyWeather(icao, 'METAR'),
      'taf': taf ?? _createEmptyWeather(icao, 'TAF'),
    };
  }
  
  // Helper method to create empty weather data when API fails
  Weather _createEmptyWeather(String icao, String type) {
    return Weather(
      icao: icao,
      timestamp: DateTime.now().toUtc(),
      rawText: 'No data available',
      decodedText: 'No $type data available for $icao',
      windDirection: 0,
      windSpeed: 0,
      visibility: 9999,
      cloudCover: 'Unknown',
      temperature: 0.0,
      dewPoint: 0.0,
      qnh: 0,
      conditions: 'No data',
      type: type,
    );
  }

  // Helper method to test network connectivity
  Future<bool> testNetworkConnectivity() async {
    try {
      // Test basic internet connectivity with a reliable service
      final response = await http.get(Uri.parse('https://httpbin.org/status/200'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Network connectivity test failed: $e');
      return false;
    }
  }

  // Helper method to test FAA API accessibility
  Future<bool> testFaaApiAccess() async {
    try {
      final response = await http.get(Uri.parse('https://external-api.faa.gov/health'))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('FAA API accessibility test failed: $e');
      return false;
    }
  }

  // SATCOM-optimized NOTAM fetching with fallback strategies
  Future<List<Notam>> fetchNotamsWithSatcomFallback(String icao) async {
    print('DEBUG: 🛰️ Attempting SATCOM-optimized NOTAM fetch for $icao');
    
    // Strategy 1: Try the main multi-strategy pagination approach
    try {
      final notams = await fetchNotams(icao);
      if (notams.isNotEmpty) {
        print('DEBUG: ✅ Strategy 1 succeeded for $icao: ${notams.length} NOTAMs');
        return notams;
      }
    } catch (e) {
      print('DEBUG: ❌ Strategy 1 failed for $icao: $e');
    }
    
    // Strategy 2: Try with different API endpoints (if available)
    try {
      // Try alternative endpoint format
      final alternativeUrl = 'https://external-api.faa.gov/notamapi/v1/notams/search';
      final url = _getUrl(alternativeUrl, queryParams: {
        'icaoLocation': icao,
        'limit': '100', // Try higher limit
        'sortBy': 'effectiveStartDate',
        'sortOrder': 'Desc',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

      print('DEBUG: 🔄 Trying Strategy 2 (alternative endpoint) for $icao...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'client_id': clientId,
          'client_secret': clientSecret,
          'Connection': 'close',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        print('DEBUG: ✅ Strategy 2 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      print('DEBUG: ❌ Strategy 2 failed for $icao: $e');
    }
    
    // Strategy 3: Try with minimal parameters and different sorting
    try {
      final url = _getUrl(_notamBaseUrl, queryParams: {
        'icaoLocation': icao,
        'limit': '50',
        'sortBy': 'effectiveEndDate', // Try different sort
        'sortOrder': 'Desc',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

      print('DEBUG: 🔄 Trying Strategy 3 (minimal params) for $icao...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'client_id': clientId,
          'client_secret': clientSecret,
          'Connection': 'close',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        print('DEBUG: ✅ Strategy 3 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      print('DEBUG: ❌ Strategy 3 failed for $icao: $e');
    }
    
    // Strategy 4: Try with no sorting at all (let API decide order)
    try {
      final url = _getUrl(_notamBaseUrl, queryParams: {
        'icaoLocation': icao,
        'limit': '50',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

      print('DEBUG: 🔄 Trying Strategy 4 (no sorting) for $icao...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'client_id': clientId,
          'client_secret': clientSecret,
          'Connection': 'close',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        print('DEBUG: ✅ Strategy 4 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      print('DEBUG: ❌ Strategy 4 failed for $icao: $e');
    }
    
    // Strategy 5: Try with different airport code format (remove K prefix for US airports)
    try {
      String modifiedIcao = icao;
      if (icao.startsWith('K') && icao.length == 4) {
        modifiedIcao = icao.substring(1); // Remove K prefix
        print('DEBUG: 🔄 Trying Strategy 5 with modified ICAO: $icao -> $modifiedIcao');
      } else {
        print('DEBUG: 🔄 Trying Strategy 5 with original ICAO: $icao');
      }
      
      final url = _getUrl(_notamBaseUrl, queryParams: {
        'icaoLocation': modifiedIcao,
        'limit': '50',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'client_id': clientId,
          'client_secret': clientSecret,
          'Connection': 'close',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        print('DEBUG: ✅ Strategy 5 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      print('DEBUG: ❌ Strategy 5 failed for $icao: $e');
    }
    
    print('DEBUG: ❌ All SATCOM strategies failed for $icao. Returning empty list.');
    return [];
  }

  // Diagnostic method to test FAA NOTAM API parameters
  Future<Map<String, dynamic>> testFaaNotamApiParameters(String icao) async {
    print('DEBUG: 🔬 Testing FAA NOTAM API parameters for $icao');
    
    final results = <String, dynamic>{};
    final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';
    
    // Test different parameter combinations
    final List<Map<String, dynamic>> testCases = [
      {
        'name': 'Basic (limit=50)',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50'},
      },
      {
        'name': 'With sorting (effectiveStartDate Desc)',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50', 'sortBy': 'effectiveStartDate', 'sortOrder': 'Desc'},
      },
      {
        'name': 'With sorting (effectiveEndDate Desc)',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50', 'sortBy': 'effectiveEndDate', 'sortOrder': 'Desc'},
      },
      {
        'name': 'With offset (offset=50)',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50', 'offset': '50'},
      },
      {
        'name': 'Higher limit (limit=100)',
        'params': <String, String>{'icaoLocation': icao, 'limit': '100'},
      },
      {
        'name': 'With effectiveStartDate filter',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50', 'effectiveStartDate': DateTime.now().subtract(Duration(days: 30)).toIso8601String()},
      },
      {
        'name': 'With effectiveEndDate filter',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50', 'effectiveEndDate': DateTime.now().add(Duration(days: 30)).toIso8601String()},
      },
      {
        'name': 'Alternative endpoint (/search)',
        'url': 'https://external-api.faa.gov/notamapi/v1/notams/search',
        'params': <String, String>{'icaoLocation': icao, 'limit': '50'},
      },
    ];
    
    for (final testCase in testCases) {
      try {
        final url = (testCase['url'] as String?) ?? _notamBaseUrl;
        final params = Map<String, String>.from(testCase['params'] as Map<String, String>);
        params['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
        
        final testUrl = _getUrl(url, queryParams: params);
        print('DEBUG: 🔬 Testing: ${testCase['name']}');
        print('DEBUG: 🔬 URL: $testUrl');
        
        final response = await http.get(
          Uri.parse(testUrl),
          headers: {
            'Accept': 'application/json',
            'client_id': clientId,
            'client_secret': clientSecret,
            'Connection': 'close',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> items = data['items'] ?? [];
          final totalCount = data['totalCount'] ?? 'unknown';
          
          results[testCase['name'] as String] = {
            'status': 'success',
            'statusCode': response.statusCode,
            'notamCount': items.length,
            'totalCount': totalCount,
            'responseSize': response.body.length,
          };
          
          print('DEBUG: ✅ ${testCase['name']}: ${items.length} NOTAMs, total: $totalCount');
        } else {
          results[testCase['name'] as String] = {
            'status': 'error',
            'statusCode': response.statusCode,
            'error': 'HTTP ${response.statusCode}',
          };
          print('DEBUG: ❌ ${testCase['name']}: HTTP ${response.statusCode}');
        }
      } catch (e) {
        results[testCase['name'] as String] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('DEBUG: ❌ ${testCase['name']}: $e');
      }
      
      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    print('DEBUG: 🔬 FAA NOTAM API parameter test results:');
    for (final entry in results.entries) {
      print('DEBUG: 🔬 ${entry.key}: ${entry.value}');
    }
    
    return results;
  }
} 