import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// NAIPS Service
/// 
/// Handles authentication and data requests to NAIPS (Airservices Australia)
/// Provides access to Australian aviation weather and NOTAM data
class NAIPSService {
  static const String baseUrl = 'https://www.airservicesaustralia.com/naips';
  
  // Session management
  Map<String, String> _sessionCookies = {};
  bool _isAuthenticated = false;
  
  /// Authenticate with NAIPS using username and password
  /// Returns true if authentication successful, false otherwise
  Future<bool> authenticate(String username, String password) async {
    try {
      debugPrint('DEBUG: NAIPSService - Attempting authentication for user: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Account/LogOn'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/Account/LogOn',
          'Origin': 'https://www.airservicesaustralia.com',
        },
        body: {
          'UserName': username,
          'Password': password,
        },
      );
      
      debugPrint('DEBUG: NAIPSService - Authentication response status: ${response.statusCode}');
      
      if (response.statusCode == 302) {
        // Parse and store session cookies
        _parseSessionCookies(response.headers);
        _isAuthenticated = true;
        debugPrint('DEBUG: NAIPSService - Authentication successful');
        
          // Follow the authentication redirect to establish session properly
          final redirectLocation = response.headers['location'];
          if (redirectLocation != null) {
            debugPrint('DEBUG: NAIPSService - Following auth redirect to: $redirectLocation');
            
            final redirectResponse = await http.get(
              Uri.parse('$baseUrl$redirectLocation'),
              headers: {
                'Cookie': _buildCookieHeader(),
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
                'Referer': '$baseUrl/Account/LogOn',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'en-AU,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'Connection': 'keep-alive',
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'same-origin',
              },
            );
            debugPrint('DEBUG: NAIPSService - Auth redirect response status: ${redirectResponse.statusCode}');
            
            // Update cookies from redirect response
            _parseSessionCookies(redirectResponse.headers);
            debugPrint('DEBUG: NAIPSService - Updated session cookies after auth redirect: ${_sessionCookies.length}');
          }
        
        // Navigate to the main NAIPS page to establish session
        debugPrint('DEBUG: NAIPSService - Navigating to main NAIPS page...');
        final mainPageResponse = await http.get(
          Uri.parse('$baseUrl/'),
          headers: {
            'Cookie': _buildCookieHeader(),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
            'Referer': '$baseUrl/Account/LogOn',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-AU,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'same-origin',
          },
        );
        debugPrint('DEBUG: NAIPSService - Main page response status: ${mainPageResponse.statusCode}');
        
        // Update cookies from main page response
        _parseSessionCookies(mainPageResponse.headers);
        debugPrint('DEBUG: NAIPSService - Updated session cookies after main page: ${_sessionCookies.length}');
        
        return true;
      } else {
        debugPrint('DEBUG: NAIPSService - Authentication failed, status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: NAIPSService - Authentication error: $e');
      return false;
    }
  }
  
  /// Request location briefing for a specific airport
  /// Returns HTML response containing weather and NOTAM data
  Future<String> requestLocationBriefing(String icao, {int validityHours = 336}) async {
    if (!_isAuthenticated) {
      throw Exception('NAIPS not authenticated');
    }
    
    try {
      debugPrint('DEBUG: NAIPSService - Requesting location briefing for $icao');
      debugPrint('DEBUG: NAIPSService - Session cookies: ${_sessionCookies.length}');
      debugPrint('DEBUG: NAIPSService - Cookie header: ${_buildCookieHeader()}');
      debugPrint('DEBUG: NAIPSService - All session cookies: $_sessionCookies');
      
      // First, try to navigate to the briefing page to get any additional cookies
      debugPrint('DEBUG: NAIPSService - Step 1: Navigating to briefing page to get additional cookies...');
      try {
        final briefingPageResponse = await http.get(
          Uri.parse('$baseUrl/Briefing/Location'),
          headers: {
            'Cookie': _buildCookieHeader(),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
            'Referer': '$baseUrl/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
        );
        debugPrint('DEBUG: NAIPSService - Briefing page response status: ${briefingPageResponse.statusCode}');
        
        // Update cookies from briefing page response
        _parseSessionCookies(briefingPageResponse.headers);
        debugPrint('DEBUG: NAIPSService - Updated cookies after briefing page: ${_sessionCookies.length}');
        debugPrint('DEBUG: NAIPSService - Updated cookie header: ${_buildCookieHeader()}');
        
        if (briefingPageResponse.statusCode != 200) {
          debugPrint('DEBUG: NAIPSService - Briefing page failed, but continuing with POST...');
        }
        
        // Navigate back to main page to get any additional cookies
        debugPrint('DEBUG: NAIPSService - Step 1.5: Navigating back to main page for additional cookies...');
        try {
          final mainPageResponse2 = await http.get(
            Uri.parse('$baseUrl/'),
            headers: {
              'Cookie': _buildCookieHeader(),
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
              'Referer': '$baseUrl/Briefing/Location',
            },
          );
          _parseSessionCookies(mainPageResponse2.headers);
          debugPrint('DEBUG: NAIPSService - Final cookies after main page: ${_sessionCookies.length}');
          debugPrint('DEBUG: NAIPSService - Final cookie header: ${_buildCookieHeader()}');
        } catch (e) {
          debugPrint('DEBUG: NAIPSService - Main page navigation failed: $e');
        }
      } catch (e) {
        debugPrint('DEBUG: NAIPSService - Briefing page navigation failed: $e');
      }
      
      // Direct form submission (like the NAIPS app does)
      debugPrint('DEBUG: NAIPSService - Step 2: Submitting briefing form directly...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/Briefing/Location'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/',
          'Origin': 'https://www.airservicesaustralia.com',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
        body: {
          'Locations[0]': icao,
          'Met': 'true',
          'NOTAM': 'true', 
          'HeadOfficeNotam': 'false',
          'SIGMET': 'false',
          'Charts': 'true',
          'MidSigwxGpwt': 'true',
          'Validity': validityHours.toString(),
          'DomesticOnly': 'false',
        },
      );
      
      debugPrint('DEBUG: NAIPSService - Briefing response status: ${response.statusCode}');
      debugPrint('DEBUG: NAIPSService - Response headers: ${response.headers}');
      debugPrint('DEBUG: NAIPSService - Response body length: ${response.body.length}');
      if (response.body.length > 0) {
        debugPrint('DEBUG: NAIPSService - Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        // Check if it's a 404 error page
        if (response.body.contains('404') || response.body.contains('not found')) {
          debugPrint('DEBUG: NAIPSService - This is a 404 error page');
          // Look for any clues about the correct URL
          if (response.body.contains('href=')) {
            final hrefMatches = RegExp(r'href="([^"]*)"').allMatches(response.body);
            for (final match in hrefMatches) {
              debugPrint('DEBUG: NAIPSService - Found link: ${match.group(1)}');
            }
          }
        }
      }
      
      // Handle redirect to get final response
      if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          debugPrint('DEBUG: NAIPSService - Following redirect to: $redirectUrl');
          
          // Try different URL formats for the results page
          final possibleUrls = [
            '$baseUrl$redirectUrl', // Original format
            'https://www.airservicesaustralia.com$redirectUrl', // Full URL
            '$baseUrl/Briefing/LocationResults', // Direct path
            '$baseUrl/Briefing/Results', // Alternative path
          ];
          
          for (final url in possibleUrls) {
            debugPrint('DEBUG: NAIPSService - Trying URL: $url');
            try {
              final finalResponse = await http.get(
                Uri.parse(url),
                headers: {
                  'Cookie': _buildCookieHeader(),
                  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
                  'Referer': '$baseUrl/Briefing/Location',
                  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                  'Accept-Language': 'en-US,en;q=0.5',
                  'Accept-Encoding': 'gzip, deflate',
                  'Connection': 'keep-alive',
                  'Cache-Control': 'no-cache',
                },
              );
              debugPrint('DEBUG: NAIPSService - URL $url response status: ${finalResponse.statusCode}');
              debugPrint('DEBUG: NAIPSService - URL $url response headers: ${finalResponse.headers}');
              
              // Update cookies from the redirect response
              _parseSessionCookies(finalResponse.headers);
              debugPrint('DEBUG: NAIPSService - Updated cookies after redirect: ${_sessionCookies.length}');
              
              if (finalResponse.statusCode == 200) {
                debugPrint('DEBUG: NAIPSService - Found working URL: $url');
                debugPrint('DEBUG: NAIPSService - Final response body length: ${finalResponse.body.length}');
                if (finalResponse.body.length > 0) {
                  debugPrint('DEBUG: NAIPSService - Final response preview: ${finalResponse.body.substring(0, finalResponse.body.length > 1000 ? 1000 : finalResponse.body.length)}');
                  
                  // Check if we got the login page instead of results
                  if (finalResponse.body.contains('LogOn') || finalResponse.body.contains('login') || finalResponse.body.contains('UserName')) {
                    debugPrint('DEBUG: NAIPSService - WARNING: Got login page instead of results!');
                  } else if (finalResponse.body.contains('Location Briefing Results')) {
                    debugPrint('DEBUG: NAIPSService - SUCCESS: Got briefing results!');
                    
                    // Look for the actual briefing content
                    if (finalResponse.body.contains('<pre')) {
                      debugPrint('DEBUG: NAIPSService - Found <pre> tags - looking for briefing content...');
                      final preMatches = RegExp(r'<pre[^>]*>(.*?)</pre>', dotAll: true).allMatches(finalResponse.body);
                      for (int i = 0; i < preMatches.length; i++) {
                        final preContent = preMatches.elementAt(i).group(1);
                        debugPrint('DEBUG: NAIPSService - PRE content ${i + 1}: ${preContent?.substring(0, preContent.length > 2000 ? 2000 : preContent.length)}');
                      }
                    }
                    
                    // Also look for any text that looks like weather data
                    if (finalResponse.body.contains('METAR') || finalResponse.body.contains('TAF') || finalResponse.body.contains('NOTAM')) {
                      debugPrint('DEBUG: NAIPSService - Found weather/NOTAM keywords in response!');
                      
                      // Extract text between specific markers
                      final weatherMatches = RegExp(r'(METAR|TAF|NOTAM)[^<]*', caseSensitive: false).allMatches(finalResponse.body);
                      for (final match in weatherMatches.take(5)) {
                        debugPrint('DEBUG: NAIPSService - Weather data: ${match.group(0)}');
                      }
                    }
                  }
                }
                return finalResponse.body;
              }
            } catch (e) {
              debugPrint('DEBUG: NAIPSService - URL $url failed: $e');
            }
          }
          
          // If none work, return the original response
          debugPrint('DEBUG: NAIPSService - No working URL found, returning original response');
          return response.body;
        }
      }
      
      return response.body;
    } catch (e) {
      debugPrint('DEBUG: NAIPSService - Location briefing request error: $e');
      rethrow;
    }
  }
  
  /// Parse session cookies from response headers
  void _parseSessionCookies(Map<String, String> headers) {
    // Get all Set-Cookie headers (there might be multiple)
    final setCookieHeaders = headers.entries
        .where((entry) => entry.key.toLowerCase() == 'set-cookie')
        .map((entry) => entry.value)
        .toList();
    
    debugPrint('DEBUG: NAIPSService - Found ${setCookieHeaders.length} Set-Cookie headers');
    
    for (final cookieHeader in setCookieHeaders) {
      debugPrint('DEBUG: NAIPSService - Parsing cookie header: $cookieHeader');
      
      // Split by comma to handle multiple cookies in one header
      final individualCookies = cookieHeader.split(',');
      
      for (final individualCookie in individualCookies) {
        // Split by semicolon to get individual parts
        final cookieParts = individualCookie.split(';');
        if (cookieParts.isNotEmpty) {
          final nameValue = cookieParts[0].split('=');
          if (nameValue.length >= 2) {
            final name = nameValue[0].trim();
            final value = nameValue.sublist(1).join('=').trim();
            
            // Only store if we don't already have this cookie or if it's a newer value
            if (name.isNotEmpty && value.isNotEmpty) {
              _sessionCookies[name] = value;
              debugPrint('DEBUG: NAIPSService - Stored cookie: $name = $value');
            }
          }
        }
      }
    }
    
    debugPrint('DEBUG: NAIPSService - Total cookies after parsing: ${_sessionCookies.length}');
  }
  
  /// Build cookie header for authenticated requests
  String _buildCookieHeader() {
    return _sessionCookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  /// Public helper to build standard authenticated headers for NAIPS GETs
  Map<String, String> buildAuthHeaders({String? referer}) {
    return {
      if (_sessionCookies.isNotEmpty) 'Cookie': _buildCookieHeader(),
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
      if (referer != null) 'Referer': referer,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache',
    };
  }

  /// Verify that current cookies can access the Chart Directory. Returns true when
  /// the response looks like the directory (has table headers like Code/Name),
  /// false when we got the login page.
  /// Fetch first/last light data for a specific airport and date
  /// Returns a map with 'firstLight' and 'lastLight' times in UTC
  Future<Map<String, String>?> fetchFirstLastLight({
    required String icao,
    required DateTime date,
  }) async {
    if (!_isAuthenticated) {
      debugPrint('DEBUG: NAIPSService - Cannot fetch first/last light: not authenticated');
      return null;
    }

    try {
      debugPrint('DEBUG: NAIPSService - Fetching first/last light for $icao on ${date.toIso8601String()}');
      
      // Try multiple approaches for first/last light
      // Approach 1: Page navigation approach (more reliable)
      debugPrint('DEBUG: NAIPSService - Trying Approach 1: Page navigation...');
      final result1 = await _tryPageNavigationApproach(icao, date);
      if (result1 != null) {
        debugPrint('DEBUG: NAIPSService - Approach 1 succeeded');
        return result1;
      }
      
      // Approach 2: Try page navigation with longer delays
      debugPrint('DEBUG: NAIPSService - Trying Approach 2: Page navigation with delays...');
      final result2 = await _tryPageNavigationWithDelays(icao, date);
      if (result2 != null) {
        debugPrint('DEBUG: NAIPSService - Approach 2 succeeded');
        return result2;
      }
      
      // Approach 3: Direct POST (like weather briefing) - try last
      debugPrint('DEBUG: NAIPSService - Trying Approach 3: Direct POST...');
      final result3 = await _tryDirectPostApproach(icao, date);
      if (result3 != null) {
        debugPrint('DEBUG: NAIPSService - Approach 3 succeeded');
        return result3;
      }
      
      
      debugPrint('DEBUG: NAIPSService - All approaches failed for $icao');
      return null;
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Exception fetching first/last light for $icao: $e');
      return null;
    }
  }
  
  /// Submit the First/Last Light form following proper flow
  Future<Map<String, String>?> _submitFirstLastLightForm(String icao, DateTime date) async {
    try {
      // Format date as YYMMDD (e.g., "250920" for 20 Sep 2025)
      final dateStr = _formatDateForNaips(date);
      debugPrint('DEBUG: NAIPSService - Formatted date: $dateStr');
      
      // Prepare form data
      final formData = {
        'DomesticOnly': 'true',
        'LocationName': icao.toUpperCase(),
        'FirstLastDate': dateStr,
      };
      
      debugPrint('DEBUG: NAIPSService - Form data: $formData');
      debugPrint('DEBUG: NAIPSService - Submitting First/Last Light form...');
      
      // Submit the form
      final response = await http.post(
        Uri.parse('$baseUrl/FirstLastLight'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/FirstLastLight',
          'Origin': 'https://www.airservicesaustralia.com',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-AU,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'same-origin',
        },
        body: formData.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );
      
      debugPrint('DEBUG: NAIPSService - Form submission response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('DEBUG: NAIPSService - Form submission response body length: ${response.body.length}');
        
        // Parse HTML response to extract first/last light times
        final result = _parseFirstLastLightHtml(response.body);
        if (result != null) {
          debugPrint('DEBUG: NAIPSService - Successfully fetched first/last light data for $icao: $result');
          return result;
        } else {
          debugPrint('DEBUG: NAIPSService - Failed to parse first/last light HTML for $icao');
          return null;
        }
      } else if (response.statusCode == 302) {
        // Handle redirect to results page
        final redirectLocation = response.headers['location'];
        debugPrint('DEBUG: NAIPSService - Form submission redirect to: $redirectLocation');
        
        if (redirectLocation != null && redirectLocation.contains('ShowResults')) {
          // Follow the redirect to the results page
          String resultsUrl;
          if (redirectLocation.startsWith('http')) {
            resultsUrl = redirectLocation;
          } else {
            // Remove leading /naips/ if present to avoid double /naips/naips/
            final cleanRedirect = redirectLocation.startsWith('/naips/') 
                ? redirectLocation.substring(6) // Remove '/naips'
                : redirectLocation;
            resultsUrl = '$baseUrl$cleanRedirect';
          }
          debugPrint('DEBUG: NAIPSService - Following redirect to results page...');
          debugPrint('DEBUG: NAIPSService - Corrected redirect URL: $resultsUrl');
          
          // Add a small delay before following the redirect
          await Future.delayed(Duration(milliseconds: 500));
          
          final resultsResponse = await http.get(
            Uri.parse(resultsUrl),
            headers: {
              'Cookie': _buildCookieHeader(),
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
              'Referer': '$baseUrl/FirstLastLight',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-AU,en;q=0.9',
              'Accept-Encoding': 'gzip, deflate, br',
              'Connection': 'keep-alive',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          );
          
          debugPrint('DEBUG: NAIPSService - Results page response status: ${resultsResponse.statusCode}');
          debugPrint('DEBUG: NAIPSService - Results page body length: ${resultsResponse.body.length}');
          
          // Update cookies from results page response
          _parseSessionCookies(resultsResponse.headers);
          debugPrint('DEBUG: NAIPSService - Updated cookies after results page: ${_sessionCookies.length}');
          
          if (resultsResponse.statusCode == 200) {
            return _parseFirstLastLightHtml(resultsResponse.body);
          } else {
            debugPrint('DEBUG: NAIPSService - Results page failed with status: ${resultsResponse.statusCode}');
            return null;
          }
        } else {
          debugPrint('DEBUG: NAIPSService - Unexpected redirect location: $redirectLocation');
          return null;
        }
      } else {
        debugPrint('DEBUG: NAIPSService - Form submission failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Form submission failed: $e');
      return null;
    }
  }

  /// Try direct POST approach (like weather briefing)
  Future<Map<String, String>?> _tryDirectPostApproach(String icao, DateTime date) async {
    try {
      // Add a small delay to ensure session is fully established
      debugPrint('DEBUG: NAIPSService - Waiting for session to stabilize...');
      await Future.delayed(Duration(milliseconds: 1000));
      
      // First, navigate to the First/Last Light page to get any additional cookies (like weather flow)
      debugPrint('DEBUG: NAIPSService - Step 1: Navigating to First/Last Light page to get additional cookies...');
      try {
        final firstLastLightPageResponse = await http.get(
          Uri.parse('$baseUrl/FirstLastLight'),
          headers: {
            'Cookie': _buildCookieHeader(),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
            'Referer': '$baseUrl/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-AU,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        );
        debugPrint('DEBUG: NAIPSService - First/Last Light page response status: ${firstLastLightPageResponse.statusCode}');
        
        // Update cookies from First/Last Light page response
        _parseSessionCookies(firstLastLightPageResponse.headers);
        debugPrint('DEBUG: NAIPSService - Updated cookies after First/Last Light page: ${_sessionCookies.length}');
        
        if (firstLastLightPageResponse.statusCode != 200) {
          debugPrint('DEBUG: NAIPSService - First/Last Light page failed, but continuing with POST...');
        }
        
        // Navigate back to main page to get any additional cookies
        debugPrint('DEBUG: NAIPSService - Step 1.5: Navigating back to main page for additional cookies...');
        try {
          final mainPageResponse = await http.get(
            Uri.parse('$baseUrl/'),
            headers: {
              'Cookie': _buildCookieHeader(),
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
              'Referer': '$baseUrl/FirstLastLight',
            },
          );
          _parseSessionCookies(mainPageResponse.headers);
          debugPrint('DEBUG: NAIPSService - Final cookies after main page: ${_sessionCookies.length}');
        } catch (e) {
          debugPrint('DEBUG: NAIPSService - Main page navigation failed: $e');
        }
      } catch (e) {
        debugPrint('DEBUG: NAIPSService - First/Last Light page navigation failed: $e');
      }
      
      // Format date as DDMMYY (e.g., "150925" for 15 Sep 2025)
      final dateStr = _formatDateForNaips(date);
      debugPrint('DEBUG: NAIPSService - Formatted date: $dateStr');
      
      // Prepare form data
      final formData = {
        'DomesticOnly': 'true',
        'LocationName': icao.toUpperCase(),
        'FirstLastDate': dateStr,
      };
      
      debugPrint('DEBUG: NAIPSService - Form data: $formData');
      debugPrint('DEBUG: NAIPSService - Making POST request to FirstLastLight endpoint');
      
      // Step 2: Submit First/Last Light form directly (like weather briefing)
      debugPrint('DEBUG: NAIPSService - Step 2: Submitting First/Last Light form directly...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/FirstLastLight'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/FirstLastLight',
          'Origin': 'https://www.airservicesaustralia.com',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-AU,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'same-origin',
        },
        body: formData.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&'),
      );
      
      debugPrint('DEBUG: NAIPSService - First/last light response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('DEBUG: NAIPSService - First/last light response body length: ${response.body.length}');
        debugPrint('DEBUG: NAIPSService - First/last light response preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        
        // Parse HTML response to extract first/last light times
        final result = _parseFirstLastLightHtml(response.body);
        if (result != null) {
          debugPrint('DEBUG: NAIPSService - Successfully fetched first/last light data for $icao: $result');
          return result;
        } else {
          debugPrint('DEBUG: NAIPSService - Failed to parse first/last light HTML for $icao');
          return null;
        }
      } else if (response.statusCode == 302) {
        // Handle redirect to results page
        final redirectLocation = response.headers['location'];
        debugPrint('DEBUG: NAIPSService - First/last light redirect to: $redirectLocation');
        
        if (redirectLocation != null && redirectLocation.contains('ShowResults')) {
          // Follow the redirect to get the actual results
          debugPrint('DEBUG: NAIPSService - Following redirect to results page...');
          
          // Add a small delay to ensure the server has processed the request
          await Future.delayed(Duration(milliseconds: 500));
          
          // Try different URL formats for the results page (like weather briefing)
          // Clean the redirect location to avoid double /naips/naips/
          final cleanRedirect = redirectLocation.startsWith('/naips/') 
              ? redirectLocation.substring(6) // Remove '/naips'
              : redirectLocation;
          
          final possibleUrls = [
            '$baseUrl$cleanRedirect', // Clean format
            'https://www.airservicesaustralia.com$redirectLocation', // Full URL
            '$baseUrl/FirstLastLight/ShowResults', // Direct path
            '$baseUrl/FirstLastLight/Results', // Alternative path
          ];
          
          for (final url in possibleUrls) {
            debugPrint('DEBUG: NAIPSService - Trying URL: $url');
            try {
              final resultsResponse = await http.get(
                Uri.parse(url),
                headers: {
                  'Cookie': _buildCookieHeader(),
                  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
                  'Referer': '$baseUrl/FirstLastLight',
                  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                  'Accept-Language': 'en-AU,en;q=0.9',
                  'Accept-Encoding': 'gzip, deflate, br',
                  'Connection': 'keep-alive',
                  'Cache-Control': 'no-cache, no-store, must-revalidate',
                  'Pragma': 'no-cache',
                  'Expires': '0',
                },
              );
              
              debugPrint('DEBUG: NAIPSService - URL $url response status: ${resultsResponse.statusCode}');
              debugPrint('DEBUG: NAIPSService - URL $url response headers: ${resultsResponse.headers}');
              
              // Update cookies from results response
              _parseSessionCookies(resultsResponse.headers);
              debugPrint('DEBUG: NAIPSService - Updated cookies after results page: ${_sessionCookies.length}');
              
              if (resultsResponse.statusCode == 200) {
                debugPrint('DEBUG: NAIPSService - Found working URL: $url');
                debugPrint('DEBUG: NAIPSService - Results page body length: ${resultsResponse.body.length}');
                debugPrint('DEBUG: NAIPSService - Results page preview: ${resultsResponse.body.substring(0, resultsResponse.body.length > 500 ? 500 : resultsResponse.body.length)}');
                
                // Check if we got the login page instead of results
                if (resultsResponse.body.contains('LogOn') || resultsResponse.body.contains('login') || resultsResponse.body.contains('UserName')) {
                  debugPrint('DEBUG: NAIPSService - WARNING: Got login page instead of results!');
                  continue; // Try next URL
                } else if (resultsResponse.body.contains('First Light - Last Light Results') || resultsResponse.body.contains('First-Light') || resultsResponse.body.contains('Last-Light')) {
                  debugPrint('DEBUG: NAIPSService - SUCCESS: Got first/last light results!');
                  
                  // Parse HTML response to extract first/last light times
                  final result = _parseFirstLastLightHtml(resultsResponse.body);
                  if (result != null) {
                    debugPrint('DEBUG: NAIPSService - Successfully fetched first/last light data for $icao: $result');
                    return result;
                  } else {
                    debugPrint('DEBUG: NAIPSService - Failed to parse first/last light HTML from results page for $icao');
                    continue; // Try next URL
                  }
                } else {
                  debugPrint('DEBUG: NAIPSService - Unknown page content, trying next URL...');
                  continue; // Try next URL
                }
              }
            } catch (e) {
              debugPrint('DEBUG: NAIPSService - URL $url failed: $e');
            }
          }
          
          // If none work, return null
          debugPrint('DEBUG: NAIPSService - No working URL found for results page');
          return null;
        } else {
          debugPrint('DEBUG: NAIPSService - Unexpected redirect location: $redirectLocation');
          debugPrint('DEBUG: NAIPSService - Redirect response body: ${response.body}');
          return null;
        }
      } else {
        debugPrint('DEBUG: NAIPSService - First/last light HTTP error ${response.statusCode} for $icao');
        debugPrint('DEBUG: NAIPSService - Error response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Exception fetching first/last light for $icao: $e');
      return null;
    }
  }

  /// Try page navigation approach with longer delays (more reliable)
  Future<Map<String, String>?> _tryPageNavigationWithDelays(String icao, DateTime date) async {
    try {
      // Add a longer delay to ensure session is fully established
      debugPrint('DEBUG: NAIPSService - Waiting longer for session to stabilize...');
      await Future.delayed(Duration(milliseconds: 2000));
      
      // Navigate to First/Last Light page to get any additional cookies
      debugPrint('DEBUG: NAIPSService - Step 1: Navigating to First/Last Light page...');
      final firstLastLightPageResponse = await http.get(
        Uri.parse('$baseUrl/FirstLastLight'),
        headers: {
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-AU,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      debugPrint('DEBUG: NAIPSService - First/Last Light page response status: ${firstLastLightPageResponse.statusCode}');
      
      // Update cookies from First/Last Light page response
      _parseSessionCookies(firstLastLightPageResponse.headers);
      debugPrint('DEBUG: NAIPSService - Updated cookies after First/Last Light page: ${_sessionCookies.length}');
      
      if (firstLastLightPageResponse.statusCode != 200) {
        debugPrint('DEBUG: NAIPSService - First/Last Light page failed, but continuing with POST...');
      }
      
      // Navigate back to main page to get additional cookies
      debugPrint('DEBUG: NAIPSService - Step 2: Navigating back to main page for additional cookies...');
      final mainPageResponse = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/FirstLastLight',
        },
      );
      _parseSessionCookies(mainPageResponse.headers);
      debugPrint('DEBUG: NAIPSService - Final cookies after main page: ${_sessionCookies.length}');
      
      // Add another longer delay before POST request
      debugPrint('DEBUG: NAIPSService - Waiting longer before POST request...');
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Now submit the form to get results
      return await _submitFirstLastLightForm(icao, date);
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Page navigation with delays approach failed: $e');
      return null;
    }
  }

  /// Try page navigation approach (more complex but might work)
  Future<Map<String, String>?> _tryPageNavigationApproach(String icao, DateTime date) async {
    try {
      // Add a small delay to ensure session is fully established
      debugPrint('DEBUG: NAIPSService - Waiting for session to stabilize...');
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Navigate to First/Last Light page to get any additional cookies
      debugPrint('DEBUG: NAIPSService - Step 1: Navigating to First/Last Light page...');
      final firstLastLightPageResponse = await http.get(
        Uri.parse('$baseUrl/FirstLastLight'),
        headers: {
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      );
      debugPrint('DEBUG: NAIPSService - First/Last Light page response status: ${firstLastLightPageResponse.statusCode}');
      
      // Update cookies from First/Last Light page response
      _parseSessionCookies(firstLastLightPageResponse.headers);
      debugPrint('DEBUG: NAIPSService - Updated cookies after First/Last Light page: ${_sessionCookies.length}');
      
      if (firstLastLightPageResponse.statusCode != 200) {
        debugPrint('DEBUG: NAIPSService - First/Last Light page failed, but continuing with POST...');
      }
      
      // Navigate back to main page to get additional cookies
      debugPrint('DEBUG: NAIPSService - Step 2: Navigating back to main page for additional cookies...');
      final mainPageResponse = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Cookie': _buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/FirstLastLight',
        },
      );
      _parseSessionCookies(mainPageResponse.headers);
      debugPrint('DEBUG: NAIPSService - Final cookies after main page: ${_sessionCookies.length}');
      
      // Add another small delay before POST request
      debugPrint('DEBUG: NAIPSService - Waiting before POST request...');
      await Future.delayed(Duration(milliseconds: 500));
      
      // Now submit the form to get results
      return await _submitFirstLastLightForm(icao, date);
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Page navigation approach failed: $e');
      return null;
    }
  }

  /// Formats DateTime to YYMMDD format for NAIPS
  String _formatDateForNaips(DateTime date) {
    final year = date.year.toString().substring(2); // Get last 2 digits
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// Parses the HTML response from NAIPS to extract first/last light times
  Map<String, String>? _parseFirstLastLightHtml(String htmlString) {
    try {
      debugPrint('DEBUG: NAIPSService - Parsing HTML of length ${htmlString.length}');
      
      // Check if this is the expected results page
      if (htmlString.contains('First Light - Last Light Results')) {
        debugPrint('DEBUG: NAIPSService - Found expected results page title');
        
        // Look for the actual HTML structure: <td><span>First-Light:</span></td><td>19:31&nbsp;UTC</td>
        final firstLightMatch = RegExp(r'<td><span>First-Light:</span></td>\s*<td>(\d{1,2}:\d{2})&nbsp;UTC</td>', caseSensitive: false).firstMatch(htmlString);
        final lastLightMatch = RegExp(r'<td><span>Last-Light:</span></td>\s*<td>(\d{1,2}:\d{2})&nbsp;UTC</td>', caseSensitive: false).firstMatch(htmlString);
        
        // If the above doesn't work, try a more flexible approach
        if (firstLightMatch == null || lastLightMatch == null) {
          final firstLightMatch2 = RegExp(r'First-Light:\s*(\d{1,2}:\d{2})', caseSensitive: false).firstMatch(htmlString);
          final lastLightMatch2 = RegExp(r'Last-Light:\s*(\d{1,2}:\d{2})', caseSensitive: false).firstMatch(htmlString);
          
          if (firstLightMatch2 != null && lastLightMatch2 != null) {
            final firstLight = firstLightMatch2.group(1)!;
            final lastLight = lastLightMatch2.group(1)!;
            
            debugPrint('DEBUG: NAIPSService - Successfully parsed times (flexible): First=$firstLight, Last=$lastLight');
            return {
              'firstLight': firstLight,
              'lastLight': lastLight,
            };
          }
        }
        
        // If still no match, try looking for the table structure directly
        if (firstLightMatch == null || lastLightMatch == null) {
          final tableMatch = RegExp(r'<table[^>]*class="formTable"[^>]*>.*?First-Light:\s*(\d{1,2}:\d{2})[^<]*UTC[^<]*Last-Light:\s*(\d{1,2}:\d{2})[^<]*UTC', caseSensitive: false, dotAll: true).firstMatch(htmlString);
          
          if (tableMatch != null) {
            final firstLight = tableMatch.group(1)!;
            final lastLight = tableMatch.group(2)!;
            
            debugPrint('DEBUG: NAIPSService - Successfully parsed times (table): First=$firstLight, Last=$lastLight');
            return {
              'firstLight': firstLight,
              'lastLight': lastLight,
            };
          }
        }
        
        if (firstLightMatch != null && lastLightMatch != null) {
          final firstLight = firstLightMatch.group(1)!;
          final lastLight = lastLightMatch.group(1)!;
          
          debugPrint('DEBUG: NAIPSService - Successfully parsed times: First=$firstLight, Last=$lastLight');
          return {
            'firstLight': firstLight,
            'lastLight': lastLight,
          };
        }
        
        // Fallback: Look for other time patterns
        final timePatterns = [
          r'First.*?Light.*?(\d{1,2}:\d{2})',
          r'Last.*?Light.*?(\d{1,2}:\d{2})',
          r'First-Light.*?(\d{1,2}:\d{2})',
          r'Last-Light.*?(\d{1,2}:\d{2})',
        ];
        
        for (int i = 0; i < timePatterns.length; i += 2) {
          if (i + 1 < timePatterns.length) {
            final firstMatch = RegExp(timePatterns[i], caseSensitive: false).firstMatch(htmlString);
            final lastMatch = RegExp(timePatterns[i + 1], caseSensitive: false).firstMatch(htmlString);
            
            if (firstMatch != null && lastMatch != null) {
              final firstLight = firstMatch.group(1)!;
              final lastLight = lastMatch.group(1)!;
              
              debugPrint('DEBUG: NAIPSService - Fallback pattern ${i ~/ 2 + 1} worked: First=$firstLight, Last=$lastLight');
              return {
                'firstLight': firstLight,
                'lastLight': lastLight,
              };
            }
          }
        }
        
        debugPrint('DEBUG: NAIPSService - No time patterns found in results page');
        
      } else if (htmlString.contains('NAIPS Login')) {
        debugPrint('DEBUG: NAIPSService - Got login page instead of results');
      } else {
        debugPrint('DEBUG: NAIPSService - Unknown page type - not results or login');
      }
      
      debugPrint('DEBUG: NAIPSService - Could not find first/last light in HTML');
      debugPrint('DEBUG: NAIPSService - HTML preview: ${htmlString.substring(0, htmlString.length > 1000 ? 1000 : htmlString.length)}');
      return null;
    } catch (e) {
      debugPrint('ERROR: NAIPSService - Error parsing first/last light HTML: $e');
      return null;
    }
  }

  Future<bool> ensureChartsSession() async {
    try {
      final uri = Uri.parse('$baseUrl/ChartDirectory');
      final res = await http.get(uri, headers: buildAuthHeaders(referer: '$baseUrl/'));
      debugPrint('DEBUG: NAIPSService - ensureChartsSession status: ${res.statusCode}');
      if (res.statusCode != 200) return false;
      final body = res.body;
      final looksLogin = body.contains('User Not Logged in') || body.contains('Login') || body.contains('User Name');
      if (looksLogin) return false;
      final looksDirectory = body.contains('Code') && body.contains('Lo-Res') && body.contains('Hi-Res');
      return looksDirectory;
    } catch (e) {
      debugPrint('DEBUG: NAIPSService - ensureChartsSession error: $e');
      return false;
    }
  }
  
  /// Check if currently authenticated
  bool get isAuthenticated => _isAuthenticated;
  
  /// Clear authentication state
  void clearAuthentication() {
    _isAuthenticated = false;
    _sessionCookies.clear();
    debugPrint('DEBUG: NAIPSService - Authentication cleared');
  }
} 