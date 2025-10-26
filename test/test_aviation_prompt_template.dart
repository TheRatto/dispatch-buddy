import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/aviation_prompt_template.dart';
import 'package:briefing_buddy/models/flight_context.dart';
import 'package:briefing_buddy/models/weather.dart';
import 'package:briefing_buddy/models/notam.dart';
import 'package:briefing_buddy/models/airport.dart';
import 'package:briefing_buddy/models/airport_infrastructure.dart';

void main() {
  group('AviationPromptTemplate', () {
    late FlightContext testFlightContext;
    late List<Weather> testWeatherData;
    late List<Notam> testNotams;
    late List<Airport> testAirports;

    setUp(() {
      // Create test flight context
      testFlightContext = FlightContext(
        departureIcao: 'YPPH',
        destinationIcao: 'YSSY',
        alternateIcaos: ['YBBN', 'YMML'],
        departureTime: DateTime(2024, 1, 15, 14, 30),
        arrivalTime: DateTime(2024, 1, 15, 18, 45),
        aircraftType: 'B737-800',
        flightRules: 'IFR',
        pilotExperience: 'ATP',
        briefingStyle: 'comprehensive',
      );

      // Create test weather data
      testWeatherData = [
        Weather(
          icao: 'YPPH',
          timestamp: DateTime(2024, 1, 15, 14, 0),
          rawText: 'YPPH 150400Z 25015G25KT 10SM SCT030 BKN050 25/15 Q1015',
          decodedText: 'Perth Airport, 4:00 AM UTC, Wind 250° at 15 knots gusting 25, 10 statute miles visibility, scattered clouds at 3000 feet, broken clouds at 5000 feet, temperature 25°C, dew point 15°C, pressure 1015 hPa',
          windDirection: 250,
          windSpeed: 15,
          visibility: 10,
          cloudCover: 'SCT030 BKN050',
          temperature: 25.0,
          dewPoint: 15.0,
          qnh: 1015,
          conditions: 'VFR',
          type: 'METAR',
          decodedWeather: null,
          source: 'aviationweather',
        ),
        Weather(
          icao: 'YSSY',
          timestamp: DateTime(2024, 1, 15, 14, 0),
          rawText: 'YSSY 150400Z 18012KT 10SM FEW030 BKN080 28/18 Q1018',
          decodedText: 'Sydney Airport, 4:00 AM UTC, Wind 180° at 12 knots, 10 statute miles visibility, few clouds at 3000 feet, broken clouds at 8000 feet, temperature 28°C, dew point 18°C, pressure 1018 hPa',
          windDirection: 180,
          windSpeed: 12,
          visibility: 10,
          cloudCover: 'FEW030 BKN080',
          temperature: 28.0,
          dewPoint: 18.0,
          qnh: 1018,
          conditions: 'VFR',
          type: 'TAF',
          decodedWeather: null,
          source: 'aviationweather',
        ),
      ];

      // Create test NOTAMs
      testNotams = [
        Notam(
          id: 'A1234/24',
          qCode: 'RWY',
          rawText: 'A1234/24 YPPH RWY 03/21 CLSD 15JAN06:00 15JAN18:00',
          fieldD: 'YPPH',
          fieldE: 'RWY 03/21 CLSD',
          fieldF: '15JAN06:00',
          fieldG: '15JAN18:00',
          validFrom: DateTime(2024, 1, 15, 6, 0),
          validTo: DateTime(2024, 1, 15, 18, 0),
          icao: 'YPPH',
          type: NotamType.runway,
          group: NotamGroup.runways,
          isPermanent: false,
          isCritical: true,
        ),
        Notam(
          id: 'A1235/24',
          qCode: 'NAV',
          rawText: 'A1235/24 YSSY ILS RWY 16L U/S 15JAN08:00 15JAN20:00',
          fieldD: 'YSSY',
          fieldE: 'ILS RWY 16L U/S',
          fieldF: '15JAN08:00',
          fieldG: '15JAN20:00',
          validFrom: DateTime(2024, 1, 15, 8, 0),
          validTo: DateTime(2024, 1, 15, 20, 0),
          icao: 'YSSY',
          type: NotamType.navaid,
          group: NotamGroup.instrumentProcedures,
          isPermanent: false,
          isCritical: true,
        ),
      ];

      // Create test airports
      testAirports = [
        Airport(
          icao: 'YPPH',
          name: 'Perth Airport',
          city: 'Perth',
          latitude: -31.9403,
          longitude: 115.9669,
          systems: {},
          runways: [
            Runway(
              identifier: '03/21',
              length: 3444.0, // meters
              surface: 'Asphalt',
              approaches: [],
              hasLighting: true,
              width: 45.0,
              status: 'CLOSED',
            ),
            Runway(
              identifier: '06/24',
              length: 2164.0, // meters
              surface: 'Asphalt',
              approaches: [],
              hasLighting: true,
              width: 45.0,
              status: 'OPERATIONAL',
            ),
          ],
          navaids: [],
        ),
        Airport(
          icao: 'YSSY',
          name: 'Sydney Kingsford Smith Airport',
          city: 'Sydney',
          latitude: -33.9399,
          longitude: 151.1753,
          systems: {},
          runways: [
            Runway(
              identifier: '16L/34R',
              length: 2438.0, // meters
              surface: 'Asphalt',
              approaches: [],
              hasLighting: true,
              width: 45.0,
              status: 'OPERATIONAL',
            ),
            Runway(
              identifier: '16R/34L',
              length: 2438.0, // meters
              surface: 'Asphalt',
              approaches: [],
              hasLighting: true,
              width: 45.0,
              status: 'OPERATIONAL',
            ),
          ],
          navaids: [],
        ),
      ];
    });

    test('should generate comprehensive briefing prompt', () {
      final prompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: testFlightContext,
        weatherData: testWeatherData,
        notams: testNotams,
        airports: testAirports,
        briefingStyle: 'comprehensive',
      );

      // Verify prompt contains key sections
      expect(prompt, contains('=== FLIGHT CONTEXT ==='));
      expect(prompt, contains('YPPH → YSSY'));
      expect(prompt, contains('B737-800'));
      expect(prompt, contains('IFR'));

      expect(prompt, contains('=== AIRPORT INFORMATION ==='));
      expect(prompt, contains('YPPH - Perth Airport'));
      expect(prompt, contains('YSSY - Sydney Kingsford Smith Airport'));

      expect(prompt, contains('=== WEATHER DATA ==='));
      expect(prompt, contains('CURRENT METARs:'));
      expect(prompt, contains('YPPH 150400Z 25015G25KT'));

      expect(prompt, contains('=== NOTAMs ==='));
      expect(prompt, contains('RUNWAY NOTAMs:'));
      expect(prompt, contains('A1234/24 YPPH RWY 03/21 CLSD'));
      expect(prompt, contains('NAVAID NOTAMs:'));
      expect(prompt, contains('A1235/24 YSSY ILS RWY 16L U/S'));

      expect(prompt, contains('=== BRIEFING REQUEST ==='));
      expect(prompt, contains('Generate a comprehensive flight briefing'));
      expect(prompt, contains('Briefing Style: comprehensive'));
    });

    test('should generate quick prompt for simple queries', () {
      final prompt = AviationPromptTemplate.generateQuickPrompt(
        query: 'What is the weather at YPPH?',
        weatherData: testWeatherData,
        notams: testNotams,
      );

      expect(prompt, contains('=== QUICK QUERY ==='));
      expect(prompt, contains('Query: What is the weather at YPPH?'));
      expect(prompt, contains('CURRENT WEATHER:'));
      expect(prompt, contains('YPPH 150400Z 25015G25KT'));
      expect(prompt, contains('RELEVANT NOTAMs:'));
    });

    test('should handle empty data gracefully', () {
      final prompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: testFlightContext,
        weatherData: [],
        notams: [],
        airports: [],
      );

      expect(prompt, contains('No active NOTAMs'));
      expect(prompt, contains('=== FLIGHT CONTEXT ==='));
      expect(prompt, contains('YPPH → YSSY'));
    });

    test('should format runway lengths correctly', () {
      final prompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: testFlightContext,
        weatherData: [],
        notams: [],
        airports: testAirports,
      );

      // Check that runway lengths are converted from meters to feet
      expect(prompt, contains('03/21 (11299ft)')); // 3444m * 3.28084 = 11299ft (rounded)
      expect(prompt, contains('06/24 (7100ft)'));  // 2164m * 3.28084 = 7100ft
    });

    test('should group NOTAMs by type correctly', () {
      final prompt = AviationPromptTemplate.generateBriefingPrompt(
        flightContext: testFlightContext,
        weatherData: [],
        notams: testNotams,
        airports: [],
      );

      expect(prompt, contains('RUNWAY NOTAMs:'));
      expect(prompt, contains('A1234/24 YPPH RWY 03/21 CLSD'));
      expect(prompt, contains('NAVAID NOTAMs:'));
      expect(prompt, contains('A1235/24 YSSY ILS RWY 16L U/S'));
    });
  });
}
