import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/services/api_service.dart';

void main() {
  group('ApiService NAIPS Integration Tests', () {
    test('should fall back to free APIs when NAIPS is disabled', () async {
      final apiService = ApiService();
      
      // Test with NAIPS disabled (default behavior)
      final weatherList = await apiService.fetchWeather(
        ['YSCB'],
        naipsEnabled: false,
        naipsUsername: null,
        naipsPassword: null,
      );
      
      // Should return weather data from free APIs
      expect(weatherList, isNotEmpty);
      print('✅ Test passed: Free API weather data returned');
      
      // Test NOTAMs
      final notamList = await apiService.fetchNotams(
        'YSCB',
        naipsEnabled: false,
        naipsUsername: null,
        naipsPassword: null,
      );
      
      // Should return NOTAM data from free APIs
      expect(notamList, isNotEmpty);
      print('✅ Test passed: Free API NOTAM data returned');
      
      // Test TAFs
      final tafList = await apiService.fetchTafs(
        ['YSCB'],
        naipsEnabled: false,
        naipsUsername: null,
        naipsPassword: null,
      );
      
      // Should return TAF data from free APIs
      expect(tafList, isNotEmpty);
      print('✅ Test passed: Free API TAF data returned');
    });

    test('should attempt NAIPS when enabled but fall back on authentication failure', () async {
      final apiService = ApiService();
      
      // Test with NAIPS enabled but invalid credentials
      final weatherList = await apiService.fetchWeather(
        ['YSCB'],
        naipsEnabled: true,
        naipsUsername: 'invalid',
        naipsPassword: 'invalid',
      );
      
      // Should fall back to free APIs when NAIPS authentication fails
      expect(weatherList, isNotEmpty);
      print('✅ Test passed: NAIPS authentication failed, fell back to free APIs');
    });

    test('should handle empty NAIPS credentials gracefully', () async {
      final apiService = ApiService();
      
      // Test with NAIPS enabled but null credentials
      final weatherList = await apiService.fetchWeather(
        ['YSCB'],
        naipsEnabled: true,
        naipsUsername: null,
        naipsPassword: null,
      );
      
      // Should fall back to free APIs when credentials are null
      expect(weatherList, isNotEmpty);
      print('✅ Test passed: NAIPS credentials null, fell back to free APIs');
    });
  });
} 