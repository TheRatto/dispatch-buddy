import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/airport.dart';
import 'airport_detail_screen.dart';
import 'raw_data_screen.dart';
import '../widgets/zulu_time_widget.dart';

class SummaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispatch Summary'),
        actions: [
          const ZuluTimeWidget(),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pop(context); // Go back to input screen
            },
            tooltip: 'Edit Flight Plan',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              context.read<FlightProvider>().saveCurrentFlight();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Briefing saved')),
              );
            },
          ),
        ],
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final flight = flightProvider.currentFlight;
          
          if (flight == null) {
            return Center(
              child: Text('No flight data available'),
            );
          }

          return Column(
            children: [
              // Route Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Color(0xFF1E3A8A),
                child: Column(
                  children: [
                    Text(
                      '${flight.departure} → ${flight.destination}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ETD: ${flight.etd.day}/${flight.etd.month}/${flight.etd.year} ${flight.etd.hour.toString().padLeft(2, '0')}:${flight.etd.minute.toString().padLeft(2, '0')} | ${flight.flightLevel}',
                      style: TextStyle(
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
                  padding: EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(
                      context,
                      'Departure',
                      flight.departure,
                      flight.airports.firstWhere((a) => a.icao == flight.departure),
                      Icons.flight_takeoff,
                      Color(0xFF10B981),
                    ),
                    SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      'Enroute',
                      'Flight Level ${flight.flightLevel}',
                      null,
                      Icons.flight,
                      Color(0xFF3B82F6),
                    ),
                    SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      'Arrival',
                      flight.destination,
                      flight.airports.firstWhere((a) => a.icao == flight.destination),
                      Icons.flight_land,
                      Color(0xFFF59E0B),
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
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
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
                          builder: (context) => AirportDetailScreen(),
                        ),
                      );
                    },
                    child: Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            if (airport != null) ...[
              SizedBox(height: 16),
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
        Text(
          'System Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            _buildStatusIndicator('Runways', airport.systems['runways']),
            SizedBox(width: 16),
            _buildStatusIndicator('Navaids', airport.systems['navaids']),
            SizedBox(width: 16),
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
        color = Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case SystemStatus.yellow:
        color = Color(0xFFF59E0B);
        icon = Icons.warning;
        break;
      case SystemStatus.red:
        color = Color(0xFFEF4444);
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 