import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class AdminSystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const AdminSystemWidget({
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
        final adminNotams = systemNotams['admin'] ?? [];
        final overallStatus = systemAnalyzer.analyzeAdminStatus(filteredNotams, icao);
        
        // Group NOTAMs by admin type for detailed display
        final adminGroups = _groupByAdmin(adminNotams);
        final adminStatuses = adminGroups.entries.map((entry) {
          return _analyzeAdmin(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(adminNotams);
        
        // Generate summary
        final summary = _generateSummary(adminStatuses, overallStatus);

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
              Text('Administrative Items:', style: Theme.of(context).textTheme.titleMedium),
              ...adminStatuses.map((admin) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(admin.status), color: _statusColor(admin.status)),
                  title: Text(admin.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: admin.impacts.isNotEmpty
                    ? Text(admin.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (admin.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this administrative item.'),
                      )
                    else
                      ...admin.notams.map((notam) => ListTile(
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
                          children: adminNotams.map((n) => Padding(
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

  /// Group NOTAMs by admin type
  Map<String, List<Notam>> _groupByAdmin(List<Notam> adminNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in adminNotams) {
      final adminTypes = _extractAdminTypes(notam.rawText);
      for (final adminType in adminTypes) {
        groups.putIfAbsent(adminType, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract admin types from NOTAM text
  List<String> _extractAdminTypes(String text) {
    final adminItems = <String>[];
    
    // Pattern for PPR requirements
    final pprPattern = RegExp(r'\b(?:PPR|PRIOR PERMISSION REQUIRED)\b', caseSensitive: false);
    
    // Pattern for curfew and noise restrictions
    final curfewPattern = RegExp(r'\b(?:CURFEW|NOISE ABATEMENT|NOISE RESTRICTION)\b', caseSensitive: false);
    
    // Pattern for frequency changes
    final frequencyPattern = RegExp(r'\b(?:FREQUENCY|FREQUENCIES|ATIS)\b', caseSensitive: false);
    
    // Pattern for administrative procedures
    final adminPattern = RegExp(r'\b(?:ADMINISTRATION|ADMINISTRATIVE|ADMINISTRATIVE PROCEDURE)\b', caseSensitive: false);
    
    // Pattern for slot restrictions
    final slotPattern = RegExp(r'\b(?:SLOT|SLOTS|SLOT RESTRICTION)\b', caseSensitive: false);
    
    // Pattern for information services
    final infoPattern = RegExp(r'\b(?:INFORMATION SERVICE|FIS|FLIGHT INFORMATION SERVICE)\b', caseSensitive: false);
    
    // Pattern for procedural changes
    final proceduralPattern = RegExp(r'\b(?:PROCEDURAL|PROCEDURE)\b', caseSensitive: false);
    
    // Extract PPR requirements
    if (pprPattern.hasMatch(text)) {
      adminItems.add('PPR Requirements');
    }
    
    // Extract curfew and noise restrictions
    if (curfewPattern.hasMatch(text)) {
      adminItems.add('Noise Restrictions');
    }
    
    // Extract frequency changes
    if (frequencyPattern.hasMatch(text)) {
      adminItems.add('Frequency Changes');
    }
    
    // Extract administrative procedures
    if (adminPattern.hasMatch(text)) {
      adminItems.add('Administrative Procedures');
    }
    
    // Extract slot restrictions
    if (slotPattern.hasMatch(text)) {
      adminItems.add('Slot Restrictions');
    }
    
    // Extract information services
    if (infoPattern.hasMatch(text)) {
      adminItems.add('Information Services');
    }
    
    // Extract procedural changes
    if (proceduralPattern.hasMatch(text)) {
      adminItems.add('Procedural Changes');
    }
    
    // If no specific admin items found, add a default
    if (adminItems.isEmpty) {
      adminItems.add('General Administrative');
    }
    
    return adminItems;
  }
  
  /// Analyze status of a specific admin item
  _AdminStatus _analyzeAdmin(String adminType, List<Notam> notams) {
    bool hasRestriction = false;
    bool hasRequirement = false;
    bool hasChange = false;
    bool hasProcedure = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('restriction') || text.contains('limited') || text.contains('curfew')) {
        hasRestriction = true;
        impacts.add('Operational restriction');
      }
      
      if (text.contains('required') || text.contains('permission') || text.contains('ppr')) {
        hasRequirement = true;
        impacts.add('Permission required');
      }
      
      if (text.contains('change') || text.contains('frequency') || text.contains('atis')) {
        hasChange = true;
        impacts.add('Service change');
      }
      
      if (text.contains('procedure') || text.contains('administrative')) {
        hasProcedure = true;
        impacts.add('Procedural change');
      }
    }
    
    // Determine admin status
    SystemStatus status;
    if (hasRestriction || hasRequirement) {
      status = SystemStatus.yellow;
    } else if (hasChange || hasProcedure) {
      status = SystemStatus.green;
    } else {
      status = SystemStatus.green;
    }
    
    return _AdminStatus(
      identifier: adminType,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Extract key operational impacts
  List<String> _extractOperationalImpacts(List<Notam> adminNotams) {
    final impacts = <String>[];
    
    for (final notam in adminNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('ppr') && !impacts.contains('PPR required')) {
        impacts.add('PPR required');
      }
      
      if (text.contains('curfew') && !impacts.contains('Curfew restrictions')) {
        impacts.add('Curfew restrictions');
      }
      
      if (text.contains('noise') && !impacts.contains('Noise restrictions')) {
        impacts.add('Noise restrictions');
      }
      
      if (text.contains('frequency') && !impacts.contains('Frequency changes')) {
        impacts.add('Frequency changes');
      }
      
      if (text.contains('slot') && !impacts.contains('Slot restrictions')) {
        impacts.add('Slot restrictions');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  String _generateSummary(List<_AdminStatus> adminStatuses, SystemStatus overallStatus) {
    if (adminStatuses.isEmpty) {
      return 'No administrative restrictions';
    }
    
    final yellowItems = adminStatuses.where((a) => a.status == SystemStatus.yellow).length;
    final greenItems = adminStatuses.where((a) => a.status == SystemStatus.green).length;
    
    if (yellowItems > 0) {
      return '$yellowItems administrative restriction(s) in effect';
    } else {
      return 'Administrative procedures updated';
    }
  }
}

class _AdminStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  _AdminStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
} 