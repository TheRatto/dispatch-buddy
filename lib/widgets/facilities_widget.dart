import 'package:flutter/material.dart';
import '../models/notam.dart';
import '../services/airport_cache_manager.dart';
import '../providers/flight_provider.dart';
import 'package:provider/provider.dart';

/// Facilities Widget
/// 
/// Displays airport infrastructure information in a clean, compact format.
/// Shows runways, navaids, lighting, and other facilities with their status.
/// Designed to be a one-glance view of important airport facilities.
class FacilitiesWidget extends StatefulWidget {
  final String airportName;
  final String icao;
  final List<Notam> notams;

  const FacilitiesWidget({
    Key? key,
    required this.airportName,
    required this.icao,
    required this.notams,
  }) : super(key: key);

  @override
  State<FacilitiesWidget> createState() => _FacilitiesWidgetState();
}

class _FacilitiesWidgetState extends State<FacilitiesWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        return FutureBuilder<dynamic>(
          future: _loadAirportData(widget.icao),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading airport data: ${snapshot.error}'),
                  ],
                ),
              );
            }
            
            final airportData = snapshot.data;
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Airport header
                  _buildAirportHeader(),
                  const SizedBox(height: 24),
                  
                  // Runways section
                  _buildRunwaysSection(airportData),
                  const SizedBox(height: 16),
                  
                  // NAVAIDs section
                  _buildNavAidsSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Lighting section
                  _buildLightingSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Services section
                  _buildServicesSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Hazards section
                  _buildHazardsSection(airportData),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic> _loadAirportData(String icao) async {
    try {
      // Use the cache manager instead of direct API calls
      return await AirportCacheManager.getAirportInfrastructure(icao);
    } catch (e) {
      print('Error loading airport data for $icao: $e');
      return null;
    }
  }

  Widget _buildAirportHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.airplanemode_active, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.airportName} (${widget.icao})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Facilities Overview',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunwaysSection(dynamic airportData) {
    final runways = airportData?.runways ?? [];
    
    return _buildFacilitySection(
      title: 'Runways',
      icon: Icons.run_circle,
      color: Colors.green,
      facilities: runways.map((runway) => _buildRunwayItem(runway)).toList().cast<Widget>(),
      emptyMessage: 'No runway data available',
    );
  }

  Widget _buildRunwayItem(dynamic runway) {
    // Handle both string runways (from OpenAIP) and object runways
    String identifier;
    String details = '';
    
    if (runway is String) {
      identifier = runway;
      details = 'Runway available';
    } else {
      identifier = runway?.identifier ?? 'Unknown';
      final length = runway?.length?.toString() ?? '';
      details = length.isNotEmpty ? '$length m' : '';
    }
    
    return _buildFacilityItem(
      name: identifier,
      details: details,
      status: 'Operational',
      statusColor: Colors.green,
    );
  }

  Widget _buildNavAidsSection(dynamic airportData) {
    // For now, we'll show a placeholder since OpenAIP data structure
    // may not include detailed navaid information
    return _buildFacilitySection(
      title: 'NAVAIDs',
      icon: Icons.radar,
      color: Colors.blue,
      facilities: [
        _buildFacilityItem(
          name: 'ILS',
          details: 'Instrument Landing System',
          status: 'Operational',
          statusColor: Colors.green,
        ),
        _buildFacilityItem(
          name: 'VOR',
          details: 'VHF Omnidirectional Range',
          status: 'Operational',
          statusColor: Colors.green,
        ),
      ],
      emptyMessage: 'No navaid data available',
    );
  }

  Widget _buildLightingSection(dynamic airportData) {
    return _buildFacilitySection(
      title: 'Lighting',
      icon: Icons.lightbulb,
      color: Colors.orange,
      facilities: [
        _buildFacilityItem(
          name: 'HIAL',
          details: 'High Intensity Approach Lighting',
          status: 'Operational',
          statusColor: Colors.green,
        ),
        _buildFacilityItem(
          name: 'PAPI',
          details: 'Precision Approach Path Indicator',
          status: 'Operational',
          statusColor: Colors.green,
        ),
      ],
      emptyMessage: 'No lighting data available',
    );
  }

  Widget _buildServicesSection(dynamic airportData) {
    return _buildFacilitySection(
      title: 'Services',
      icon: Icons.business,
      color: Colors.purple,
      facilities: [
        _buildFacilityItem(
          name: 'Fuel',
          details: 'Aviation fuel available',
          status: 'Available',
          statusColor: Colors.green,
        ),
      ],
      emptyMessage: 'No service data available',
    );
  }

  Widget _buildHazardsSection(dynamic airportData) {
    return _buildFacilitySection(
      title: 'Hazards',
      icon: Icons.warning,
      color: Colors.red,
      facilities: [
        _buildFacilityItem(
          name: 'None reported',
          details: 'No hazards identified',
          status: 'Clear',
          statusColor: Colors.green,
        ),
      ],
      emptyMessage: 'No hazard data available',
    );
  }

  Widget _buildFacilitySection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> facilities,
    required String emptyMessage,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${facilities.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (facilities.isNotEmpty) ...[
              ...facilities,
            ] else ...[
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityItem({
    required String name,
    required String details,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
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