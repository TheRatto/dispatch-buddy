import 'package:flutter_test/flutter_test.dart';
import '../lib/services/airport_api_service.dart';
import '../lib/models/airport.dart';

void main() {
  group('AirportApiService', () {
    test('fetches KJFK airport from API', () async {
      final airport = await AirportApiService.fetchAirportData('KJFK');
      expect(airport, isNotNull);
      expect(airport!.icao, equals('KJFK'));
      expect(airport.name.toLowerCase(), contains('kennedy'));
      expect(airport.city.toLowerCase(), contains('ny')); //State code instead of full name
      expect(airport.latitude, isNonZero);
      expect(airport.longitude, isNonZero);
    });
  });
}

Matcher get isNonZero => isNot(equals(0)); 