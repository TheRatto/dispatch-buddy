import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notam.dart';
import '../services/airport_cache_manager.dart';
import '../services/airport_system_analyzer.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../models/airport_infrastructure.dart';
import '../models/airport.dart';
import '../services/notam_grouping_service.dart';

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
  final NotamGroupingService _groupingService = NotamGroupingService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Airport Facilities'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FlightProvider>(
        builder: (context, flightProvider, child) {
          final selectedAirport = flightProvider.selectedAirport;
          if (selectedAirport == null) {
            return const Center(
              child: Text('Please select an airport from the home screen.'),
            );
          }

          return FutureBuilder<AirportInfrastructure?>(
            future: _loadAirportData(selectedAirport),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading airport data: ${snapshot.error}'),
                );
              }

              final airportData = snapshot.data;
              if (airportData == null) {
                return const Center(
                  child: Text('No airport data available.'),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAirportHeader(airportData),
                    const SizedBox(height: 16),
                    _buildRunwaySection(airportData, flightProvider),
                    const SizedBox(height: 16),
                    _buildNavAidsSection(airportData, flightProvider),
                    const SizedBox(height: 16),
                    _buildLightingSection(airportData, flightProvider),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Load airport infrastructure data from cache or database
  Future<AirportInfrastructure?> _loadAirportData(String icao) async {
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

  Widget _buildAirportHeader(AirportInfrastructure airportData) {
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
        size: Size(24, 24),
      ),
    );
  }

  Widget _buildRunwaySection(AirportInfrastructure airportData, FlightProvider flightProvider) {
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
    return Consumer2<SettingsProvider, FlightProvider>(
      builder: (context, settingsProvider, flightProvider, child) {
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
        
        // Analyze NOTAMs for this specific runway to determine real-time status
        final runwayStatus = _analyzeRunwayStatus(identifier, flightProvider);
        
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
          status: runwayStatus.statusText,
          statusColor: runwayStatus.statusColor,
          onTap: runwayStatus.hasNotams ? () => _showRunwayNotams(identifier, runwayStatus.notams) : null,
        );
      },
    );
  }

  Widget _buildNavAidsSection(AirportInfrastructure airportData, FlightProvider flightProvider) {
    debugPrint('DEBUG: _buildNavAidsSection called with airportData: ${airportData?.runtimeType}');
    
    final navaids = airportData.navaids;
    debugPrint('DEBUG: _buildNavAidsSection - Found ${navaids.length} navaids from AirportInfrastructure');
    for (final navaid in navaids) {
      debugPrint('DEBUG: _buildNavAidsSection - Navaid: ${navaid.type} ${navaid.identifier} ${navaid.frequency} (runway: ${navaid.runway})');
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
    // Get dynamic status from NOTAM analysis
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final navaidStatus = _analyzeNavaidStatus(navaid.identifier, navaid.type, flightProvider);
    
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
          // Status badge - now dynamic based on NOTAM analysis with light styling
          GestureDetector(
            onTap: navaidStatus.hasNotams ? () => _showNavaidNotams(navaid.identifier, navaidStatus.notams) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: navaidStatus.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: navaidStatus.statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                navaidStatus.statusText,
                style: TextStyle(
                  color: navaidStatus.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build general navaid item with column layout
  Widget _buildGeneralNavaidItem(Navaid navaid) {
    // Get dynamic status from NOTAM analysis
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final navaidStatus = _analyzeNavaidStatus(navaid.identifier, navaid.type, flightProvider);
    
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
      status: navaidStatus.statusText,
      statusColor: navaidStatus.statusColor,
    );
  }

  Widget _buildLightingSection(AirportInfrastructure airportData, FlightProvider flightProvider) {
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
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        // Analyze NOTAMs for this runway end's lighting to determine real-time status
        final lightingStatus = _analyzeLightingStatus(runwayEnd, lights, flightProvider);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Runway end heading (just the text, no status)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 2.0, left: 0, right: 16.0),
                child: Text(
                  'RWY $runwayEnd',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Lighting types row with right-aligned status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  children: [
                    // Lighting components on the left
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: lights.map((light) => _buildLightingChip(light, runwayEnd, flightProvider)).toList(),
                      ),
                    ),
                    // Status indicator on the right
                    GestureDetector(
                      onTap: lightingStatus.hasNotams ? () => _showLightingNotams(runwayEnd, lightingStatus.notams) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightingStatus.statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: lightingStatus.statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          lightingStatus.statusText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: lightingStatus.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual lighting chip with status-based coloring
  Widget _buildLightingChip(Lighting light, String runwayEnd, FlightProvider flightProvider) {
    // Analyze individual lighting component status
    final componentStatus = _analyzeIndividualLightingStatus(light, runwayEnd, flightProvider);
    
    // Determine colors based on status
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    switch (componentStatus) {
      case 'unserviceable':
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
        textColor = Colors.red[800]!;
        break;
      case 'limited':
        backgroundColor = Colors.orange[100]!;
        borderColor = Colors.orange;
        textColor = Colors.orange[800]!;
        break;
      case 'operational':
      default:
        backgroundColor = Colors.grey[100]!;
        borderColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        light.description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
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
    VoidCallback? onTap,
  }) {
    Widget content = Padding(
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

    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Analyze runway status based on NOTAMs
  RunwayStatusInfo _analyzeRunwayStatus(String runwayId, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific runway
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract runway-specific NOTAMs from the grouped results
    final runwayGroupNotams = groupedNotams[NotamGroup.runways] ?? [];
    final runwayNotams = _getRunwayNotams(runwayId, runwayGroupNotams);
    
    if (runwayNotams.isEmpty) {
      return RunwayStatusInfo(
        statusText: 'Operational',
        statusColor: Colors.green,
        hasNotams: false,
        notams: [],
      );
    }

    // Use our enhanced Q-code analysis
    final systemAnalyzer = AirportSystemAnalyzer();
    final status = systemAnalyzer.analyzeRunwayStatus(runwayNotams, widget.icao);
    
    // Determine status text and color based on Q-code analysis
    String statusText;
    Color statusColor;
    
    switch (status) {
      case SystemStatus.red:
        statusText = 'Closed';
        statusColor = Colors.red;
        break;
      case SystemStatus.yellow:
        statusText = 'Limited';
        statusColor = Colors.orange;
        break;
      case SystemStatus.green:
        statusText = 'Operational';
        statusColor = Colors.green;
        break;
    }

    return RunwayStatusInfo(
      statusText: statusText,
      statusColor: statusColor,
      hasNotams: runwayNotams.isNotEmpty,
      notams: runwayNotams,
    );
  }

  /// Get NOTAMs that affect a specific runway
  List<Notam> _getRunwayNotams(String runwayId, List<Notam> notams) {
    return notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      
      // Check for runway-specific NOTAMs
      return text.contains('RWY $runwayId') || 
             text.contains('RUNWAY $runwayId') ||
             text.contains('RWY ${runwayId.split('/')[0]}') ||
             text.contains('RWY ${runwayId.split('/')[1]}');
    }).toList();
  }



  /// Show runway NOTAMs in a modal
  void _showRunwayNotams(String runwayId, List<Notam> notams) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NOTAMs for Runway $runwayId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notams.length,
                itemBuilder: (context, index) {
                  final notam = notams[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(notam.rawText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: notam.rawText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('NOTAM copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy NOTAM text',
                          ),
                        ],
                      ),
                      subtitle: notam.qCode != null 
                        ? Row(
                            children: [
                              Expanded(
                                child: Text('Q-Code: ${notam.qCode}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: notam.qCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Q-Code copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy Q-Code',
                              ),
                            ],
                          )
                        : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced NAVAID item with NOTAM-based status
  Widget _buildEnhancedNavaidItem(dynamic navaid, String? runwayId) {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        if (navaid is! Navaid) {
          return _buildFacilityItem(
            name: 'Navaid ${navaid.toString()}',
            details: '',
            status: 'Operational',
            statusColor: Colors.green,
          );
        }

        final identifier = navaid.identifier;
        final frequency = navaid.frequency;
        final type = navaid.type;
        
        // Analyze NOTAMs for this specific NAVAID to determine real-time status
        final navaidStatus = _analyzeNavaidStatus(identifier, type, flightProvider);
        
        // Build the name with frequency and runway association
        String name = '$type $identifier';
        if (frequency != null && frequency.isNotEmpty) {
          name += ' ($frequency)';
        }
        if (runwayId != null) {
          name += ' (RWY $runwayId)';
        }

        return _buildFacilityItem(
          name: name,
          details: '',
          status: navaidStatus.statusText,
          statusColor: navaidStatus.statusColor,
          onTap: navaidStatus.hasNotams ? () => _showNavaidNotams(identifier, navaidStatus.notams) : null,
        );
      },
    );
  }

  /// Analyze NAVAID status based on NOTAMs
  NavaidStatusInfo _analyzeNavaidStatus(String navaidId, String navaidType, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific NAVAID
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract NAVAID-specific NOTAMs from the grouped results
    final navaidGroupNotams = groupedNotams[NotamGroup.instrumentProcedures] ?? [];
    final navaidNotams = _getNavaidNotams(navaidId, navaidType, navaidGroupNotams);
    
    if (navaidNotams.isEmpty) {
      return NavaidStatusInfo(
        statusText: 'Operational',
        statusColor: Colors.green,
        hasNotams: false,
        notams: [],
      );
    }

    // Use our enhanced Q-code analysis
    final systemAnalyzer = AirportSystemAnalyzer();
    final status = systemAnalyzer.analyzeNavaidStatus(navaidNotams, widget.icao);
    
    // Determine status text and color based on Q-code analysis
    String statusText;
    Color statusColor;
    
    switch (status) {
      case SystemStatus.red:
        statusText = 'Unserviceable';
        statusColor = Colors.red;
        break;
      case SystemStatus.yellow:
        statusText = 'Limited';
        statusColor = Colors.orange;
        break;
      case SystemStatus.green:
        statusText = 'Operational';
        statusColor = Colors.green;
        break;
    }

    return NavaidStatusInfo(
      statusText: statusText,
      statusColor: statusColor,
      hasNotams: navaidNotams.isNotEmpty,
      notams: navaidNotams,
    );
  }

  /// Get NOTAMs that affect a specific NAVAID
  List<Notam> _getNavaidNotams(String navaidId, String navaidType, List<Notam> notams) {
    return notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      final navaidIdUpper = navaidId.toUpperCase();
      final navaidTypeUpper = navaidType.toUpperCase();
      
      // Check for NAVAID-specific NOTAMs with more precise matching
      // Look for the specific NAVAID identifier (e.g., "IPN", "IGD", "IPH")
      if (text.contains(navaidIdUpper)) {
        return true;
      }
      
      // For ILS systems, check for the specific identifier in quotes or after "ILS"
      if (navaidTypeUpper.contains('ILS')) {
        // Look for patterns like "ILS 'IPN'", "ILS 'IGD'", etc.
        if (text.contains("ILS '$navaidIdUpper'") || 
            text.contains("ILS $navaidIdUpper") ||
            text.contains("'$navaidIdUpper'")) {
          return true;
        }
        
        // Also check if the NOTAM mentions the specific runway this ILS serves
        // This helps catch runway-specific ILS NOTAMs
        if (text.contains('RWY') && text.contains('ILS')) {
          return true;
        }
      }
      
      if (navaidTypeUpper.contains('VOR') && text.contains('VOR')) {
        return true;
      }
      
      if (navaidTypeUpper.contains('DME') && text.contains('DME')) {
        return true;
      }
      
      return false;
    }).toList();
  }

  /// Show NAVAID NOTAMs in a modal
  void _showNavaidNotams(String navaidId, List<Notam> notams) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NOTAMs for $navaidId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notams.length,
                itemBuilder: (context, index) {
                  final notam = notams[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notam.rawText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: notam.rawText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('NOTAM copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy NOTAM text',
                          ),
                        ],
                      ),
                      subtitle: notam.qCode != null 
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Q-Code: ${notam.qCode}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: notam.qCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Q-Code copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy Q-Code',
                              ),
                            ],
                          )
                        : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Analyze lighting status based on NOTAMs
  LightingStatusInfo _analyzeLightingStatus(String runwayEnd, List<Lighting> lights, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific runway end's lighting
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract lighting-specific NOTAMs from the grouped results
    // Note: Some lighting NOTAMs might be in airportServices group
    final lightingGroupNotams = (groupedNotams[NotamGroup.airportServices] ?? []) + 
                                (groupedNotams[NotamGroup.runways] ?? []);
    final lightingNotams = _getLightingNotams(runwayEnd, lightingGroupNotams);
    
    if (lightingNotams.isEmpty) {
      return LightingStatusInfo(
        statusText: 'Operational',
        statusColor: Colors.green,
        hasNotams: false,
        notams: [],
      );
    }

    // NEW APPROACH: Derive overall status from individual component statuses
    // This ensures consistency between overall status and individual component statuses
    String mostSevereComponentStatus = 'operational';
    
    for (final light in lights) {
      final componentStatus = _analyzeIndividualLightingStatus(light, runwayEnd, flightProvider);
      
      // Determine severity hierarchy: unserviceable > limited > operational
      if (componentStatus == 'unserviceable') {
        mostSevereComponentStatus = 'unserviceable';
        break; // Can't get more severe than unserviceable
      } else if (componentStatus == 'limited' && mostSevereComponentStatus == 'operational') {
        mostSevereComponentStatus = 'limited';
      }
    }
    
    // Map component status to overall status
    String statusText;
    Color statusColor;
    
    switch (mostSevereComponentStatus) {
      case 'unserviceable':
        statusText = 'Unserviceable';
        statusColor = Colors.red;
        break;
      case 'limited':
        statusText = 'Limited';
        statusColor = Colors.orange;
        break;
      case 'operational':
      default:
        statusText = 'Operational';
        statusColor = Colors.green;
        break;
    }

    return LightingStatusInfo(
      statusText: statusText,
      statusColor: statusColor,
      hasNotams: lightingNotams.isNotEmpty,
      notams: lightingNotams,
    );
  }

  /// Get NOTAMs that affect lighting for a specific runway end
  List<Notam> _getLightingNotams(String runwayEnd, List<Notam> notams) {
    return notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      final runwayEndUpper = runwayEnd.toUpperCase();
      
      // Check if the NOTAM mentions this specific runway end
      return text.contains('RWY $runwayEndUpper') || 
             text.contains('RUNWAY $runwayEndUpper') ||
             text.contains(runwayEndUpper);
    }).toList();
  }

  /// Analyze individual lighting component status based on NOTAMs
  String _analyzeIndividualLightingStatus(Lighting light, String runwayEnd, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific runway end's lighting
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract lighting-specific NOTAMs from the grouped results
    final lightingGroupNotams = (groupedNotams[NotamGroup.airportServices] ?? []) + 
                                (groupedNotams[NotamGroup.runways] ?? []);
    
    // Look for NOTAMs that specifically mention this lighting component
    final componentNotams = lightingGroupNotams.where((notam) {
      final text = notam.rawText.toUpperCase();
      final runwayEndUpper = runwayEnd.toUpperCase();
      
      // Check if NOTAM mentions this specific runway end
      final mentionsRunway = text.contains('RWY $runwayEndUpper') || 
                            text.contains('RUNWAY $runwayEndUpper') ||
                            text.contains(runwayEndUpper);
      
      if (!mentionsRunway) return false;
      
      // Check if NOTAM mentions this specific lighting type (using expanded search terms)
      return _doesNotamMentionLightingType(text, light.type);
    }).toList();
    
    if (componentNotams.isEmpty) {
      return 'operational';
    }
    
    // Find the most severe status among all relevant NOTAMs for this specific component
    String mostSevereStatus = 'operational';
    
    for (final notam in componentNotams) {
      final componentStatus = _getComponentStatusFromNotam(notam, light.type);
      
      // Determine severity hierarchy: unserviceable > limited > operational
      if (componentStatus == 'unserviceable') {
        mostSevereStatus = 'unserviceable';
        break; // Can't get more severe than unserviceable
      } else if (componentStatus == 'limited' && mostSevereStatus == 'operational') {
        mostSevereStatus = 'limited';
      }
    }
    
    return mostSevereStatus;
  }

  /// Check if NOTAM text mentions a specific lighting type (handles abbreviations vs full descriptions)
  bool _doesNotamMentionLightingType(String notamText, String lightingType) {
    final text = notamText.toUpperCase();
    final type = lightingType.toUpperCase();
    
    // Direct match first
    if (text.contains(type)) return true;
    
    // Handle common lighting type abbreviations and their full NOTAM descriptions
    switch (type) {
      case 'HIAL':
        return text.contains('HIGH INTENSITY APPROACH LGT') || 
               text.contains('HIGH INTENSITY APPROACH LIGHTING') ||
               text.contains('APPROACH LGT') ||
               text.contains('APPROACH LIGHTING');
      case 'HIRL':
        return text.contains('HIGH INTENSITY RUNWAY LGT') || 
               text.contains('HIGH INTENSITY RUNWAY LIGHTING') ||
               text.contains('RUNWAY LGT') ||
               text.contains('RUNWAY LIGHTING');
      case 'MIRL':
        return text.contains('MEDIUM INTENSITY RUNWAY LGT') || 
               text.contains('MEDIUM INTENSITY RUNWAY LIGHTING') ||
               text.contains('RUNWAY LGT') ||
               text.contains('RUNWAY LIGHTING');
      case 'PAPI':
        return text.contains('PAPI') || 
               text.contains('PRECISION APPROACH PATH INDICATOR') ||
               text.contains('APPROACH PATH INDICATOR');
      case 'RCLL':
        return text.contains('RCLL') || 
               text.contains('RUNWAY CENTERLINE LGT') ||
               text.contains('RUNWAY CENTERLINE LIGHTING') ||
               text.contains('CENTERLINE LGT') ||
               text.contains('CENTERLINE LIGHTING');
      case 'RTZL':
        return text.contains('RTZL') || 
               text.contains('RUNWAY TOUCHDOWN ZONE LGT') ||
               text.contains('RUNWAY TOUCHDOWN ZONE LIGHTING') ||
               text.contains('TOUCHDOWN ZONE LGT') ||
               text.contains('TOUCHDOWN ZONE LIGHTING');
      case 'RTIL':
        return text.contains('RTIL') || 
               text.contains('RUNWAY THRESHOLD IDENTIFICATION LGT') ||
               text.contains('RUNWAY THRESHOLD IDENTIFICATION LIGHTING') ||
               text.contains('THRESHOLD IDENTIFICATION LGT') ||
               text.contains('THRESHOLD IDENTIFICATION LIGHTING');
      default:
        // For any other lighting types, try both the abbreviation and common variations
        return text.contains(type) ||
               text.contains(type.replaceAll('/', ' ')) ||
               text.contains(type.replaceAll('_', ' '));
    }
  }

  /// Get the specific status for a lighting component from a NOTAM
  String _getComponentStatusFromNotam(Notam notam, String lightingType) {
    final text = notam.rawText.toUpperCase();
    final type = lightingType.toUpperCase();
    
    // Check if this NOTAM specifically mentions this lighting component
    if (!_doesNotamMentionLightingType(text, type)) {
      return 'operational'; // Component not mentioned in this NOTAM
    }
    
    // Determine status based on Q-code analysis
    if (notam.qCode != null && notam.qCode!.isNotEmpty) {
      final qCode = notam.qCode!.toUpperCase();
      
      // Extract status identifier (4th and 5th letters) and map to our status
      if (qCode.length >= 5) {
        final status = qCode.substring(3, 5);
        
        switch (status) {
          // RED Status - Facility is unusable
          case 'LC': return 'unserviceable'; // QMRLC = Runway Closed
          case 'AS': return 'unserviceable'; // QICAS = ILS Unserviceable
          case 'CC': return 'unserviceable'; // QFACC = Facility Closed
          case 'UC': return 'unserviceable'; // QICUC = Instrument Unserviceable
          
          // YELLOW Status - Facility has operational limitations
          case 'LT': return 'limited';       // QMRLT = Runway Limited
          case 'MT': return 'limited';       // QMRMT = Runway Maintenance
          case 'DP': return 'limited';       // QMRDP = Runway Displaced Threshold
          case 'RD': return 'limited';       // QMRRD = Runway Reduced
          case 'LM': return 'limited';       // QICLM = ILS Limited
          case 'MM': return 'limited';       // QICMM = ILS Maintenance
          case 'LR': return 'limited';       // QOLR = Lighting Limited
          case 'MR': return 'limited';       // QOLMR = Lighting Maintenance
          case 'CR': return 'limited';       // QFACR = Facility Reduced
          case 'CM': return 'limited';       // QFACM = Facility Maintenance
          
          // GREEN Status - No operational impact
          case 'OP': return 'operational';   // QMROP = Runway Operational
          case 'AC': return 'operational';   // QICAC = ILS Active
          case 'OK': return 'operational';   // QFAOK = Facility Operational
          
          // Default to unknown for unmapped status codes
          default: return 'operational';
        }
      }
    }
    
    // Fallback: analyze text for status indicators
    if (text.contains('U/S') || text.contains('UNSERVICEABLE') || text.contains('CLOSED')) {
      return 'unserviceable';
    } else if (text.contains('LIMITED') || text.contains('RESTRICTED') || text.contains('DUE WIP')) {
      return 'limited';
    }
    
    return 'operational';
  }

  /// Show lighting NOTAMs in a modal
  void _showLightingNotams(String runwayEnd, List<Notam> notams) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NOTAMs for RWY $runwayEnd Lighting',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: notams.length,
                itemBuilder: (context, index) {
                  final notam = notams[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notam.rawText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: notam.rawText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('NOTAM copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy NOTAM text',
                          ),
                        ],
                      ),
                      subtitle: notam.qCode != null 
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Q-Code: ${notam.qCode}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: notam.qCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Q-Code copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy Q-Code',
                              ),
                            ],
                          )
                        : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for runway status information
class RunwayStatusInfo {
  final String statusText;
  final Color statusColor;
  final bool hasNotams;
  final List<Notam> notams;

  RunwayStatusInfo({
    required this.statusText,
    required this.statusColor,
    required this.hasNotams,
    required this.notams,
  });
}

/// Data class for NAVAID status information
class NavaidStatusInfo {
  final String statusText;
  final Color statusColor;
  final bool hasNotams;
  final List<Notam> notams;

  NavaidStatusInfo({
    required this.statusText,
    required this.statusColor,
    required this.hasNotams,
    required this.notams,
  });
}

/// Data class for lighting status information
class LightingStatusInfo {
  final String statusText;
  final Color statusColor;
  final bool hasNotams;
  final List<Notam> notams;

  LightingStatusInfo({
    required this.statusText,
    required this.statusColor,
    required this.hasNotams,
    required this.notams,
  });
} 