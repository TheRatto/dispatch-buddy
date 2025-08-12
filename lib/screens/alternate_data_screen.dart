import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import '../models/notam.dart';
import '../widgets/zulu_time_widget.dart';
import '../widgets/taf_tab.dart';
import '../widgets/taf_airport_selector.dart';

class AlternateDataScreen extends StatefulWidget {
  const AlternateDataScreen({super.key});

  @override
  _AlternateDataScreenState createState() => _AlternateDataScreenState();
}

class _AlternateDataScreenState extends State<AlternateDataScreen> {
  // Time filter for NOTAMs
  String _selectedTimeFilter = '24 hours'; // Default to 24 hours
  final List<String> _timeFilterOptions = [
    '6 hours',
    '12 hours', 
    '24 hours',
    '72 hours',
    'All NOTAMs'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
              SizedBox(height: 2),
              Text(
                'Alternate Data',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            indicatorColor: Color(0xFFF97316), // Accent Orange
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'NOTAMs'),
              Tab(text: 'TAFs'),
            ],
          ),
        ),
        body: Consumer<FlightProvider>(
          builder: (context, flightProvider, child) {
            final flight = flightProvider.currentFlight;
            if (flight == null) {
              return const Center(child: Text('No flight data available'));
            }
            
            return TabBarView(
              children: [
                _buildAlternateNotamsTab(context, flight.notams, flightProvider),
                RefreshIndicator(
                  onRefresh: () async {
                    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                    await flightProvider.refreshCurrentData(
                      naipsEnabled: settingsProvider.naipsEnabled,
                      naipsUsername: settingsProvider.naipsUsername,
                      naipsPassword: settingsProvider.naipsPassword,
                    );
                  },
                  child: TafTab(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlternateNotamsTab(BuildContext context, List<Notam> notams, FlightProvider flightProvider) {
    // Get unique airports from NOTAMs
    final airports = notams.map((notam) => _normalizeAirportCode(notam.icao)).toSet().toList();
    
    // Initialize selected airport if not set
    if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
      if (airports.isNotEmpty) {
        flightProvider.setSelectedAirport(airports.first);
      }
    }
    
    // Get filtered NOTAMs
    final filteredNotams = _getFilteredNotams(notams, flightProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
        await flightProvider.refreshCurrentData(
          naipsEnabled: settingsProvider.naipsEnabled,
          naipsUsername: settingsProvider.naipsUsername,
          naipsPassword: settingsProvider.naipsPassword,
        );
      },
      child: Column(
        children: [
          // Fixed airport selector at top
          if (airports.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: RepaintBoundary(
                child: Center(
                  child: TafAirportSelector(
                    airports: airports,
                    selectedAirport: flightProvider.selectedAirport ?? airports.first,
                    onAirportSelected: (String airport) {
                      flightProvider.setSelectedAirport(airport);
                    },
                    onAddAirport: _showAddAirportDialog,
                    onAirportLongPress: _showEditAirportDialog,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          // Time filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Show NOTAMs for next:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E3A8A),
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: filteredNotams.isEmpty 
                        ? Colors.grey[200] 
                        : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredNotams.length} NOTAM${filteredNotams.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: filteredNotams.isEmpty ? Colors.grey[600] : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // NOTAM list with expandable cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredNotams.length,
              itemBuilder: (context, index) {
                final notam = filteredNotams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      '${notam.id} - ${notam.affectedSystem}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${notam.icao} | ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}',
                    ),
                    leading: Icon(
                      notam.isCritical ? Icons.error : Icons.warning,
                      color: notam.isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Basic NOTAM Information
                            Text(
                              'NOTAM Details:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('NOTAM ID', notam.id),
                            _buildInfoRow('ICAO', notam.icao),
                            _buildInfoRow('Type', notam.type.toString().split('.').last),
                            if (notam.qCode != null) _buildInfoRow('Q Code', notam.qCode!),
                            _buildInfoRow('Affected System', notam.affectedSystem),
                            _buildInfoRow('Critical', notam.isCritical ? 'Yes' : 'No'),
                            _buildInfoRow('Effective From', _formatDateTime(notam.validFrom)),
                            _buildInfoRow('Effective To', _formatDateTime(notam.validTo)),
                            
                            const SizedBox(height: 20),
                            
                            // Raw NOTAM Data
                            Text(
                              'Raw NOTAM Data:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                notam.displayRawText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Decoded NOTAM Data
                            Text(
                              'Decoded NOTAM Data:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                notam.displayDecodedText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }

  // Filter NOTAMs based on selected time filter
  List<Notam> _getFilteredNotams(List<Notam> notams, FlightProvider flightProvider) {
    // Filter by airport first
    final airportFilteredNotams = flightProvider.selectedAirport != null 
        ? notams.where((notam) => _normalizeAirportCode(notam.icao) == flightProvider.selectedAirport).toList()
        : notams;
    
    // Filter by time
    return _filterNotamsByTime(airportFilteredNotams);
  }

  // Filter NOTAMs based on selected time filter
  List<Notam> _filterNotamsByTime(List<Notam> notams) {
    if (_selectedTimeFilter == 'All NOTAMs') {
      return notams;
    }
    
    final now = DateTime.now().toUtc(); // Use UTC time consistently
    Duration filterDuration;
    
    switch (_selectedTimeFilter) {
      case '6 hours':
        filterDuration = const Duration(hours: 6);
        break;
      case '12 hours':
        filterDuration = const Duration(hours: 12);
        break;
      case '24 hours':
        filterDuration = const Duration(hours: 24);
        break;
      case '72 hours':
        filterDuration = const Duration(hours: 72);
        break;
      default:
        return notams;
    }
    
    final filterEndTime = now.add(filterDuration);
    
    return notams.where((notam) {
      // Show NOTAMs that are either:
      // 1. Currently active (started before now, ends after now)
      // 2. Will become active within the time window
      return (notam.validFrom.isBefore(now) && notam.validTo.isAfter(now)) || // Currently active
             (notam.validFrom.isAfter(now) && notam.validFrom.isBefore(filterEndTime)); // Future active
    }).toList();
  }

  // Normalize airport codes to ensure consistency across tabs
  String _normalizeAirportCode(String icao) {
    // If it's a 3-letter US airport code, add 'K' prefix
    if (icao.length == 3 && icao == icao.toUpperCase()) {
      return 'K$icao';
    }
    return icao.toUpperCase();
  }

  void _showAddAirportDialog(BuildContext context) {
    // TODO: Implement add airport dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add airport functionality coming soon')),
    );
  }

  void _showEditAirportDialog(BuildContext context, String icao) {
    // TODO: Implement edit airport dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit airport $icao functionality coming soon')),
    );
  }
} 