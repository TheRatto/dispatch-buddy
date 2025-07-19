import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class OtherSystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const OtherSystemWidget({
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
        final otherNotams = systemNotams['other'] ?? [];
        final overallStatus = systemAnalyzer.analyzeOtherStatus(filteredNotams, icao);
        
        // Group NOTAMs by other type for detailed display
        final otherGroups = _groupByOther(otherNotams);
        final otherStatuses = otherGroups.entries.map((entry) {
          return _analyzeOther(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(otherNotams);
        
        // Generate summary
        final summary = _generateSummary(otherStatuses, overallStatus);

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
              Text('Other Items:', style: Theme.of(context).textTheme.titleMedium),
              ...otherStatuses.map((other) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(other.status), color: _statusColor(other.status)),
                  title: Text(other.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: other.impacts.isNotEmpty
                    ? Text(other.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (other.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this item.'),
                      )
                    else
                      ...other.notams.map((notam) => ListTile(
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
                          children: otherNotams.map((n) => Padding(
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

  /// Group NOTAMs by other type
  Map<String, List<Notam>> _groupByOther(List<Notam> otherNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in otherNotams) {
      final otherTypes = _extractOtherTypes(notam.rawText);
      for (final otherType in otherTypes) {
        groups.putIfAbsent(otherType, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract other types from NOTAM text
  List<String> _extractOtherTypes(String text) {
    final otherItems = <String>[];
    
    // Pattern for parking and stands
    final parkingPattern = RegExp(r'\b(?:PARKING|STAND|STANDS|AIRCRAFT STAND)\b', caseSensitive: false);
    
    // Pattern for facilities
    final facilityPattern = RegExp(r'\b(?:FACILITY|FACILITIES)\b', caseSensitive: false);
    
    // Pattern for services
    final servicePattern = RegExp(r'\b(?:SERVICE|SERVICES)\b', caseSensitive: false);
    
    // Pattern for equipment
    final equipmentPattern = RegExp(r'\b(?:EQUIPMENT|MACHINE|MACHINERY)\b', caseSensitive: false);
    
    // Pattern for maintenance
    final maintenancePattern = RegExp(r'\b(?:MAINTENANCE|REPAIR|SERVICING)\b', caseSensitive: false);
    
    // Pattern for general operations
    final operationsPattern = RegExp(r'\b(?:OPERATION|OPERATIONAL|OPERATIONS)\b', caseSensitive: false);
    
    // Extract parking and stands
    if (parkingPattern.hasMatch(text)) {
      otherItems.add('Parking/Stands');
    }
    
    // Extract facilities
    if (facilityPattern.hasMatch(text)) {
      otherItems.add('Facilities');
    }
    
    // Extract services
    if (servicePattern.hasMatch(text)) {
      otherItems.add('Services');
    }
    
    // Extract equipment
    if (equipmentPattern.hasMatch(text)) {
      otherItems.add('Equipment');
    }
    
    // Extract maintenance
    if (maintenancePattern.hasMatch(text)) {
      otherItems.add('Maintenance');
    }
    
    // Extract operations
    if (operationsPattern.hasMatch(text)) {
      otherItems.add('Operations');
    }
    
    // If no specific items found, add a default
    if (otherItems.isEmpty) {
      otherItems.add('General Other');
    }
    
    return otherItems;
  }
  
  /// Analyze status of a specific other item
  _OtherStatus _analyzeOther(String otherType, List<Notam> notams) {
    bool hasRestriction = false;
    bool hasMaintenance = false;
    bool hasChange = false;
    bool hasService = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('restricted') || text.contains('limited') || text.contains('not available')) {
        hasRestriction = true;
        impacts.add('Operational restriction');
      }
      
      if (text.contains('maintenance') || text.contains('repair') || text.contains('servicing')) {
        hasMaintenance = true;
        impacts.add('Maintenance work');
      }
      
      if (text.contains('change') || text.contains('modified') || text.contains('updated')) {
        hasChange = true;
        impacts.add('Service change');
      }
      
      if (text.contains('service') || text.contains('operational')) {
        hasService = true;
        impacts.add('Service update');
      }
    }
    
    // Determine other status
    SystemStatus status;
    if (hasRestriction) {
      status = SystemStatus.yellow;
    } else if (hasMaintenance || hasChange || hasService) {
      status = SystemStatus.green;
    } else {
      status = SystemStatus.green;
    }
    
    return _OtherStatus(
      identifier: otherType,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Extract key operational impacts
  List<String> _extractOperationalImpacts(List<Notam> otherNotams) {
    final impacts = <String>[];
    
    for (final notam in otherNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('parking') && (text.contains('not available') || text.contains('closed')) && !impacts.contains('Parking restrictions')) {
        impacts.add('Parking restrictions');
      }
      
      if (text.contains('facility') && (text.contains('not available') || text.contains('closed')) && !impacts.contains('Facility issues')) {
        impacts.add('Facility issues');
      }
      
      if (text.contains('service') && (text.contains('not available') || text.contains('unavailable')) && !impacts.contains('Service unavailable')) {
        impacts.add('Service unavailable');
      }
      
      if (text.contains('maintenance') && !impacts.contains('Maintenance work')) {
        impacts.add('Maintenance work');
      }
      
      if (text.contains('equipment') && (text.contains('not available') || text.contains('unserviceable')) && !impacts.contains('Equipment issues')) {
        impacts.add('Equipment issues');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  String _generateSummary(List<_OtherStatus> otherStatuses, SystemStatus overallStatus) {
    if (otherStatuses.isEmpty) {
      return 'No other operational issues';
    }
    
    final yellowItems = otherStatuses.where((o) => o.status == SystemStatus.yellow).length;
    final greenItems = otherStatuses.where((o) => o.status == SystemStatus.green).length;
    
    if (yellowItems > 0) {
      return '$yellowItems operational restriction(s) in effect';
    } else {
      return 'Operational updates available';
    }
  }
}

class _OtherStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  _OtherStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
} 