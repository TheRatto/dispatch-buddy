import '../models/notam.dart';

class RunwayStatusAnalyzer {
  /// Analyze NOTAMs to determine runway system status
  static RunwaySystemStatus analyzeRunwayStatus(List<Notam> notams) {
    if (notams.isEmpty) {
      return RunwaySystemStatus(
        overallStatus: SystemStatus.green,
        runways: [],
        operationalImpacts: [],
        summary: 'All runways operational',
      );
    }

    // Extract runway-specific NOTAMs
    final runwayNotams = _filterRunwayNotams(notams);
    
    // Group NOTAMs by runway
    final runwayGroups = _groupByRunway(runwayNotams);
    
    // Analyze each runway
    final runwayStatuses = runwayGroups.entries.map((entry) {
      return _analyzeRunway(entry.key, entry.value);
    }).toList();
    
    // Determine overall system status
    final overallStatus = _determineOverallStatus(runwayStatuses);
    
    // Extract operational impacts
    final operationalImpacts = _extractOperationalImpacts(runwayNotams);
    
    // Generate summary
    final summary = _generateSummary(runwayStatuses, overallStatus);
    
    return RunwaySystemStatus(
      overallStatus: overallStatus,
      runways: runwayStatuses,
      operationalImpacts: operationalImpacts,
      summary: summary,
    );
  }
  
  /// Filter NOTAMs that are runway-related
  static List<Notam> _filterRunwayNotams(List<Notam> notams) {
    final runwayKeywords = [
      'runway', 'rw', 'rwy', 'approach', 'departure',
      'ils', 'localizer', 'glide', 'papi',
      'threshold', 'displaced', 'closed', 'construction',
      'maintenance', 'ork', 'resurfacing', 'marking'
    ];
    
    return notams.where((notam) {
      final text = notam.rawText.toLowerCase();
      return runwayKeywords.any((keyword) => text.contains(keyword));
    }).toList();
  }
  
  /// Group NOTAMs by runway identifier
  static Map<String, List<Notam>> _groupByRunway(List<Notam> runwayNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in runwayNotams) {
      final runways = extractRunwayIdentifiers(notam.rawText);
      for (final runway in runways) {
        groups.putIfAbsent(runway, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract runway identifiers from NOTAM text
  static List<String> extractRunwayIdentifiers(String text) {
    final runways = <String>[];
    
    // Pattern for runway identifiers (e.g., RWY01, RWY19RWY 04R)
    final runwayPattern = RegExp(r'RWY?\s*(\d{1,2}[LCR]?)', caseSensitive: false);
    final matches = runwayPattern.allMatches(text);
    
    for (final match in matches) {
      final runway = match.group(1);
      if (runway != null) {
        runways.add('RWY $runway');
      }
    }
    
    // If no specific runways found, check for general runway references
    if (runways.isEmpty && text.toLowerCase().contains('runway')) {
      runways.add('General Runway');
    }
    
    return runways;
  }
  
  /// Analyze status of a specific runway
  static RunwayStatus _analyzeRunway(String runwayId, List<Notam> notams) {
    bool hasClosure = false;
    bool hasRestriction = false;
    bool hasConstruction = false;
    bool hasMaintenance = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('closed') || text.contains('not available')) {
        hasClosure = true;
        impacts.add('Runway closed');
      }
      
      if (text.contains('restricted') || text.contains('limited')) {
        hasRestriction = true;
        impacts.add('Operational restrictions');
      }
      
      if (text.contains('construction') || text.contains('work')) {
        hasConstruction = true;
        impacts.add('Construction work');
      }
      
      if (text.contains('maintenance')) {
        hasMaintenance = true;
        impacts.add('Maintenance work');
      }
    }
    
    // Determine runway status
    SystemStatus status;
    if (hasClosure) {
      status = SystemStatus.red;
    } else if (hasRestriction || hasConstruction || hasMaintenance) {
      status = SystemStatus.yellow;
    } else {
      status = SystemStatus.green;
    }
    
    return RunwayStatus(
      identifier: runwayId,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Determine overall runway system status
  static SystemStatus _determineOverallStatus(List<RunwayStatus> runwayStatuses) {
    if (runwayStatuses.isEmpty) return SystemStatus.green;
    
    final hasRed = runwayStatuses.any((r) => r.status == SystemStatus.red);
    final hasYellow = runwayStatuses.any((r) => r.status == SystemStatus.yellow);
    
    if (hasRed) return SystemStatus.red;
    if (hasYellow) return SystemStatus.yellow;
    return SystemStatus.green;
  }
  
  /// Extract key operational impacts
  static List<String> _extractOperationalImpacts(List<Notam> runwayNotams) {
    final impacts = <String>[];
    
    for (final notam in runwayNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('closed') && !impacts.contains('Runway closures')) {
        impacts.add('Runway closures');
      }
      
      if (text.contains('ils') && text.contains('out') && !impacts.contains('ILS outages')) {
        impacts.add('ILS outages');
      }
      
      if (text.contains('approach') && text.contains('not available') && !impacts.contains('Approach procedure restrictions')) {
        impacts.add('Approach procedure restrictions');
      }
      
      if (text.contains('construction') && !impacts.contains('Construction work')) {
        impacts.add('Construction work');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  static String _generateSummary(List<RunwayStatus> runwayStatuses, SystemStatus overallStatus) {
    if (runwayStatuses.isEmpty) {
      return 'All runways operational';
    }
    
    final closedRunways = runwayStatuses.where((r) => r.status == SystemStatus.red).toList();
    final restrictedRunways = runwayStatuses.where((r) => r.status == SystemStatus.yellow).toList();
    
    if (closedRunways.isNotEmpty) {
      final runwayList = closedRunways.map((r) => r.identifier).join(', ');
      return '${closedRunways.length} runway(s) closed: $runwayList';
    }
    
    if (restrictedRunways.isNotEmpty) {
      final runwayList = restrictedRunways.map((r) => r.identifier).join(', ');
      return '${restrictedRunways.length} runway(s) with restrictions: $runwayList';
    }
    
    return 'All runways operational with minor restrictions';
  }
}

enum SystemStatus { green, yellow, red }

class RunwayStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  RunwayStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
}

class RunwaySystemStatus {
  final SystemStatus overallStatus;
  final List<RunwayStatus> runways;
  final List<String> operationalImpacts;
  final String summary;
  
  RunwaySystemStatus({
    required this.overallStatus,
    required this.runways,
    required this.operationalImpacts,
    required this.summary,
  });
} 