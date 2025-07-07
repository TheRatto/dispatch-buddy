enum NotamType { runway, navaid, taxiway, lighting, procedure, other, airspace }

class Notam {
  final String id;
  final String icao;
  final NotamType type;
  final DateTime validFrom;
  final DateTime validTo;
  final String rawText;
  final String decodedText;
  final String affectedSystem;
  final bool isCritical;
  final String? qCode; // Q code from NOTAM text

  Notam({
    required this.id,
    required this.icao,
    required this.type,
    required this.validFrom,
    required this.validTo,
    required this.rawText,
    required this.decodedText,
    required this.affectedSystem,
    required this.isCritical,
    this.qCode,
  });

  // Extract Q code from NOTAM text using regex
  static String? extractQCode(String text) {
    // Q codes are 5 letters total: Q + 4 letters (e.g., QMRLC, QOLCC)
    // First letter is always Q, next 2 identify subject, last 2 identify status
    final qCodeRegex = RegExp(r'\bQ[A-Z]{4}\b');
    final match = qCodeRegex.firstMatch(text);
    return match?.group(0);
  }

  // Determine NOTAM type based on Q code (using second and third letters)
  static NotamType determineTypeFromQCode(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return NotamType.other;
    }
    
    // Extract subject identifier (second and third letters)
    final subject = qCode.substring(1, 3);
    
    switch (subject) {
      // Runway-related codes
      case 'MR': // Runway marking
      case 'RW': // Runway
      case 'RR': // Runway
        return NotamType.runway;
      
      // Navigation aid codes
      case 'NT': // Navigation aid
      case 'NA': // Navigation aid
      case 'NL': // Navigation aid
        return NotamType.navaid;
      
      // Taxiway codes
      case 'TW': // Taxiway
        return NotamType.taxiway;
      
      // Lighting codes
      case 'LT': // Lighting
      case 'OL': // Obstacle lighting
        return NotamType.lighting;
      
      // Airspace codes
      case 'AX': // Airspace
      case 'AS': // Airspace
        return NotamType.airspace;
      
      // Procedure codes
      case 'PR': // Procedure
      case 'AP': // Approach procedure
        return NotamType.procedure;
      
      default:
        return NotamType.other;
    }
  }

  // Get Q code status/condition (fourth and fifth letters)
  static String? getQCodeStatus(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return null;
    }
    
    // Extract status identifier (fourth and fifth letters)
    return qCode.substring(3, 5);
  }

  factory Notam.fromJson(Map<String, dynamic> json) {
    return Notam(
      id: json['id'],
      icao: json['icao'],
      type: NotamType.values.firstWhere((e) => e.toString() == 'NotamType.${json['type']}'),
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      rawText: json['rawText'],
      decodedText: json['decodedText'],
      affectedSystem: json['affectedSystem'],
      isCritical: json['isCritical'],
      qCode: json['qCode'],
    );
  }

  factory Notam.fromFaaJson(Map<String, dynamic> json) {
    // Parse the actual FAA API JSON format
    final properties = json['properties'];
    if (properties == null) {
      throw Exception('Invalid NOTAM data: properties object is null');
    }

    final coreNotamData = properties['coreNOTAMData'];
    if (coreNotamData == null) {
      throw Exception('Invalid NOTAM data: coreNOTAMData object is null');
    }

    final notam = coreNotamData['notam'];
    if (notam == null) {
      throw Exception('Invalid NOTAM data: notam object is null');
    }

    // Safely parse dates, providing defaults if they are null.
    final validFromStr = notam['effectiveStart'];
    final validToStr = notam['effectiveEnd'];

    DateTime validFrom;
    DateTime validTo;
    
    try {
      validFrom = validFromStr != null ? DateTime.parse(validFromStr) : DateTime.now();
    } catch (e) {
      print('Error parsing effectiveStart date: $validFromStr - $e');
      validFrom = DateTime.now();
    }

    try {
      if (validToStr == 'PERM' || validToStr == 'PERMANENT') {
        // Permanent NOTAM - set to a far future date
        validTo = DateTime.now().add(const Duration(days: 365 * 10));
      } else {
        validTo = validToStr != null ? DateTime.parse(validToStr) : DateTime.now().add(const Duration(days: 365 * 10));
      }
    } catch (e) {
      print('Error parsing effectiveEnd date: $validToStr - $e');
      validTo = DateTime.now().add(const Duration(days: 365 * 10));
    }
    
    final text = notam['text'] ?? '';
    
    // Extract Q code from text
    final qCode = extractQCode(text);
    
    // Determine NOTAM type - prefer Q code over text-based classification
    NotamType type = determineTypeFromQCode(qCode);
    
    // Fallback to text-based classification if no Q code found
    if (type == NotamType.other) {
      if (text.toLowerCase().contains('rwy') || text.toLowerCase().contains('runway')) {
        type = NotamType.runway;
      } else if (text.toLowerCase().contains('navaid') || text.toLowerCase().contains('ils')) {
        type = NotamType.navaid;
      } else if (text.toLowerCase().contains('airspace')) {
        type = NotamType.airspace;
      }
    }
    
    return Notam(
      id: notam['number'] ?? 'N/A',
      icao: notam['location'] ?? 'N/A',
      type: type,
      validFrom: validFrom,
      validTo: validTo,
      rawText: text,
      decodedText: '', // Will be generated by AI later
      affectedSystem: notam['featureType'] ?? 'N/A',
      isCritical: notam['classification'] == 'CRITICAL',
      qCode: qCode,
    );
  }

  factory Notam.fromDbJson(Map<String, dynamic> json) {
    return Notam(
      id: json['id'],
      icao: json['icao'],
      type: NotamType.values.firstWhere((e) => e.toString() == 'NotamType.${json['type']}'),
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      rawText: json['rawText'],
      decodedText: json['decodedText'],
      affectedSystem: json['affectedSystem'],
      isCritical: json['isCritical'] == 1,
      qCode: json['qCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icao': icao,
      'type': type.toString().split('.').last,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'affectedSystem': affectedSystem,
      'isCritical': isCritical,
      'qCode': qCode,
    };
  }

  Map<String, dynamic> toDbJson(String flightId) {
    return {
      'flightId': flightId,
      'id': id,
      'icao': icao,
      'type': type.toString().split('.').last,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'affectedSystem': affectedSystem,
      'isCritical': isCritical ? 1 : 0,
      'qCode': qCode,
    };
  }
} 