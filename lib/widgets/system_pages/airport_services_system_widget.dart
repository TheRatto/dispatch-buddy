import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class AirportServicesSystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const AirportServicesSystemWidget({
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
        final serviceNotams = systemNotams['lighting'] ?? [];
        final overallStatus = systemAnalyzer.analyzeLightingStatus(filteredNotams, icao);
        
        // Group NOTAMs by service type for detailed display
        final serviceGroups = _groupByService(serviceNotams);
        final serviceStatuses = serviceGroups.entries.map((entry) {
          return _analyzeService(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(serviceNotams);
        
        // Generate summary
        final summary = _generateSummary(serviceStatuses, overallStatus);

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
              Text('Airport Services:', style: Theme.of(context).textTheme.titleMedium),
              ...serviceStatuses.map((service) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(service.status), color: _statusColor(service.status)),
                  title: Text(service.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: service.impacts.isNotEmpty
                    ? Text(service.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (service.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this service.'),
                      )
                    else
                      ...service.notams.map((notam) => ListTile(
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
                          children: serviceNotams.map((n) => Padding(
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

  /// Group NOTAMs by service type
  Map<String, List<Notam>> _groupByService(List<Notam> serviceNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in serviceNotams) {
      final serviceTypes = _extractServiceTypes(notam.rawText);
      for (final serviceType in serviceTypes) {
        groups.putIfAbsent(serviceType, () => []).add(notam);
      }
    }
    
    return groups;
  }
  
  /// Extract service types from NOTAM text
  List<String> _extractServiceTypes(String text) {
    final services = <String>[];
    
    // Pattern for ATC services
    final atcPattern = RegExp(r'\b(?:ATC|AIR TRAFFIC CONTROL|TWR|TOWER|GND|GROUND|APP)\b', caseSensitive: false);
    final atisPattern = RegExp(r'\b(?:ATIS|AUTOMATIC TERMINAL INFORMATION SERVICE)\b', caseSensitive: false);
    
    // Pattern for fuel services
    final fuelPattern = RegExp(r'\b(?:FUEL|AVGAS|JET A1)\b', caseSensitive: false);
    
    // Pattern for fire services
    final firePattern = RegExp(r'\b(?:FIRE|FIRE FIGHTING|RESCUE|FIRE CATEGORY|FIRE SERVICE)\b', caseSensitive: false);
    
    // Pattern for lighting services
    final lightingPattern = RegExp(r'\b(?:LIGHTING|LIGHTS|AERODROME BEACON|APPROACH LIGHTING|APPROACH LIGHTS|ALS|APPROACH LIGHTING SYSTEM)\b', caseSensitive: false);
    final centerlinePattern = RegExp(r'\b(?:CENTERLINE|CENTER LINE)\b', caseSensitive: false);
    final edgePattern = RegExp(r'\b(?:EDGE LIGHTS)\b', caseSensitive: false);
    final thresholdPattern = RegExp(r'\b(?:THRESHOLD LIGHTS)\b', caseSensitive: false);
    final beaconPattern = RegExp(r'\b(?:AERODROME BEACON)\b', caseSensitive: false);
    
    // Pattern for airport operations
    final airportPattern = RegExp(r'\b(?:AIRPORT|AERODROME)\b', caseSensitive: false);
    final pprPattern = RegExp(r'\b(?:PPR|PRIOR PERMISSION REQUIRED)\b', caseSensitive: false);
    final curfewPattern = RegExp(r'\b(?:CURFEW|NOISE ABATEMENT)\b', caseSensitive: false);
    
    // Pattern for hazards
    final dronePattern = RegExp(r'\b(?:DRONE|DRONES|DRONE HAZARD)\b', caseSensitive: false);
    final birdPattern = RegExp(r'\b(?:BIRD HAZARD|BIRD STRIKE)\b', caseSensitive: false);
    
    // Extract ATC services
    if (atcPattern.hasMatch(text)) {
      services.add('ATC Services');
    }
    if (atisPattern.hasMatch(text)) {
      services.add('ATIS');
    }
    
    // Extract fuel services
    if (fuelPattern.hasMatch(text)) {
      services.add('Fuel Services');
    }
    
    // Extract fire services
    if (firePattern.hasMatch(text)) {
      services.add('Fire Services');
    }
    
    // Extract lighting services
    if (lightingPattern.hasMatch(text)) {
      services.add('Lighting');
    }
    if (centerlinePattern.hasMatch(text)) {
      services.add('Centerline Lighting');
    }
    if (edgePattern.hasMatch(text)) {
      services.add('Edge Lighting');
    }
    if (thresholdPattern.hasMatch(text)) {
      services.add('Threshold Lighting');
    }
    if (beaconPattern.hasMatch(text)) {
      services.add('Aerodrome Beacon');
    }
    
    // Extract airport operations
    if (airportPattern.hasMatch(text)) {
      services.add('Airport Operations');
    }
    if (pprPattern.hasMatch(text)) {
      services.add('PPR Requirements');
    }
    if (curfewPattern.hasMatch(text)) {
      services.add('Noise Restrictions');
    }
    
    // Extract hazards
    if (dronePattern.hasMatch(text)) {
      services.add('Drone Hazards');
    }
    if (birdPattern.hasMatch(text)) {
      services.add('Bird Hazards');
    }
    
    // If no specific services found, check for general facility references
    if (services.isEmpty && text.toLowerCase().contains('facility')) {
      services.add('General Facilities');
    }
    
    // If no specific services found, check for general service references
    if (services.isEmpty && text.toLowerCase().contains('service')) {
      services.add('General Services');
    }
    
    // If still no services found, add a default
    if (services.isEmpty) {
      services.add('General Services');
    }
    
    return services;
  }
  
  /// Analyze status of a specific service type
  _ServiceStatus _analyzeService(String serviceType, List<Notam> notams) {
    bool hasOutage = false;
    bool hasRestriction = false;
    bool hasMaintenance = false;
    bool hasClosure = false;
    bool hasHazard = false;
    
    final impacts = <String>[];
    
    for (final notam in notams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('unserviceable') || text.contains('out of service') || text.contains('not available')) {
        hasOutage = true;
        impacts.add('Service unserviceable');
      }
      
      if (text.contains('restricted') || text.contains('limited') || text.contains('not available')) {
        hasRestriction = true;
        impacts.add('Operational restrictions');
      }
      
      if (text.contains('maintenance')) {
        hasMaintenance = true;
        impacts.add('Maintenance work');
      }
      
      if (text.contains('closed') || text.contains('not avbl')) {
        hasClosure = true;
        impacts.add('Service closed');
      }
      
      if (text.contains('hazard') || text.contains('drone') || text.contains('bird')) {
        hasHazard = true;
        impacts.add('Safety hazards');
      }
    }
    
    // Determine service status
    SystemStatus status;
    if (hasOutage || hasClosure) {
      status = SystemStatus.red;
    } else if (hasRestriction || hasMaintenance || hasHazard) {
      status = SystemStatus.yellow;
    } else {
      status = SystemStatus.green;
    }
    
    return _ServiceStatus(
      identifier: serviceType,
      status: status,
      notams: notams,
      impacts: impacts,
    );
  }
  
  /// Extract key operational impacts
  List<String> _extractOperationalImpacts(List<Notam> serviceNotams) {
    final impacts = <String>[];
    
    for (final notam in serviceNotams) {
      final text = notam.rawText.toLowerCase();
      
      if (text.contains('airport closed') && !impacts.contains('Airport closure')) {
        impacts.add('Airport closure');
      }
      
      if (text.contains('fuel') && (text.contains('not available') || text.contains('unavailable')) && !impacts.contains('Fuel unavailable')) {
        impacts.add('Fuel unavailable');
      }
      
      if (text.contains('fire') && (text.contains('not available') || text.contains('unserviceable')) && !impacts.contains('Fire services unavailable')) {
        impacts.add('Fire services unavailable');
      }
      
      if (text.contains('lighting') && (text.contains('out') || text.contains('unserviceable')) && !impacts.contains('Lighting issues')) {
        impacts.add('Lighting issues');
      }
      
      if (text.contains('ppr') && !impacts.contains('PPR required')) {
        impacts.add('PPR required');
      }
      
      if (text.contains('curfew') && !impacts.contains('Noise restrictions')) {
        impacts.add('Noise restrictions');
      }
    }
    
    return impacts;
  }
  
  /// Generate human-readable summary
  String _generateSummary(List<_ServiceStatus> serviceStatuses, SystemStatus overallStatus) {
    if (serviceStatuses.isEmpty) {
      return 'All airport services operational';
    }
    
    final redServices = serviceStatuses.where((s) => s.status == SystemStatus.red).length;
    final yellowServices = serviceStatuses.where((s) => s.status == SystemStatus.yellow).length;
    final greenServices = serviceStatuses.where((s) => s.status == SystemStatus.green).length;
    
    if (redServices > 0) {
      return '$redServices service(s) unserviceable';
    } else if (yellowServices > 0) {
      return '$yellowServices service(s) with operational restrictions';
    } else {
      return 'All services operational with minor restrictions';
    }
  }
}

class _ServiceStatus {
  final String identifier;
  final SystemStatus status;
  final List<Notam> notams;
  final List<String> impacts;
  
  _ServiceStatus({
    required this.identifier,
    required this.status,
    required this.notams,
    required this.impacts,
  });
} 