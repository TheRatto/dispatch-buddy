import 'package:flutter/material.dart';
import '../models/notam.dart';
import '../services/airport_cache_manager.dart';
import '../providers/flight_provider.dart';
import 'package:provider/provider.dart';
import '../models/airport_infrastructure.dart';

/// Custom painter for runway icon
class RunwayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw the vertical runway line
    final verticalStart = Offset(center.dx, center.dy - radius * 0.6);
    final verticalEnd = Offset(center.dx, center.dy + radius * 0.6);
    canvas.drawLine(verticalStart, verticalEnd, paint);

    // Draw the diagonal runway line
    final diagonalStart = Offset(center.dx - radius * 0.4, center.dy - radius * 0.4);
    final diagonalEnd = Offset(center.dx + radius * 0.4, center.dy + radius * 0.4);
    canvas.drawLine(diagonalStart, diagonalEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
            // Show content immediately with placeholder data
            final airportData = snapshot.data;
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Airport header
                  _buildAirportHeader(),
                  const SizedBox(height: 24),
                  
                  // Runways section - uses real data when available
                  _buildRunwaysSection(airportData),
                  const SizedBox(height: 16),
                  
                  // NAVAIDs section - placeholder for now, will use real data later
                  _buildNavAidsSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Lighting section - placeholder for now, will use real data later
                  _buildLightingSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Services section - placeholder for now, will use real data later
                  _buildServicesSection(airportData),
                  const SizedBox(height: 16),
                  
                  // Hazards section - placeholder for now, will use real data later
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
      // Use the cache manager to get airport infrastructure data
      return await AirportCacheManager.getAirportInfrastructure(icao);
    } catch (e) {
      print('Error loading airport data for $icao: $e');
      return null;
    }
  }

  Widget _buildAirportHeader() {
    // Debug logging to see what airport name we have
    debugPrint('DEBUG: FacilitiesWidget - Airport name: "${widget.airportName}", ICAO: "${widget.icao}"');
    
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

  /// Custom runway icon widget
  Widget _buildRunwayIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: RunwayIconPainter(),
        size: const Size(24, 24),
      ),
    );
  }

  Widget _buildRunwaysSection(dynamic airportData) {
    if (airportData == null) {
      return _buildFacilitySection(
        title: 'Runways',
        icon: _buildRunwayIcon(), // Use custom icon immediately
        color: Colors.green,
        facilities: [
          _buildFacilityItem(
            name: 'Loading runway data...',
            details: '',
            status: 'Loading',
            statusColor: Colors.orange,
          ),
        ],
        emptyMessage: 'No runway data available',
      );
    }

    final runways = airportData.runways ?? [];
    debugPrint('DEBUG: FacilitiesWidget - Runway data received: ${runways.length} runways');
    
    for (int i = 0; i < runways.length; i++) {
      final runway = runways[i];
      debugPrint('DEBUG: FacilitiesWidget - Runway $i: $runway');
    }

    // Group runways into pairs (e.g., 03/21, 06/24)
    final List<dynamic> runwayPairs = [];
    final Set<String> processedRunways = {};

    for (final runway in runways) {
      if (runway is! Runway) continue;
      
      final identifier = runway.identifier;
      if (processedRunways.contains(identifier)) continue;

      // Try to find the opposite runway (e.g., if we have 03, look for 21)
      final oppositeIdentifier = _getOppositeRunwayEnd(identifier);
      Runway? oppositeRunway;
      try {
        oppositeRunway = runways.where((r) => r is Runway && r.identifier == oppositeIdentifier).first;
      } catch (e) {
        oppositeRunway = null;
      }

      if (oppositeRunway != null) {
        final pair = _createRunwayPair(runway, oppositeRunway);
        runwayPairs.add(pair);
        processedRunways.add(identifier);
        processedRunways.add(oppositeIdentifier);
      } else {
        runwayPairs.add(runway);
        processedRunways.add(identifier);
      }
    }

    return _buildFacilitySection(
      title: 'Runways',
      icon: _buildRunwayIcon(), // Use custom icon immediately
      color: Colors.green,
      facilities: runwayPairs.map((pair) => _buildEnhancedRunwayItem(pair)).toList().cast<Widget>(),
      emptyMessage: 'No runway data available',
    );
  }
  
  /// Get the opposite runway end (e.g., 17 -> 35, 12 -> 30)
  String _getOppositeRunwayEnd(String runwayEnd) {
    final number = int.tryParse(runwayEnd) ?? 0;
    if (number == 0) return runwayEnd;
    
    final opposite = (number + 18) % 36;
    return opposite == 0 ? '36' : opposite.toString().padLeft(2, '0');
  }

  /// Create a runway pair object that combines two runway objects
  dynamic _createRunwayPair(Runway? runway1, Runway? runway2) {
    if (runway1 == null || runway2 == null) return runway1 ?? runway2;
    
    // Use the longer runway's length, or average if they're close
    final length1 = runway1.length;
    final length2 = runway2.length;
    final avgLength = (length1 + length2) / 2;
    
    // Create a combined runway object
    return Runway(
      identifier: '${runway1.identifier}/${runway2.identifier}',
      length: avgLength,
      surface: runway1.surface,
      approaches: runway1.approaches,
      hasLighting: runway1.hasLighting || runway2.hasLighting,
      width: runway1.width,
      status: 'OPERATIONAL',
    );
  }

  Widget _buildRunwayItem(dynamic runway) {
    // Handle both string runways (from OpenAIP) and object runways
    String identifier;
    String details = '';
    
    if (runway is String) {
      identifier = runway;
      // Check if it's a runway pair (e.g., "17/35")
      if (identifier.contains('/')) {
        details = 'Rwy $identifier';
        // Add length if available (for now, show placeholder)
        details += ' (length data not available)';
      } else {
        details = 'Rwy $identifier';
      }
    } else if (runway is Runway) {
      identifier = runway.identifier;
      final length = runway.length;
      final surface = runway.surface;
      
      if (length > 0) {
        // Convert meters to feet and format as "10,800ft"
        final lengthFeet = (length * 3.28084).round();
        final formattedLength = lengthFeet.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},'
        );
        
        // Add surface information if available
        if (surface != null && surface != 'Unknown') {
          details = 'Rwy $identifier $formattedLength ft ($surface)';
        } else {
          details = 'Rwy $identifier $formattedLength ft';
        }
      } else {
        details = 'Rwy $identifier (length data not available)';
      }
    } else {
      identifier = 'Unknown';
      details = 'Rwy $identifier';
    }
    
    return _buildFacilityItem(
      name: details,
      details: '', // Empty since we put everything in the name
      status: 'Operational',
      statusColor: Colors.green,
    );
  }
  
  /// Build a facility item with enhanced runway formatting
  Widget _buildEnhancedRunwayItem(dynamic runway) {
    if (runway is! Runway) {
      return _buildFacilityItem(
        name: 'Rwy ${runway.toString()}',
        details: '',
        status: 'Operational',
        statusColor: Colors.green,
      );
    }
    
    final identifier = runway.identifier;
    final length = runway.length;
    final surface = runway.surface;
    
    List<InlineSpan> textSpans = [];
    
    // Runway identifier (bold, fixed width)
    textSpans.add(
      TextSpan(
        text: 'Rwy $identifier'.padRight(12), // Fixed width for runway identifier
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
    
    if (length > 0) {
      // Convert meters to feet
      final lengthFeet = (length * 3.28084).round();
      final formattedLength = lengthFeet.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
      
      // Length (medium weight, fixed width)
      textSpans.add(
        TextSpan(
          text: '$formattedLength ft'.padRight(15), // Fixed width for length
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      );
      
      // Surface (normal weight, fixed width)
      if (surface != null && surface != 'Unknown') {
        textSpans.add(
          TextSpan(
            text: surface.padRight(12), // Fixed width for surface
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: ''.padRight(12), // Empty space to maintain alignment
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        );
      }
    } else {
      textSpans.add(
        TextSpan(
          text: ' (length data not available)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return _buildFacilityItem(
      name: RichText(
        text: TextSpan(
          children: textSpans,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      details: '',
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
    required dynamic icon, // Can be IconData or Widget
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
                icon is IconData
                    ? Icon(icon, color: color, size: 24)
                    : icon as Widget,
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
    required dynamic name, // Can be String or Widget
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
                name is String
                    ? Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : name as Widget,
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