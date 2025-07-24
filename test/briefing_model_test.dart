import 'package:flutter_test/flutter_test.dart';
import '../lib/models/briefing.dart';

void main() {
  group('Briefing Model Tests', () {
    test('should create briefing with correct ID format', () {
      final briefing = Briefing.create(
        airports: ['YSCB', 'YMML', 'YSSY'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      expect(briefing.id, startsWith('briefing_'));
      expect(briefing.airports, equals(['YSCB', 'YMML', 'YSSY']));
      expect(briefing.isFlagged, isFalse);
    });

    test('should generate display name from airports', () {
      final briefing = Briefing.create(
        airports: ['YSCB', 'YMML', 'YSSY'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      expect(briefing.displayName, equals('YSCB YMML YSSY'));
    });

    test('should use custom name when provided', () {
      final briefing = Briefing.create(
        name: 'My Custom Briefing',
        airports: ['YSCB', 'YMML', 'YSSY'],
        notams: {'YSCB': []},
        weather: {'YSCB': {}},
      );

      expect(briefing.displayName, equals('My Custom Briefing'));
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

    test('should calculate total NOTAMs correctly', () {
      final briefing = Briefing.create(
        airports: ['YSCB', 'YMML'],
        notams: {
          'YSCB': [{'id': '1'}, {'id': '2'}],
          'YMML': [{'id': '3'}],
        },
        weather: {'YSCB': {}},
      );

      expect(briefing.totalNotams, equals(3));
    });

    test('should serialize and deserialize correctly', () {
      final original = Briefing.create(
        name: 'Test Briefing',
        airports: ['YSCB', 'YMML'],
        notams: {'YSCB': [{'id': '1'}]},
        weather: {'YSCB': {'temp': 25}},
        isFlagged: true,
        userNotes: 'Test notes',
      );

      final json = original.toJson();
      final restored = Briefing.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.airports, equals(original.airports));
      expect(restored.isFlagged, equals(original.isFlagged));
      expect(restored.userNotes, equals(original.userNotes));
    });

    test('should copy with updated fields', () {
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
  });
} 