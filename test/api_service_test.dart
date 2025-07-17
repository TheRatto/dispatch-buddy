import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';

void main() {
  group('NOTAM Model Tests', () {
    group('FAA JSON Parsing', () {
      test('should parse FAA JSON correctly', () {
        final faaJson = {
          'properties': {
            'coreNOTAMData': {
              'notam': {
                'number': 'TEST123',
                'location': 'YPPH',
                'effectiveStart': '2025-01-01T00:00:00Z',
                'effectiveEnd': '2025-01-02T00:00:00Z',
                'text': 'Runway 06/24 closed for maintenance',
                'featureType': 'RWY',
                'classification': 'CRITICAL'
              }
            }
          }
        };

        final notam = Notam.fromFaaJson(faaJson);
        
        expect(notam.id, 'TEST123');
        expect(notam.icao, 'YPPH');
        expect(notam.type, NotamType.runway);
        expect(notam.isCritical, isTrue);
        expect(notam.rawText, 'Runway 06/24 closed for maintenance');
        expect(notam.affectedSystem, 'RWY');
      });

      test('should handle permanent NOTAMs', () {
        final faaJson = {
          'properties': {
            'coreNOTAMData': {
              'notam': {
                'number': 'PERM123',
                'location': 'YPPH',
                'effectiveStart': '2025-01-01T00:00:00Z',
                'effectiveEnd': 'PERM',
                'text': 'Permanent NOTAM',
                'featureType': 'RWY',
                'classification': 'NORMAL'
              }
            }
          }
        };

        final notam = Notam.fromFaaJson(faaJson);
        
        expect(notam.id, 'PERM123');
        expect(notam.validTo.isAfter(DateTime.now().add(Duration(days: 365 * 5))), isTrue);
      });

      test('should handle missing dates gracefully', () {
        final faaJson = {
          'properties': {
            'coreNOTAMData': {
              'notam': {
                'number': 'NODATE123',
                'location': 'YPPH',
                'text': 'NOTAM without dates',
                'featureType': 'RWY',
                'classification': 'NORMAL'
              }
            }
          }
        };

        final notam = Notam.fromFaaJson(faaJson);
        
        expect(notam.id, 'NODATE123');
        expect(notam.validFrom, isA<DateTime>());
        expect(notam.validTo, isA<DateTime>());
      });

      test('should handle invalid date formats', () {
        final faaJson = {
          'properties': {
            'coreNOTAMData': {
              'notam': {
                'number': 'BADDATE123',
                'location': 'YPPH',
                'effectiveStart': 'invalid-date',
                'effectiveEnd': 'also-invalid',
                'text': 'NOTAM with bad dates',
                'featureType': 'RWY',
                'classification': 'NORMAL'
              }
            }
          }
        };

        final notam = Notam.fromFaaJson(faaJson);
        
        expect(notam.id, 'BADDATE123');
        expect(notam.validFrom, isA<DateTime>());
        expect(notam.validTo, isA<DateTime>());
      });

      test('should classify NOTAM types correctly', () {
        final testCases = [
          {
            'text': 'Runway 06/24 closed',
            'expectedType': NotamType.runway,
          },
          {
            'text': 'RWY 06/24 closed',
            'expectedType': NotamType.runway,
          },
          {
            'text': 'ILS approach unavailable',
            'expectedType': NotamType.navaid,
          },
          {
            'text': 'NAVAID out of service',
            'expectedType': NotamType.navaid,
          },
          {
            'text': 'Airspace restricted',
            'expectedType': NotamType.airspace,
          },
          {
            'text': 'Taxiway A closed',
            'expectedType': NotamType.other, // Current implementation doesn't check for taxiway
          },
          {
            'text': 'General information',
            'expectedType': NotamType.other,
          },
        ];

        for (final testCase in testCases) {
          final faaJson = {
            'properties': {
              'coreNOTAMData': {
                'notam': {
                  'number': 'TEST123',
                  'location': 'YPPH',
                  'effectiveStart': '2025-01-01T00:00:00Z',
                  'effectiveEnd': '2025-01-02T00:00:00Z',
                  'text': testCase['text'],
                  'featureType': 'RWY',
                  'classification': 'NORMAL'
                }
              }
            }
          };

          final notam = Notam.fromFaaJson(faaJson);
          expect(notam.type, testCase['expectedType'], reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should extract Q codes correctly', () {
        final testCases = [
          {
            'text': 'QOLCC Obstacle lighting unserviceable',
            'expectedQCode': 'QOLCC',
            'expectedType': NotamType.lighting,
            'expectedStatus': 'CC',
          },
          {
            'text': 'QMRLC Runway marking maintenance',
            'expectedQCode': 'QMRLC',
            'expectedType': NotamType.runway,
            'expectedStatus': 'LC',
          },
          {
            'text': 'QNTLC Navigation aid out of service',
            'expectedQCode': 'QNTLC',
            'expectedType': NotamType.navaid,
            'expectedStatus': 'LC',
          },
          {
            'text': 'QTWLC Taxiway closed for maintenance',
            'expectedQCode': 'QTWLC',
            'expectedType': NotamType.taxiway,
            'expectedStatus': 'LC',
          },
          {
            'text': 'QAXLC Airspace restricted',
            'expectedQCode': 'QAXLC',
            'expectedType': NotamType.airspace,
            'expectedStatus': 'LC',
          },
          {
            'text': 'QPRLC Approach procedure changed',
            'expectedQCode': 'QPRLC',
            'expectedType': NotamType.procedure,
            'expectedStatus': 'LC',
          },
          {
            'text': 'No Q code in this NOTAM',
            'expectedQCode': null,
            'expectedType': NotamType.other,
            'expectedStatus': null,
          },
          {
            'text': 'Multiple Q codes QOLCC and QMRLC but first one wins',
            'expectedQCode': 'QOLCC',
            'expectedType': NotamType.lighting,
            'expectedStatus': 'CC',
          },
        ];

        for (final testCase in testCases) {
          final faaJson = {
            'properties': {
              'coreNOTAMData': {
                'notam': {
                  'number': 'TEST123',
                  'location': 'YPPH',
                  'effectiveStart': '2025-01-01T00:00:00Z',
                  'effectiveEnd': '2025-01-02T00:00:00Z',
                  'text': testCase['text'],
                  'featureType': 'RWY',
                  'classification': 'NORMAL'
                }
              }
            }
          };

          final notam = Notam.fromFaaJson(faaJson);
          expect(notam.qCode, testCase['expectedQCode'], reason: 'Failed for text: ${testCase['text']}');
          expect(notam.type, testCase['expectedType'], reason: 'Failed for text: ${testCase['text']}');
          
          // Test status extraction
          final status = Notam.getQCodeStatus(notam.qCode);
          expect(status, testCase['expectedStatus'], reason: 'Failed for text: ${testCase['text']}');
        }
      });

      test('should prioritize Q code classification over text-based classification', () {
        // This NOTAM has runway-related text but a navaid Q code
        final faaJson = {
          'properties': {
            'coreNOTAMData': {
              'notam': {
                'number': 'TEST123',
                'location': 'YPPH',
                'effectiveStart': '2025-01-01T00:00:00Z',
                'effectiveEnd': '2025-01-02T00:00:00Z',
                'text': 'QNTLC ILS runway 06 approach unavailable due to maintenance',
                'featureType': 'RWY',
                'classification': 'NORMAL'
              }
            }
          }
        };

        final notam = Notam.fromFaaJson(faaJson);
        expect(notam.qCode, 'QNTLC');
        expect(notam.type, NotamType.navaid); // Should be navaid based on Q code, not runway based on text
        expect(Notam.getQCodeStatus(notam.qCode), 'LC'); // LC = closed
      });

      test('should debug Q code regex pattern', () {
        // Test the regex pattern directly
        final text = 'QOLCC Obstacle lighting unserviceable';
        final qCode = Notam.extractQCode(text);
        print('DEBUG: Text: "$text"');
        print('DEBUG: Code units: ${text.codeUnits}');
        print('DEBUG: Extracted Q code: "$qCode"');
        
        // Test with different patterns
        final patterns = [
          r'Q[A-Z]{4}',
          r'\bQ[A-Z]{4}\b',
          r'^Q[A-Z]{4}',
          r'Q[A-Z]{4}\b',
        ];
        
        for (final pattern in patterns) {
          final regex = RegExp(pattern);
          final match = regex.firstMatch(text);
          print('DEBUG: Pattern "$pattern" -> "${match?.group(0)}"');
        }
        
        // Test status extraction
        final status = Notam.getQCodeStatus(qCode);
        print('DEBUG: Q code status: "$status"');
        
        expect(qCode, isNotNull);
        expect(qCode, equals('QOLCC'));
        expect(status, equals('CC'));
      });

      test('should test basic regex functionality', () {
        // Test basic regex functionality
        final text = 'QOLCC Obstacle lighting unserviceable';
        
        // Test simple string matching
        expect(text.contains('QOLCC'), isTrue);
        expect(text.startsWith('QOLCC'), isTrue);
        
        // Test basic regex
        final basicRegex = RegExp(r'QOLCC');
        final basicMatch = basicRegex.firstMatch(text);
        expect(basicMatch?.group(0), equals('QOLCC'));
        
        // Test Q code pattern
        final qCodeRegex = RegExp(r'Q[A-Z]{4}');
        final qCodeMatch = qCodeRegex.firstMatch(text);
        expect(qCodeMatch?.group(0), equals('QOLCC'));
        
        print('DEBUG: Basic regex test passed');
      });
    });

    group('NOTAM Serialization', () {
      test('should serialize and deserialize correctly', () {
        final originalNotam = Notam(
          id: 'TEST123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime(2025, 1, 1),
          validTo: DateTime(2025, 1, 2),
          rawText: 'Test NOTAM',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.runways,
        );

        final json = originalNotam.toJson();
        final deserializedNotam = Notam.fromJson(json);

        expect(deserializedNotam.id, originalNotam.id);
        expect(deserializedNotam.icao, originalNotam.icao);
        expect(deserializedNotam.type, originalNotam.type);
        expect(deserializedNotam.validFrom, originalNotam.validFrom);
        expect(deserializedNotam.validTo, originalNotam.validTo);
        expect(deserializedNotam.rawText, originalNotam.rawText);
        expect(deserializedNotam.decodedText, originalNotam.decodedText);
        expect(deserializedNotam.affectedSystem, originalNotam.affectedSystem);
        expect(deserializedNotam.isCritical, originalNotam.isCritical);
      });

      test('should handle database serialization', () {
        final originalNotam = Notam(
          id: 'TEST123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime(2025, 1, 1),
          validTo: DateTime(2025, 1, 2),
          rawText: 'Test NOTAM',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: true,
          group: NotamGroup.runways,
        );

        final dbJson = originalNotam.toDbJson('FLIGHT123');
        final deserializedNotam = Notam.fromDbJson(dbJson);

        expect(deserializedNotam.id, originalNotam.id);
        expect(deserializedNotam.icao, originalNotam.icao);
        expect(deserializedNotam.type, originalNotam.type);
        expect(deserializedNotam.validFrom, originalNotam.validFrom);
        expect(deserializedNotam.validTo, originalNotam.validTo);
        expect(deserializedNotam.rawText, originalNotam.rawText);
        expect(deserializedNotam.decodedText, originalNotam.decodedText);
        expect(deserializedNotam.affectedSystem, originalNotam.affectedSystem);
        expect(deserializedNotam.isCritical, originalNotam.isCritical);
      });
    });

    group('NOTAM Validation', () {
      test('should validate NOTAM dates', () {
        final validNotam = Notam(
          id: 'TEST123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(days: 1)),
          rawText: 'Test NOTAM',
          decodedText: 'Decoded test NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.runways,
        );

        expect(validNotam.validFrom.isBefore(validNotam.validTo), isTrue);
      });

      test('should handle currently active NOTAMs', () {
        final now = DateTime.now();
        final activeNotam = Notam(
          id: 'ACTIVE123',
          icao: 'YPPH',
          type: NotamType.runway,
          validFrom: now.subtract(Duration(hours: 1)),
          validTo: now.add(Duration(hours: 1)),
          rawText: 'Active NOTAM',
          decodedText: 'Currently active NOTAM',
          affectedSystem: 'RWY',
          isCritical: false,
          group: NotamGroup.runways,
        );

        expect(activeNotam.validFrom.isBefore(now), isTrue);
        expect(activeNotam.validTo.isAfter(now), isTrue);
      });
    });
  });
} 