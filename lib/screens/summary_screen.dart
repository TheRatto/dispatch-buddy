import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/global_drawer.dart';
import '../widgets/zulu_time_widget.dart';
import '../models/airport.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
import '../services/taf_state_manager.dart';
import '../services/cache_manager.dart';
import 'airport_detail_screen.dart';
import 'input_screen.dart';
import 'briefing_tabs_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  // Clear cache when refreshing data
  void _clearCache() {
    final tafStateManager = TafStateManager();
    tafStateManager.clearCache();
    final cacheManager = CacheManager();
    cacheManager.clearPrefix('notam_');
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
              'Summary',
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dashboard_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Flight Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No active briefing',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start a new briefing to see your flight summary, weather conditions, and NOTAMs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InputScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Briefing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'or',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // Switch to Home tab (index 0) in the parent BriefingTabsScreen
                        BriefingTabsScreen.switchToTab(context, 0);
                      },
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text(
                        'Open Previous Briefing',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Route Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1E3A8A),
                child: Column(
                  children: [
                    Text(
                      '${flight.departure} → ${flight.destination}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ETD: ${flight.etd.day}/${flight.etd.month}/${flight.etd.year} ${flight.etd.hour.toString().padLeft(2, '0')}:${flight.etd.minute.toString().padLeft(2, '0')} | ${flight.flightLevel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Summary Cards with Pull-to-Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    debugPrint('DEBUG: SummaryScreen - Unified pull-to-refresh triggered');
                    
                    // Clear caches like Raw Data screen does
                    _clearCache();
                    
                    if (flightProvider.currentBriefing != null) {
                      debugPrint('DEBUG: SummaryScreen - Refreshing briefing ${flightProvider.currentBriefing!.id}');
                      
                      try {
                        // Use the unified refresh method
                        final success = await flightProvider.refreshCurrentBriefingUnified();
                        
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
                        debugPrint('DEBUG: SummaryScreen - Unified refresh failed: $e');
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
                      debugPrint('DEBUG: SummaryScreen - Not viewing a briefing, just refreshing flight data');
                      // Just refresh flight data for new flights
                      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                      await flightProvider.refreshCurrentData(
                        naipsEnabled: settingsProvider.naipsEnabled,
                        naipsUsername: settingsProvider.naipsUsername,
                        naipsPassword: settingsProvider.naipsPassword,
                      );
                    }
                  },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(
                      context,
                      'Departure',
                      flight.departure,
                      flight.airports.where((a) => a.icao == flight.departure).firstOrNull,
                      Icons.flight_takeoff,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      'Enroute',
                      'Flight Level ${flight.flightLevel}',
                      null,
                      Icons.flight,
                      const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      'Arrival',
                      flight.destination,
                      flight.airports.where((a) => a.icao == flight.destination).firstOrNull,
                      Icons.flight_land,
                      const Color(0xFFF59E0B),
                    ),
                  ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String subtitle,
    dynamic airport,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (airport != null)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AirportDetailScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Details'),
                  ),
              ],
            ),
            if (airport != null) ...[
              const SizedBox(height: 16),
              _buildSystemStatus(airport),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus(dynamic airport) {
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
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatusIndicator('Runways', airport.systems['runways']),
            const SizedBox(width: 16),
            _buildStatusIndicator('Navaids', airport.systems['navaids']),
            const SizedBox(width: 16),
            _buildStatusIndicator('Taxiways', airport.systems['taxiways']),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, dynamic status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case SystemStatus.green:
        color = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case SystemStatus.yellow:
        color = const Color(0xFFF59E0B);
        icon = Icons.warning;
        break;
      case SystemStatus.red:
        color = const Color(0xFFEF4444);
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 