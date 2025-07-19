import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class HazardsSystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const HazardsSystemWidget({
    Key? key,
    required this.airportName,
    required this.icao,
    required this.notams,
  }) : super(key: key);

  Color _statusColor(SystemStatus status) {
    switch (status) {
      case SystemStatus.green:
        return Colors.green;
      case SystemStatus.yellow:
        return Colors.orange;
      case SystemStatus.red:
        return Colors.red;
    }
  }

  IconData _statusIcon(SystemStatus status) {
    switch (status) {
      case SystemStatus.green:
        return Icons.check_circle;
      case SystemStatus.yellow:
        return Icons.warning;
      case SystemStatus.red:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        // Filter NOTAMs by time and airport using global filter
        final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(notams, icao);
        
        final systemAnalyzer = AirportSystemAnalyzer();
        final systemNotams = systemAnalyzer.getSystemNotams(filteredNotams, icao);
        final hazardNotams = systemNotams['hazards'] ?? [];
        final overallStatus = systemAnalyzer.analyzeHazardStatus(filteredNotams, icao);
        
        // Group NOTAMs by hazard type for detailed display
        final hazardGroups = _groupByHazard(hazardNotams);
        final hazardStatuses = hazardGroups.entries.map((entry) {
          return _analyzeHazard(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(hazardNotams);
        
        // Generate summary
        final summary = _generateSummary(hazardStatuses, overallStatus);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                children: [
                  Icon(_statusIcon(overallStatus), color: _statusColor(overallStatus), size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Overall Status: ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    overallStatus.name.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(overallStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (operationalImpacts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Key Operational Impacts:', style: Theme.of(context).textTheme.titleSmall),
                ...operationalImpacts.map((impact) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(impact)),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 20),
              Text('Hazards:', style: Theme.of(context).textTheme.titleMedium),
              ...hazardStatuses.map((hazard) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(hazard.status), color: _statusColor(hazard.status)),
                  title: Text(hazard.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: hazard.impacts.isNotEmpty
                    ? Text(hazard.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (hazard.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this hazard.'),
                      )
                    else
                      ...hazard.notams.map((notam) => ListTile(
                        title: Text(notam.rawText, style: const TextStyle(fontSize: 14)),
                      )),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.article_outlined),
                label: const Text('View All Raw NOTAMs'),
                onPressed: () {
                  // TODO: Implement navigation to raw NOTAMs view or show dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('All Raw NOTAMs'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: hazardNotams.map((n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(n.rawText, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Group NOTAMs by hazard type
  Map<String, List<Notam>> _groupByHazard(List<Notam> hazardNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in hazardNotams) {
      final hazardTypes = _extractHazardTypes(notam.rawText);
      for (final hazardType in hazardTypes) {
        groups.putIfAbsent(hazardType, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract hazard types from NOTAM text
  List<String> _extractHazardTypes(String text) {
    final hazards = <String>[];
    
    // Pattern for obstacles
    final obstaclePattern = RegExp(r'\b(?:OBSTACLE|OBSTACLES|CRANE|CRANES|BUILDING|TOWER|TOWERS|MAST|MASTS|ANTENNA|ANTENNAE)\b', caseSensitive: false);
    
    // Pattern for construction
    final constructionPattern = RegExp(r'\b(?:CONSTRUCTION|WORK|WORKING|REPAIR|REPAIRS)\b', caseSensitive: false);
    
    // Pattern for wildlife
    final wildlifePattern = RegExp(r'\b(?:WILDLIFE|BIRD|BIRDS|BIRD STRIKE|BIRD STRIKES|ANIMAL|ANIMALS)\b', caseSensitive: false);
    
    // Pattern for lighting issues
    final lightingPattern = RegExp(r'\b(?:UNLIT|UNLIGHTED|LIGHT FAILURE|OBSTACLE LIGHT|OBSTACLE LIGHTS)\b', caseSensitive: false);
    
    // Pattern for drone hazards
    final dronePattern = RegExp(r'\b(?:DRONE|DRONES|DRONE HAZARD)\b', caseSensitive: false);
    
    // Pattern for general hazards
    final hazardPattern = RegExp(r'\b(?:HAZARD|HAZARDS|DANGER|DANGEROUS)\b', caseSensitive: false);
    
    // Extract obstacles
    if (obstaclePattern.hasMatch(text)) {
      hazards.add('Obstacles');
    }
    
    // Extract construction
    if (constructionPattern.hasMatch(text)) {
      hazards.add('Construction Work');
    }
    
    // Extract wildlife
    if (wildlifePattern.hasMatch(text)) {
      hazards.add('Wildlife Hazards');
    }
    
    // Extract lighting issues
    if (lightingPattern.hasMatch(text)) {
      hazards.add('Lighting Issues');
    }
    
    // Extract drone hazards
    if (dronePattern.hasMatch(text)) {
      hazards.add('Drone Hazards');
    }
    
    // Extract general hazards
    if (hazardPattern.hasMatch(text)) {
      hazards.add('General Hazards');
    }
    
    // If no specific hazards found, add a default
    if (hazards.isEmpty) {
      hazards.add('General Hazards');
    }
    
    return hazards;
  }
  
  /// Analyze status of a specific hazard
  _HazardStatus _analyzeHazard(String hazardType, List<Notam> notams) {
    bool hasCriticalHazard = false;
    bool hasModerateHazard = false;
    bool hasConstruction = false;
    bool hasWildlife = false;
    bool hasLightingIssue = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('critical') || text.contains('dangerous') || text.contains('severe')) {
        hasCriticalHazard = true;
        impacts.add('Critical hazard');
      }
      
      if (text.contains('obstacle') && (text.contains('high') || text.contains('significant'))) {
        hasModerateHazard = true;
        impacts.add('Significant obstacle');
      }
      
      if (text.contains('construction') || text.contains('work')) {
        hasConstruction = true;
        impacts.add('Construction work');
      }
      
      if (text.contains('bird') || text.contains('wildlife')) {
        hasWildlife = true;
        impacts.add('Wildlife hazard');
      }
      
      if (text.contains('unlit') || text.contains('light failure')) {
        hasLightingIssue = true;
        impacts.add('Lighting issue');
      }
    }
    
    // Determine hazard status
    SystemStatus status;
    if (hasCriticalHazard) {
      status = SystemStatus.red;
    } else if (hasModerateHazard || hasConstruction || hasWildlife || hasLightingIssue) {
      status = SystemStatus.yellow;
    } else {
      status = SystemStatus.green;
    }
    
    return _HazardStatus(
      identifier: hazardType,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Extract key operational impacts
  List<String> _extractOperationalImpacts(List<Notam> hazardNotams) {
    final impacts = <String>[];
    
    for (final notam in hazardNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('obstacle') && !impacts.contains('Obstacles present')) {
        impacts.add('Obstacles present');
      }
      
      if (text.contains('construction') && !impacts.contains('Construction work')) {
        impacts.add('Construction work');
      }
      
      if (text.contains('bird') && !impacts.contains('Wildlife hazards')) {
        impacts.add('Wildlife hazards');
      }
      
      if (text.contains('unlit') && !impacts.contains('Unlit obstacles')) {
        impacts.add('Unlit obstacles');
      }
      
      if (text.contains('drone') && !impacts.contains('Drone hazards')) {
        impacts.add('Drone hazards');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  String _generateSummary(List<_HazardStatus> hazardStatuses, SystemStatus overallStatus) {
    if (hazardStatuses.isEmpty) {
      return 'No hazards identified';
    }
    
    final redHazards = hazardStatuses.where((h) => h.status == SystemStatus.red).length;
    final yellowHazards = hazardStatuses.where((h) => h.status == SystemStatus.yellow).length;
    final greenHazards = hazardStatuses.where((h) => h.status == SystemStatus.green).length;
    
    if (redHazards > 0) {
      return '$redHazards critical hazard(s) identified';
    } else if (yellowHazards > 0) {
      return '$yellowHazards moderate hazard(s) present';
    } else {
      return 'Minor hazards present';
    }
  }
}

class _HazardStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  _HazardStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
} 