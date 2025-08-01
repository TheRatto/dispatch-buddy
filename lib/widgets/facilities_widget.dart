import 'package:flutter/material.dart';
import '../models/notam.dart';
import '../services/airport_cache_manager.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
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
          key: ValueKey('facilities_${widget.icao}'),
          future: _loadAirportData(widget.icao),
          builder: (context, snapshot) {
            debugPrint('DEBUG: FutureBuilder - Connection state: ${snapshot.connectionState}');
            debugPrint('DEBUG: FutureBuilder - Has data: ${snapshot.hasData}');
            debugPrint('DEBUG: FutureBuilder - Data type: ${snapshot.data?.runtimeType}');
            
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
      debugPrint('DEBUG: _loadAirportData called for $icao');
      // Use the cache manager to get airport infrastructure data
      final result = await AirportCacheManager.getAirportInfrastructure(icao);
      debugPrint('DEBUG: _loadAirportData result for $icao: ${result?.runtimeType}');
      if (result != null) {
        debugPrint('DEBUG: _loadAirportData - Found ${result.runtimeType} data for $icao');
      } else {
        debugPrint('DEBUG: _loadAirportData - No data found for $icao');
      }
      return result;
    } catch (e) {
      debugPrint('Error loading airport data for $icao: $e');
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
  /// Also handles L/R designations (e.g., 18R -> 36L, 18L -> 36R)
  String _getOppositeRunwayEnd(String runwayEnd) {
    // Extract the number and L/R designation
    final match = RegExp(r'(\d+)([LR]?)').firstMatch(runwayEnd);
    if (match == null) return runwayEnd;
    
    final number = int.tryParse(match.group(1) ?? '0') ?? 0;
    final designation = match.group(2) ?? '';
    
    if (number == 0) return runwayEnd;
    
    // Calculate opposite direction
    final opposite = (number + 18) % 36;
    final oppositeNumber = opposite == 0 ? '36' : opposite.toString().padLeft(2, '0');
    
    // For L/R designations, flip the designation (L becomes R, R becomes L)
    String oppositeDesignation = '';
    if (designation == 'L') {
      oppositeDesignation = 'R';
    } else if (designation == 'R') {
      oppositeDesignation = 'L';
    }
    
    return '$oppositeNumber$oppositeDesignation';
  }

  /// Create a runway pair object that combines two runway objects
  dynamic _createRunwayPair(Runway? runway1, Runway? runway2) {
    if (runway1 == null || runway2 == null) return runway1 ?? runway2;
    
    // Use the longer runway's length, or average if they're close
    final length1 = runway1.length;
    final length2 = runway2.length;
    final avgLength = (length1 + length2) / 2;
    
    // Use the wider runway's width, or average if they're close
    final width1 = runway1.width;
    final width2 = runway2.width;
    final avgWidth = (width1 + width2) / 2;
    
    // Create a combined runway object
    return Runway(
      identifier: '${runway1.identifier}/${runway2.identifier}',
      length: avgLength,
      surface: runway1.surface,
      approaches: runway1.approaches,
      hasLighting: runway1.hasLighting || runway2.hasLighting,
      width: avgWidth,
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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
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
        final width = runway.width;
        final surface = runway.surface;
        
        // Use settings provider to format length and width
        final formattedLength = settingsProvider.formatLength(length);
        final formattedWidth = settingsProvider.formatWidth(width);
        final unitSymbol = settingsProvider.unitSymbol;
        
        return _buildFacilityItem(
          name: Row(
            children: [
              // Runway identifier - fixed width
              SizedBox(
                width: 80,
                child: Text(
                  identifier,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Length - fixed width
              SizedBox(
                width: 70,
                child: Text(
                  formattedLength.isNotEmpty ? '$formattedLength $unitSymbol' : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Width - fixed width (always in meters)
              SizedBox(
                width: 50,
                child: Text(
                  formattedWidth.isNotEmpty ? '$formattedWidth m' : '',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Surface - fixed width
              SizedBox(
                width: 75,
                child: Text(
                  surface != null && surface != 'Unknown' ? surface : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          details: '',
          status: 'Operational',
          statusColor: Colors.green,
        );
      },
    );
  }

  Widget _buildNavAidsSection(dynamic airportData) {
    debugPrint('DEBUG: _buildNavAidsSection called with airportData: ${airportData?.runtimeType}');
    
    if (airportData == null) {
      debugPrint('DEBUG: _buildNavAidsSection - airportData is null, showing loading');
      return _buildFacilitySection(
        title: 'NAVAIDs',
        icon: Icons.radar,
        color: Colors.blue,
        facilities: [
          _buildFacilityItem(
            name: 'Loading navaid data...',
            details: '',
            status: 'Loading',
            statusColor: Colors.orange,
          ),
        ],
        emptyMessage: 'No navaid data available',
      );
    }

    // Extract navaids from airport infrastructure data
    List<Navaid> navaids = [];
    
    if (airportData is AirportInfrastructure) {
      navaids = airportData.navaids;
      debugPrint('DEBUG: _buildNavAidsSection - Found ${navaids.length} navaids from AirportInfrastructure');
      for (final navaid in navaids) {
        debugPrint('DEBUG: _buildNavAidsSection - Navaid: ${navaid.type} ${navaid.identifier} ${navaid.frequency} (runway: ${navaid.runway})');
      }
    } else {
      debugPrint('DEBUG: _buildNavAidsSection - airportData is not AirportInfrastructure: ${airportData.runtimeType}');
      debugPrint('DEBUG: _buildNavAidsSection - airportData value: $airportData');
    }
    
    // Group navaids by runway and type
    final runwayNavaids = <String, List<Navaid>>{};
    final generalNavaids = <Navaid>[];
    
    for (final navaid in navaids) {
      if (_isRunwaySpecificNavaid(navaid.type) && navaid.runway.isNotEmpty) {
        // Group by runway
        runwayNavaids.putIfAbsent(navaid.runway, () => []).add(navaid);
        debugPrint('DEBUG: _buildNavAidsSection - Added runway navaid: ${navaid.type} ${navaid.identifier} for runway ${navaid.runway}');
      } else {
        // General navaids
        generalNavaids.add(navaid);
        debugPrint('DEBUG: _buildNavAidsSection - Added general navaid: ${navaid.type} ${navaid.identifier}');
      }
    }
    
    // Build facility items
    final List<Widget> facilities = [];
    
    // Add general navaids FIRST (in current font)
    for (final navaid in generalNavaids) {
      facilities.add(_buildGeneralNavaidItem(navaid));
    }
    
    // Add runway-specific navaids grouped by runway
    for (final runway in runwayNavaids.keys) {
      final runwayNavaidList = runwayNavaids[runway]!;
      
      // Add runway heading (smaller, grey font, left aligned)
      facilities.add(_buildRunwayNavaidHeading(runway));
      
      // Add navaids for this runway (normal font)
      for (final navaid in runwayNavaidList) {
        facilities.add(_buildRunwayNavaidItem(navaid));
      }
    }
    
    // Calculate actual NAVAID count (excluding runway headings)
    final actualNavaidCount = generalNavaids.length + runwayNavaids.values.fold(0, (sum, navaids) => sum + navaids.length);
    
    return _buildFacilitySection(
      title: 'NAVAIDs',
      icon: Icons.radar,
      color: Colors.blue,
      facilities: facilities,
      emptyMessage: 'No navaid data available',
      count: actualNavaidCount.toInt(), // Pass actual count instead of facilities.length
    );
  }
  
  // Removed unused methods _getNavaidFullName and _getNavaidStatusColor
  
  /// Check if navaid is runway-specific (ILS, ILS/DME, GBAS, etc.)
  bool _isRunwaySpecificNavaid(String type) {
    final upperType = type.toUpperCase();
    return upperType.contains('ILS') || 
           upperType.contains('GBAS') || 
           upperType.contains('GLS') ||
           upperType.contains('LOC');
  }
  
  /// Build runway heading for navaids
  Widget _buildRunwayNavaidHeading(String runway) {
    return Container(
      padding: const EdgeInsets.only(top: 4.0, bottom: 0, left: 0, right: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        'RWY $runway',
        style: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  /// Build runway-specific navaid item with column layout and reduced padding
  Widget _buildRunwayNavaidItem(Navaid navaid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Reduced padding
      child: Row(
        children: [
          // Type - fixed width
          SizedBox(
            width: 80,
            child: Text(
              navaid.type,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          // Identifier - fixed width
          SizedBox(
            width: 60,
            child: Text(
              navaid.identifier,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          // Frequency - fixed width
          SizedBox(
            width: 70,
            child: Text(
              navaid.frequency,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Spacer(),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Operational',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build general navaid item with column layout
  Widget _buildGeneralNavaidItem(Navaid navaid) {
    return _buildFacilityItem(
      name: Row(
        children: [
          // Type - fixed width
          SizedBox(
            width: 80,
            child: Text(
              navaid.type,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          // Identifier - fixed width
          SizedBox(
            width: 60,
            child: Text(
              navaid.identifier,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          // Frequency - fixed width
          SizedBox(
            width: 70,
            child: Text(
              navaid.frequency,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      details: '',
      status: 'Operational',
      statusColor: Colors.green,
    );
  }

  Widget _buildLightingSection(dynamic airportData) {
    if (airportData == null || airportData.lighting == null) {
      return _buildFacilitySection(
        title: 'Lighting',
        icon: Icons.lightbulb,
        color: Colors.orange,
        facilities: [],
        emptyMessage: 'No lighting data available',
      );
    }

    final lighting = airportData.lighting as List<Lighting>;
    debugPrint('DEBUG: _buildLightingSection - Found ${lighting.length} lighting systems');

    if (lighting.isEmpty) {
      return _buildFacilitySection(
        title: 'Lighting',
        icon: Icons.lightbulb,
        color: Colors.orange,
        facilities: [],
        emptyMessage: 'No lighting data available',
      );
    }

    // Group lighting by runway end
    final Map<String, List<Lighting>> runwayEndLighting = {};

    for (final light in lighting) {
      List<String> runwayEnds = [];
      
      // Handle different runway naming patterns
      if (light.runway.contains('/')) {
        // Full runway designation (e.g., "07/25", "16L/34R")
        // Split into individual ends
        final ends = light.runway.split('/');
        runwayEnds = ends;
      } else {
        // Single runway end (e.g., "16L", "34R", "07")
        runwayEnds = [light.runway];
      }
      
      // Add lighting to each runway end
      for (final runwayEnd in runwayEnds) {
        if (!runwayEndLighting.containsKey(runwayEnd)) {
          runwayEndLighting[runwayEnd] = [];
        }
        runwayEndLighting[runwayEnd]!.add(light);
      }
    }

    final List<Widget> lightingWidgets = [];

    // Add lighting grouped by runway end
    for (final runwayEnd in runwayEndLighting.keys) {
      final runwayLights = runwayEndLighting[runwayEnd]!;
      lightingWidgets.add(_buildRunwayEndLightingItem(runwayEnd, runwayLights));
    }

    return _buildFacilitySection(
      title: 'Lighting',
      icon: Icons.lightbulb,
      color: Colors.orange,
      facilities: lightingWidgets,
      count: lighting.length,
      emptyMessage: 'No lighting data available',
    );
  }

  /// Build runway end lighting item with horizontal layout
  Widget _buildRunwayEndLightingItem(String runwayEnd, List<Lighting> lights) {
    // Determine overall status for this runway end
    final hasOperational = lights.any((light) => light.status == 'OPERATIONAL');
    final hasClosed = lights.any((light) => light.status == 'CLOSED');
    final hasMaintenance = lights.any((light) => light.status == 'MAINTENANCE');
    
    String overallStatus;
    Color statusColor;
    if (hasClosed) {
      overallStatus = 'CLOSED';
      statusColor = Colors.red;
    } else if (hasMaintenance) {
      overallStatus = 'MAINTENANCE';
      statusColor = Colors.orange;
    } else if (hasOperational) {
      overallStatus = 'OPERATIONAL';
      statusColor = Colors.green;
    } else {
      overallStatus = 'UNKNOWN';
      statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Runway end heading
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 0, right: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RWY $runwayEnd',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Lighting types row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: lights.map((light) => _buildLightingChip(light)).toList(),
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    overallStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual lighting chip
  Widget _buildLightingChip(Lighting light) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        light.description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Get status color based on status string
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return Colors.green;
      case 'CLOSED':
        return Colors.red;
      case 'MAINTENANCE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
    int? count, // Optional count parameter
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
                    '${count ?? facilities.length}',
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