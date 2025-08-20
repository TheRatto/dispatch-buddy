import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/naips_service.dart';
import '../services/naips_parser.dart';
import '../providers/settings_provider.dart';
import '../services/decoder_service.dart';

import 'dart:async';

class ApiService {
  // Use CORS proxy for web development
  final String _corsProxy = 'https://cors-anywhere.herokuapp.com/';
  final String _notamBaseUrl = 'https://external-api.faa.gov/notamapi/v1/notams';
  final String _weatherBaseUrl = 'https://aviationweather.gov/api/data/metar';
  final String _tafBaseUrl = 'https://aviationweather.gov/api/data/taf';

  // Helper method to get NAIPS settings automatically
  Future<Map<String, dynamic>> _getNaipsSettings() async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.initialize();
    
    return {
      'enabled': settingsProvider.naipsEnabled,
      'username': settingsProvider.naipsUsername,
      'password': settingsProvider.naipsPassword,
    };
  }

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
          debugPrint('Attempt ${i + 1} failed with status ${response.statusCode}. Retrying...');
          // Exponential backoff for SATCOM: 2s, 4s, 8s
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        } else { // Client error, don't retry
          return response;
        }
      } catch (e) {
        debugPrint('Attempt ${i + 1} failed with exception: $e. Retrying...');
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
    debugPrint('DEBUG: 🔍 fetchNotams - Fetching NOTAMs from FAA API for $icao');
    
    try {
      debugPrint('DEBUG: 🔍 Attempting to fetch NOTAMs for $icao with offset-based pagination...');
      
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
        debugPrint('DEBUG: 🔍 Trying sort strategy ${strategyIndex + 1}: ${strategy['sortBy']} ${strategy['sortOrder']}');
        
        offset = 0; // Reset offset for each strategy
        int strategyFetched = 0;
        
        while (true) {
          debugPrint('DEBUG: 🔍 Fetching page for $icao (strategy ${strategyIndex + 1}): offset=$offset, limit=$pageSize');
          
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

          debugPrint('DEBUG: 🔍 API URL: $url');

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
        
            debugPrint('DEBUG: ✅ Strategy ${strategyIndex + 1}, Page ${(offset / pageSize) + 1}: Fetched ${items.length} NOTAMs for $icao');
            debugPrint('DEBUG: 🔍 API response body length: ${response.body.length} characters');
            
            if (items.isEmpty) {
              debugPrint('DEBUG: 🔍 No more NOTAMs found for $icao in strategy ${strategyIndex + 1} (empty page)');
              break; // No more results for this strategy
            }
            
            // Process items and track unique NOTAMs
            final List<Notam> pageNotams = [];
            int newNotamsInPage = 0;
            
            for (final item in items) {
              final notam = Notam.fromFaaJson(item);
              // Debug: Print full JSON for H5496/25 or H4696/25
              if (notam.id == 'H5496/25' || notam.id == 'H4696/25') {
                debugPrint('DEBUG: FOUND TARGET NOTAM: ${notam.id}');
                debugPrint('DEBUG: FULL FAA JSON: ${jsonEncode(item)}');
                debugPrint('DEBUG: NOTAM TEXT: ${notam.rawText}');
                debugPrint('DEBUG: DECODED TEXT: ${notam.decodedText}');
                debugPrint('DEBUG: Q CODE: ${notam.qCode}');
                debugPrint('DEBUG: Q CODE SUBJECT: ${Notam.getQCodeSubjectDescription(notam.qCode)}');
                debugPrint('DEBUG: Q CODE STATUS: ${Notam.getQCodeStatusDescription(notam.qCode)}');
              }
              // Debug: Print all NOTAM IDs to see what we're getting
              debugPrint('DEBUG: Processing NOTAM: ${notam.id}');
              if (!seenNotamIds.contains(notam.id)) {
                seenNotamIds.add(notam.id);
                pageNotams.add(notam);
                newNotamsInPage++;
              } else {
                debugPrint('DEBUG: 🔍 Skipping duplicate NOTAM: ${notam.id}');
              }
            }
            
            // Only log sample NOTAMs occasionally to reduce console spam
            if (pageNotams.isNotEmpty && allNotams.length < 10) {
              for (int i = 0; i < math.min(3, pageNotams.length); i++) {
                final notam = pageNotams[i];
                debugPrint('DEBUG: 🔍 NEW NOTAM ${allNotams.length + i + 1}: ${notam.id} - Valid: ${notam.validFrom} to ${notam.validTo}');
              }
            }
            
            allNotams.addAll(pageNotams);
            totalFetched += items.length;
            strategyFetched += items.length;
            
            debugPrint('DEBUG: 🔍 Strategy ${strategyIndex + 1} summary: ${items.length} total fetched, $newNotamsInPage new unique NOTAMs');
            debugPrint('DEBUG: 🔍 Total unique NOTAMs so far: ${allNotams.length}');
            
            // Debug: Print all NOTAM IDs from this page
            final notamIds = pageNotams.map((n) => n.id).toList();
            debugPrint('DEBUG: 🔍 NOTAM IDs from this page: $notamIds');
            
            // If we got fewer items than requested, we've reached the end for this strategy
            if (items.length < pageSize) {
              debugPrint('DEBUG: 🔍 Reached end of NOTAMs for $icao in strategy ${strategyIndex + 1} (got ${items.length} < $pageSize)');
              break;
            }
            
            // If we're getting mostly duplicates, move to next strategy
            if (newNotamsInPage < items.length * 0.3) { // Less than 30% new NOTAMs
              debugPrint('DEBUG: 🔍 Strategy ${strategyIndex + 1} producing mostly duplicates (${newNotamsInPage}/${items.length} new). Moving to next strategy.');
              break;
            }
            
            offset += pageSize;
            
            // Safety check: don't go beyond 200 NOTAMs per strategy (4 pages)
            if (strategyFetched >= 200) {
              debugPrint('DEBUG: ⚠️ Reached safety limit of 200 NOTAMs for strategy ${strategyIndex + 1}');
              break;
            }
            
            // Small delay between requests to be respectful
            await Future.delayed(const Duration(milliseconds: 100));
            
      } else {
            debugPrint('Warning: NOTAM API returned status ${response.statusCode} for $icao strategy ${strategyIndex + 1}. Moving to next strategy.');
            break;
          }
        }
        
        // If we've found a good number of unique NOTAMs, we can stop
        if (allNotams.length >= 150) {
          debugPrint('DEBUG: ✅ Found sufficient NOTAMs (${allNotams.length}). Stopping pagination.');
          break;
        }
      }
      
      debugPrint('DEBUG: ✅ Successfully fetched ${allNotams.length} unique NOTAMs for $icao via FAA API');
      debugPrint('DEBUG: 🔍 Total API responses: $totalFetched');
      debugPrint('DEBUG: 🔍 Total unique NOTAMs: ${allNotams.length}');
      
      // Debug: Print all NOTAM IDs that were fetched
      final faaNotamIds = allNotams.map((n) => n.id).toList();
      debugPrint('DEBUG: 🔍 FAA API NOTAM IDs fetched: $faaNotamIds');
      
      return allNotams;
      
    } catch (e) {
      debugPrint('Warning: Failed to load NOTAMs for $icao: $e');
      debugPrint('This is likely due to SATCOM network limitations. Continuing with empty NOTAM list.');
      return [];
    }
  }

  /// Fetch weather data for the given ICAO codes (combines METARs and ATIS)
  Future<List<Weather>> fetchWeather(List<String> icaos) async {
    debugPrint('DEBUG: 🔍 fetchWeather called for ICAOs: $icaos');
    
    // Fetch METARs and ATIS separately using the new dedicated methods
    final metars = await fetchMetars(icaos);
    final atis = await fetchAtis(icaos);
    
    // Combine the results
    final combined = [...metars, ...atis];
    debugPrint('DEBUG: 🔍 fetchWeather combined result: ${combined.length} items (${metars.length} METARs, ${atis.length} ATIS)');
    
    return combined;
  }

  Future<List<Weather>> fetchTafs(List<String> icaos) async {
    final stationString = icaos.map((e) => e.trim()).join(',');
    debugPrint('DEBUG: 🔍 fetchTafs called for ICAOs: $icaos');
    debugPrint('DEBUG: 🔍 Station string: $stationString');
    
    // Check if EGLL is in the list
    if (icaos.contains('EGLL')) {
      debugPrint('DEBUG: 🎯 EGLL is in the ICAO list for TAF fetching');
    }
    
    // Get NAIPS settings automatically
    final naipsSettings = await _getNaipsSettings();
    final naipsEnabled = naipsSettings['enabled'] as bool;
    final naipsUsername = naipsSettings['username'] as String?;
    final naipsPassword = naipsSettings['password'] as String?;
    
    debugPrint('DEBUG: 🔍 fetchTafs - Auto-loaded NAIPS settings: enabled=$naipsEnabled, username=${naipsUsername != null ? "SET" : "NOT SET"}, password=${naipsPassword != null ? "SET" : "NOT SET"}');
    
    List<Weather> naipsTafs = [];
    List<Weather> apiTafs = [];
    
    // Always fetch from aviationweather.gov
    try {
      debugPrint('DEBUG: 🔍 Fetching TAFs from aviationweather.gov for $icaos');
      final url = _getUrl(_tafBaseUrl, queryParams: {
        'ids': stationString,
        'format': 'json',
        'hours': '24' // TAFs are typically valid for 24 hours
      });
      
      debugPrint('DEBUG: 🔍 TAF API URL: $url');
      
      final response = await _makeRequestWithRetry(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
        },
      );

      debugPrint('DEBUG: 🔍 TAF API response status: ${response.statusCode}');
      debugPrint('DEBUG: 🔍 TAF API response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('DEBUG: 🔍 TAF API returned ${data.length} records');
        
        // Check for EGLL in the response
        final egllData = data.where((item) => (item['icaoId'] ?? '').contains('EGLL')).toList();
        if (egllData.isNotEmpty) {
          debugPrint('DEBUG: 🎯 EGLL TAF data found in API response: ${egllData.length} records');
          for (int i = 0; i < egllData.length; i++) {
            final item = egllData[i];
            debugPrint('DEBUG: 🎯 EGLL TAF record $i: ICAO=${item['icaoId']}, rawTAF="${item['rawTAF']}"');
          }
        } else {
          debugPrint('DEBUG: ⚠️ No EGLL TAF data found in API response');
        }
        
        if (data.isNotEmpty) {
          apiTafs = data.map((item) => Weather.fromTaf(item)).toList();
          final receivedIcaos = apiTafs.map((w) => w.icao).toSet();
          debugPrint('DEBUG: 🔍 TAF weather list created with ${apiTafs.length} items');
          debugPrint('DEBUG: 🔍 Received ICAOs: $receivedIcaos');
        }
      }
    } catch (e) {
      debugPrint('DEBUG: 🔍 aviationweather.gov TAF fetch failed: $e');
    }
    
    // Fallback: for any ICAOs missing from API JSON, try raw CGI endpoint and decode
    try {
      final haveApiFor = apiTafs.map((w) => w.icao).toSet();
      final missing = icaos.where((id) => !haveApiFor.contains(id)).toList();
      if (missing.isNotEmpty) {
        debugPrint('DEBUG: 🔍 TAF JSON missing for: $missing, trying raw CGI fallback');
        for (final icao in missing) {
          try {
            final url = 'https://aviationweather.gov/cgi-bin/data/taf.php?ids=$icao&format=raw&hours=24&layout=off';
            final resp = await _makeRequestWithRetry(Uri.parse(url), headers: {
              'Accept': 'text/plain',
            });
            if (resp.statusCode == 200) {
              final raw = resp.body;
              if (raw.trim().isNotEmpty && raw.trim() != 'No data found') {
                // Use the full multi-line TAF block; decode on compact form
                final lines = raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final fullBlock = lines.join('\n');

                // Build a compact single-line for decoding
                final firstLine = lines.first;
                final decoderService = DecoderService();
                final decoded = decoderService.decodeTaf(firstLine);

                apiTafs.add(Weather(
                  icao: icao,
                  timestamp: decoded.timestamp,
                  rawText: fullBlock,
                  decodedText: '',
                  windDirection: 0,
                  windSpeed: 0,
                  visibility: 9999,
                  cloudCover: decoded.cloudCover ?? '',
                  temperature: 0.0,
                  dewPoint: 0.0,
                  qnh: 0,
                  conditions: decoded.conditions ?? '',
                  type: 'TAF',
                  decodedWeather: decoded,
                  source: 'aviationweather',
                ));
              }
            }
          } catch (e) {
            debugPrint('DEBUG: 🔍 Raw CGI TAF fetch failed for $icao: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('DEBUG: 🔍 TAF CGI fallback error: $e');
    }
    
    // If NAIPS is enabled, fetch NAIPS for each ICAO and MERGE with API:
    // - Prefer NAIPS for ICAOs where available
    // - Keep API results for others
    if (naipsEnabled && naipsUsername != null && naipsPassword != null) {
      try {
        debugPrint('DEBUG: 🔍 Attempting to fetch TAFs from NAIPS for each ICAO: $icaos');
        final naipsService = NAIPSService();

        final isAuthenticated = await naipsService.authenticate(naipsUsername, naipsPassword);
        if (isAuthenticated) {
          debugPrint('DEBUG: 🔍 NAIPS authentication successful');

          final List<Weather> aggregated = [];
          for (final icao in icaos) {
            try {
              final html = await naipsService.requestLocationBriefing(icao);
              final weatherList = NAIPSParser.parseWeatherFromHTML(html);
              final tafOnly = weatherList.where((w) => w.type == 'TAF');
              debugPrint('DEBUG: 🔍 NAIPS $icao -> ${tafOnly.length} TAF items');
              aggregated.addAll(tafOnly);
            } catch (e) {
              debugPrint('DEBUG: 🔍 NAIPS TAF fetch failed for $icao: $e');
            }
          }

          naipsTafs = aggregated.where((w) => icaos.contains(w.icao)).toList();
          // Merge by freshest timestamp per ICAO (independent per type)
          if (naipsTafs.isNotEmpty || apiTafs.isNotEmpty) {
            final Map<String, Weather> mergedByIcao = {};
            const naipsAdvantage = Duration(minutes: 2);

            void consider(Weather cand) {
              final cur = mergedByIcao[cand.icao];
              if (cur == null) {
                mergedByIcao[cand.icao] = cand;
                return;
              }
              // If candidate is NAIPS and within 2 minutes older than current API, prefer NAIPS
              final isCandNaips = cand.source == 'naips';
              final isCurApi = cur.source != 'naips';
              if (isCandNaips && isCurApi) {
                if (!cand.timestamp.isAfter(cur.timestamp)) {
                  final diff = cur.timestamp.difference(cand.timestamp).abs();
                  if (diff <= naipsAdvantage) {
                    mergedByIcao[cand.icao] = cand;
                    return;
                  }
                }
              }
              // If current is NAIPS and candidate is API, replace only if API is > 2 minutes newer
              final isCurNaips = cur.source == 'naips';
              final isCandApi = cand.source != 'naips';
              if (isCurNaips && isCandApi) {
                if (cand.timestamp.isAfter(cur.timestamp.add(naipsAdvantage))) {
                  mergedByIcao[cand.icao] = cand;
                }
                return;
              }
              // Default: pick newest timestamp
              if (cand.timestamp.isAfter(cur.timestamp)) {
                mergedByIcao[cand.icao] = cand;
              }
            }

            // Evaluate both sets
            for (final w in naipsTafs) consider(w);
            for (final w in apiTafs) consider(w);

            final merged = mergedByIcao.values.toList();
            debugPrint('DEBUG: 🔍 Returning merged TAF data (newest wins, NAIPS +2min advantage): API=${apiTafs.length}, NAIPS=${naipsTafs.length}, merged=${merged.length}');
            return merged;
          }
          debugPrint('DEBUG: 🔍 No TAF data from NAIPS or API');
        } else {
          debugPrint('DEBUG: 🔍 NAIPS authentication failed, falling back to API');
        }
      } catch (e) {
        debugPrint('DEBUG: 🔍 NAIPS TAF fetch error, falling back: $e');
      }
    }

    // NAIPS disabled/unavailable: return API (including CGI fallback) results
    // Ensure we return the newest per ICAO
    final Map<String, Weather> newestApi = {};
    for (final w in apiTafs) {
      final existing = newestApi[w.icao];
      if (existing == null || w.timestamp.isAfter(existing.timestamp)) {
        newestApi[w.icao] = w;
      }
    }
    return newestApi.values.toList();
  }

  /// Fetch METAR data for the given ICAO codes
  Future<List<Weather>> fetchMetars(List<String> icaos) async {
    final naipsSettings = await _getNaipsSettings();
    final naipsEnabled = naipsSettings['enabled'] as bool? ?? false;
    final naipsUsername = naipsSettings['username'] as String?;
    final naipsPassword = naipsSettings['password'] as String?;

    // If NAIPS is enabled, try NAIPS and MERGE with API by ICAO
    if (naipsEnabled && naipsUsername != null && naipsPassword != null) {
      try {
        debugPrint('DEBUG: 🔍 Attempting to fetch METARs from NAIPS for each ICAO: $icaos');
          debugPrint('DEBUG: 🔍 NAIPS credentials: username=SET, password=SET');
        final naipsService = NAIPSService();

        final isAuthenticated = await naipsService.authenticate(naipsUsername, naipsPassword);
        debugPrint('DEBUG: 🔍 NAIPS authentication result: $isAuthenticated');
        if (isAuthenticated) {
          debugPrint('DEBUG: 🔍 NAIPS authentication successful');

          final List<Weather> aggregated = [];
          for (final icao in icaos) {
            try {
              debugPrint('DEBUG: 🔍 Fetching NAIPS METAR data for $icao...');
              final html = await naipsService.requestLocationBriefing(icao);
              debugPrint('DEBUG: 🔍 NAIPS HTML for $icao: ${html.length} characters');
              debugPrint('DEBUG: 🔍 NAIPS HTML preview for $icao: ${html.substring(0, html.length > 200 ? 200 : html.length)}...');
              
              final parsed = NAIPSParser.parseWeatherFromHTML(html);
              debugPrint('DEBUG: 🔍 NAIPS $icao -> ${parsed.length} weather items');
              
              // Debug each parsed item
              for (final item in parsed) {
                debugPrint('DEBUG: 🔍   - Type: ${item.type}, ICAO: ${item.icao}, Source: ${item.source}');
              }
              
              aggregated.addAll(parsed);
            } catch (e) {
              debugPrint('DEBUG: 🔍 NAIPS METAR fetch failed for $icao: $e');
            }
          }

          // Filter aggregated to only METAR/SPECI types and requested ICAOs
          final naipsMetars = aggregated
              .where((w) => (w.type == 'METAR' || w.type == 'SPECI') && icaos.contains(w.icao))
              .toList();

          debugPrint('DEBUG: 🔍 NAIPS METARs found: ${naipsMetars.length}');

          // Build set of ICAOs covered by NAIPS
          final naipsIcaos = naipsMetars.map((w) => w.icao).toSet();

          // Fetch API METARs only for ICAOs not covered by NAIPS
          final remainingIcaos = icaos.where((code) => !naipsIcaos.contains(code)).toList();
          final List<Weather> apiMetarsForRemaining = [];
          if (remainingIcaos.isNotEmpty) {
            debugPrint('DEBUG: 🔍 Fetching API METARs for remaining ICAOs: $remainingIcaos');
            for (final icao in remainingIcaos) {
              try {
                final response = await http.get(
                  Uri.parse('https://aviationweather.gov/cgi-bin/data/metar.php?ids=$icao&format=raw&hours=2&taf=off&layout=off'),
                );
                if (response.statusCode == 200) {
                  final rawText = response.body.trim();
                  if (rawText.isNotEmpty && rawText != 'No data found') {
                    // Decode using Weather.fromMetar for consistency
                    final lines = rawText.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                    if (lines.isNotEmpty) {
                      final firstLine = lines.first; // Latest METAR
                      final w = Weather.fromMetar({
                        'icaoId': icao,
                        'rawOb': firstLine,
                        'metarType': firstLine.startsWith('SPECI') ? 'SPECI' : 'METAR',
                      });
                      apiMetarsForRemaining.add(w);
                    }
                  }
                }
              } catch (e) {
                debugPrint('DEBUG: 🔍 API METAR fetch failed for $icao: $e');
              }
            }
          }

          // Merge NAIPS and API results
          final combined = [...naipsMetars, ...apiMetarsForRemaining];
          debugPrint('DEBUG: 🔍 Returning merged METARs: NAIPS=${naipsMetars.length}, API=${apiMetarsForRemaining.length}, total=${combined.length}');
          return combined;
        } else {
          debugPrint('DEBUG: 🔍 NAIPS authentication failed, falling back to API');
        }
      } catch (e) {
        debugPrint('DEBUG: 🔍 NAIPS METAR fetch error: $e, falling back to API');
      }
    }

    // NAIPS disabled/unavailable: fetch API for all ICAOs and DECODE each
    debugPrint('DEBUG: 🔍 Fetching METARs from aviationweather.gov API');
    final List<Weather> metars = [];
    for (final icao in icaos) {
      try {
        final response = await http.get(
          Uri.parse('https://aviationweather.gov/cgi-bin/data/metar.php?ids=$icao&format=raw&hours=2&taf=off&layout=off'),
        );
        if (response.statusCode == 200) {
          final raw = response.body.trim();
          if (raw.isNotEmpty && raw != 'No data found') {
            // Split into individual lines and take the latest (first line)
            final lines = raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            if (lines.isNotEmpty) {
              final firstLine = lines.first;
              // Ensure it has METAR/SPECI label for consistent decoding
              final normalized = firstLine; // already a standard METAR line
              // Use factory to decode and set true issue timestamp
              final w = Weather.fromMetar({
                'icaoId': icao,
                'rawOb': normalized,
                'metarType': normalized.startsWith('SPECI') ? 'SPECI' : 'METAR',
              });
              metars.add(w);
            }
          }
        }
      } catch (e) {
        debugPrint('DEBUG: 🔍 API METAR fetch failed for $icao: $e');
      }
    }
    return metars;
  }

  /// Fetch ATIS data for the given ICAO codes
  Future<List<Weather>> fetchAtis(List<String> icaos) async {
    final naipsSettings = await _getNaipsSettings();
    final naipsEnabled = naipsSettings['enabled'] as bool? ?? false;
    final naipsUsername = naipsSettings['username'] as String?;
    final naipsPassword = naipsSettings['password'] as String?;

    // If NAIPS is enabled, fetch NAIPS for each ICAO and return NAIPS-only if available; otherwise fallback to API
    if (naipsEnabled && naipsUsername != null && naipsPassword != null) {
      try {
        debugPrint('DEBUG: 🔍 Attempting to fetch ATIS from NAIPS for each ICAO: $icaos');
        debugPrint('DEBUG: 🔍 NAIPS credentials: username=${naipsUsername != null ? "SET" : "NOT SET"}, password=${naipsPassword != null ? "SET" : "NOT SET"}');
        final naipsService = NAIPSService();

        final isAuthenticated = await naipsService.authenticate(naipsUsername, naipsPassword);
        debugPrint('DEBUG: 🔍 NAIPS authentication result: $isAuthenticated');
        if (isAuthenticated) {
          debugPrint('DEBUG: 🔍 NAIPS authentication successful');

          final List<Weather> aggregated = [];
          for (final icao in icaos) {
            try {
              debugPrint('DEBUG: 🔍 Fetching NAIPS ATIS data for $icao...');
              final html = await naipsService.requestLocationBriefing(icao);
              debugPrint('DEBUG: 🔍 NAIPS HTML for $icao: ${html.length} characters');
              debugPrint('DEBUG: 🔍 NAIPS HTML preview for $icao: ${html.substring(0, html.length > 200 ? 200 : html.length)}...');
              
              final parsed = NAIPSParser.parseWeatherFromHTML(html);
              debugPrint('DEBUG: 🔍 NAIPS $icao -> ${parsed.length} weather items');
              
              // Debug each parsed item
              for (final item in parsed) {
                debugPrint('DEBUG: 🔍   - Type: ${item.type}, ICAO: ${item.icao}, Source: ${item.source}');
              }
              
              aggregated.addAll(parsed);
            } catch (e) {
              debugPrint('DEBUG: 🔍 NAIPS ATIS fetch failed for $icao: $e');
            }
          }

          // Filter aggregated to only ATIS types and requested ICAOs
          final naipsAtis = aggregated.where((w) => w.type == 'ATIS' && icaos.contains(w.icao)).toList();
          
          debugPrint('DEBUG: 🔍 NAIPS ATIS found: ${naipsAtis.length}');
          
          // Debug: Show all NAIPS ATIS items being returned
          debugPrint('DEBUG: 🔍 NAIPS ATIS items being returned:');
          for (final item in naipsAtis) {
            debugPrint('DEBUG: 🔍   - ${item.icao}: ${item.type} (source: ${item.source})');
          }

          // Return NAIPS ATIS if any found
          if (naipsAtis.isNotEmpty) {
            debugPrint('DEBUG: 🔍 Returning NAIPS ATIS data (${naipsAtis.length} items)');
            return naipsAtis;
          }
          debugPrint('DEBUG: 🔍 NAIPS has no ATIS for requested ICAOs, falling back to API');
        } else {
          debugPrint('DEBUG: 🔍 NAIPS authentication failed, falling back to API');
        }
      } catch (e) {
        debugPrint('DEBUG: 🔍 NAIPS ATIS fetch error: $e, falling back to API');
      }
    }

    // Fallback to API (Note: aviationweather.gov doesn't provide ATIS, so return empty list)
    debugPrint('DEBUG: 🔍 No ATIS available from API fallback, returning empty list');
    return [];
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
      debugPrint('Warning: Failed to fetch METAR for $icao: $e');
    }
    
    try {
      final tafs = await fetchTafs([icao]);
      if (tafs.isNotEmpty) taf = tafs.first;
    } catch (e) {
      debugPrint('Warning: Failed to fetch TAF for $icao: $e');
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
      debugPrint('Network connectivity test failed: $e');
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
      debugPrint('FAA API accessibility test failed: $e');
      return false;
    }
  }

  // SATCOM-optimized NOTAM fetching with fallback strategies
  Future<List<Notam>> fetchNotamsWithSatcomFallback(String icao) async {
    debugPrint('DEBUG: 🛰️ Attempting SATCOM-optimized NOTAM fetch for $icao');
    
    // Strategy 1: Try the main multi-strategy pagination approach
    try {
      final notams = await fetchNotams(icao);
      if (notams.isNotEmpty) {
        debugPrint('DEBUG: ✅ Strategy 1 succeeded for $icao: ${notams.length} NOTAMs');
        return notams;
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Strategy 1 failed for $icao: $e');
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

      debugPrint('DEBUG: 🔄 Trying Strategy 2 (alternative endpoint) for $icao...');
      
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
        debugPrint('DEBUG: ✅ Strategy 2 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Strategy 2 failed for $icao: $e');
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

      debugPrint('DEBUG: 🔄 Trying Strategy 3 (minimal params) for $icao...');
      
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
        debugPrint('DEBUG: ✅ Strategy 3 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Strategy 3 failed for $icao: $e');
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

      debugPrint('DEBUG: 🔄 Trying Strategy 4 (no sorting) for $icao...');
      
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
        debugPrint('DEBUG: ✅ Strategy 4 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Strategy 4 failed for $icao: $e');
    }
    
    // Strategy 5: Try with different airport code format (remove K prefix for US airports)
    try {
      String modifiedIcao = icao;
      if (icao.startsWith('K') && icao.length == 4) {
        modifiedIcao = icao.substring(1); // Remove K prefix
        debugPrint('DEBUG: 🔄 Trying Strategy 5 with modified ICAO: $icao -> $modifiedIcao');
      } else {
        debugPrint('DEBUG: 🔄 Trying Strategy 5 with original ICAO: $icao');
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
        debugPrint('DEBUG: ✅ Strategy 5 succeeded for $icao: ${items.length} NOTAMs');
        return items.map((item) => Notam.fromFaaJson(item)).toList();
      }
    } catch (e) {
      debugPrint('DEBUG: ❌ Strategy 5 failed for $icao: $e');
    }
    
    debugPrint('DEBUG: ❌ All SATCOM strategies failed for $icao. Returning empty list.');
    return [];
  }

  // Diagnostic method to test FAA NOTAM API parameters
  Future<Map<String, dynamic>> testFaaNotamApiParameters(String icao) async {
    debugPrint('DEBUG: 🔬 Testing FAA NOTAM API parameters for $icao');
    
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
        debugPrint('DEBUG: 🔬 Testing: ${testCase['name']}');
        debugPrint('DEBUG: 🔬 URL: $testUrl');
        
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
          
          debugPrint('DEBUG: ✅ ${testCase['name']}: ${items.length} NOTAMs, total: $totalCount');
        } else {
          results[testCase['name'] as String] = {
            'status': 'error',
            'statusCode': response.statusCode,
            'error': 'HTTP ${response.statusCode}',
          };
          debugPrint('DEBUG: ❌ ${testCase['name']}: HTTP ${response.statusCode}');
        }
      } catch (e) {
        results[testCase['name'] as String] = {
          'status': 'error',
          'error': e.toString(),
        };
        debugPrint('DEBUG: ❌ ${testCase['name']}: $e');
      }
      
      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    debugPrint('DEBUG: 🔬 FAA NOTAM API parameter test results:');
    for (final entry in results.entries) {
      debugPrint('DEBUG: 🔬 ${entry.key}: ${entry.value}');
    }
    
    return results;
  }
} 