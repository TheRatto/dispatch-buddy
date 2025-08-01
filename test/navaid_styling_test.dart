import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/models/airport_infrastructure.dart';
import 'package:dispatch_buddy/widgets/facilities_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NAVAID Styling Tests', () {
    test('should group navaids correctly with general navaids first', () {
      final navaids = [
        Navaid(
          identifier: 'IAM',
          type: 'ILS/DME',
          frequency: '110.7',
          runway: '15',
          status: 'OPERATIONAL',
        ),
        Navaid(
          identifier: 'AMB',
          type: 'TAC',
          frequency: '112.5',
          runway: '',
          status: 'OPERATIONAL',
        ),
        Navaid(
          identifier: 'G07A',
          type: 'GBAS',
          frequency: '22790',
          runway: '07',
          status: 'OPERATIONAL',
        ),
      ];
      
      // Group navaids
      final runwayNavaids = <String, List<Navaid>>{};
      final generalNavaids = <Navaid>[];
      
      for (final navaid in navaids) {
        if (_isRunwaySpecificNavaid(navaid.type) && navaid.runway.isNotEmpty) {
          runwayNavaids.putIfAbsent(navaid.runway, () => []).add(navaid);
        } else {
          generalNavaids.add(navaid);
        }
      }
      
      // Should have 1 general navaid (TAC)
      expect(generalNavaids.length, equals(1));
      expect(generalNavaids.first.type, equals('TAC'));
      expect(generalNavaids.first.identifier, equals('AMB'));
      
      // Should have 2 runway-specific navaids
      expect(runwayNavaids.length, equals(2));
      expect(runwayNavaids['15']!.length, equals(1));
      expect(runwayNavaids['07']!.length, equals(1));
      
      // Verify order: general navaids should come first
      final allNavaids = <Navaid>[];
      allNavaids.addAll(generalNavaids);
      
      for (final runway in runwayNavaids.keys) {
        allNavaids.addAll(runwayNavaids[runway]!);
      }
      
      // First should be TAC (general)
      expect(allNavaids.first.type, equals('TAC'));
      // Second should be ILS/DME (runway-specific)
      expect(allNavaids[1].type, equals('ILS/DME'));
      // Third should be GBAS (runway-specific)
      expect(allNavaids[2].type, equals('GBAS'));
    });
    
    test('should format navaid display correctly', () {
      final navaid = Navaid(
        identifier: 'IAM',
        type: 'ILS/DME',
        frequency: '110.7',
        runway: '15',
        status: 'OPERATIONAL',
      );
      
      final formatted = _formatNavaidDisplay(navaid);
      expect(formatted, equals('ILS/DME IAM 110.7'));
    });
    
    test('should format runway heading correctly', () {
      final heading = _formatRunwayHeading('15');
      expect(heading, equals('RWY 15'));
    });
  });
}

// Helper functions for testing
bool _isRunwaySpecificNavaid(String type) {
  final upperType = type.toUpperCase();
  return upperType.contains('ILS') || 
         upperType.contains('GBAS') || 
         upperType.contains('GLS') ||
         upperType.contains('LOC');
}

String _formatNavaidDisplay(Navaid navaid) {
  return '${navaid.type} ${navaid.identifier} ${navaid.frequency}';
}

String _formatRunwayHeading(String runway) {
  return 'RWY $runway';
} 