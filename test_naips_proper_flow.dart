import 'dart:io';
import 'package:http/http.dart' as http;
import 'lib/services/naips_service.dart';

void main(List<String> args) async {
  if (args.length != 2) {
    print('Usage: dart run test_naips_proper_flow.dart <username> <password>');
    exit(1);
  }

  final username = args[0];
  final password = args[1];
  final date = DateTime.now();

  print('🔍 Testing NAIPS First/Last Light with Proper Flow...');
  print('📅 Today\'s date: ${date.day}/${date.month}/${date.year}');

  // Test both airports
  final airports = ['YSSY', 'YSCB'];
  
  for (final icao in airports) {
    print('\n🏢 Testing $icao...');
    
    try {
      // Create NAIPSService instance
      final naipsService = NAIPSService();
      
      // Authenticate
      print('🔐 Authenticating...');
      final authResult = await naipsService.authenticate(username, password);
      
      if (authResult) {
        print('✅ Authentication successful');
        
        // Fetch first/last light data
        print('📊 Fetching first/last light data...');
        final result = await naipsService.fetchFirstLastLight(icao, date);
        
        if (result != null) {
          print('✅ Successfully fetched first/last light data for $icao:');
          print('   First Light: ${result['firstLight']}');
          print('   Last Light: ${result['lastLight']}');
        } else {
          print('❌ Failed to fetch first/last light data for $icao');
        }
      } else {
        print('❌ Authentication failed');
      }
    } catch (e) {
      print('❌ Error testing $icao: $e');
    }
  }
  
  print('\n🏁 Test completed');
}
