import 'package:flutter/material.dart';
import '../../models/notam.dart';
import '../../services/airport_system_analyzer.dart';
import '../../models/airport.dart';
import '../../providers/flight_provider.dart';
import 'package:provider/provider.dart';

class RunwaySystemWidget extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const RunwaySystemWidget({
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
        final runwayNotams = systemNotams['runways'] ?? [];
        final overallStatus = systemAnalyzer.analyzeRunwayStatus(filteredNotams, icao);
        
        // Group NOTAMs by runway identifier for detailed display
        final runwayGroups = _groupByRunway(runwayNotams);
        final runwayStatuses = runwayGroups.entries.map((entry) {
          return _analyzeRunway(entry.key, entry.value);
        }).toList();
        
        // Extract operational impacts
        final operationalImpacts = _extractOperationalImpacts(runwayNotams);
        
        // Generate summary
        final summary = _generateSummary(runwayStatuses, overallStatus);

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
              Text('Runways:', style: Theme.of(context).textTheme.titleMedium),
              ...runwayStatuses.map((rwy) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  leading: Icon(_statusIcon(rwy.status), color: _statusColor(rwy.status)),
                  title: Text(rwy.identifier, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: rwy.impacts.isNotEmpty
                    ? Text(rwy.impacts.join(', '), style: const TextStyle(color: Colors.black87))
                    : null,
                  children: [
                    if (rwy.notams.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No NOTAMs for this runway.'),
                      )
                    else
                      ...rwy.notams.map((notam) => ListTile(
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
                          children: runwayNotams.map((n) => Padding(
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

  Map<String, List<Notam>> _groupByRunway(List<Notam> runwayNotams) {
    final groups = <String, List<Notam>>{};
    
    for (final notam in runwayNotams) {
      // Extract runway identifier from NOTAM text
      final runwayId = _extractRunwayIdentifier(notam.rawText);
      if (runwayId != null) {
        groups.putIfAbsent(runwayId, () => []).add(notam);
      }
    }
    
    return groups;
  }

  String? _extractRunwayIdentifier(String notamText) {
    // Simple regex to find runway identifiers (e.g., RWY 03, RWY 21L, etc.)
    final regex = RegExp(r'RWY\s+(\d{2}[LCR]?)', caseSensitive: false);
    final match = regex.firstMatch(notamText);
    return match?.group(1);
  }

  RunwayStatus _analyzeRunway(String identifier, List<Notam> notams) {
    // Determine status based on NOTAMs
    SystemStatus status = SystemStatus.green;
    final impacts = <String>[];
    
    for (final notam in notams) {
      if (notam.isCritical) {
        status = SystemStatus.red;
        impacts.add('Critical: ${notam.rawText}');
      } else if (status != SystemStatus.red) {
        status = SystemStatus.yellow;
        impacts.add(notam.rawText);
      }
    }
    
    return RunwayStatus(
      identifier: identifier,
      status: status,
      impacts: impacts,
      notams: notams,
    );
  }

  List<String> _extractOperationalImpacts(List<Notam> runwayNotams) {
    final impacts = <String>[];
    
    for (final notam in runwayNotams) {
      if (notam.isCritical) {
        impacts.add('Critical: ${notam.rawText}');
      } else {
        impacts.add(notam.rawText);
      }
    }
    
    return impacts;
  }

  String _generateSummary(List<RunwayStatus> runwayStatuses, SystemStatus overallStatus) {
    final operationalCount = runwayStatuses.where((rwy) => rwy.status == SystemStatus.green).length;
    final totalCount = runwayStatuses.length;
    
    if (totalCount == 0) {
      return 'No runway information available.';
    }
    
    if (overallStatus == SystemStatus.green) {
      return 'All $totalCount runways are operational.';
    } else if (overallStatus == SystemStatus.yellow) {
      return '$operationalCount of $totalCount runways operational. Some restrictions may apply.';
    } else {
      return 'Critical runway issues detected. Review NOTAMs for details.';
    }
  }
}

class RunwayStatus {
  final String identifier;
  final SystemStatus status;
  final List<String> impacts;
  final List<Notam> notams;

  RunwayStatus({
    required this.identifier,
    required this.status,
    required this.impacts,
    required this.notams,
  });
} 