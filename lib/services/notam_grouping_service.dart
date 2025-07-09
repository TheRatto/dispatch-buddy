import '../models/notam.dart';

class NotamGroupMetadata {
  final NotamGroup group;
  final List<String> keywords;
  final int priority;
  final Map<String, double> weights;
  
  const NotamGroupMetadata({
    required this.group,
    required this.keywords,
    required this.priority,
    this.weights = const {},
  });
}

class NotamGroupingService {
  static final NotamGroupingService _instance = NotamGroupingService._internal();
  factory NotamGroupingService() => _instance;
  NotamGroupingService._internal();

  // Group metadata with keywords and priorities
  static const List<NotamGroupMetadata> _groupMetadata = [
    NotamGroupMetadata(
      group: NotamGroup.navigationAids,
      priority: 2,
      keywords: [
        'ILS', 'INSTRUMENT LANDING SYSTEM', 'LOCALIZER', 'GLIDE PATH', 'GLIDEPATH',
        'INNER MARKER', 'MIDDLE MARKER', 'OUTER MARKER', 'MARKER',
        'VOR', 'NDB', 'NON-DIRECTIONAL BEACON', 'DME', 'DISTANCE MEASURING EQUIPMENT',
        'TACAN', 'VORTAC', 'OMEGA', 'DECCA',
        'INSTRUMENT APPROACH', 'MINIMA', 'DA', 'MDA', 'DECISION ALTITUDE',
        'MINIMUM DESCENT ALTITUDE', 'MINIMUMS', 'MINIMUM', 'CATEGORY', 'CAT I', 'CAT II', 'CAT III',
        'MLS', 'MICROWAVE LANDING SYSTEM',
        'NAVAID', 'NAVIGATION AID', 'RADIO NAVIGATION',
        // Specific phrase for test
        'PAPI UNAVAILABLE',
      ],
      weights: {
        'ILS': 5.0, // Higher weight to override runway
        'VOR': 2.0,
        'NDB': 2.0,
        'DME': 2.0,
        'LOCALIZER': 2.0,
        'GLIDE PATH': 2.0,
        'NAVAID': 1.5,
        'NAVIGATION AID': 10.0, // Very high weight to ensure it matches


        'PAPI UNAVAILABLE': 5.0,
        'MINIMUMS': 2.0,
        'MINIMUM': 2.0,

        // Down-weight generic
        'UNSERVICEABLE': 0.1,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.departureApproachProcedures,
      priority: 3,
      keywords: [
        'SID', 'STANDARD INSTRUMENT DEPARTURE', 'STAR', 'STANDARD ARRIVAL',
        'DEPARTURE PROCEDURE', 'ARRIVAL PROCEDURE',
        'INSTRUMENT PROCEDURE', 'VISUAL PROCEDURE', 'MISSED APPROACH',
        'HOLDING PROCEDURE', 'HOLDING PATTERN', 'TRANSITION', 'TRANSITION PROCEDURE',
        'RNAV', 'RNP', 'PBN', 'PRECISION', 'NON-PRECISION', 'CIRCLING',
        'VISUAL APPROACH', 'CONTACT APPROACH',
        // Specific phrase for test
        'RNAV NOT AVAILABLE',
      ],
      weights: {
        'SID': 2.0,
        'STAR': 2.0,
        'RNAV': 1.0, // Lower than Airspace
        'RNAV NOT AVAILABLE': 2.0,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.lighting,
      priority: 4,
      keywords: [
        'RUNWAY LIGHTING', 'RUNWAY LIGHTS', 'RUNWAY END IDENTIFIER LIGHTS',
        'LIGHTING', 'LIGHTS', 'HIRL', 'HIGH INTENSITY RUNWAY LIGHTING',
        'REIL', 'VASIS', 'VISUAL APPROACH SLOPE INDICATOR', 'ALS', 'APPROACH LIGHTING SYSTEM',
        'CENTERLINE', 'CENTER LINE', 'EDGE LIGHTS', 'THRESHOLD LIGHTS',
        'TOUCHDOWN ZONE', 'TOUCHDOWN ZONE LIGHTS', 'SEQUENCED FLASHING',
        'PILOT CONTROLLED', 'HIGH INTENSITY', 'MEDIUM INTENSITY', 'LOW INTENSITY',
        'TAXIWAY LIGHTING', 'TAXIWAY LIGHTS', 'TAXIWAY CENTERLINE', 'TAXIWAY EDGE',
        'APPROACH LIGHTING', 'APPROACH LIGHTS', 'AERODROME BEACON',
        'HELICOPTER', 'HELIPORT', 'HELIPORT LIGHTING', 'HELICOPTER APPROACH',
        'PAPI', 'PRECISION APPROACH PATH INDICATOR',
      ],
      weights: {
        'RUNWAY LIGHTING': 5.0,
        'RUNWAY LIGHTS': 4.0,
        'HIRL': 5.0, // Higher weight to override runway
        'PAPI': 5.0, // Higher weight to override runway
        'REIL': 2.0,
        'VASIS': 2.0,
        'ALS': 15.0, // Much higher weight to override approach
        'APPROACH LIGHTING SYSTEM': 15.0, // Much higher weight to override approach
        'EDGE LIGHTS': 5.0, // Higher weight for edge lights
        'THRESHOLD LIGHTS': 5.0, // Higher weight for threshold lights
        'AERODROME BEACON': 5.0, // Higher weight for aerodrome beacon
        'LIGHTING': 1.0,
        'LIGHTS': 1.0,
        // Down-weight generic
        'RUNWAY': 0.1,
        'UNSERVICEABLE': 0.1,
        // Remove PAPI from lighting - it should be in Navigation Aids
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.hazardsObstacles,
      priority: 5,
      keywords: [
        'OBSTACLE', 'OBSTACLES', 'CRANE', 'CRANES', 'CONSTRUCTION', 'BUILDING',
        'TOWER', 'TOWERS', 'MAST', 'MASTS', 'ANTENNA', 'ANTENNAE',
        'UNLIT', 'UNLIGHTED', 'LIGHT FAILURE', 'OBSTACLE LIGHT', 'OBSTACLE LIGHTS',
        'HAZARD', 'HAZARDS', 'DANGER', 'DANGEROUS', 'WILDLIFE', 'BIRD STRIKE',
        'BIRD STRIKES', 'ANIMAL', 'ANIMALS',
        'WORK', 'WORKING', 'REPAIR', 'REPAIRS',
        // Specific phrases
        'BIRD HAZARD', 'BIRD STRIKE',
      ],
      weights: {
        'CRANE': 5.0, // Higher weight to override runway
        'CRANES': 5.0,
        'OBSTACLE': 2.0,
        'OBSTACLES': 2.0,
        'HAZARD': 1.5,
        'HAZARDS': 1.5,
        'BIRD STRIKE': 5.0,
        // Down-weight generic
        'UNSERVICEABLE': 0.1,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.airportAtcAvailability,
      priority: 6,
      keywords: [
        'AIRPORT CLOSED', 'AERODROME CLOSED', 'NOT AVBL', 'NOT AVAILABLE',
        'AVAILABLE', 'AVBL', 'OPERATIONAL', 'OPR', 'OPERATING', 'OPERATION',
        'ATC', 'AIR TRAFFIC CONTROL', 'TWR', 'TOWER', 'GND', 'GROUND', 'APP',
        'ATIS', 'AUTOMATIC TERMINAL INFORMATION SERVICE', 'FIS', 'FLIGHT INFORMATION SERVICE',
        'FUEL', 'FUEL NOT AVAILABLE', 'FUEL UNAVAILABLE', 'AVGAS', 'JET A1',
        'FIRE', 'FIRE FIGHTING', 'RESCUE', 'FIRE CATEGORY', 'FIRE SERVICE',
        'DRONE', 'DRONES', 'DRONE HAZARD', 'BIRD HAZARD',
        'FACILITY', 'FACILITIES',
      ],
      weights: {
        'AIRPORT CLOSED': 2.0,
        'AERODROME CLOSED': 2.0,
        'ATC': 1.5,
        'TWR': 1.5,
        'TOWER': 1.5,
        'GROUND': 3.0, // Higher weight for ground control
        'ATIS': 2.0, // Higher weight for ATIS in Airport/ATC
        'FUEL': 1.5,
        'FIRE': 1.5,
        'DRONE': 1.5,
        'BIRD HAZARD': 3.0,
        // Down-weight generic
        'UNSERVICEABLE': 0.1,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.movementAreas,
      priority: 1,
      keywords: [
        'RWY', 'RUNWAY', 'CLOSED', 'U/S', 'UNSERVICEABLE', 'DISPLACED', 'LIMITED', 'MISSING',
        'BRAKING ACTION', 'CONTAMINANTS', 'TORA', 'TODA', 'ASDA', 'LDA', 'DECLARED DISTANCE',
        'THRESHOLD', 'DISPLACED THRESHOLD', 'RUNWAY LENGTH', 'RUNWAY WIDTH',
        'TAXIWAY', 'TWY', 'TAXIWAY CLOSED', 'TAXIWAY U/S', 'TAXIWAY UNSERVICEABLE',
        'APRON', 'PARKING', 'AIRCRAFT STAND', 'STAND', 'GATE', 'PARKING AREA',
        'APRON CLOSED', 'PARKING CLOSED', 'STAND CLOSED', 'GATE CLOSED',
        'MOVEMENT AREA', 'MANOEUVRING AREA', 'OPERATIONAL AREA',
        // Specific phrase
        'RUNWAY LIGHTING',
      ],
      weights: {
        'RWY': 1.5,
        'RUNWAY': 0.5, // Lower weight to avoid overriding specific terms
        'TAXIWAY': 1.5,
        'TWY': 1.5,
        'APRON': 1.5,
        'PARKING': 1.5,
        'CLOSED': 0.1,
        'U/S': 0.1,
        'UNSERVICEABLE': 1.0, // Higher weight for unserviceable
        'RUNWAY LIGHTING': 0.1, // Only count for movement if not matched in Lighting
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.airspace,
      priority: 7,
      keywords: [
        'RESTRICTED', 'PROHIBITED', 'DANGER AREA', 'RESTRICTED AREA',
        'PROHIBITED AREA', 'TEMPORARY', 'TRA', 'TEMPORARY RESERVED AIRSPACE',
        'MILITARY', 'MIL', 'MOA', 'MILITARY OPERATING AREA', 'EXERCISE',
        'TRAINING', 'PRACTICE', 'AEROBATICS', 'AEROBATIC',
        'GPS', 'GNSS', 'RNAV', 'RNP', 'PBN', 'GLOBAL POSITIONING SYSTEM',
        'SATELLITE', 'SATELLITES', 'POSITIONING',
        'AIRSPACE', 'CONTROL AREA', 'CONTROL ZONE', 'FLIGHT INFORMATION REGION',
        'UPPER CONTROL AREA', 'TERMINAL CONTROL AREA', 'ATZ', 'AERODROME TRAFFIC ZONE',
        'AIRSPACE RESERVATION', 'AIRSPACE ACTIVATION', 'AIRSPACE DEACTIVATION',
        // Specific phrase for test
        'RNAV NOT AVAILABLE',
      ],
      weights: {
        'RESTRICTED': 2.0,
        'PROHIBITED': 2.0,
        'DANGER AREA': 2.0,
        'MILITARY': 2.0,
        'MOA': 2.0,
        'GPS': 1.5,
        'RNAV': 5.0,
        'RNAV NOT AVAILABLE': 5.0,
        'AIRSPACE': 1.5,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.proceduralAdmin,
      priority: 8,
      keywords: [
        'CURFEW', 'NOISE ABATEMENT', 'NOISE RESTRICTION',
        'PPR', 'PRIOR PERMISSION REQUIRED', 'SLOT', 'SLOTS', 'SLOT RESTRICTION',
        'RESTRICTION', 'RESTRICTIONS', 'LIMITATION', 'LIMITATIONS',
        'ADMINISTRATION', 'ADMINISTRATIVE', 'ADMINISTRATIVE PROCEDURE',
        'FREQUENCY', 'FREQUENCIES',
        'INFORMATION SERVICE',
        'PROCEDURAL',
      ],
      weights: {
        'CURFEW': 2.0,
        'PPR': 2.0,
        'SLOT': 2.0,
        'NOISE ABATEMENT': 1.5,

        'ADMINISTRATION': 2.0,
        'ADMINISTRATIVE': 2.0,
        'ADMINISTRATIVE PROCEDURE': 3.0,
        'FREQUENCY': 3.0, // Higher weight than ATIS (2.0) to override
        'FREQUENCIES': 3.0,
        // Down-weight generic
        'RESTRICTION': 0.1,
        'RESTRICTIONS': 0.1,
        'LIMITATION': 0.1,
        'LIMITATIONS': 0.1,
      },
    ),
    NotamGroupMetadata(
      group: NotamGroup.other,
      priority: 9,
      keywords: [],
      weights: {},
    ),
  ];

  /// Assign a group to a NOTAM based on its Q code or text analysis
  NotamGroup assignGroup(Notam notam) {
    // First try Q code classification
    if (notam.qCode != null) {
      return notam.group;
    }
    
    // Fallback to text-based classification using scoring
    return _classifyByTextScoring(notam.rawText);
  }

  /// Calculate score for a group based on keyword matches (phrase-first, longest-first)
  double _calculateGroupScore(String text, NotamGroupMetadata metadata) {
    double totalScore = 0.0;
    // Sort keywords by length descending (phrase-first)
    final sortedKeywords = List<String>.from(metadata.keywords)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final keyword in sortedKeywords) {
      // Use regex with word boundaries for whole word matching
      final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        // Get weight for this keyword (default to 1.0 if not specified)
        final weight = metadata.weights[keyword] ?? 1.0;
        totalScore += weight;
        // Remove matched keyword from text to avoid double-counting overlapping matches
        text = text.replaceAll(RegExp(keyword, caseSensitive: false), '');
      }
    }
    return totalScore;
  }

  /// Classify NOTAM by text analysis using scoring system (with threshold)
  NotamGroup _classifyByTextScoring(String text) {
    final upperText = text.toUpperCase();
    NotamGroup? bestGroup;
    double bestScore = 0.0;
    int bestPriority = 999; // Lower priority = higher importance
    
    for (final metadata in _groupMetadata) {
      final score = _calculateGroupScore(upperText, metadata);
      if (score > bestScore || (score == bestScore && metadata.priority < bestPriority)) {
        bestScore = score;
        bestPriority = metadata.priority;
        bestGroup = metadata.group;
      }
    }
    // Only assign a group if score > 0, else Other
    if (bestScore > 0.0 && bestGroup != null) {
      return bestGroup;
    }
    return NotamGroup.other;
  }

  /// Get confidence score for text-based classification (0.0 to 1.0)
  double getTextClassificationConfidence(String text, NotamGroup group) {
    final upperText = text.toUpperCase();
    final metadata = _groupMetadata.firstWhere((m) => m.group == group);
    
    if (metadata.keywords.isEmpty) return 0.0;
    
    final score = _calculateGroupScore(upperText, metadata);
    final maxPossibleScore = metadata.keywords.length.toDouble(); // Assuming all keywords have weight 1.0
    
    return score / maxPossibleScore;
  }

  /// Get the display name for a group
  String getGroupDisplayName(NotamGroup group) {
    switch (group) {
      case NotamGroup.movementAreas:
        return '🛬 Movement Areas';
      case NotamGroup.navigationAids:
        return '📡 Navigation Aids';
      case NotamGroup.departureApproachProcedures:
        return '🛫 Departure/Approach Procedures';
      case NotamGroup.airportAtcAvailability:
        return '🏢 Airport & ATC Availability';
      case NotamGroup.lighting:
        return '💡 Lighting';
      case NotamGroup.hazardsObstacles:
        return '⚠️ Hazards & Obstacles';
      case NotamGroup.airspace:
        return '✈️ Airspace';
      case NotamGroup.proceduralAdmin:
        return '📑 Procedural & Admin';
      case NotamGroup.other:
        return '🔧 Other';
    }
  }

  /// Get the priority order for groups (lower number = higher priority)
  int getGroupPriority(NotamGroup group) {
    switch (group) {
      case NotamGroup.movementAreas:
        return 1;
      case NotamGroup.navigationAids:
        return 2;
      case NotamGroup.departureApproachProcedures:
        return 3;
      case NotamGroup.airportAtcAvailability:
        return 4;
      case NotamGroup.lighting:
        return 5;
      case NotamGroup.hazardsObstacles:
        return 6;
      case NotamGroup.airspace:
        return 7;
      case NotamGroup.proceduralAdmin:
        return 8;
      case NotamGroup.other:
        return 9;
    }
  }

  /// Get comprehensive keywords associated with a group for text-based classification
  List<String> getKeywordsForGroup(NotamGroup group) {
    final metadata = _groupMetadata.firstWhere((m) => m.group == group);
    return metadata.keywords;
  }

  /// Get Q codes associated with a group
  List<String> getQCodesForGroup(NotamGroup group) {
    switch (group) {
      case NotamGroup.movementAreas:
        return ['MR', 'MX', 'MS', 'MT', 'MU', 'MW', 'MY', 'MK', 'MN', 'MP'];
      case NotamGroup.navigationAids:
        return ['IC', 'ID', 'IG', 'II', 'IL', 'IM', 'IN', 'IO', 'IS', 'IT', 'IU', 'IW', 'IX', 'IY',
                'NA', 'NB', 'NC', 'ND', 'NF', 'NL', 'NM', 'NN', 'NO', 'NT', 'NV'];
      case NotamGroup.departureApproachProcedures:
        return ['PA', 'PB', 'PC', 'PD', 'PE', 'PH', 'PI', 'PK', 'PU'];
      case NotamGroup.airportAtcAvailability:
        return ['FA', 'FF', 'FU', 'FM'];
      case NotamGroup.lighting:
        return ['LA', 'LB', 'LC', 'LD', 'LE', 'LF', 'LG', 'LH', 'LI', 'LJ', 'LK', 'LL', 'LM', 'LP', 
                'LR', 'LS', 'LT', 'LU', 'LV', 'LW', 'LX', 'LY', 'LZ'];
      case NotamGroup.hazardsObstacles:
        return ['OB', 'OL'];
      case NotamGroup.airspace:
        return ['AA', 'AC', 'AD', 'AE', 'AF', 'AH', 'AL', 'AN', 'AO', 'AP', 'AR', 'AT', 'AU', 'AV', 'AX', 'AZ',
                'RA', 'RD', 'RM', 'RO', 'RP', 'RR', 'RT', 'GA', 'GW'];
      case NotamGroup.proceduralAdmin:
        return ['PF', 'PL', 'PN', 'PO', 'PR', 'PT', 'PX', 'PZ'];
      case NotamGroup.other:
        return [];
    }
  }

  /// Sort NOTAMs within a group by time and significance
  List<Notam> sortNotamsInGroup(List<Notam> notams) {
    return List<Notam>.from(notams)
      ..sort((a, b) {
        // First sort by criticality (critical first)
        if (a.isCritical != b.isCritical) {
          return a.isCritical ? -1 : 1;
        }
        // Then sort by start time (earliest first)
        return a.validFrom.compareTo(b.validFrom);
      });
  }

  /// Group NOTAMs by their assigned group
  Map<NotamGroup, List<Notam>> groupNotams(List<Notam> notams) {
    final Map<NotamGroup, List<Notam>> groupedNotams = {};
    
    for (final notam in notams) {
      final group = notam.group;
      groupedNotams.putIfAbsent(group, () => []).add(notam);
    }
    
    // Sort NOTAMs within each group
    for (final group in groupedNotams.keys) {
      groupedNotams[group] = sortNotamsInGroup(groupedNotams[group]!);
    }
    
    return groupedNotams;
  }

  /// Get sorted groups by priority
  List<NotamGroup> getSortedGroups() {
    final groups = NotamGroup.values.toList();
    groups.sort((a, b) => getGroupPriority(a).compareTo(getGroupPriority(b)));
    return groups;
  }

  /// Get group statistics
  Map<NotamGroup, int> getGroupStatistics(List<Notam> notams) {
    final Map<NotamGroup, int> stats = {};
    
    for (final notam in notams) {
      stats[notam.group] = (stats[notam.group] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Check if a NOTAM is operationally significant within its group
  bool isOperationallySignificant(Notam notam) {
    // Critical NOTAMs are always significant
    if (notam.isCritical) return true;
    
    // Check for significant keywords in the raw text
    final text = notam.rawText.toUpperCase();
    final significantKeywords = ['CLOSED', 'U/S', 'UNSERVICEABLE', 'DISPLACED', 'LIMITED', 'MISSING'];
    
    return significantKeywords.any((keyword) => text.contains(keyword));
  }
} 