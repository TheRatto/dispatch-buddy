# NAIPS Integration Roadmap

## Overview
This document outlines the implementation plan for integrating NAIPS (Airservices Australia) data into Dispatch Buddy, providing users with access to Australian aviation weather and NOTAM data using their own NAIPS credentials.

## Goals
- Add NAIPS as an optional data source alongside existing free APIs
- Maintain all existing functionality without breaking changes
- Provide users with access to comprehensive Australian aviation data
- Implement secure credential storage and session management

## Current State Analysis

### Existing Data Sources (PRESERVE)
- **Weather APIs**: AviationWeather.gov (METAR/TAF), FAA APIs
- **NOTAM APIs**: FAA NOTAM API with SATCOM optimization
- **Airport Data**: ERSA integration for Australian airports + OpenAIP for international
- **Services**: `ApiService`, `AirportCacheManager`, `ERSADataService`

### NAIPS Integration Points
- **Authentication**: User-provided NAIPS credentials
- **Data Types**: Weather (METAR, TAF, ATIS), NOTAMs (Airport and FIR)
- **Priority**: Toggle in settings to prioritize NAIPS over free APIs
- **Geographic Scope**: Primarily Australian domestic, with international capability

## Technical Architecture

### Authentication Flow
```
User enters credentials → POST /naips/Account/LogOn → 302 redirect → Session cookies set
```

### Data Request Flow
```
Authenticated session → POST /naips/Briefing/Location → 302 redirect → GET /naips/Briefing/LocationResults → HTML response with <pre> tags
```

### Response Format
- **HTML response** with embedded text data in `<pre class="briefing">` tags
- **Structured aviation data**: TAF, METAR, ATIS, NOTAMs
- **Clean, parseable format** similar to existing API responses

## Implementation Phases

### Phase 1: Foundation & Authentication (Week 1)

#### 1.1 Create NAIPSService Class
**File**: `lib/services/naips_service.dart`
**Purpose**: Handle NAIPS authentication and requests
**Dependencies**: `http` package (already used in existing services)

```dart
class NAIPSService {
  static const String baseUrl = 'https://www.airservicesaustralia.com/naips';
  
  // Session management
  Map<String, String> _sessionCookies = {};
  bool _isAuthenticated = false;
  
  // Authentication method
  Future<bool> authenticate(String username, String password) async {
    // Implementation details below
  }
  
  // Data request methods
  Future<String> requestLocationBriefing(String icao, {int validityHours = 6}) async {
    // Implementation details below
  }
}
```

#### 1.2 Add Settings Integration
**File**: `lib/providers/settings_provider.dart`
**Changes**: Add NAIPS settings (PRESERVE existing settings)
```dart
// ADD to existing SettingsProvider class
bool naipsEnabled = false;
String? naipsUsername;
String? naipsPassword;
```

#### 1.3 Update Settings UI
**File**: `lib/screens/settings_screen.dart`
**Changes**: Add NAIPS section (PRESERVE existing UI)
```dart
// ADD new section to existing settings form
// NAIPS Credentials Section
// - Username field
// - Password field  
// - Enable/disable toggle
```

### Phase 2: Data Request Implementation (Week 2)

#### 2.1 Implement Authentication Method
```dart
Future<bool> authenticate(String username, String password) async {
  try {
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
    
    if (response.statusCode == 302) {
      // Parse and store session cookies
      _parseSessionCookies(response.headers);
      _isAuthenticated = true;
      return true;
    }
    
    return false;
  } catch (e) {
    print('NAIPS authentication error: $e');
    return false;
  }
}
```

#### 2.2 Implement Location Briefing Request
```dart
Future<String> requestLocationBriefing(String icao, {int validityHours = 6}) async {
  if (!_isAuthenticated) {
    throw Exception('NAIPS not authenticated');
  }
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/Briefing/Location'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': _buildCookieHeader(),
        'Referer': '$baseUrl/Briefing/Location',
      },
      body: {
        'Locations[0]': icao,
        'Met': 'true',
        'NOTAM': 'true', 
        'HeadOfficeNotam': 'false',
        'SEGMET': 'false',
        'Charts': 'true',
        'MidSigwxGpwt': 'true',
        'Validity': validityHours.toString(),
        'DomesticOnly': 'true',
      },
    );
    
    // Handle redirect to get final response
    if (response.statusCode == 302) {
      final redirectUrl = response.headers['location'];
      if (redirectUrl != null) {
        final finalResponse = await http.get(
          Uri.parse('$baseUrl$redirectUrl'),
          headers: {'Cookie': _buildCookieHeader()},
        );
        return finalResponse.body;
      }
    }
    
    return response.body;
  } catch (e) {
    print('NAIPS briefing request error: $e');
    rethrow;
  }
}
```

### Phase 3: Data Parsing (Week 3)

#### 3.1 Create NAIPSParser Class
**File**: `lib/services/naips_parser.dart`
**Purpose**: Parse HTML responses into existing data models

```dart
class NAIPSParser {
  static List<Weather> parseWeatherFromHTML(String html) {
    // Extract <pre class="briefing"> content
    // Parse TAF, METAR, ATIS sections
    // Convert to existing Weather models
  }
  
  static List<Notam> parseNOTAMsFromHTML(String html) {
    // Extract NOTAM section
    // Parse individual NOTAM entries
    // Convert to existing Notam models
  }
  
  static String _extractBriefingContent(String html) {
    // Use html package to parse and extract <pre class="briefing"> content
  }
}
```

#### 3.2 Extend Existing Models (PRESERVE)
**File**: `lib/models/weather.dart`, `lib/models/notam.dart`
**Changes**: Add source field to existing models
```dart
// ADD to existing Weather class
final String source; // 'aviationweather', 'naips', 'faa'

// ADD to existing Notam class  
final String source; // 'faa', 'naips'
```

### Phase 4: Integration with Existing Services (Week 4)

#### 4.1 Update ApiService (PRESERVE existing functionality)
**File**: `lib/services/api_service.dart`
**Changes**: Add NAIPS routing logic
```dart
// MODIFY existing fetchWeather method (PRESERVE existing logic)
Future<List<Weather>> fetchWeather(List<String> icaos) async {
  final settings = context.read<SettingsProvider>();
  
  if (settings.naipsEnabled && settings.naipsUsername != null) {
    try {
      final naipsService = NAIPSService();
      final isAuthenticated = await naipsService.authenticate(
        settings.naipsUsername!,
        settings.naipsPassword ?? '',
      );
      
      if (isAuthenticated) {
        final html = await naipsService.requestLocationBriefing(icaos.first);
        final weather = NAIPSParser.parseWeatherFromHTML(html);
        return weather.map((w) => w.copyWith(source: 'naips')).toList();
      }
    } catch (e) {
      print('NAIPS weather fetch failed: $e');
      // Fall back to existing APIs
    }
  }
  
  // PRESERVE existing API logic
  return await _fetchWeatherFromFreeAPIs(icaos);
}

// MODIFY existing fetchNotams method (PRESERVE existing logic)
Future<List<Notam>> fetchNotams(String icao) async {
  final settings = context.read<SettingsProvider>();
  
  if (settings.naipsEnabled && settings.naipsUsername != null) {
    try {
      final naipsService = NAIPSService();
      final isAuthenticated = await naipsService.authenticate(
        settings.naipsUsername!,
        settings.naipsPassword ?? '',
      );
      
      if (isAuthenticated) {
        final html = await naipsService.requestLocationBriefing(icao);
        final notams = NAIPSParser.parseNOTAMsFromHTML(html);
        return notams.map((n) => n.copyWith(source: 'naips')).toList();
      }
    } catch (e) {
      print('NAIPS NOTAM fetch failed: $e');
      // Fall back to existing APIs
    }
  }
  
  // PRESERVE existing API logic
  return await _fetchNotamsFromFreeAPIs(icao);
}
```

#### 4.2 Add Error Handling
- **Authentication failures**: Fall back to free APIs
- **Network errors**: Retry logic with exponential backoff
- **Parsing errors**: Graceful degradation
- **Session expiry**: Automatic re-authentication

### Phase 5: Testing & Validation (Week 5)

#### 5.1 Unit Tests
**File**: `test/naips_service_test.dart`
- Authentication success/failure scenarios
- Data parsing accuracy
- Error handling

#### 5.2 Integration Tests
**File**: `test/naips_integration_test.dart`
- End-to-end data flow
- Fallback to free APIs
- Settings integration

#### 5.3 UI Tests
**File**: `test/naips_ui_test.dart`
- Settings page functionality
- Data source switching
- Error message display

### Phase 6: Polish & Documentation (Week 6)

#### 6.1 User Experience
- **Loading indicators** for NAIPS requests
- **Error messages** for authentication failures
- **Success indicators** when NAIPS data is used
- **Offline handling** for cached NAIPS data

#### 6.2 Documentation
- **User guide** for NAIPS setup
- **Developer documentation** for the integration
- **Troubleshooting guide** for common issues

## Risk Mitigation

### Preserving Existing Functionality
1. **No breaking changes** to existing APIs
2. **Fallback mechanisms** always available
3. **Feature flags** for gradual rollout
4. **Comprehensive testing** of existing functionality

### Security Considerations
1. **Secure credential storage** using Flutter's secure storage
2. **No credential logging** in debug output
3. **Session timeout handling**
4. **HTTPS enforcement** for all NAIPS requests

### Performance Considerations
1. **Caching** of NAIPS responses
2. **Parallel requests** where possible
3. **Timeout handling** for slow responses
4. **Memory management** for large responses

## Success Metrics

### Technical Metrics
- **Authentication success rate** > 95%
- **Data parsing accuracy** > 98%
- **Fallback reliability** 100%
- **No regression** in existing functionality

### User Metrics
- **NAIPS adoption rate** among Australian users
- **User satisfaction** with data quality
- **Error rate** for NAIPS-related issues
- **Performance impact** on app responsiveness

## Future Enhancements

### Phase 7: Advanced Features (Future)
- **Multiple airport briefings** in single request
- **Area briefings** for route planning
- **Custom briefing periods** beyond 6 hours
- **Offline caching** of NAIPS data
- **Push notifications** for new NOTAMs

### Phase 8: Integration Enhancements (Future)
- **Flight plan integration** with NAIPS
- **Automated briefing generation**
- **Export functionality** for NAIPS data
- **Advanced filtering** options

## Dependencies

### New Dependencies
- **html**: For parsing NAIPS HTML responses
- **flutter_secure_storage**: For credential storage

### Existing Dependencies (PRESERVE)
- **http**: Already used in existing services
- **provider**: Already used for state management
- **shared_preferences**: Already used for settings

## Timeline Summary

| Week | Phase | Focus | Deliverables |
|------|-------|-------|--------------|
| 1 | Foundation | Authentication & Settings | NAIPSService, Settings UI |
| 2 | Data Requests | Request Implementation | Location briefing requests |
| 3 | Parsing | Data Parsing | NAIPSParser, Model updates |
| 4 | Integration | Service Integration | ApiService updates |
| 5 | Testing | Validation | Unit, integration, UI tests |
| 6 | Polish | UX & Documentation | User guides, error handling |

## Notes

### Critical Preservation Points
1. **Existing ApiService methods** must maintain current behavior
2. **Settings provider** must preserve all existing settings
3. **UI components** must not break existing layouts
4. **Error handling** must not interfere with existing flows
5. **Testing** must include regression testing of existing features

### Development Guidelines
1. **Feature branches** for all NAIPS development
2. **Comprehensive testing** before merging
3. **Code review** focusing on preservation of existing functionality
4. **Gradual rollout** with feature flags
5. **Monitoring** of both new and existing functionality

This roadmap ensures that NAIPS integration enhances the app without compromising existing functionality, providing users with additional data sources while maintaining the reliability of current free APIs. 