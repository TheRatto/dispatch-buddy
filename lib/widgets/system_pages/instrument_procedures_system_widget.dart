import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class InstrumentProceduresSystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const InstrumentProceduresSystemWidget({
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
        final navaidNotams = systemNotams['navaids'] ?? [];
        final overallStatus = systemAnalyzer.analyzeNavaidStatus(filteredNotams, icao);
        
        // Group NOTAMs by procedure type for detailed display
        final procedureGroups = _groupByProcedure(navaidNotams);
        final procedureStatuses = procedureGroups.entries.map((entry) {
          return _analyzeProcedure(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(navaidNotams);
        
        // Generate summary
        final summary = _generateSummary(procedureStatuses, overallStatus);

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
              Text('Instrument Procedures:', style: Theme.of(context).textTheme.titleMedium),
              ...procedureStatuses.map((proc) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(proc.status), color: _statusColor(proc.status)),
                  title: Text(proc.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: proc.impacts.isNotEmpty
                    ? Text(proc.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (proc.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this procedure.'),
                      )
                    else
                      ...proc.notams.map((notam) => ListTile(
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
                          children: navaidNotams.map((n) => Padding(
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

  /// Group NOTAMs by procedure type
  Map<String, List<Notam>> _groupByProcedure(List<Notam> procedureNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in procedureNotams) {
      final procedureTypes = _extractProcedureTypes(notam.rawText);
      for (final procedureType in procedureTypes) {
        groups.putIfAbsent(procedureType, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract procedure types from NOTAM text
  List<String> _extractProcedureTypes(String text) {
    final procedures = <String>[];
    
    // Pattern for navigation aids
    final ilsPattern = RegExp(r'\b(?:ILS|INSTRUMENT LANDING SYSTEM)\b', caseSensitive: false);
    final vorPattern = RegExp(r'\bVOR\b', caseSensitive: false);
    final ndbPattern = RegExp(r'\b(?:NDB|NON-DIRECTIONAL BEACON)\b', caseSensitive: false);
    final dmePattern = RegExp(r'\b(?:DME|DISTANCE MEASURING EQUIPMENT)\b', caseSensitive: false);
    final localizerPattern = RegExp(r'\bLOCALIZER\b', caseSensitive: false);
    final glidePathPattern = RegExp(r'\b(?:GLIDE PATH|GLIDEPATH)\b', caseSensitive: false);
    
    // Pattern for procedures
    final sidPattern = RegExp(r'\b(?:SID|STANDARD INSTRUMENT DEPARTURE)\b', caseSensitive: false);
    final starPattern = RegExp(r'\b(?:STAR|STANDARD ARRIVAL)\b', caseSensitive: false);
    final approachPattern = RegExp(r'\b(?:INSTRUMENT APPROACH|APPROACH PROCEDURE)\b', caseSensitive: false);
    final rnavPattern = RegExp(r'\b(?:RNAV|RNP|PBN)\b', caseSensitive: false);
    
    // Pattern for airspace
    final restrictedPattern = RegExp(r'\b(?:RESTRICTED|PROHIBITED|DANGER AREA)\b', caseSensitive: false);
    final militaryPattern = RegExp(r'\b(?:MILITARY|MOA|MILITARY OPERATING AREA)\b', caseSensitive: false);
    final gpsPattern = RegExp(r'\b(?:GPS|GNSS|GLOBAL POSITIONING SYSTEM)\b', caseSensitive: false);
    
    // Extract navigation aids
    if (ilsPattern.hasMatch(text)) {
      procedures.add('ILS');
    }
    if (vorPattern.hasMatch(text)) {
      procedures.add('VOR');
    }
    if (ndbPattern.hasMatch(text)) {
      procedures.add('NDB');
    }
    if (dmePattern.hasMatch(text)) {
      procedures.add('DME');
    }
    if (localizerPattern.hasMatch(text)) {
      procedures.add('Localizer');
    }
    if (glidePathPattern.hasMatch(text)) {
      procedures.add('Glide Path');
    }
    
    // Extract procedures
    if (sidPattern.hasMatch(text)) {
      procedures.add('SID');
    }
    if (starPattern.hasMatch(text)) {
      procedures.add('STAR');
    }
    if (approachPattern.hasMatch(text)) {
      procedures.add('Instrument Approach');
    }
    if (rnavPattern.hasMatch(text)) {
      procedures.add('RNAV');
    }
    
    // Extract airspace
    if (restrictedPattern.hasMatch(text)) {
      procedures.add('Restricted Airspace');
    }
    if (militaryPattern.hasMatch(text)) {
      procedures.add('Military Airspace');
    }
    if (gpsPattern.hasMatch(text)) {
      procedures.add('GPS/GNSS');
    }
    
    // If no specific procedures found, check for general navigation references
    if (procedures.isEmpty && text.toLowerCase().contains('navaid')) {
      procedures.add('General Navaid');
    }
    
    // If still no procedures found, add a default
    if (procedures.isEmpty) {
      procedures.add('General Instrument Procedure');
    }
    
    return procedures;
  }
  
  /// Analyze status of a specific procedure
  _ProcedureStatus _analyzeProcedure(String procedureType, List<Notam> notams) {
    bool hasOutage = false;
    bool hasRestriction = false;
    bool hasMaintenance = false;
    bool hasUnserviceable = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('out of service') || text.contains('unserviceable') || text.contains('not available')) {
        hasOutage = true;
        impacts.add('Procedure unserviceable');
      }
      
      if (text.contains('restricted') || text.contains('limited') || text.contains('not available')) {
        hasRestriction = true;
        impacts.add('Operational restrictions');
      }
      
      if (text.contains('maintenance')) {
        hasMaintenance = true;
        impacts.add('Maintenance work');
      }
      
      if (text.contains('unserviceable')) {
        hasUnserviceable = true;
        impacts.add('Equipment unserviceable');
      }
    }
    
    // Determine procedure status
    SystemStatus status;
    if (hasOutage || hasUnserviceable) {
      status = SystemStatus.red;
    } else if (hasRestriction || hasMaintenance) {
      status = SystemStatus.yellow;
    } else {
      status = SystemStatus.green;
    }
    
    return _ProcedureStatus(
      identifier: procedureType,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Extract key operational impacts
  List<String> _extractOperationalImpacts(List<Notam> procedureNotams) {
    final impacts = <String>[];
    
    for (final notam in procedureNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('ils') && (text.contains('out') || text.contains('unserviceable')) && !impacts.contains('ILS outages')) {
        impacts.add('ILS outages');
      }
      
      if (text.contains('vor') && (text.contains('out') || text.contains('unserviceable')) && !impacts.contains('VOR outages')) {
        impacts.add('VOR outages');
      }
      
      if (text.contains('approach') && (text.contains('not available') || text.contains('unserviceable')) && !impacts.contains('Approach procedure issues')) {
        impacts.add('Approach procedure issues');
      }
      
      if (text.contains('gps') && (text.contains('out') || text.contains('unserviceable')) && !impacts.contains('GPS issues')) {
        impacts.add('GPS issues');
      }
      
      if (text.contains('restricted') && !impacts.contains('Airspace restrictions')) {
        impacts.add('Airspace restrictions');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  String _generateSummary(List<_ProcedureStatus> procedureStatuses, SystemStatus overallStatus) {
    if (procedureStatuses.isEmpty) {
      return 'All instrument procedures operational';
    }
    
    final redProcedures = procedureStatuses.where((p) => p.status == SystemStatus.red).length;
    final yellowProcedures = procedureStatuses.where((p) => p.status == SystemStatus.yellow).length;
    final greenProcedures = procedureStatuses.where((p) => p.status == SystemStatus.green).length;
    
    if (redProcedures > 0) {
      return '$redProcedures procedure(s) unserviceable';
    } else if (yellowProcedures > 0) {
      return '$yellowProcedures procedure(s) with operational restrictions';
    } else {
      return 'All procedures operational with minor restrictions';
    }
  }
}

class _ProcedureStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  _ProcedureStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
} 