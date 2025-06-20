import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/airport.dart';

class AirportDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Airport Details'),
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final flight = flightProvider.currentFlight;
          
          if (flight == null) {
            return Center(
              child: Text('No flight data available'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: flight.airports.length,
            itemBuilder: (context, index) {
              final airport = flight.airports[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.airplanemode_active, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${airport.name} (${airport.icao})',
                                  style: TextStyle(
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
                      SizedBox(height: 16),
                      _buildSystemsList(airport),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSystemsList(Airport airport) {
    final systems = [
      {'name': 'Runways', 'status': airport.systems['runways'], 'icon': Icons.run_circle},
      {'name': 'Navaids', 'status': airport.systems['navaids'], 'icon': Icons.radar},
      {'name': 'Taxiways', 'status': airport.systems['taxiways'], 'icon': Icons.route},
      {'name': 'Lighting', 'status': airport.systems['lighting'], 'icon': Icons.lightbulb},
    ];

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
        SizedBox(height: 12),
        ...systems.map((system) => _buildSystemRow(
          system['name'] as String,
          system['status'] as SystemStatus,
          system['icon'] as IconData,
        )),
      ],
    );
  }

  Widget _buildSystemRow(String name, SystemStatus status, IconData icon) {
    Color color;
    String statusText;
    
    switch (status) {
      case SystemStatus.green:
        color = Color(0xFF10B981);
        statusText = 'Operational';
        break;
      case SystemStatus.yellow:
        color = Color(0xFFF59E0B);
        statusText = 'Partial';
        break;
      case SystemStatus.red:
        color = Color(0xFFEF4444);
        statusText = 'Affected';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ],
      ),
    );
  }
} 