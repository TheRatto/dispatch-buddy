import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../widgets/global_drawer.dart';
import '../widgets/zulu_time_widget.dart';
import '../models/airport.dart';
import '../models/briefing.dart';
import '../services/briefing_storage_service.dart';
import 'airport_detail_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

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
            return const Center(
              child: Text('No flight data available'),
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
              
              // Summary Cards
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(
                      context,
                      'Departure',
                      flight.departure,
                      flight.airports.firstWhere((a) => a.icao == flight.departure),
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
                      flight.airports.firstWhere((a) => a.icao == flight.destination),
                      Icons.flight_land,
                      const Color(0xFFF59E0B),
                    ),
                  ],
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