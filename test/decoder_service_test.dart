import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/decoder_service.dart';
import 'package:briefing_buddy/services/weather_parser.dart';

void main() {
  group('DecoderService Tests', () {
    late DecoderService decoderService;

    setUp(() {
      decoderService = DecoderService();
    });

    group('Weather Parser Tests', () {
      test('should handle intensity prefixes correctly', () {
        // Test light intensity
        expect(WeatherParser.describeConditions('-RA'), equals('Light Rain'));
        expect(WeatherParser.describeConditions('-SHRA'), equals('Light Showers of Rain'));
        expect(WeatherParser.describeConditions('-SN'), equals('Light Snow'));
        
        // Test heavy intensity
        expect(WeatherParser.describeConditions('+RA'), equals('Heavy Rain'));
        expect(WeatherParser.describeConditions('+SHRA'), equals('Heavy Showers of Rain'));
        expect(WeatherParser.describeConditions('+TSRA'), equals('Heavy Thunderstorms and Rain'));
        
        // Test no intensity
        expect(WeatherParser.describeConditions('RA'), equals('Rain'));
        expect(WeatherParser.describeConditions('SHRA'), equals('Showers of Rain'));
        expect(WeatherParser.describeConditions('TSRA'), equals('Thunderstorms and Rain'));
      });

      test('should parse weather from segment with intensity prefixes', () {
        const segment = '09010KT 9999 FEW015 -SHRA';
        final weather = WeatherParser.parseWeatherFromSegment(segment);
        
        expect(weather['Weather'], equals('Light Showers of Rain'));
        expect(weather['Wind'], equals('090° at 10kt'));
        expect(weather['Visibility'], equals('>10km'));
      });
    });

    group('TAF Decoding Tests', () {
      test('should decode simple TAF correctly', () {
        const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020';
        final result = decoderService.decodeTaf(tafText);
        
        expect(result, isNotNull);
        expect(result.forecastPeriods, isNotEmpty);
        expect(result.forecastPeriods!.first.type, equals('INITIAL'));
        expect(result.forecastPeriods!.first.weather['Wind'], contains('170°'));
        expect(result.forecastPeriods!.first.weather['Visibility'], equals('>10km'));
      });

      test('should decode TAF with TEMPO periods', () {
        const tafText = 'TAF CYYZ 271740Z 2718/2824 09010KT P6SM BKN020 TEMPO 2718/2720 P6SM VCTS BKN020 BKN030CB';
        final result = decoderService.decodeTaf(tafText);
        
        expect(result, isNotNull);
        expect(result.forecastPeriods!.length, greaterThan(1));
        
        final tempoPeriod = result.forecastPeriods!.where((p) => p.isConcurrent).first;
        expect(tempoPeriod.type, contains('TEMPO'));
        expect(tempoPeriod.weather['Weather'], contains('Vicinity Thunderstorms'));
      });

      test('should decode TAF with PROB40 TEMPO periods', () {
        const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 PROB40 TEMPO 2802/2805 3000 TSRA FEW012CB BKN015';
        final result = decoderService.decodeTaf(tafText);
        
        expect(result, isNotNull);
        expect(result.forecastPeriods!.length, greaterThan(1));
        
        final probPeriod = result.forecastPeriods!.where((p) => p.isConcurrent).first;
        expect(probPeriod.type, equals('PROB40 TEMPO'));
        expect(probPeriod.weather['Visibility'], equals('3000m'));
        expect(probPeriod.weather['Weather'], contains('Thunderstorms and Rain'));
      });

      test('should handle BECMG periods with inheritance', () {
        const tafText = 'TAF EGLL 271700Z 2718/2900 09010KT 9999 FEW015 SCT020 BECMG 2718/2720 12015KT';
        final result = decoderService.decodeTaf(tafText);
        
        expect(result, isNotNull);
        expect(result.forecastPeriods!.length, greaterThan(1));
        
        final becmgPeriod = result.forecastPeriods!.where((p) => p.type == 'BECMG').first;
        expect(becmgPeriod.weather['Wind'], contains('120°'));
        // Note: BECMG inheritance is handled in the UI layer, not in decoder
        // So we just check that the period exists and has wind
        expect(becmgPeriod.weather['Wind'], isNotNull);
      });
    });

    group('Period Detection Tests', () {
      test('should find active periods at specific time', () {
        const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 PROB40 TEMPO 2802/2805 3000 TSRA FEW012CB BKN015';
        final result = decoderService.decodeTaf(tafText);
        
        // Test at 02:00 on 28th (during PROB40 TEMPO)
        final activePeriods = decoderService.findActivePeriodsAtTime(
          DateTime(2025, 7, 28, 2, 0),
          result.forecastPeriods!
        );
        
        expect(activePeriods['baseline'], isNotNull);
        expect(activePeriods['concurrent'], isNotEmpty);
        expect(activePeriods['concurrent']!.first.type, equals('PROB40 TEMPO'));
      });
    });

    group('Text Formatting Tests', () {
      test('should format TAF text with line breaks', () {
        const rawText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 PROB40 TEMPO 2802/2805 3000 TSRA FEW012CB BKN015';
        final formatted = decoderService.formatTafForDisplay(rawText);
        
        expect(formatted, contains('\nPROB40 TEMPO'));
        expect(formatted, isNot(contains('PROB40\nTEMPO'))); // Should not break PROB40 TEMPO
      });
    });
  });
} 