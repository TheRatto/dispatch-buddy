import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import 'input_screen.dart';
import 'briefing_tabs_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dispatch Buddy'),
        centerTitle: true,
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'AI Preflight Briefing Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // New Briefing Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InputScreen()),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text(
                    'Start New Briefing',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Previous Briefings Section
                Text(
                  'Previous Briefings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Previous briefings list
                Expanded(
                  child: flightProvider.savedFlights.isEmpty
                      ? _buildEmptyState()
                      : _buildBriefingsList(context, flightProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No previous briefings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start your first briefing to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingsList(BuildContext context, FlightProvider flightProvider) {
    return ListView.builder(
      itemCount: flightProvider.savedFlights.length,
      itemBuilder: (context, index) {
        final flight = flightProvider.savedFlights[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.flight),
            title: Text('${flight.departure} → ${flight.destination}'),
            subtitle: Text(
              '${flight.etd.day}/${flight.etd.month}/${flight.etd.year} at ${flight.etd.hour.toString().padLeft(2, '0')}:${flight.etd.minute.toString().padLeft(2, '0')}',
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              flightProvider.loadFlight(flight);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BriefingTabsScreen()),
              );
            },
          ),
        );
      },
    );
  }
} 