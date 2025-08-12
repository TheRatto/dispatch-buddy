import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/services/decoder_service.dart';

void main() {
  group('TAF BECMG Initial Weather Tests', () {
    test('should create INITIAL period when TAF starts with BECMG', () {
      const tafText = 'TAF CYYZ 061200Z 0612/0618 33012KT CAVOK BECMG 0612/0615 34015KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      
      expect(result.forecastPeriods, isNotNull);
      expect(result.forecastPeriods!.length, greaterThanOrEqualTo(2));
      
      // Should have an INITIAL period
      final initialPeriod = result.forecastPeriods!.where((p) => p.type == 'INITIAL').firstOrNull;
      expect(initialPeriod, isNotNull);
      expect(initialPeriod!.weather['Wind'], equals('330° at 12kt'));
      expect(initialPeriod.weather['Visibility'], equals('CAVOK'));
      
      // Should have a BECMG period
      final becmgPeriod = result.forecastPeriods!.where((p) => p.type == 'BECMG').firstOrNull;
      expect(becmgPeriod, isNotNull);
      expect(becmgPeriod!.weather['Wind'], equals('340° at 15kt'));
      
      print('INITIAL period: ${initialPeriod.weather}');
      print('BECMG period: ${becmgPeriod.weather}');
    });

    test('should handle EGLL TAF with BECMG at start', () {
      const tafText = 'TAF EGLL 061200Z 0612/0618 09010KT 9999 FEW015 SCT020 BECMG 0612/0615 12015KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      
      expect(result.forecastPeriods, isNotNull);
      expect(result.forecastPeriods!.length, greaterThanOrEqualTo(2));
      
      // Should have an INITIAL period
      final initialPeriod = result.forecastPeriods!.where((p) => p.type == 'INITIAL').firstOrNull;
      expect(initialPeriod, isNotNull);
      expect(initialPeriod!.weather['Wind'], equals('090° at 10kt'));
      expect(initialPeriod.weather['Visibility'], equals('>10km'));
      expect(initialPeriod.weather['Cloud'], contains('FEW at 1500ft'));
      
      // Should have a BECMG period
      final becmgPeriod = result.forecastPeriods!.where((p) => p.type == 'BECMG').firstOrNull;
      expect(becmgPeriod, isNotNull);
      expect(becmgPeriod!.weather['Wind'], equals('120° at 15kt'));
      
      print('INITIAL period: ${initialPeriod.weather}');
      print('BECMG period: ${becmgPeriod.weather}');
    });

    test('should handle TAF with explicit initial text', () {
      const tafText = 'TAF YPPH 061200Z 0612/0618 33012KT CAVOK FM061500 34015KT';
      final decoderService = DecoderService();
      final result = decoderService.decodeTaf(tafText);
      
      expect(result.forecastPeriods, isNotNull);
      expect(result.forecastPeriods!.length, greaterThanOrEqualTo(2));
      
      // Should have an INITIAL period
      final initialPeriod = result.forecastPeriods!.where((p) => p.type == 'INITIAL').firstOrNull;
      expect(initialPeriod, isNotNull);
      expect(initialPeriod!.weather['Wind'], equals('330° at 12kt'));
      expect(initialPeriod.weather['Visibility'], equals('CAVOK'));
      
      // Should have an FM period
      final fmPeriod = result.forecastPeriods!.where((p) => p.type == 'FM').firstOrNull;
      expect(fmPeriod, isNotNull);
      expect(fmPeriod!.weather['Wind'], equals('340° at 15kt'));
      
      print('INITIAL period: ${initialPeriod.weather}');
      print('FM period: ${fmPeriod.weather}');
    });
  });
} 