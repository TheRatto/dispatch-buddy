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
    // Make regex more flexible to catch Q codes in various contexts
    final qCodeRegex = RegExp(r'\bQ[A-Z]{4}\b', caseSensitive: false);
    final match = qCodeRegex.firstMatch(text.toUpperCase());
    
    if (match != null) {
      print('DEBUG: 🔍 Q code extracted: ${match.group(0)} from text: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
    } else {
      print('DEBUG: 🔍 No Q code found in text: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
    }
    
    return match?.group(0);
  }

  // Determine NOTAM type based on Q code (using first letter of subject - second letter)
  static NotamType determineTypeFromQCode(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return NotamType.other;
    }
    
    // Extract subject identifier (second letter - first letter of subject)
    final subjectFirstLetter = qCode.substring(1, 2);
    
    switch (subjectFirstLetter) {
      // Airspace Organization (A)
      case 'A':
        return NotamType.airspace;
      
      // Communications and Surveillance Facilities (C)
      case 'C':
        return NotamType.navaid;
      
      // Facilities and Services (F)
      case 'F':
        return NotamType.procedure;
      
      // GNSS Services (G)
      case 'G':
        return NotamType.navaid;
      
      // Instrument and Microwave Landing System (I)
      case 'I':
        return NotamType.navaid;
      
      // Lighting Facilities (L)
      case 'L':
        return NotamType.lighting;
      
      // Movement and Landing Area (M)
      case 'M':
        return NotamType.runway;
      
      // Navigation Aids (N)
      case 'N':
        return NotamType.navaid;
      
      // Taxiway (T)
      case 'T':
        return NotamType.taxiway;
      
      default:
        return NotamType.other;
    }
  }

  // Get human-readable description of Q code subject
  static String getQCodeSubjectDescription(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return 'Unknown';
    }
    
    final subject = qCode.substring(1, 3);
    
    switch (subject) {
      // Airspace Organization (A)
      case 'AA': return 'Minimum Altitude';
      case 'AC': return 'Class B/C/D/E Surface Area';
      case 'AD': return 'Air Defense Identification Zone';
      case 'AE': return 'Control Area';
      case 'AF': return 'Flight Information Region';
      case 'AH': return 'Upper Control Area';
      case 'AL': return 'Minimum Usable Flight Level';
      case 'AN': return 'Area Navigation Route';
      case 'AO': return 'Oceanic Control Area';
      case 'AP': return 'Reporting Point';
      case 'AR': return 'ATS Route';
      case 'AT': return 'Terminal Control Area';
      case 'AU': return 'Upper Flight Information Region';
      case 'AV': return 'Upper Advisory Area';
      case 'AX': return 'Significant Point';
      case 'AZ': return 'Aerodrome Traffic Zone';
      
      // Communications and Surveillance (C)
      case 'CA': return 'Air/Ground Facility';
      case 'CB': return 'ADS-B';
      case 'CC': return 'ADS-C';
      case 'CD': return 'CPDLC';
      case 'CE': return 'En Route Surveillance Radar';
      case 'CG': return 'GCA System';
      case 'CL': return 'SELCAL';
      case 'CM': return 'Surface Movement Radar';
      case 'CP': return 'Precision Approach Radar';
      case 'CR': return 'SRE of PAR';
      case 'CS': return 'SSR';
      case 'CT': return 'Terminal Area Surveillance Radar';
      
      // Facilities and Services (F)
      case 'FA': return 'Aerodrome';
      case 'FB': return 'Friction Measuring Device';
      case 'FC': return 'Ceiling Measurement Equipment';
      case 'FD': return 'Docking System';
      case 'FE': return 'Oxygen';
      case 'FF': return 'Fire Fighting and Rescue';
      case 'FG': return 'Ground Movement Control';
      case 'FH': return 'Helicopter Alighting Area';
      case 'FI': return 'Aircraft De-icing';
      case 'FJ': return 'Oils';
      case 'FL': return 'Landing Direction Indicator';
      case 'FM': return 'Meteorological Service';
      case 'FO': return 'Fog Dispersal System';
      case 'FP': return 'Heliport';
      case 'FS': return 'Snow Removal Equipment';
      case 'FT': return 'Transmissometer';
      case 'FU': return 'Fuel Availability';
      case 'FW': return 'Wind Direction Indicator';
      case 'FZ': return 'Customs/Immigration';
      
      // GNSS Services (G)
      case 'GA': return 'GNSS Airfield-Specific Operations';
      case 'GW': return 'GNSS Area-Wide Operations';
      
      // Instrument and Microwave Landing System (I)
      case 'IC': return 'ILS';
      case 'ID': return 'ILS DME';
      case 'IG': return 'Glide Path (ILS)';
      case 'II': return 'Inner Marker (ILS)';
      case 'IL': return 'Localizer (ILS)';
      case 'IM': return 'Middle Marker (ILS)';
      case 'IN': return 'Localizer (Non-ILS)';
      case 'IO': return 'Outer Marker (ILS)';
      case 'IS': return 'ILS Category I';
      case 'IT': return 'ILS Category II';
      case 'IU': return 'ILS Category III';
      case 'IW': return 'MLS';
      case 'IX': return 'Locator, Outer (ILS)';
      case 'IY': return 'Locator, Middle (ILS)';
      
      // Lighting Facilities (L)
      case 'LA': return 'Approach Lighting System';
      case 'LB': return 'Aerodrome Beacon';
      case 'LC': return 'Runway Centre Line Lights';
      case 'LD': return 'Landing Direction Indicator Lights';
      case 'LE': return 'Runway Edge Lights';
      case 'LF': return 'Sequenced Flashing Lights';
      case 'LG': return 'Pilot-Controlled Lighting';
      case 'LH': return 'High Intensity Runway Lights';
      case 'LI': return 'Runway End Identifier Lights';
      case 'LJ': return 'Runway Alignment Indicator Lights';
      case 'LK': return 'CAT II Components of ALS';
      case 'LL': return 'Low Intensity Runway Lights';
      case 'LM': return 'Medium Intensity Runway Lights';
      case 'LP': return 'PAPI';
      case 'LR': return 'All Landing Area Lighting Facilities';
      case 'LS': return 'Stopway Lights';
      case 'LT': return 'Threshold Lights';
      case 'LU': return 'Helicopter Approach Path Indicator';
      case 'LV': return 'VASIS';
      case 'LW': return 'Heliport Lighting';
      case 'LX': return 'Taxiway Centre Line Lights';
      case 'LY': return 'Taxiway Edge Lights';
      case 'LZ': return 'Runway Touchdown Zone Lights';
      
      // Movement and Landing Area (M)
      case 'MA': return 'Movement Area';
      case 'MB': return 'Bearing Strength';
      case 'MC': return 'Clearway';
      case 'MD': return 'Declared Distances';
      case 'MG': return 'Taxiing Guidance System';
      case 'MH': return 'Arresting Gear';
      case 'MK': return 'Parking Area';
      case 'MM': return 'Daylight Markings';
      case 'MN': return 'Apron';
      case 'MO': return 'Stopbar';
      case 'MP': return 'Aircraft Stands';
      case 'MR': return 'Runway';
      case 'MS': return 'Stopway';
      case 'MT': return 'Threshold';
      case 'MU': return 'Runway Turning Bay';
      case 'MW': return 'Strip/Shoulder';
      case 'MX': return 'Taxiway(s)';
      case 'MY': return 'Rapid Exit Taxiway';
      
      // COM Terminal and En Route Navigation Facilities (N)
      case 'NA': return 'All Radio Navigation Facilities';
      case 'NB': return 'Nondirectional Radio Beacon';
      case 'NC': return 'DECCA';
      case 'ND': return 'Distance Measuring Equipment (DME)';
      case 'NF': return 'Fan Marker';
      case 'NL': return 'Locator';
      case 'NM': return 'VOR/DME';
      case 'NN': return 'TACAN';
      case 'NO': return 'OMEGA';
      case 'NT': return 'VORTAC';
      case 'NV': return 'VOR';
      
      // Other Information (O)
      case 'OA': return 'Aeronautical Information Service';
      case 'OB': return 'Obstacle';
      case 'OE': return 'Aircraft Entry Requirements';
      case 'OL': return 'Obstacle Lights';
      case 'OR': return 'Rescue Coordination Centre';
      
      // ATM Air Traffic Procedures (P)
      case 'PA': return 'Standard Instrument Arrival';
      case 'PB': return 'Standard VFR Arrival';
      case 'PC': return 'Contingency Procedures';
      case 'PD': return 'Standard Instrument Departure';
      case 'PE': return 'Standard VFR Departure';
      case 'PF': return 'Flow Control Procedure';
      case 'PH': return 'Holding Procedure';
      case 'PI': return 'Instrument Approach Procedure';
      case 'PK': return 'VFR Approach Procedure';
      case 'PL': return 'Flight Plan Processing';
      case 'PM': return 'Aerodrome Operating Minima';
      case 'PN': return 'Noise Operating Restriction';
      case 'PO': return 'Obstacle Clearance Altitude and Height';
      case 'PR': return 'Radio Failure Procedures';
      case 'PT': return 'Transition Altitude or Transition Level';
      case 'PU': return 'Missed Approach Procedure';
      case 'PX': return 'Minimum Holding Altitude';
      case 'PZ': return 'ADIZ Procedure';
      
      // Navigation Warnings: Airspace Restrictions (R)
      case 'RA': return 'Airspace Reservation';
      case 'RD': return 'Danger Area';
      case 'RM': return 'Military Operating Area';
      case 'RO': return 'Overflying of...';
      case 'RP': return 'Prohibited Area';
      case 'RR': return 'Restricted Area';
      case 'RT': return 'Temporary Restricted Area';
      
      // ATM Air Traffic and VOLMET Services (S)
      case 'SA': return 'Automatic Terminal Information Service';
      case 'SB': return 'ATS Reporting Office';
      case 'SC': return 'Area Control Centre';
      case 'SE': return 'Flight Information Service';
      case 'SF': return 'Aerodrome Flight Information Service';
      case 'SL': return 'Flow Control Centre';
      case 'SO': return 'Oceanic Area Control Centre';
      case 'SP': return 'Approach Control Service';
      case 'SS': return 'Flight Service Station';
      case 'ST': return 'Aerodrome Control Tower';
      case 'SU': return 'Upper Area Control Centre';
      case 'SV': return 'VOLMET Broadcast';
      case 'SY': return 'Upper Advisory Service';
      
      // Navigation Warnings: Warnings (W)
      case 'WA': return 'Air Display';
      case 'WB': return 'Aerobatics';
      case 'WC': return 'Captive Balloon or Kite';
      case 'WD': return 'Demolition of Explosives';
      case 'WE': return 'Exercises';
      case 'WF': return 'Air Refueling';
      case 'WG': return 'Glider Flying';
      case 'WH': return 'Blasting';
      case 'WJ': return 'Banner/Target Towing';
      case 'WL': return 'Ascent of Free Balloon';
      case 'WM': return 'Missile, Gun or Rocket Flying';
      case 'WP': return 'Parachute Jumping Exercise, Paragliding or Hang Gliding';
      case 'WR': return 'Radioactive Materials or Toxic Chemicals';
      case 'WS': return 'Burning or Blowing Gas';
      case 'WT': return 'Mass Movement of Aircraft';
      case 'WU': return 'Unmanned Aircraft';
      case 'WV': return 'Formation Flight';
      case 'WW': return 'Significant Volcanic Activity';
      case 'WY': return 'Aerial Survey';
      case 'WZ': return 'Model Flying';
      
      default: return 'Unknown Subject';
    }
  }

  // Get human-readable description of Q code status
  static String getQCodeStatusDescription(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return 'Unknown';
    }
    
    final status = qCode.substring(3, 5);
    
    switch (status) {
      // Availability (A)
      case 'AC': return 'Withdrawn for Maintenance';
      case 'AD': return 'Available for Daylight Operation';
      case 'AF': return 'Flight Checked and Found Reliable';
      case 'AG': return 'Ground Checked Only';
      case 'AH': return 'Hours of Service Now';
      case 'AK': return 'Resumed Normal Operations';
      case 'AL': return 'Operative Subject to Prior Conditions';
      case 'AM': return 'Military Operations Only';
      case 'AN': return 'Available for Night Ops';
      case 'AO': return 'Operational';
      case 'AP': return 'Prior Permission Required';
      case 'AR': return 'Available on Request';
      case 'AS': return 'Unserviceable';
      case 'AU': return 'Not Available';
      case 'AW': return 'Completely Withdrawn';
      case 'AX': return 'Previously Promulgated Shutdown Cancelled';
      
      // Changes (C)
      case 'CA': return 'Activated';
      case 'CC': return 'Completed';
      case 'CD': return 'Deactivated';
      case 'CE': return 'Erected';
      case 'CF': return 'Operating Frequency(ies) Changed To';
      case 'CG': return 'Downgraded To';
      case 'CH': return 'Changed';
      case 'CI': return 'Identification or Radio Call Sign Changed To';
      case 'CL': return 'Realigned';
      case 'CM': return 'Displaced';
      case 'CN': return 'Canceled';
      case 'CO': return 'Operating';
      case 'CP': return 'Operating on Reduced Power';
      case 'CR': return 'Temporarily Replaced By';
      case 'CS': return 'Installed';
      case 'CT': return 'On Test, Do Not Use';
      
      // Hazard Conditions (H)
      case 'HA': return 'Braking Action Is...';
      case 'HB': return 'Friction Coefficient Is...';
      case 'HC': return 'Covered by Compacted Snow to Depth of';
      case 'HD': return 'Covered by Dry Snow to Depth of';
      case 'HE': return 'Covered by Water to Depth of';
      case 'HF': return 'Totally Free of Snow and Ice';
      case 'HG': return 'Grass Cutting in Progress';
      case 'HH': return 'Hazard Due To';
      case 'HI': return 'Covered by Ice';
      case 'HJ': return 'Launch Planned';
      case 'HK': return 'Bird Migration in Progress';
      case 'HL': return 'Snow Clearance Completed';
      case 'HM': return 'Marked By';
      case 'HN': return 'Covered by Wet Snow or Slush to Depth of';
      case 'HO': return 'Obscured by Snow';
      case 'HP': return 'Snow Clearance in Progress';
      case 'HQ': return 'Operation Canceled';
      case 'HR': return 'Standing Water';
      case 'HS': return 'Sanding in Progress';
      case 'HT': return 'Approach According to Signal Area Only';
      case 'HU': return 'Launch in Progress';
      case 'HV': return 'Work Completed';
      case 'HW': return 'Work in Progress';
      case 'HX': return 'Concentration of Birds';
      case 'HY': return 'Snow Banks Exist';
      case 'HZ': return 'Covered by Frozen Ruts and Ridges';
      
      // Limitations (L)
      case 'LA': return 'Operating on Auxiliary Power';
      case 'LB': return 'Reserved for Aircraft Based Therein';
      case 'LC': return 'Closed';
      case 'LD': return 'Unsafe';
      case 'LE': return 'Operating Without Auxiliary Power Supply';
      case 'LF': return 'Interference From';
      case 'LG': return 'Operating Without Identification';
      case 'LH': return 'Unserviceable for Aircraft Heavier Than';
      case 'LI': return 'Closed to IFR Operations';
      case 'LK': return 'Operating as a Fixed Light';
      case 'LL': return 'Usable for Length of...and Width of...';
      case 'LN': return 'Closed to All Night Operations';
      case 'LP': return 'Prohibited To';
      case 'LR': return 'Aircraft Restricted to Runways and Taxiways';
      case 'LS': return 'Subject to Interruption';
      case 'LT': return 'Limited To';
      case 'LV': return 'Closed to VFR Operations';
      case 'LW': return 'Will Take Place';
      case 'LX': return 'Operating but Caution Advised Due To';
      
      // Other (XX)
      case 'XX': return 'Unknown/Unspecified';
      
      default: return 'Other';
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

    // Debug: Log the complete raw NOTAM JSON structure
    print(' COMPLETE RAW NOTAM JSON for ${notam['number']}:');
    print('${'=' * 80}');
    print('NOTAM OBJECT:');
    print(notam);
    print('${'=' * 80}');
    print('CORE NOTAM DATA:');
    print(coreNotamData);
    print('${'=' * 80}');
    print('PROPERTIES:');
    print(properties);
    print('${'=' * 80}');
    print('COMPLETE JSON:');
    print(json);
    print('${'=' * 80}');

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
    
    // Extract Q code from notamTranslation (ICAO format) instead of text
    String? qCode;
    final translations = coreNotamData['notamTranslation'] as List?;
    if (translations != null) {
      print('DEBUG: 🔍 Found ${translations.length} translations for ${notam['number']}');
      for (final translation in translations) {
        print('DEBUG: 🔍 Translation type: ${translation['type']}');
        if (translation['type'] == 'ICAO') {
          final formattedText = translation['formattedText'] as String?;
          if (formattedText != null) {
            print('DEBUG: 🔍 ICAO formatted text: $formattedText');
            qCode = extractQCode(formattedText);
            print('DEBUG: 🔍 Extracted Q code: $qCode');
            if (qCode != null) break;
          }
        }
      }
    }
    
    // Fallback to text field if no Q code found in translations
    if (qCode == null) {
      print('DEBUG: 🔍 No Q code found in translations, trying text field');
      qCode = extractQCode(text);
    }
    
    // Debug: Log the complete raw NOTAM text
    print(' RAW NOTAM TEXT for ${notam['number']}:');
    print('${'=' * 80}');
    print(text);
    print('${'=' * 80}');
    
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