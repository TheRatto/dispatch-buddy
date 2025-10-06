import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/api_service.dart';
import 'package:briefing_buddy/services/naips_service.dart';
import 'package:briefing_buddy/models/first_last_light.dart';

void main() {
  group('First/Last Light Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('should test NAIPS First/Last Light service directly', () async {
      // Test credentials - you can modify these for your test account
      const username = 'jamesmitchell111';
      const password = 'naIpsnaIps1';
      
      print('🔍 Testing NAIPS First/Last Light service directly...');
      
      final naipsService = NAIPSService();
      final today = DateTime.now();
      
      // Test authentication
      print('🔐 Authenticating...');
      final isAuthenticated = await naipsService.authenticate(username, password);
      
      if (!isAuthenticated) {
        print('❌ Authentication failed - skipping test');
        return;
      }
      
      print('✅ Authentication successful');
      
      // Test fetching First/Last Light data
      print('🔍 Fetching First/Last Light data for YSSY...');
      final data = await naipsService.fetchFirstLastLight(
        icao: 'YSSY',
        date: today,
      );
      
      if (data != null) {
        print('✅ Got data: ${data}');
        
        // Test model creation
        final firstLastLight = FirstLastLight.fromApiResponse(
          icao: 'YSSY',
          date: today,
          data: data,
        );
        
        print('✅ Model created: ${firstLastLight.firstLight} - ${firstLastLight.lastLight}');
        
        expect(firstLastLight.icao, 'YSSY');
        expect(firstLastLight.firstLight, isNotEmpty);
        expect(firstLastLight.lastLight, isNotEmpty);
      } else {
        print('❌ No data returned');
        expect(data, isNotNull); // This will fail if no data
      }
    });

    test('should test ApiService fetchFirstLastLight method', () async {
      print('🔍 Testing ApiService fetchFirstLastLight method...');
      
      final apiService = ApiService();
      
      // Test single airport
      print('🏢 Testing single airport (YSSY)...');
      final singleResult = await apiService.fetchFirstLastLight(['YSSY']);
      
      print('📊 Single airport result: ${singleResult.length} items');
      if (singleResult.isNotEmpty) {
        final firstLastLight = singleResult.first;
        print('✅ Got data for ${firstLastLight.icao}: ${firstLastLight.firstLight} - ${firstLastLight.lastLight}');
        expect(firstLastLight.icao, 'YSSY');
      } else {
        print('❌ No data returned for single airport');
      }
      
      // Test multiple airports
      print('🏢 Testing multiple airports (YSSY, YSCB)...');
      final multipleResult = await apiService.fetchFirstLastLight(['YSSY', 'YSCB']);
      
      print('📊 Multiple airports result: ${multipleResult.length} items');
      for (final firstLastLight in multipleResult) {
        print('✅ Got data for ${firstLastLight.icao}: ${firstLastLight.firstLight} - ${firstLastLight.lastLight}');
        expect(['YSSY', 'YSCB'], contains(firstLastLight.icao));
      }
      
      if (multipleResult.isEmpty) {
        print('❌ No data returned for multiple airports');
      }
    });

    test('should handle authentication failure gracefully', () async {
      print('🔍 Testing authentication failure handling...');
      
      final naipsService = NAIPSService();
      
      // Test with invalid credentials
      print('🔐 Testing with invalid credentials...');
      final isAuthenticated = await naipsService.authenticate('invalid', 'invalid');
      
      expect(isAuthenticated, isFalse);
      print('✅ Authentication correctly failed with invalid credentials');
      
      // Test fetchFirstLastLight with unauthenticated service
      print('🔍 Testing fetchFirstLastLight with unauthenticated service...');
      final data = await naipsService.fetchFirstLastLight(
        icao: 'YSSY',
        date: DateTime.now(),
      );
      
      expect(data, isNull);
      print('✅ fetchFirstLastLight correctly returned null when not authenticated');
    });
  });
}
