import 'dart:convert';
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
        final response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500) { // Server error, worth retrying
          print('Attempt ${i + 1} failed with status ${response.statusCode}. Retrying...');
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying
        } else { // Client error, don't retry
          return response;
        }
      } catch (e) {
        print('Attempt ${i + 1} failed with exception: $e. Retrying...');
        if (i < retries - 1) {
          await Future.delayed(Duration(seconds: 1));
        } else {
          rethrow; // Rethrow on the last attempt
        }
      }
    }
    throw Exception('Failed to fetch data after $retries retries');
  }

  Future<List<Notam>> fetchNotams(String icao) async {
    try {
      final url = _getUrl(_notamBaseUrl,
          queryParams: {
            'icaoLocation': icao, 
            'sortBy': 'effectiveStartDate', 
            'sortOrder': 'Desc'
          });

      final clientId = dotenv.env['FAA_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['FAA_CLIENT_SECRET'] ?? '';

      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Origin': 'https://localhost',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      } else {
        throw Exception('Failed to load NOTAMs for $icao: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load NOTAMs for $icao: $e');
    }
  }

  Future<List<Weather>> fetchWeather(List<String> icaos) async {
    final stationString = icaos.map((e) => e.trim()).join(',');
    try {
      final url = _getUrl(_weatherBaseUrl, queryParams: {
        'ids': stationString,
        'format': 'json',
        'hours': '1'
      });
      
      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final List<Weather> weatherList = data.map((item) => Weather.fromMetar(item)).toList();
          final receivedIcaos = weatherList.map((w) => w.icao).toSet();

          // Handle missing data by creating empty weather objects
          for (final icao in icaos) {
            if (!receivedIcaos.contains(icao)) {
              print('Warning: No METAR data received for $icao. Creating empty object.');
              weatherList.add(_createEmptyWeather(icao, 'METAR'));
            }
          }
          return weatherList;
        }
      }
      // If call fails or returns empty, create empty data for all requested ICAOs
      return icaos.map((icao) => _createEmptyWeather(icao, 'METAR')).toList();
    } catch (e) {
      print('Error fetching METAR data: $e');
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
} 