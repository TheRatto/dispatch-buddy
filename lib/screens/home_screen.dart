import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../widgets/zulu_time_widget.dart';
import '../widgets/global_drawer.dart';
import 'input_screen.dart';
import 'briefing_tabs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              'Dispatch Buddy',
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
      endDrawer: const GlobalDrawer(currentScreen: '/home'),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80, // Restore original size
                      ),
                      const SizedBox(height: 16),
                      const Text(
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
                
                const SizedBox(height: 32),
                
                // New Briefing Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InputScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Start New Briefing',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Previous Briefings Section
                const Text(
                  'Previous Briefings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
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
          const SizedBox(height: 16),
          Text(
            'No previous briefings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
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
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.flight),
            title: Text('${flight.departure} → ${flight.destination}'),
            subtitle: Text(
              '${flight.etd.day}/${flight.etd.month}/${flight.etd.year} at ${flight.etd.hour.toString().padLeft(2, '0')}:${flight.etd.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              flightProvider.loadFlight(flight);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BriefingTabsScreen()),
              );
            },
          ),
        );
      },
    );
  }
} 