import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  print('🔍 Testing Fixed First/Last Light functionality...\n');

  // Get credentials from command line arguments
  String username;
  String password;
  
  if (args.length >= 2) {
    username = args[0];
    password = args[1];
    print('🔐 Using credentials from command line arguments');
  } else {
    print('❌ Please provide NAIPS credentials as command line arguments:');
    print('   dart run test_first_last_light_fixed.dart <username> <password>');
    print('');
    print('   Example: dart run test_first_last_light_fixed.dart jamesmitchell111 naIpsnaIps1');
    exit(1);
  }
  
  final baseUrl = 'https://www.airservicesaustralia.com/naips';
  final testIcaos = ['YSSY', 'YSCB'];
  final today = DateTime.now();
  final formattedDate = _formatDateForNaips(today);
  
  print('📅 Today\'s date: ${today.day}/${today.month}/${today.year}');
  print('📅 Formatted date (YYMMDD): $formattedDate\n');

  // Test First/Last Light for each ICAO (with fixed flow)
  for (final icao in testIcaos) {
    print('🏢 Testing $icao with FIXED flow...');

    // Store cookies for the session for this specific airport
    Map<String, String> cookies = {};

    // Step 1: Authenticate for this airport
    print('🔐 Authenticating for $icao...');
    final authResponse = await http.post(
      Uri.parse('$baseUrl/Account/LogOn'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'Referer': '$baseUrl/Account/LogOn',
        'Origin': 'https://www.airservicesaustralia.com',
      },
      body: {
        'UserName': username,
        'Password': password,
      },
    );

    _parseSessionCookies(authResponse.headers, cookies);
    print('🔐 Auth response status: ${authResponse.statusCode}');

    bool isAuthenticated = false;
    if (authResponse.statusCode == 200) {
      if (authResponse.body.contains('logout') || authResponse.body.contains('Logout')) {
        print('✅ Authentication successful - found logout link');
        isAuthenticated = true;
      } else if (authResponse.body.contains('NAIPS Login') || authResponse.body.contains('login')) {
        print('❌ Authentication failed - returned login page (credentials may be incorrect)');
      } else if (authResponse.body.contains('error') || authResponse.body.contains('Error')) {
        print('❌ Authentication failed - found error in response');
      } else {
        print('⚠️  Unexpected 200 response - continuing to test...');
      }
    } else if (authResponse.statusCode == 302) {
      print('✅ Authentication successful - received 302 redirect');
      final redirectLocation = authResponse.headers['location'];
      if (redirectLocation != null) {
        print('🔄 Following auth redirect to: $redirectLocation');
        final redirectResponse = await http.get(
          Uri.parse('$baseUrl$redirectLocation'),
          headers: {
            'Cookie': _buildCookieHeader(cookies),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
          },
        );
        _parseSessionCookies(redirectResponse.headers, cookies);
        print('🔐 Auth redirect response status: ${redirectResponse.statusCode}');
        isAuthenticated = true;
      }
    } else {
      print('❌ Authentication failed with status: ${authResponse.statusCode}');
    }

    if (!isAuthenticated) {
      print('❌ Skipping First/Last Light fetch for $icao due to authentication failure.');
      print('');
      continue; // Skip to next airport
    }

    print('🍪 Current cookies after authentication for $icao: $cookies\n');

    // Step 2: Navigate to main page to establish session (like weather briefing does)
    print('📄 Step 2: Navigating to main page to establish session...');
    final mainPageResponse = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Cookie': _buildCookieHeader(cookies),
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
        'Referer': '$baseUrl/Account/LogOn',
      },
    );
    print('📄 Main page response status: ${mainPageResponse.statusCode}');
    _parseSessionCookies(mainPageResponse.headers, cookies);
    print('🍪 Cookies after main page navigation: ${cookies.length} cookies');

    // Step 3: Navigate to First/Last Light page to get viewstate values
    print('📄 Step 3: Navigating to First/Last Light page to get viewstate values...');
    // Try different possible URLs for First/Last Light
    final possibleUrls = [
      '$baseUrl/FirstLastLight',
      '$baseUrl/First-Last-Light', 
      '$baseUrl/FirstLastLight/Index',
      '$baseUrl/Briefing/FirstLastLight',
      '$baseUrl/Weather/FirstLastLight',
    ];
    
    http.Response? firstLastLightPageResponse;
    String? workingUrl;
    
    for (final url in possibleUrls) {
      print('📄 Trying URL: $url');
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Cookie': _buildCookieHeader(cookies),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
            'Referer': '$baseUrl/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
        );
        print('📄 Response status for $url: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('✅ Found working URL: $url');
          firstLastLightPageResponse = response;
          workingUrl = url;
          break;
        } else if (response.statusCode == 404) {
          print('❌ 404 for $url');
        } else {
          print('⚠️ Unexpected status ${response.statusCode} for $url');
        }
      } catch (e) {
        print('❌ Error accessing $url: $e');
      }
    }
    
    if (firstLastLightPageResponse == null) {
      print('❌ No working URL found for First/Last Light page');
      firstLastLightPageResponse = http.Response('', 404);
    } else {
      print('📄 Using working URL: $workingUrl');
    }
    
    print('📄 First/Last Light page response status: ${firstLastLightPageResponse.statusCode}');
    _parseSessionCookies(firstLastLightPageResponse.headers, cookies);
    print('🍪 Cookies after First/Last Light page navigation: $cookies');
    
    // Extract viewstate values from the page
    String viewState = '';
    String viewStateGenerator = '';
    String eventValidation = '';
    
    if (firstLastLightPageResponse.statusCode == 200) {
      final body = firstLastLightPageResponse.body;
      
      // Check if we got the actual form or login page
      if (body.contains('First Light - Last Light') || body.contains('FirstLastDate')) {
        print('✅ Got actual First/Last Light form page');
        
        final viewStateMatch = RegExp(r'name="__VIEWSTATE".*?value="([^"]*)"').firstMatch(body);
        final viewStateGeneratorMatch = RegExp(r'name="__VIEWSTATEGENERATOR".*?value="([^"]*)"').firstMatch(body);
        final eventValidationMatch = RegExp(r'name="__EVENTVALIDATION".*?value="([^"]*)"').firstMatch(body);
        
        viewState = viewStateMatch?.group(1) ?? '';
        viewStateGenerator = viewStateGeneratorMatch?.group(1) ?? '';
        eventValidation = eventValidationMatch?.group(1) ?? '';
        
        print('📄 Extracted viewstate values:');
        print('   __VIEWSTATE: ${viewState.length > 0 ? '${viewState.substring(0, 20)}...' : 'empty'}');
        print('   __VIEWSTATEGENERATOR: $viewStateGenerator');
        print('   __EVENTVALIDATION: ${eventValidation.length > 0 ? '${eventValidation.substring(0, 20)}...' : 'empty'}');
      } else {
        print('❌ Got login page instead of First/Last Light form');
        print('📄 HTML preview (first 1000 chars): ${body.substring(0, body.length > 1000 ? 1000 : body.length)}');
      }
    } else {
      print('❌ Failed to get First/Last Light page, proceeding without viewstate values');
    }

    // Step 4: Navigate back to main page for additional cookies (like weather briefing does)
    print('📄 Step 4: Navigating back to main page for additional cookies...');
    try {
      final mainPageResponse2 = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {
          'Cookie': _buildCookieHeader(cookies),
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
          'Referer': '$baseUrl/FirstLastLight',
        },
      );
      _parseSessionCookies(mainPageResponse2.headers, cookies);
      print('📄 Additional main page response status: ${mainPageResponse2.statusCode}');
      print('🍪 Final cookies after additional main page: ${cookies.length} cookies');
    } catch (e) {
      print('⚠️ Additional main page navigation failed: $e');
    }

    // Step 5: Perform POST request for First/Last Light data
    print('✉️ Step 5: Performing POST request for First/Last Light data for $icao...');
    final postResponse = await http.post(
      Uri.parse('$baseUrl/FirstLastLight'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': _buildCookieHeader(cookies),
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'Referer': '$baseUrl/FirstLastLight',
        'Origin': 'https://www.airservicesaustralia.com',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-AU,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
      },
      body: {
        'DomesticOnly': 'true',
        'LocationName': icao,
        'FirstLastDate': formattedDate,
        '__VIEWSTATE': viewState,
        '__VIEWSTATEGENERATOR': viewStateGenerator,
        '__EVENTVALIDATION': eventValidation,
      },
    );

    print('✉️ POST response status: ${postResponse.statusCode}');
    _parseSessionCookies(postResponse.headers, cookies);
    print('🍪 Cookies after POST request: $cookies');

    if (postResponse.statusCode == 302) {
      final redirectLocation = postResponse.headers['location'];
      print('🔄 POST request redirected to: $redirectLocation');

      if (redirectLocation != null && redirectLocation.contains('ShowResults')) {
        print('🔄 Following redirect to results page...');

        // Fix double /naips/ in URL
        final fullUrl = redirectLocation.startsWith('/naips/')
            ? 'https://www.airservicesaustralia.com$redirectLocation'
            : '$baseUrl$redirectLocation';

        print('🔄 Corrected redirect URL: $fullUrl');

        // Add a small delay to ensure the server has processed the request
        await Future.delayed(Duration(milliseconds: 500));

        final resultsResponse = await http.get(
          Uri.parse(fullUrl),
          headers: {
            'Cookie': _buildCookieHeader(cookies),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
            'Referer': '$baseUrl/FirstLastLight',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-AU,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        );

        print('✅ Results page response status: ${resultsResponse.statusCode}');
        print('📄 Results page body length: ${resultsResponse.body.length}');
        _parseSessionCookies(resultsResponse.headers, cookies);
        print('🍪 Cookies after results page: $cookies');

        if (resultsResponse.statusCode == 200) {
          final result = _parseFirstLastLightHtml(resultsResponse.body);
          if (result != null) {
            print('🎉 Successfully fetched First/Last Light for $icao:');
            print('   First Light (UTC): ${result['firstLight']}');
            print('   Last Light (UTC): ${result['lastLight']}');
          } else {
            print('❌ Failed to parse First/Last Light HTML from results page for $icao');
            print('DEBUG: Could not find first/last light patterns in HTML');
            print('DEBUG: HTML preview (first 2000 chars): ${resultsResponse.body.substring(0, resultsResponse.body.length > 2000 ? 2000 : resultsResponse.body.length)}');
            
            // Additional debugging for YSSY success case
            if (icao == 'YSSY') {
              print('🔍 YSSY DEBUG: Analyzing successful results page structure...');
              final body = resultsResponse.body;
              
              // Look for time patterns in different formats
              final timePatterns = [
                r'(\d{1,2}:\d{2})\s*(AM|PM)',
                r'(\d{1,2}:\d{2})\s*(am|pm)', 
                r'(\d{1,2}:\d{2})\s*UTC',
                r'(\d{1,2}:\d{2})\s*Z',
                r'First.*?Light.*?(\d{1,2}:\d{2})',
                r'Last.*?Light.*?(\d{1,2}:\d{2})',
                r'(\d{2}:\d{2})',
              ];
              
              for (int i = 0; i < timePatterns.length; i++) {
                final matches = RegExp(timePatterns[i], caseSensitive: false).allMatches(body);
                if (matches.isNotEmpty) {
                  print('🔍 Pattern ${i+1} found ${matches.length} matches: ${matches.map((m) => m.group(0)).take(5).join(", ")}');
                }
              }
              
              // Look for table structures
              final tableMatches = RegExp(r'<table[^>]*>.*?</table>', caseSensitive: false, dotAll: true).allMatches(body);
              print('🔍 Found ${tableMatches.length} table structures');
              
              // Look for div structures with time content
              final timeDivMatches = RegExp(r'<div[^>]*>.*?(\d{1,2}:\d{2}).*?</div>', caseSensitive: false, dotAll: true).allMatches(body);
              print('🔍 Found ${timeDivMatches.length} div structures with time content');
            }
          }
        } else {
          print('❌ Results page error ${resultsResponse.statusCode}');
          print('📄 404 response body: ${resultsResponse.body}');
        }
      } else if (redirectLocation != null && redirectLocation.contains('/naips/Account/LogOn')) {
        print('❌ Session expired - redirected to login page');
        print('🔍 This suggests the .ASPXAUTH cookie was cleared or invalidated');
        print('🔍 Redirect location: $redirectLocation');
      } else {
        print('❌ Unexpected redirect location: $redirectLocation');
      }
    } else {
      print('❌ POST request did not redirect as expected for $icao');
    }
    print(''); // Newline for readability
  }
}

String _formatDateForNaips(DateTime date) {
  return '${date.year.toString().substring(2, 4)}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

void _parseSessionCookies(Map<String, String> headers, Map<String, String> cookies) {
  final setCookieHeaders = headers['set-cookie'];
  if (setCookieHeaders != null) {
    // Handle multiple Set-Cookie headers (they come as a list)
    final cookieStrings = setCookieHeaders.split(',');
    
    for (final cookieString in cookieStrings) {
      final cookieStringTrimmed = cookieString.trim();
      if (cookieStringTrimmed.isEmpty) continue;
      
      // Split by semicolon to get cookie parts
      final parts = cookieStringTrimmed.split(';');
      if (parts.isNotEmpty) {
        final keyValue = parts[0].split('=');
        if (keyValue.length >= 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();
          
          // Only update if it's a valid cookie name and not empty
          if (key.isNotEmpty && value.isNotEmpty) {
            cookies[key] = value;
            print('🍪 Updated cookie: $key=${value.length > 20 ? '${value.substring(0, 20)}...' : value}');
          }
        }
      }
    }
  }
}

String _buildCookieHeader(Map<String, String> cookies) {
  return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
}

Map<String, String>? _parseFirstLastLightHtml(String htmlString) {
  try {
    // Attempt to find the table structure first
    final tableMatch = RegExp(
      r'<table[^>]*class="firstLastLightTable"[^>]*>(.*?)</table>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(htmlString);

    if (tableMatch != null) {
      final tableContent = tableMatch.group(1)!;

      final firstLightMatch = RegExp(r'First Light \(UTC\)[^<]*<td[^>]*>(\d{2}:\d{2})', caseSensitive: false).firstMatch(tableContent);
      final lastLightMatch = RegExp(r'Last Light \(UTC\)[^<]*<td[^>]*>(\d{2}:\d{2})', caseSensitive: false).firstMatch(tableContent);

      if (firstLightMatch != null && lastLightMatch != null) {
        final firstLight = firstLightMatch.group(1)!;
        final lastLight = lastLightMatch.group(1)!;

        return {
          'firstLight': firstLight,
          'lastLight': lastLight,
        };
      }
    }

    // Look for the exact format from the expected output: First-Light: 19:35 UTC
    print('🔍 DEBUG: Parsing HTML with length: ${htmlString.length}');
    
    // Check if this is the expected results page
    if (htmlString.contains('First Light - Last Light Results')) {
      print('✅ Found expected results page title');
      
      // Look for the exact format: First-Light: 19:35 UTC
      final firstLightMatch = RegExp(r'First-Light:\s*(\d{1,2}:\d{2})\s*UTC', caseSensitive: false).firstMatch(htmlString);
      final lastLightMatch = RegExp(r'Last-Light:\s*(\d{1,2}:\d{2})\s*UTC', caseSensitive: false).firstMatch(htmlString);
      
      if (firstLightMatch != null && lastLightMatch != null) {
        final firstLight = firstLightMatch.group(1)!;
        final lastLight = lastLightMatch.group(1)!;
        
        print('✅ Successfully parsed times: First=$firstLight, Last=$lastLight');
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
            
            print('✅ Fallback pattern ${i ~/ 2 + 1} worked: First=$firstLight, Last=$lastLight');
            return {
              'firstLight': firstLight,
              'lastLight': lastLight,
            };
          }
        }
      }
      
      print('❌ No time patterns found in results page');
      
    } else if (htmlString.contains('NAIPS Login')) {
      print('❌ Got login page instead of results');
    } else {
      print('❌ Unknown page type - not results or login');
    }

    return null;
  } catch (e) {
    print('ERROR parsing First/Last Light HTML: $e');
    return null;
  }
}
