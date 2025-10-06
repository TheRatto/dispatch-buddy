import 'package:flutter_test/flutter_test.dart';
import 'package:briefing_buddy/services/decoder_service.dart';

void main() {
  group('Concurrent Weather Parsing Tests', () {
    late DecoderService decoderService;

    setUp(() {
      decoderService = DecoderService();
    });

    test('should parse concurrent weather correctly from database load', () {
      // This is the specific TAF that was having issues with concurrent weather
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 TEMPO 2802/2805 4SM SHRA BR BKN020 PROB30 2802/2805 VRB20G30KT 1SM +TSRA BR BKN008 OVC020CB';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      expect(result.forecastPeriods!.length, greaterThan(2)); // INITIAL + TEMPO + PROB30
      
      // Find concurrent periods
      final concurrentPeriods = result.forecastPeriods!.where((p) => p.isConcurrent).toList();
      expect(concurrentPeriods.length, equals(2));
      
      // Check TEMPO period
      final tempoPeriod = concurrentPeriods.where((p) => p.type == 'TEMPO').first;
      expect(tempoPeriod.weather['Visibility'], equals('4SM'));
      expect(tempoPeriod.weather['Weather'], contains('Showers of Rain'));
      expect(tempoPeriod.weather['Weather'], contains('Mist'));
      
      // Check PROB30 period
      final prob30Period = concurrentPeriods.where((p) => p.type == 'PROB30').first;
      expect(prob30Period.weather['Wind'], contains('Variable'));
      expect(prob30Period.weather['Visibility'], equals('1SM'));
      expect(prob30Period.weather['Weather'], contains('Heavy Thunderstorms and Rain'));
      expect(prob30Period.weather['Weather'], contains('Mist'));
    });

    test('should handle combined PROB40 TEMPO patterns correctly', () {
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 PROB40 TEMPO 2802/2805 3000 TSRA FEW012CB BKN015';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      
      final concurrentPeriods = result.forecastPeriods!.where((p) => p.isConcurrent).toList();
      expect(concurrentPeriods.length, equals(1));
      
      final prob40Period = concurrentPeriods.first;
      expect(prob40Period.type, equals('PROB40 TEMPO'));
      expect(prob40Period.weather['Visibility'], equals('3000m'));
      expect(prob40Period.weather['Weather'], contains('Thunderstorms and Rain'));
    });

    test('should detect changed elements correctly', () {
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 TEMPO 2802/2805 4SM SHRA BR BKN020';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      
      final concurrentPeriods = result.forecastPeriods!.where((p) => p.isConcurrent).toList();
      expect(concurrentPeriods.length, equals(1));
      
      final tempoPeriod = concurrentPeriods.first;
      expect(tempoPeriod.changedElements, contains('Visibility'));
      expect(tempoPeriod.changedElements, contains('Weather'));
      expect(tempoPeriod.changedElements, contains('Cloud'));
    });

    test('should handle weather codes with intensity prefixes', () {
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 PROB30 2802/2805 +TSRA BR BKN008';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      
      final concurrentPeriods = result.forecastPeriods!.where((p) => p.isConcurrent).toList();
      expect(concurrentPeriods.length, equals(1));
      
      final prob30Period = concurrentPeriods.first;
      expect(prob30Period.weather['Weather'], contains('Heavy Thunderstorms and Rain'));
    });

    test('should handle VCTS weather code correctly', () {
      const tafText = 'TAF WSSS 271700Z 2718/2900 17008KT 9999 FEW015 SCT020 TEMPO 2802/2805 VCTS BKN020';
      
      final result = decoderService.decodeTaf(tafText);
      
      expect(result, isNotNull);
      
      final concurrentPeriods = result.forecastPeriods!.where((p) => p.isConcurrent).toList();
      expect(concurrentPeriods.length, equals(1));
      
      final tempoPeriod = concurrentPeriods.first;
      expect(tempoPeriod.weather['Weather'], contains('Vicinity Thunderstorms'));
    });
  });
} 