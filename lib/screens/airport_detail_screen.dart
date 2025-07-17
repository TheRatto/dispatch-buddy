import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../services/airport_system_analyzer.dart';
import '../services/airport_database.dart';
import '../widgets/zulu_time_widget.dart';
import 'system_detail_screen.dart';

class AirportDetailScreen extends StatefulWidget {
  const AirportDetailScreen({super.key});

  @override
  State<AirportDetailScreen> createState() => _AirportDetailScreenState();
}

class _AirportDetailScreenState extends State<AirportDetailScreen> {
  // Time filter for NOTAMs
  String _selectedTimeFilter = '24 hours'; // Default to 24 hours
  final List<String> _timeFilterOptions = [
    '6 hours',
    '12 hours',
    '24 hours',
    '72 hours',
    'All Future:',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
            SizedBox(height: 2),
            Text(
              'Airport',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: Implement settings menu
            },
          ),
        ],
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final flight = flightProvider.currentFlight;
          
          if (flight == null) {
            return const Center(
              child: Text('No flight data available'),
            );
          }

          return Column(
            children: [
              // Page-level time filter
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildTimeFilterHeader(),
              ),
              // Airport list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: flight.airports.length,
                  itemBuilder: (context, index) {
                    final airport = flight.airports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.airplanemode_active, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${airport.name} (${airport.icao}${AirportDatabase.getIataCode(airport.icao) != null ? '/${AirportDatabase.getIataCode(airport.icao)}' : ''})',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        airport.city,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSystemsList(context, airport, flight.notams),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeFilterHeader() {
    return Row(
      children: [
        Text(
          'Next:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF10008A),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedTimeFilter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => _timeFilterOptions.map((filter) {
            return PopupMenuItem<String>(
              value: filter,
              child: Text(filter),
            );
          }).toList(),
          onSelected: (value) {
            setState(() {
              _selectedTimeFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSystemsList(BuildContext context, Airport airport, List<Notam> allNotams) {
    // Filter NOTAMs by time and airport
    final filteredNotams = _filterNotamsByTimeAndAirport(allNotams, airport.icao);
    
    // Calculate system status based on filtered NOTAMs
    final systemStatuses = _calculateSystemStatuses(filteredNotams, airport.icao);
    
    final systems = [
      {'name': 'Runways', 'status': systemStatuses['runways'], 'icon': Icons.run_circle},
      {'name': 'Taxiways', 'status': systemStatuses['taxiways'], 'icon': Icons.route},
      {'name': 'Instrument Procedures', 'status': systemStatuses['navaids'], 'icon': Icons.radar},
      {'name': 'Airport Services', 'status': systemStatuses['lighting'], 'icon': Icons.business},
      {'name': 'Hazards', 'status': systemStatuses['hazards'], 'icon': Icons.warning},
      {'name': 'Admin', 'status': systemStatuses['admin'], 'icon': Icons.admin_panel_settings},
      {'name': 'Other', 'status': systemStatuses['other'], 'icon': Icons.more_horiz},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...systems.map((system) => _buildSystemRow(
          context,
          airport,
          system['name'] as String,
          system['status'] as SystemStatus,
          system['icon'] as IconData,
          filteredNotams,
        )),
      ],
    );
  }

  List<Notam> _filterNotamsByTimeAndAirport(List<Notam> notams, String airportIcao) {
    // First filter by airport
    final airportNotams = notams.where((notam) => notam.icao == airportIcao).toList();
    
    if (_selectedTimeFilter == 'All Future:') {
      return airportNotams;
    }

    final now = DateTime.now();
    final hours = _getHoursFromFilter(_selectedTimeFilter);
    final cutoffTime = now.add(Duration(hours: hours));

    return airportNotams.where((notam) => 
      // Include NOTAMs that are currently active or will become active within the time period
      notam.validFrom.isBefore(cutoffTime) && notam.validTo.isAfter(now)
    ).toList();
  }

  int _getHoursFromFilter(String filter) {
    switch (filter) {
      case '6 hours':
        return 6;
      case '12 hours':
        return 12;
      case '24 hours':
        return 24;
      case '72 hours':
        return 72;
      default:
        return 24;
    }
  }

  Map<String, SystemStatus> _calculateSystemStatuses(List<Notam> notams, String airportIcao) {
    final systemAnalyzer = AirportSystemAnalyzer();
    final systemNotams = systemAnalyzer.getSystemNotams(notams, airportIcao);
    final statuses = <String, SystemStatus>{};
    
    // Calculate status for each system based on NOTAMs
    final systems = ['runways', 'taxiways', 'navaids', 'lighting', 'hazards', 'admin', 'other'];
    for (final system in systems) {
      final systemNotamList = systemNotams[system] ?? [];
      
      if (systemNotamList.isEmpty) {
        statuses[system] = SystemStatus.green;
      } else {
        // Check if any NOTAMs are critical
        final hasCritical = systemNotamList.any((notam) => notam.isCritical);
        
        if (hasCritical) {
          statuses[system] = SystemStatus.red;
        } else {
          statuses[system] = SystemStatus.yellow;
        }
      }
    }
    
    return statuses;
  }

  Widget _buildSystemRow(BuildContext context, Airport airport, String name, SystemStatus status, IconData icon, List<Notam> filteredNotams) {
    Color color;
    String statusText;
    
    switch (status) {
      case SystemStatus.green:
        color = const Color(0xFF10B981);
        statusText = 'Operational';
        break;
      case SystemStatus.yellow:
        color = const Color(0xFFF59E0B);
        statusText = 'Partial';
        break;
      case SystemStatus.red:
        color = const Color(0xFFEF4444);
        statusText = 'Affected';
        break;
    }

    // Get NOTAM count for this system
    final systemKey = _getSystemKey(name);
    final systemAnalyzer = AirportSystemAnalyzer();
    final systemNotams = systemAnalyzer.getSystemNotams(filteredNotams, airport.icao);
    final notamCount = systemNotams[systemKey]?.length ?? 0;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SystemDetailScreen(
              airportIcao: airport.icao,
              systemName: name,
              systemKey: systemKey,
              systemIcon: icon,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            if (notamCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$notamCount',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getSystemKey(String systemName) {
    switch (systemName) {
      case 'Runways':
        return 'runways';
      case 'Taxiways':
        return 'taxiways';
      case 'Instrument Procedures':
        return 'navaids';
      case 'Airport Services':
        return 'lighting';
      case 'Hazards':
        return 'hazards';
      case 'Admin':
        return 'admin';
      case 'Other':
        return 'other';
      default:
        return 'other';
    }
  }
} 