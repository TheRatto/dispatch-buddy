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
  String? _workingBriefingUrl; // Store the working URL we found
  
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
        
        // Don't follow server redirect - instead navigate like a browser
        // The session cookies should be sufficient for subsequent requests
        debugPrint('DEBUG: NAIPSService - Session established with ${_sessionCookies.length} cookies');
        
        // Navigate to the main NAIPS page to establish session
        debugPrint('DEBUG: NAIPSService - Navigating to main NAIPS page...');
        final mainPageResponse = await http.get(
          Uri.parse('$baseUrl/'),
          headers: {
            'Cookie': _buildCookieHeader(),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
            'Referer': '$baseUrl/Account/LogOn',
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
                        debugPrint('DEBUG: NAIPSService - PRE content ${i + 1}: ${preContent?.substring(0, preContent!.length > 2000 ? 2000 : preContent.length)}');
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
  
  /// Check if currently authenticated
  bool get isAuthenticated => _isAuthenticated;
  
  /// Clear authentication state
  void clearAuthentication() {
    _isAuthenticated = false;
    _sessionCookies.clear();
    debugPrint('DEBUG: NAIPSService - Authentication cleared');
  }
} 