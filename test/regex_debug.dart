void main() {
  print('Testing regex functionality...');
  
  final text = 'QOL Obstacle lighting unserviceable';
  print('Text: "$text"');
  print('Code units: ${text.codeUnits}');
  
  // Test basic string operations
  print('Contains QOL: ${text.contains("QOL")}');
  print('StartsWith QOL: ${text.startsWith("QOL")}');
  
  // Test basic regex
  final basicRegex = RegExp(r'QOL');
  final basicMatch = basicRegex.firstMatch(text);
  print('Basic regex match: "${basicMatch?.group(0)}"');
  
  // Test Q code pattern
  final qCodeRegex = RegExp(r'Q[A-Z]{3,4}');
  final qCodeMatch = qCodeRegex.firstMatch(text);
  print('Q code regex match: "${qCodeMatch?.group(0)}"');
  
  // Test word boundary pattern
  final wordBoundaryRegex = RegExp(r'\bQ[A-Z]{3,4}\b');
  final wordBoundaryMatch = wordBoundaryRegex.firstMatch(text);
  print('Word boundary regex match: "${wordBoundaryMatch?.group(0)}"');
  
  // Test individual character matching
  print('Character at position 0: "${text[0]}" (code: ${text.codeUnitAt(0)})');
  print('Character at position 1: "${text[1]}" (code: ${text.codeUnitAt(1)})');
  print('Character at position 2: "${text[2]}" (code: ${text.codeUnitAt(2)})');
  
  // Test if O and L are uppercase
  print('Is O uppercase: ${"O".toUpperCase() == "O"}');
  print('Is L uppercase: ${"L".toUpperCase() == "L"}');
  
  // Test character class with explicit characters
  final explicitRegex = RegExp(r'Q[OL]{2}');
  final explicitMatch = explicitRegex.firstMatch(text);
  print('Explicit character class regex match: "${explicitMatch?.group(0)}"');
  
  // Test with case insensitive flag
  final caseInsensitiveRegex = RegExp(r'Q[A-Z]{3,4}', caseSensitive: false);
  final caseInsensitiveMatch = caseInsensitiveRegex.firstMatch(text);
  print('Case insensitive regex match: "${caseInsensitiveMatch?.group(0)}"');
  
  print('Regex test completed.');
} 