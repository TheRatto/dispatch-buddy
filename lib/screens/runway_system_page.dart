import 'package:flutter/material.dart';
import '../models/notam.dart';
import '../services/runway_status_analyzer.dart';

class RunwaySystemPage extends StatelessWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const RunwaySystemPage({
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
    final runwayStatus = RunwayStatusAnalyzer.analyzeRunwayStatus(notams);

    return Scaffold(
      appBar: AppBar(
        title: Text('$airportName ($icao) - Runway Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Icon(_statusIcon(runwayStatus.overallStatus), color: _statusColor(runwayStatus.overallStatus), size: 32),
                const SizedBox(width: 12),
                Text(
                  'Overall Status: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  runwayStatus.overallStatus.name.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(runwayStatus.overallStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              runwayStatus.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (runwayStatus.operationalImpacts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Key Operational Impacts:', style: Theme.of(context).textTheme.titleSmall),
              ...runwayStatus.operationalImpacts.map((impact) => Padding(
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
            ...runwayStatus.runways.map((rwy) => Card(
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
                        children: notams.map((n) => Padding(
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
      ),
    );
  }
} 