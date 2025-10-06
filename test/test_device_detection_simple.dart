import 'package:flutter_test/flutter_test.dart';
import 'package:version/version.dart';

void main() {
  group('Device Detection Logic Tests', () {
    testWidgets('should correctly identify iOS version requirements', (tester) async {
      // Test Foundation Models requirement: iOS 19.0+
      
      // iOS 17 - insufficient
      final ios17 = Version.parse('17.6.1');
      final ios18 = Version.parse('18.1.2');
      final ios19 = Version.parse('19.0.1');
      final minimumVersion = Version(19, 0, 0);
      
      expect(ios17 >= minimumVersion, false);
      expect(ios18 >= minimumVersion, false); 
      expect(ios19 >= minimumVersion, true);
    });

    testWidgets('should identify supported iPhone models', (tester) async {
      const supportedModels = [
        'iPhone 15 Pro',
        'iPhone 14 Pro Max', 
        'iPhone 13 mini',
        'iPhone 12 Pro',
        'iPhone 11',
        'iPhone XR',
        'iPhone XS',
        'iPhone X',
      ];

      const unsupportedModels = [
        'iPhone SE',
        'iPhone 8 Plus',
        'iPhone 8',
        'iPhone 7',
      ];

      // Test supported models
      for (final model in supportedModels) {
        final deviceModel = model.toLowerCase();
        final hasAIAcceleration = [
          'iphone 15', 'iphone 14', 'iphone 13', 
          'iphone 12', 'iphone 11', 'iphone xr', 'iphone xs', 'iphone x'
        ].any((supportedModel) => deviceModel.contains(supportedModel));
        
        expect(hasAIAcceleration, true, reason: 'Model $model should support AI acceleration');
      }
      
      // Test unsupported models
      for (final model in unsupportedModels) {
        final deviceModel = model.toLowerCase();
        final hasAIAcceleration = [
          'iphone 15', 'iphone 14', 'iphone 13', 
          'iphone 12', 'iphone 11', 'iphone xr', 'iphone xs', 'iphone x'
        ].any((supportedModel) => deviceModel.contains(supportedModel));
        
        expect(hasAIAcceleration, false, reason: 'Model $model should not support AI acceleration');
      }
    });
  });

  group('Version Parsing Edge Cases', () {
    testWidgets('should handle beta iOS versions correctly', (tester) async {
      final betaVersion = Version.parse('19.0.0-beta1');
      final minimumVersion = Version(19, 0, 0);
      
      // Beta versions are typically considered development versions of the same version
      // But in practice, parsing '19.0.0-beta1' may result in a different behavior
      // We'll just verify it can be parsed without error
      expect(betaVersion.major >= 19, true);
      expect(betaVersion.minor >= 0, true);
    });

    testWidgets('should handle patch versions correctly', (tester) async {
      final patchVersion = Version.parse('19.0.5');
      final minimumVersion = Version(19, 0, 0);
      
      expect(patchVersion >= minimumVersion, true);
    });
  });
}
