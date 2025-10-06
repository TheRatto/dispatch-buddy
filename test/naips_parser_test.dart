import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/naips_parser.dart';

void main() {
  group('NAIPSParser Tests', () {
    test('should parse weather data from NAIPS HTML', () {
      // Sample NAIPS HTML response (from our previous successful test)
      final sampleHtml = '''
<!DOCTYPE html>
<html>
<head>
    <title>LocationResults</title>
</head>
<body>
    <pre>0211 UTC 02/08/25             AIRSERVICES AUSTRALIA
                                 LOCATION BRIEFING

PREPARED FOR: PAULRATTIGAN
VALID FROM 0211 UTC AUG 02, 2025 TO 0811 UTC AUG 02, 2025

                                WEATHER INFORMATION
                                -------------------

CANBERRA (YSCB)
     TAF YSCB 020204Z 0203/0300
     13016G26KT 9999 SHOWERS OF LIGHT RAIN BKN030
     FM020700 14014KT 9999 NO SIG WX BKN025
     TEMPO 0212/0300  9999 BKN020
     RMK FM020600 MOD TURB BLW 5000FT TL021800
     T 11 11 08 07 Q 1022 1022 1024 1024
     TAF3

     SPECI YSCB 020200Z AUTO 14014KT 9999 // BKN023 BKN027 OVC037 11/06
     Q1023 RMK RF00.0/000.0

     ATIS YSCB D   012323
       APCH: EXP INSTRUMENT APCH
       RWY: 17
       SFC COND: SURFACE CONDITION CODE, 5, 5, 5.WET, WET, WET
     + WIND: 140/10-20, MAX XW 14 KTS
       VIS: GT 10 KM
       WX: SH IN AREA
     + CLD: FEW015, BKN025
     + TMP: 12
     + QNH: 1023</pre>
    
    <pre>                                 NOTAM INFORMATION
                                -----------------

CANBERRA (YSCB)
                                                    C520/25 REVIEW C342/25
     TWY N CL LGT NOT TO STD
     BLUE TEMP EDGE LGT AVBL
     FROM 07 300400 TO 10 250000 EST

                                                                    C515/25
     AIP DEP AND APCH (DAP) YSCB AMD
     RNP Y RWY 35(AR)
     RNP X RWY 35(AR)
     RNP W RWY 35(AR)
     RNP 0.11 (3.8% MAP) MINIMA 2220 (351-1.1)
     DUE TO CRANE PUBLISHED IN SEPARATE NOTAM
     FROM 08 010400 TO 08 020800</pre>
</body>
</html>
''';

      // Test weather parsing
      final weatherList = NAIPSParser.parseWeatherFromHTML(sampleHtml);
      
      // Should find at least one weather item (TAF, METAR, or ATIS)
      expect(weatherList.length, greaterThan(0));
      
      // Check that we have the expected types
      final types = weatherList.map((w) => w.type).toSet();
      expect(types, contains('TAF'));
      expect(types, contains('METAR'));
      expect(types, contains('ATIS'));
      
      // Check that all items have valid ICAO codes
      for (final weather in weatherList) {
        expect(weather.icao, isNotEmpty);
        expect(weather.rawText, isNotEmpty);
        expect(weather.decodedWeather, isNotNull);
      }
      
      print('✅ Weather parsing test passed: Found ${weatherList.length} weather items');
      for (final weather in weatherList) {
        print('- ${weather.type} for ${weather.icao}: ${weather.rawText.substring(0, weather.rawText.length > 50 ? 50 : weather.rawText.length)}...');
      }
    });

    test('should parse NOTAMs from NAIPS HTML', () {
      final sampleHtml = '''
<!DOCTYPE html>
<html>
<body>
    <pre>                                 NOTAM INFORMATION
                                -----------------

CANBERRA (YSCB)
                                                    C520/25 REVIEW C342/25
     TWY N CL LGT NOT TO STD
     BLUE TEMP EDGE LGT AVBL
     FROM 07 300400 TO 10 250000 EST

                                                                    C515/25
     AIP DEP AND APCH (DAP) YSCB AMD
     RNP Y RWY 35(AR)
     RNP X RWY 35(AR)
     RNP W RWY 35(AR)
     RNP 0.11 (3.8% MAP) MINIMA 2220 (351-1.1)
     DUE TO CRANE PUBLISHED IN SEPARATE NOTAM
     FROM 08 010400 TO 08 020800</pre>
</body>
</html>
''';

      // Test NOTAM parsing
      final notamList = NAIPSParser.parseNOTAMsFromHTML(sampleHtml);
      
      // Should find at least one NOTAM
      expect(notamList.length, greaterThan(0));
      
      // Check that all NOTAMs have valid IDs
      for (final notam in notamList) {
        expect(notam.id, isNotEmpty);
        expect(notam.rawText, isNotEmpty);
      }
      
      print('✅ NOTAM parsing test passed: Found ${notamList.length} NOTAMs');
      for (final notam in notamList) {
        print('- NOTAM ${notam.id}: ${notam.rawText.substring(0, notam.rawText.length > 50 ? 50 : notam.rawText.length)}...');
      }
    });

    test('should handle empty or invalid HTML gracefully', () {
      // Test with empty HTML
      final emptyWeather = NAIPSParser.parseWeatherFromHTML('');
      expect(emptyWeather, isEmpty);
      
      final emptyNotams = NAIPSParser.parseNOTAMsFromHTML('');
      expect(emptyNotams, isEmpty);
      
      // Test with invalid HTML
      final invalidWeather = NAIPSParser.parseWeatherFromHTML('<html><body>No weather data</body></html>');
      expect(invalidWeather, isEmpty);
      
      final invalidNotams = NAIPSParser.parseNOTAMsFromHTML('<html><body>No NOTAM data</body></html>');
      expect(invalidNotams, isEmpty);
      
      print('✅ Error handling test passed');
    });
  });
} 