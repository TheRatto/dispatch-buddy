import 'package:flutter_test/flutter_test.dart';
import '../lib/services/briefing_storage_service.dart';
import '../lib/models/briefing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BriefingStorageService Tests', () {
    test('should handle JSON serialization correctly', () {
      final briefing = Briefing.create(
        name: 'Test Briefing',
        airports: ['YSCB', 'YMML'],
        notams: {'YSCB': [{'id': '1'}]},
        weather: {'YSCB': {'temp': 25}},
        isFlagged: true,
        userNotes: 'Test notes',
      );

      // Test JSON serialization
      final json = briefing.toJson();
      expect(json['id'], equals(briefing.id));
      expect(json['name'], equals(briefing.name));
      expect(json['airports'], equals(briefing.airports));
      expect(json['isFlagged'], equals(briefing.isFlagged));
      expect(json['userNotes'], equals(briefing.userNotes));

      // Test JSON deserialization
      final restored = Briefing.fromJson(json);
      expect(restored.id, equals(briefing.id));
      expect(restored.name, equals(briefing.name));
      expect(restored.airports, equals(briefing.airports));
      expect(restored.isFlagged, equals(briefing.isFlagged));
      expect(restored.userNotes, equals(briefing.userNotes));
    });

    test('should handle briefing updates correctly', () {
      final original = Briefing.create(
        airports: ['YSCB'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        isFlagged: true,
        userNotes: 'Updated notes',
      );

      expect(updated.name, equals('Updated Name'));
      expect(updated.isFlagged, isTrue);
      expect(updated.userNotes, equals('Updated notes'));
      expect(updated.airports, equals(original.airports));
    });

    test('should calculate briefing statistics correctly', () {
      final briefing1 = Briefing.create(
        airports: ['YSCB'],
        notams: {'YSCB': [{'id': '1'}, {'id': '2'}]},
        weather: {'YSCB': {}},
        isFlagged: true,
      );

      final briefing2 = Briefing.create(
        airports: ['YMML'],
        notams: {'YMML': [{'id': '3'}]},
        weather: {'YMML': {}},
      );

      expect(briefing1.totalNotams, equals(2));
      expect(briefing2.totalNotams, equals(1));
      expect(briefing1.isFlagged, isTrue);
      expect(briefing2.isFlagged, isFalse);
    });

    test('should generate correct display names', () {
      final briefing1 = Briefing.create(
        airports: ['YSCB', 'YMML', 'YSSY'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      final briefing2 = Briefing.create(
        name: 'Custom Name',
        airports: ['YSCB', 'YMML'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      expect(briefing1.displayName, equals('YSCB YMML YSSY'));
      expect(briefing2.displayName, equals('Custom Name'));
    });

    test('should separate primary and alternate airports', () {
      final briefing = Briefing.create(
        airports: ['YSCB', 'YMML', 'YSSY', 'YMAV', 'YSRI'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      expect(briefing.primaryAirports, equals(['YSCB', 'YMML', 'YSSY']));
      expect(briefing.alternateAirports, equals(['YMAV', 'YSRI']));
    });

    test('should handle data freshness calculations', () {
      final now = DateTime.now();
      final freshData = now.subtract(const Duration(hours: 6));
      final staleData = now.subtract(const Duration(hours: 18));
      final expiredData = now.subtract(const Duration(hours: 30));

      final freshBriefing = Briefing.create(
        airports: ['YSCB'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      ).copyWith(timestamp: freshData);

      final staleBriefing = Briefing.create(
        airports: ['YMML'],
        notams: {'YMML': []},
        weather: {'YMML': {}},
      ).copyWith(timestamp: staleData);

      final expiredBriefing = Briefing.create(
        airports: ['YSSY'],
        notams: {'YSSY': []},
        weather: {'YSSY': {}},
      ).copyWith(timestamp: expiredData);

      expect(freshBriefing.isFresh, isTrue);
      expect(freshBriefing.isStale, isFalse);
      expect(freshBriefing.isExpired, isFalse);

      expect(staleBriefing.isFresh, isFalse);
      expect(staleBriefing.isStale, isTrue);
      expect(staleBriefing.isExpired, isFalse);

      expect(expiredBriefing.isFresh, isFalse);
      expect(expiredBriefing.isStale, isFalse);
      expect(expiredBriefing.isExpired, isTrue);
    });
  });
} 