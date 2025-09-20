import 'dart:io';
import 'lib/services/naips_service.dart';
import 'lib/models/first_last_light.dart';

void main(List<String> args) async {
  print('🔍 Testing NAIPS Service Directly...\n');

  // Get credentials from command line arguments
  String username;
  String password;
  
  if (args.length >= 2) {
    username = args[0];
    password = args[1];
    print('🔐 Using credentials from command line arguments');
  } else {
    print('❌ Please provide NAIPS credentials as command line arguments:');
    print('   dart run test_naips_direct.dart <username> <password>');
    print('');
    print('   Example: dart run test_naips_direct.dart jamesmitchell111 naIpsnaIps1');
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
    print('🔐 Step 1: Creating new NAIPSService instance...');
    final naipsService = NAIPSService();
    
    print('🔐 Step 2: Authenticating...');
    final isAuthenticated = await naipsService.authenticate(username, password);
    
    if (!isAuthenticated) {
      print('❌ FAILED: Authentication failed for $icao');
      return;
    }
    
    print('✅ Authentication successful for $icao');
    
    print('🔍 Step 3: Fetching First/Last Light data...');
    final data = await naipsService.fetchFirstLastLight(
      icao: icao,
      date: date,
    );
    
    if (data != null) {
      print('✅ SUCCESS: Got data for $icao');
      print('   - First Light: ${data['firstLight']}');
      print('   - Last Light: ${data['lastLight']}');
      
      // Test the model creation
      print('📊 Step 4: Creating FirstLastLight model...');
      final firstLastLight = FirstLastLight.fromApiResponse(
        icao: icao,
        date: date,
        data: data,
      );
      
      print('✅ Model created successfully:');
      print('   - ICAO: ${firstLastLight.icao}');
      print('   - First Light: ${firstLastLight.firstLight}');
      print('   - Last Light: ${firstLastLight.lastLight}');
      print('   - Date: ${firstLastLight.date}');
      
    } else {
      print('❌ FAILED: No data returned for $icao');
    }
    
  } catch (e) {
    print('❌ ERROR for $icao: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
}
