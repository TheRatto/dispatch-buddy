import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/widgets/notam_grouped_list.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';

class NotamGroupedDemoScreen extends StatefulWidget {
  const NotamGroupedDemoScreen({super.key});

  @override
  State<NotamGroupedDemoScreen> createState() => _NotamGroupedDemoScreenState();
}

class _NotamGroupedDemoScreenState extends State<NotamGroupedDemoScreen> {
  late List<Notam> demoNotams;
  late NotamGroupingService groupingService;
  final GlobalKey _groupedListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    groupingService = NotamGroupingService();
    demoNotams = _createDemoNotams();
  }

  List<Notam> _createDemoNotams() {
    final now = DateTime.now().toUtc();
    
    return [
      // Movement Areas NOTAMs
      Notam(
        id: 'A001/24',
        icao: 'YPPH',
        type: NotamType.runway,
        validFrom: now,
        validTo: now.add(const Duration(days: 7)),
        rawText: 'QMRLC - Runway 06/24 closed for maintenance',
        decodedText: 'Runway 06/24 closed for maintenance',
        affectedSystem: 'Runway',
        isCritical: true,
        group: NotamGroup.movementAreas,
      ),
      Notam(
        id: 'A002/24',
        icao: 'YPPH',
        type: NotamType.taxiway,
        validFrom: now,
        validTo: now.add(const Duration(days: 3)),
        rawText: 'QMXLC - Taxiway A partially closed',
        decodedText: 'Taxiway A partially closed',
        affectedSystem: 'Taxiway',
        isCritical: false,
        group: NotamGroup.movementAreas,
      ),
      // Navigation Aids NOTAMs
      Notam(
        id: 'A003/24',
        icao: 'YPPH',
        type: NotamType.navaid,
        validFrom: now,
        validTo: now.add(const Duration(days: 14)),
        rawText: 'QICLC - ILS runway 06 unserviceable',
        decodedText: 'ILS runway 06 unserviceable',
        affectedSystem: 'ILS',
        isCritical: true,
        group: NotamGroup.navigationAids,
      ),
      Notam(
        id: 'A004/24',
        icao: 'YPPH',
        type: NotamType.navaid,
        validFrom: now,
        validTo: now.add(const Duration(days: 10)),
        rawText: 'QNVLC - VOR unserviceable',
        decodedText: 'VOR unserviceable',
        affectedSystem: 'VOR',
        isCritical: false,
        group: NotamGroup.navigationAids,
      ),
      // Lighting NOTAMs
      Notam(
        id: 'A005/24',
        icao: 'YPPH',
        type: NotamType.lighting,
        validFrom: now,
        validTo: now.add(const Duration(days: 5)),
        rawText: 'QLCLC - Runway lighting unserviceable',
        decodedText: 'Runway lighting unserviceable',
        affectedSystem: 'Lighting',
        isCritical: false,
        group: NotamGroup.lighting,
      ),
      // Hazards NOTAMs
      Notam(
        id: 'A006/24',
        icao: 'YPPH',
        type: NotamType.other,
        validFrom: now,
        validTo: now.add(const Duration(days: 2)),
        rawText: 'Bird hazard reported in vicinity',
        decodedText: 'Bird hazard reported in vicinity',
        affectedSystem: 'Hazards',
        isCritical: true,
        group: NotamGroup.hazardsObstacles,
      ),
      // Airport/ATC NOTAMs
      Notam(
        id: 'A007/24',
        icao: 'YPPH',
        type: NotamType.other,
        validFrom: now,
        validTo: now.add(const Duration(days: 1)),
        rawText: 'QFAFC - Airport fuel services limited',
        decodedText: 'Airport fuel services limited',
        affectedSystem: 'Fuel',
        isCritical: false,
        group: NotamGroup.airportAtcAvailability,
      ),
      // Procedural/Admin NOTAMs
      Notam(
        id: 'A008/24',
        icao: 'YPPH',
        type: NotamType.procedure,
        validFrom: now,
        validTo: now.add(const Duration(days: 30)),
        rawText: 'QPAFC - New arrival procedure implemented',
        decodedText: 'New arrival procedure implemented',
        affectedSystem: 'Procedures',
        isCritical: false,
        group: NotamGroup.departureApproachProcedures,
      ),
      // Airspace NOTAMs
      Notam(
        id: 'A009/24',
        icao: 'YPPH',
        type: NotamType.airspace,
        validFrom: now,
        validTo: now.add(const Duration(days: 7)),
        rawText: 'QRAFC - Temporary restricted area active',
        decodedText: 'Temporary restricted area active',
        affectedSystem: 'Airspace',
        isCritical: true,
        group: NotamGroup.airspace,
      ),
      // Other NOTAMs
      Notam(
        id: 'A010/24',
        icao: 'YPPH',
        type: NotamType.other,
        validFrom: now,
        validTo: now.add(const Duration(days: 1)),
        rawText: 'General information notice',
        decodedText: 'General information notice',
        affectedSystem: 'General',
        isCritical: false,
        group: NotamGroup.other,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTAM Grouped Demo'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.expand_more),
            onPressed: _expandAll,
            tooltip: 'Expand All',
          ),
          IconButton(
            icon: const Icon(Icons.expand_less),
            onPressed: _collapseAll,
            tooltip: 'Collapse All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'NOTAM Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${demoNotams.length} total NOTAMs',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Grouped NOTAM list
          Expanded(
            child: NotamGroupedList(
              key: _groupedListKey,
              notams: demoNotams,
              onNotamTap: _onNotamTap,
              showGroupHeaders: true,
              initiallyExpanded: false,
            ),
          ),
        ],
      ),
    );
  }

  void _expandAll() {
    final state = _groupedListKey.currentState as dynamic;
    if (state != null) {
      state.expandAll();
    }
  }

  void _collapseAll() {
    final state = _groupedListKey.currentState as dynamic;
    if (state != null) {
      state.collapseAll();
    }
  }

  void _onNotamTap(Notam notam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('NOTAM Details: ${notam.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ICAO: ${notam.icao}'),
            Text('Type: ${notam.type.name}'),
            Text('Group: ${notam.group.name}'),
            Text('Critical: ${notam.isCritical ? "Yes" : "No"}'),
            const SizedBox(height: 8),
            Text('Valid From: ${notam.validFrom.toUtc()}'),
            Text('Valid To: ${notam.validTo.toUtc()}'),
            const SizedBox(height: 8),
            Text('Raw Text:'),
            Text(notam.displayRawText, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('Decoded Text:'),
            Text(notam.displayDecodedText, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 