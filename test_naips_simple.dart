import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  print('🔍 Testing NAIPS First/Last Light Directly...\n');

  // Get credentials from command line arguments
  String username;
  String password;
  
  if (args.length >= 2) {
    username = args[0];
    password = args[1];
    print('🔐 Using credentials from command line arguments');
  } else {
    print('❌ Please provide NAIPS credentials as command line arguments:');
    print('   dart run test_naips_simple.dart <username> <password>');
    print('');
    print('   Example: dart run test_naips_simple.dart jamesmitchell111 naIpsnaIps1');
    exit(1);
  }

  final testIcaos = ['YSSY', 'YSCB'];
  final today = DateTime.now();
  
  print('📅 Today\'s date: ${today.day}/${today.month}/${today.year}\n');

  for (final icao in testIcaos) {
    print('🏢 Testing $icao...');
    await testSingleAirport(username, password, icao, today);
    print('');
  }
}

Future<void> testSingleAirport(String username, String password, String icao, DateTime date) async {
  try {
    print('🔐 Step 1: Authenticating...');
    
    // Store cookies for the session
    Map<String, String> cookies = {};
    
    // Authenticate
    final authResponse = await http.post(
      Uri.parse('https://www.airservicesaustralia.com/naips/Account/LogOn'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
        'Referer': 'https://www.airservicesaustralia.com/naips/Account/LogOn',
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
    if (authResponse.statusCode == 302) {
      print('✅ Authentication successful - received 302 redirect');
      final redirectLocation = authResponse.headers['location'];
      if (redirectLocation != null) {
        print('🔄 Following auth redirect to: $redirectLocation');
        final redirectResponse = await http.get(
          Uri.parse('https://www.airservicesaustralia.com$redirectLocation'),
          headers: {
            'Cookie': _buildCookieHeader(cookies),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
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
      return;
    }

    print('🍪 Current cookies after authentication: ${cookies.length} cookies');

    // Step 2: Navigate to main page to establish session
    print('📄 Step 2: Navigating to main page to establish session...');
    final mainPageResponse = await http.get(
      Uri.parse('https://www.airservicesaustralia.com/naips/'),
      headers: {
        'Cookie': _buildCookieHeader(cookies),
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
        'Referer': 'https://www.airservicesaustralia.com/naips/Account/LogOn',
      },
    );
    print('📄 Main page response status: ${mainPageResponse.statusCode}');
    _parseSessionCookies(mainPageResponse.headers, cookies);

    // Step 3: Skip First/Last Light page navigation (like weather briefing)
    print('📄 Step 3: Skipping First/Last Light page navigation (direct POST approach)...');

    // Step 4: Perform POST request for First/Last Light data
    print('✉️ Step 4: Performing POST request for First/Last Light data for $icao...');
    
    // Format date as YYMMDD (e.g., "250919" for 19 Sep 2025)
    final dateStr = _formatDateForNaips(date);
    print('📅 Formatted date (YYMMDD): $dateStr');
    
    final postResponse = await http.post(
      Uri.parse('https://www.airservicesaustralia.com/naips/FirstLastLight'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': _buildCookieHeader(cookies),
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'Referer': 'https://www.airservicesaustralia.com/naips/FirstLastLight',
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
        'FirstLastDate': dateStr,
      },
    );

    print('✉️ POST response status: ${postResponse.statusCode}');
    _parseSessionCookies(postResponse.headers, cookies);

    if (postResponse.statusCode == 302) {
      final redirectLocation = postResponse.headers['location'];
      print('🔄 POST request redirected to: $redirectLocation');

      if (redirectLocation != null && redirectLocation.contains('ShowResults')) {
        print('🔄 Following redirect to results page...');

        // Fix double /naips/ in URL
        final fullUrl = redirectLocation.startsWith('/naips/')
            ? 'https://www.airservicesaustralia.com$redirectLocation'
            : 'https://www.airservicesaustralia.com/naips$redirectLocation';

        print('🔄 Corrected redirect URL: $fullUrl');

        // Add a small delay to ensure the server has processed the request
        await Future.delayed(Duration(milliseconds: 500));

        final resultsResponse = await http.get(
          Uri.parse(fullUrl),
          headers: {
            'Cookie': _buildCookieHeader(cookies),
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
            'Referer': 'https://www.airservicesaustralia.com/naips/FirstLastLight',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-AU,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        );

        print('✅ Results page response status: ${resultsResponse.statusCode}');
        print('📄 Results page body length: ${resultsResponse.body.length}');
        _parseSessionCookies(resultsResponse.headers, cookies);

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
          }
        } else {
          print('❌ Results page error ${resultsResponse.statusCode}');
        }
      } else {
        print('❌ Unexpected redirect location: $redirectLocation');
      }
    } else {
      print('❌ POST request did not redirect as expected for $icao');
    }
    
  } catch (e) {
    print('❌ ERROR for $icao: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
}

String _formatDateForNaips(DateTime date) {
  final year = date.year.toString().substring(2); // Get last 2 digits
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year$month$day';
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
    print('🔍 DEBUG: Parsing HTML with length: ${htmlString.length}');
    
    // Check if this is the expected results page
    if (htmlString.contains('First Light - Last Light Results')) {
      print('✅ Found expected results page title');
      
      // Look for table structures first
      print('🔍 Looking for table structures...');
      final tableMatches = RegExp(r'<table[^>]*>.*?</table>', caseSensitive: false, dotAll: true).allMatches(htmlString);
      print('🔍 Found ${tableMatches.length} table structures');
      
      for (int i = 0; i < tableMatches.length; i++) {
        final tableContent = tableMatches.elementAt(i).group(0)!;
        print('🔍 Table ${i + 1} content: ${tableContent.substring(0, tableContent.length > 500 ? 500 : tableContent.length)}...');
        
        // Look for time patterns in table
        final firstLightMatch = RegExp(r'First.*?Light.*?(\d{1,2}:\d{2})', caseSensitive: false).firstMatch(tableContent);
        final lastLightMatch = RegExp(r'Last.*?Light.*?(\d{1,2}:\d{2})', caseSensitive: false).firstMatch(tableContent);
        
        if (firstLightMatch != null && lastLightMatch != null) {
          final firstLight = firstLightMatch.group(1)!;
          final lastLight = lastLightMatch.group(1)!;
          
          print('✅ Found times in table ${i + 1}: First=$firstLight, Last=$lastLight');
          return {
            'firstLight': firstLight,
            'lastLight': lastLight,
          };
        }
      }
      
      // Look for div structures with time content
      print('🔍 Looking for div structures with time content...');
      final timeDivMatches = RegExp(r'<div[^>]*>.*?(\d{1,2}:\d{2}).*?</div>', caseSensitive: false, dotAll: true).allMatches(htmlString);
      print('🔍 Found ${timeDivMatches.length} div structures with time content');
      
      for (int i = 0; i < timeDivMatches.length; i++) {
        final divContent = timeDivMatches.elementAt(i).group(0)!;
        print('🔍 Div ${i + 1} content: ${divContent.substring(0, divContent.length > 200 ? 200 : divContent.length)}...');
      }
      
      // Look for any time patterns in the entire HTML
      print('🔍 Looking for any time patterns in HTML...');
      final allTimeMatches = RegExp(r'(\d{1,2}:\d{2})', caseSensitive: false).allMatches(htmlString);
      print('🔍 Found ${allTimeMatches.length} time patterns: ${allTimeMatches.map((m) => m.group(1)).take(10).join(", ")}');
      
      // Look for specific text patterns
      final textPatterns = [
        r'First.*?Light.*?(\d{1,2}:\d{2})',
        r'Last.*?Light.*?(\d{1,2}:\d{2})',
        r'First-Light.*?(\d{1,2}:\d{2})',
        r'Last-Light.*?(\d{1,2}:\d{2})',
        r'First Light.*?(\d{1,2}:\d{2})',
        r'Last Light.*?(\d{1,2}:\d{2})',
      ];
      
      for (int i = 0; i < textPatterns.length; i += 2) {
        if (i + 1 < textPatterns.length) {
          final firstMatch = RegExp(textPatterns[i], caseSensitive: false).firstMatch(htmlString);
          final lastMatch = RegExp(textPatterns[i + 1], caseSensitive: false).firstMatch(htmlString);
          
          if (firstMatch != null && lastMatch != null) {
            final firstLight = firstMatch.group(1)!;
            final lastLight = lastMatch.group(1)!;
            
            print('✅ Text pattern ${i ~/ 2 + 1} worked: First=$firstLight, Last=$lastLight');
            return {
              'firstLight': firstLight,
              'lastLight': lastLight,
            };
          }
        }
      }
      
      print('❌ No time patterns found in results page');
      print('🔍 HTML preview (first 3000 chars): ${htmlString.substring(0, htmlString.length > 3000 ? 3000 : htmlString.length)}');
      
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
