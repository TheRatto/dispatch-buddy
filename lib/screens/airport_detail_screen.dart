import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../widgets/global_drawer.dart';
import '../widgets/zulu_time_widget.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../services/airport_system_analyzer.dart';
import '../services/airport_database.dart';
import '../services/taf_state_manager.dart';
import '../services/cache_manager.dart';
import '../widgets/taf_airport_selector.dart';
import '../widgets/facilities_widget.dart';
import '../widgets/system_pages/runway_system_widget.dart';
import '../widgets/system_pages/taxiway_system_widget.dart';
import '../widgets/system_pages/instrument_procedures_system_widget.dart';
import '../widgets/system_pages/airport_services_system_widget.dart';
import '../widgets/system_pages/hazards_system_widget.dart';
import '../widgets/system_pages/admin_system_widget.dart';
import '../widgets/system_pages/other_system_widget.dart';


class AirportDetailScreen extends StatefulWidget {
  const AirportDetailScreen({super.key});

  @override
  State<AirportDetailScreen> createState() => _AirportDetailScreenState();
}

class _AirportDetailScreenState extends State<AirportDetailScreen> with TickerProviderStateMixin {
  // Time filter is now managed by FlightProvider globally
  late TabController _systemTabController;
  
  // System pages configuration
  static const List<Map<String, dynamic>> _systemPages = [
    {'name': 'Facilities', 'icon': Icons.airplanemode_active},
    {'name': 'Overview', 'icon': Icons.dashboard},
    {'name': 'Runways', 'icon': Icons.run_circle},
    {'name': 'Taxiways', 'icon': Icons.route},
    {'name': 'Instrument Procedures', 'icon': Icons.radar},
    {'name': 'Airport Services', 'icon': Icons.business},
    {'name': 'Hazards', 'icon': Icons.warning},
    {'name': 'Admin', 'icon': Icons.admin_panel_settings},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  // Clear cache when refreshing data
  void _clearCache() {
    final tafStateManager = TafStateManager();
    tafStateManager.clearCache();
    final cacheManager = CacheManager();
    cacheManager.clearPrefix('notam_');
  }

  @override
  void initState() {
    super.initState();
    _systemTabController = TabController(length: _systemPages.length, vsync: this);
    
    // Add listener to save last viewed system page
    _systemTabController.addListener(() {
      if (_systemTabController.indexIsChanging) {
        final flightProvider = context.read<FlightProvider>();
        flightProvider.setLastViewedSystemPage(_systemTabController.index);
      }
    });
    
    // Restore last viewed system page if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flightProvider = context.read<FlightProvider>();
      if (flightProvider.lastViewedSystemPage != null) {
        _systemTabController.animateTo(flightProvider.lastViewedSystemPage!);
      }
    });
  }

  @override
  void dispose() {
    _systemTabController.dispose();
    super.dispose();
  }

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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                debugPrint('DEBUG: Hamburger menu pressed - opening end drawer');
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const GlobalDrawer(currentScreen: '/briefing'),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final flight = flightProvider.currentFlight;
          
          if (flight == null) {
            return const Center(
              child: Text('No flight data available'),
            );
          }

          // Get list of airport ICAO codes
          final airports = flight.airports.map((a) => a.icao).toList();
          
          // Initialize selected airport if not set
          if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
            flightProvider.setSelectedAirport(airports.first);
          }

          // Get the selected airport object
          final selectedAirport = flight.airports.firstWhere(
            (a) => a.icao == flightProvider.selectedAirport,
            orElse: () => flight.airports.first,
          );

          return Column(
            children: [
              // System navigation tabs at top
              Container(
                color: Colors.white,
                height: 45, // Reduced height from default ~48px to 40px
                child: TabBar(
                  controller: _systemTabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF1E3A8A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF1E3A8A),
                  labelStyle: const TextStyle(fontSize: 12), // Smaller text
                  unselectedLabelStyle: const TextStyle(fontSize: 12), // Smaller text
                  tabs: _systemPages.map((page) => Tab(
                    icon: Icon(page['icon'], size: 18), // Smaller icon
                    text: page['name'],
                  )).toList(),
                ),
              ),
              // Airport selector below tabs
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
              // Static time filter between airport selector and content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildTimeFilterHeader(),
              ),
              // System content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    debugPrint('DEBUG: AirportDetailScreen - Pull-to-refresh triggered');
                    
                    // Clear caches like Raw Data screen does
                    _clearCache();
                    
                    if (flightProvider.currentBriefing != null) {
                      debugPrint('DEBUG: AirportDetailScreen - Refreshing briefing ${flightProvider.currentBriefing!.id}');
                      
                      try {
                        // First refresh the flight data (like Raw Data screen)
                        await flightProvider.refreshFlightData();
                        
                        // Then update the stored briefing with fresh data
                        final success = await flightProvider.refreshCurrentBriefing();
                        
                        if (success) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Briefing refreshed successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to refresh briefing. Original data preserved.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('DEBUG: AirportDetailScreen - Refresh failed: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Refresh failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      debugPrint('DEBUG: AirportDetailScreen - Not viewing a briefing, just refreshing flight data');
                      // Just refresh flight data for new flights
                      await flightProvider.refreshFlightData();
                    }
                  },
                  child: TabBarView(
                    controller: _systemTabController,
                    children: _buildSystemPages(selectedAirport, flight.notams),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSystemPages(Airport selectedAirport, List<Notam> notams) {
    return [
      // Facilities page
      FacilitiesWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Overview page
      _buildOverviewPage(selectedAirport, notams),
      // Runways page
      RunwaySystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Taxiways page
      TaxiwaySystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Instrument Procedures page
      InstrumentProceduresSystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Airport Services page
      AirportServicesSystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Hazards page
      HazardsSystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Admin page
      AdminSystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
      // Other page
      OtherSystemWidget(
        airportName: selectedAirport.name,
        icao: selectedAirport.icao,
        notams: notams,
      ),
    ];
  }

  Widget _buildOverviewPage(Airport selectedAirport, List<Notam> notams) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Airport info
          Row(
            children: [
              const Icon(Icons.airplanemode_active, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedAirport.name} (${selectedAirport.icao}${AirportDatabase.getIataCode(selectedAirport.icao) != null ? '/${AirportDatabase.getIataCode(selectedAirport.icao)}' : ''})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      selectedAirport.city,
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
          // Systems list
          _buildSystemsList(context, selectedAirport, notams),
        ],
      ),
    );
  }



  Widget _buildTimeFilterHeader() {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
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
                      flightProvider.selectedTimeFilter,
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
              itemBuilder: (context) => flightProvider.timeFilterOptions.map((filter) {
                return PopupMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onSelected: (value) {
                flightProvider.setTimeFilter(value);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSystemsList(BuildContext context, Airport airport, List<Notam> allNotams) {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        // Filter NOTAMs by time and airport using global filter
        final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(allNotams, airport.icao);
        
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
      },
    );
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
        // Find the index of the system in the _systemPages list
        final systemIndex = _systemPages.indexWhere((page) => page['name'] == name);
        if (systemIndex != -1) {
          // Switch to the appropriate tab
          _systemTabController.animateTo(systemIndex);
          // Save the last viewed system page
          context.read<FlightProvider>().setLastViewedSystemPage(systemIndex);
        }
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
                  color: color.withValues(alpha: 0.2),
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
                color: color.withValues(alpha: 0.1),
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

  void _showAddAirportDialog(BuildContext context) {
    // TODO: Implement add airport functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Airport'),
        content: const Text('Add airport functionality coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditAirportDialog(BuildContext context, String icao) {
    // TODO: Implement edit airport functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Airport'),
        content: Text('Edit airport $icao functionality coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 