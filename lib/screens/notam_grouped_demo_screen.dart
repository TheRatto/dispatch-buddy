import 'package:flutter/material.dart';
import 'package:dispatch_buddy/models/notam.dart';
import 'package:dispatch_buddy/widgets/notam_grouped_list.dart';
import 'package:dispatch_buddy/services/notam_grouping_service.dart';
import 'package:dispatch_buddy/services/notam_status_service.dart';

class NotamGroupedDemoScreen extends StatefulWidget {
  const NotamGroupedDemoScreen({super.key});

  @override
  State<NotamGroupedDemoScreen> createState() => _NotamGroupedDemoScreenState();
}

class _NotamGroupedDemoScreenState extends State<NotamGroupedDemoScreen> {
  late List<Notam> demoNotams;
  late NotamGroupingService groupingService;
  final NotamStatusService _statusService = NotamStatusService();
  final GlobalKey _groupedListKey = GlobalKey();
  
  // Demo flight context
  final String _flightContext = 'demo_flight_001';

  @override
  void initState() {
    super.initState();
    groupingService = NotamGroupingService();
    demoNotams = _createDemoNotams();
  }

  List<Notam> _createDemoNotams() {
    final now = DateTime.now().toUtc();
    
    return [
      // Runways NOTAMs
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
        group: NotamGroup.runways,
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
        group: NotamGroup.taxiways,
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
        group: NotamGroup.instrumentProcedures,
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
        group: NotamGroup.instrumentProcedures,
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
        group: NotamGroup.airportServices,
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
        group: NotamGroup.hazards,
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
        group: NotamGroup.airportServices,
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
        group: NotamGroup.admin,
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
        group: NotamGroup.instrumentProcedures,
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
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed: _showHiddenNotams,
            tooltip: 'Show Hidden NOTAMs',
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _showFlaggedNotams,
            tooltip: 'Show Flagged NOTAMs',
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
                FutureBuilder<int>(
                  future: _statusService.getHiddenCount(flightContext: _flightContext),
                  builder: (context, snapshot) {
                    final hiddenCount = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Text(
                          '${demoNotams.length} total NOTAMs',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (hiddenCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  color: Colors.orange,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$hiddenCount hidden',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swipe left on NOTAMs to hide or flag them. Tap hidden count to restore.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
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
              flightContext: _flightContext,
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

  void _showHiddenNotams() async {
    final hiddenIds = await _statusService.getHiddenNotamIds(flightContext: _flightContext);
    final hiddenNotams = demoNotams.where((n) => hiddenIds.contains(n.id)).toList();
    
    if (hiddenNotams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hidden NOTAMs')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildHiddenNotamsModal(hiddenNotams),
    );
  }

  void _showFlaggedNotams() async {
    final flaggedIds = await _statusService.getFlaggedNotamIds(flightContext: _flightContext);
    final flaggedNotams = demoNotams.where((n) => flaggedIds.contains(n.id)).toList();
    
    if (flaggedNotams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No flagged NOTAMs')),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFlaggedNotamsModal(flaggedNotams),
    );
  }

  Widget _buildHiddenNotamsModal(List<Notam> hiddenNotams) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Hidden NOTAMs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${hiddenNotams.length} NOTAM${hiddenNotams.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Hidden NOTAMs list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: hiddenNotams.length,
                  itemBuilder: (context, index) {
                    final notam = hiddenNotams[index];
                    return ListTile(
                      title: Text(notam.id),
                      subtitle: Text(notam.displayRawText),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () async {
                          await _statusService.unhideNotam(notam.id);
                          Navigator.of(context).pop();
                          setState(() {}); // Refresh the UI
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlaggedNotamsModal(List<Notam> flaggedNotams) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Flagged NOTAMs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${flaggedNotams.length} NOTAM${flaggedNotams.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Flagged NOTAMs list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: flaggedNotams.length,
                  itemBuilder: (context, index) {
                    final notam = flaggedNotams[index];
                    return ListTile(
                      leading: Icon(Icons.flag, color: Colors.blue),
                      title: Text(notam.id),
                      subtitle: Text(notam.displayRawText),
                      trailing: IconButton(
                        icon: const Icon(Icons.flag_outlined),
                        onPressed: () async {
                          await _statusService.unflagNotam(notam.id);
                          Navigator.of(context).pop();
                          setState(() {}); // Refresh the UI
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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