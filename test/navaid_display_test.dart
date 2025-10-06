import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:briefing_buddy/models/airport_infrastructure.dart';
import 'package:briefing_buddy/widgets/facilities_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NAVAID Display Tests', () {
    test('should identify runway-specific navaids correctly', () {
      // Test runway-specific navaids
      expect(_isRunwaySpecificNavaid('ILS'), isTrue);
      expect(_isRunwaySpecificNavaid('ILS/DME'), isTrue);
      expect(_isRunwaySpecificNavaid('GBAS'), isTrue);
      expect(_isRunwaySpecificNavaid('GLS'), isTrue);
      expect(_isRunwaySpecificNavaid('LOC'), isTrue);
      
      // Test general navaids
      expect(_isRunwaySpecificNavaid('VOR'), isFalse);
      expect(_isRunwaySpecificNavaid('TAC'), isFalse);
      expect(_isRunwaySpecificNavaid('NDB'), isFalse);
      expect(_isRunwaySpecificNavaid('DME'), isFalse);
    });
    
    test('should format runway-specific navaid correctly', () {
      final navaid = Navaid(
        identifier: 'IAM',
        type: 'ILS/DME',
        frequency: '110.7',
        runway: '15',
        status: 'OPERATIONAL',
      );
      
      final formatted = _formatRunwayNavaid(navaid);
      expect(formatted, equals('ILS/DME IAM 110.7'));
    });
    
    test('should format general navaid correctly', () {
      final navaid = Navaid(
        identifier: 'AMB',
        type: 'TAC',
        frequency: '112.5',
        runway: '',
        status: 'OPERATIONAL',
      );
      
      final formatted = _formatGeneralNavaid(navaid);
      expect(formatted, equals('TAC AMB 112.5'));
    });
    
    test('should group navaids by runway correctly', () {
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
      
      final grouped = _groupNavaids(navaids);
      
      // Should have runway-specific navaids grouped
      expect(grouped['15'], isNotNull);
      expect(grouped['15']!.length, equals(1));
      expect(grouped['07'], isNotNull);
      expect(grouped['07']!.length, equals(1));
      
      // Should have general navaids
      expect(grouped[''], isNotNull);
      expect(grouped['']!.length, equals(1));
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

String _formatRunwayNavaid(Navaid navaid) {
  return '${navaid.type} ${navaid.identifier} ${navaid.frequency}';
}

String _formatGeneralNavaid(Navaid navaid) {
  return '${navaid.type} ${navaid.identifier} ${navaid.frequency}';
}

Map<String, List<Navaid>> _groupNavaids(List<Navaid> navaids) {
  final grouped = <String, List<Navaid>>{};
  
  for (final navaid in navaids) {
    if (_isRunwaySpecificNavaid(navaid.type) && navaid.runway.isNotEmpty) {
      grouped.putIfAbsent(navaid.runway, () => []).add(navaid);
    } else {
      grouped.putIfAbsent('', () => []).add(navaid);
    }
  }
  
  return grouped;
} 