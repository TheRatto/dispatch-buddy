import '../models/notam.dart';

class NotamGroupingService {
  static final NotamGroupingService _instance = NotamGroupingService._internal();
  factory NotamGroupingService() => _instance;
  NotamGroupingService._internal();

  /// Assign a group to a NOTAM based on its Q code
  NotamGroup assignGroup(Notam notam) {
    return notam.group;
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

  /// Get keywords associated with a group for text-based classification
  List<String> getKeywordsForGroup(NotamGroup group) {
    switch (group) {
      case NotamGroup.movementAreas:
        return ['CLOSED', 'U/S', 'UNSERVICEABLE', 'DISPLACED', 'LIMITED', 'MISSING', 'RWY', 'TAXIWAY', 'APRON', 'PARKING'];
      case NotamGroup.navigationAids:
        return ['ILS', 'GLS', 'VOR', 'NDB', 'DME', 'DA', 'MDA', 'MINIMA'];
      case NotamGroup.departureApproachProcedures:
        return ['SID', 'STAR', 'APPROACH', 'DEPARTURE', 'PROCEDURE'];
      case NotamGroup.airportAtcAvailability:
        return ['CLOSED', 'NO', 'NOT AVBL', 'AVBL', 'OPR HR', 'ATC', 'TWR', 'GND', 'APP'];
      case NotamGroup.lighting:
        return ['LIGHTING', 'LIGHTS', 'HIRL', 'REIL', 'PAPI', 'VASIS'];
      case NotamGroup.hazardsObstacles:
        return ['OBSTACLE', 'CRANE', 'CONSTRUCTION', 'UNLIT', 'HAZARD'];
      case NotamGroup.airspace:
        return ['RESTRICTED', 'PROHIBITED', 'DANGER', 'GPS', 'RNAV', 'AIRSPACE'];
      case NotamGroup.proceduralAdmin:
        return ['CURFEW', 'NOISE', 'PPR', 'SLOT', 'RESTRICTION'];
      case NotamGroup.other:
        return [];
    }
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