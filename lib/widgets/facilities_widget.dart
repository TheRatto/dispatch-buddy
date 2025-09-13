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
    return Consumer<FlightProvider>(
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
    final runways = airportData.runways;
    debugPrint('DEBUG: FacilitiesWidget - Runway data received: ${runways.length} runways');
    
    for (int i = 0; i < runways.length; i++) {
      final runway = runways[i];
      debugPrint('DEBUG: FacilitiesWidget - Runway $i: $runway');
    }

    // Group runways into pairs (e.g., 03/21, 06/24)
    final List<dynamic> runwayPairs = [];
    final Set<String> processedRunways = {};

    for (final runway in runways) {
      
      final identifier = runway.identifier;
      if (processedRunways.contains(identifier)) continue;

      // Try to find the opposite runway (e.g., if we have 03, look for 21)
      final oppositeIdentifier = _getOppositeRunwayEnd(identifier);
      Runway? oppositeRunway;
      try {
        oppositeRunway = runways.where((r) => r.identifier == oppositeIdentifier).first;
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

  
  /// Build a facility item with enhanced runway formatting
  Widget _buildEnhancedRunwayItem(dynamic runway) {
    return Consumer2<SettingsProvider, FlightProvider>(
      builder: (context, settingsProvider, flightProvider, child) {
        
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
        
        return LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we have enough space for horizontal layout
            final screenWidth = MediaQuery.of(context).size.width;
            final isCompact = screenWidth < 400; // iPhone 16 Pro is ~393px wide
            
            if (isCompact) {
              // Compact layout: Prioritize runway identifier and length, minimize surface info
              return _buildFacilityItem(
                name: Row(
                  children: [
                    // Runway identifier - give it more space
                    Expanded(
                      flex: 2,
                      child: Text(
                        identifier,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Length - give it more space
                    Expanded(
                      flex: 2,
                      child: Text(
                        formattedLength.isNotEmpty ? '$formattedLength $unitSymbol' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Width - minimal space
                    if (formattedWidth.isNotEmpty)
                      Text(
                        '$formattedWidth m',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    const SizedBox(width: 4),
                    // Surface - minimal space, abbreviated if needed
                    if (surface != 'Unknown')
                      Text(
                        surface.length > 8 ? surface.substring(0, 8) : surface,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                details: '',
                status: runwayStatus.statusText,
                statusColor: runwayStatus.statusColor,
                onTap: runwayStatus.hasNotams ? () => _showRunwayNotams(identifier, runwayStatus.notams) : null,
              );
            } else {
              // Standard layout: Use responsive column widths with priority for runway info
              final availableWidth = constraints.maxWidth - 100; // Reserve space for status badge
              final identifierWidth = (availableWidth * 0.3).clamp(70.0, 90.0); // Prioritize runway identifier
              final lengthWidth = (availableWidth * 0.3).clamp(70.0, 90.0); // Prioritize length
              final widthWidth = (availableWidth * 0.2).clamp(40.0, 60.0);
              final surfaceWidth = (availableWidth * 0.2).clamp(50.0, 70.0); // Reduce surface width
              
              return _buildFacilityItem(
                name: Row(
                  children: [
                    // Runway identifier - responsive width
                    SizedBox(
                      width: identifierWidth,
                      child: Text(
                        identifier,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Length - responsive width
                    SizedBox(
                      width: lengthWidth,
                      child: Text(
                        formattedLength.isNotEmpty ? '$formattedLength $unitSymbol' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Width - responsive width (always in meters)
                    SizedBox(
                      width: widthWidth,
                      child: Text(
                        formattedWidth.isNotEmpty ? '$formattedWidth m' : '',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Surface - responsive width
                    SizedBox(
                      width: surfaceWidth,
                      child: Text(
                        surface != 'Unknown' ? surface : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                details: '',
                status: runwayStatus.statusText,
                statusColor: runwayStatus.statusColor,
                onTap: runwayStatus.hasNotams ? () => _showRunwayNotams(identifier, runwayStatus.notams) : null,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildNavAidsSection(AirportInfrastructure airportData, FlightProvider flightProvider) {
    debugPrint('DEBUG: _buildNavAidsSection called with airportData: ${airportData.runtimeType}');
    
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isCompact = screenWidth < 400;
          
          if (isCompact) {
            // Compact layout: Prioritize type and identifier, minimize frequency
            return Row(
              children: [
                // Type - more space for type
                Expanded(
                  flex: 2,
                  child: Text(
                    navaid.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Identifier - give it more space
                Expanded(
                  flex: 2,
                  child: Text(
                    navaid.identifier,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Frequency - minimal space
                SizedBox(
                  width: 50,
                  child: Text(
                    navaid.frequency,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Status badge
                GestureDetector(
                  onTap: navaidStatus.hasNotams ? () => _showNavaidNotams(navaid.identifier, navaidStatus.notams) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: navaidStatus.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: navaidStatus.statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      navaidStatus.statusText,
                      style: TextStyle(
                        color: navaidStatus.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Standard layout: Use responsive column widths with priority for important info
            final availableWidth = constraints.maxWidth - 100; // Reserve space for status badge
            final typeWidth = (availableWidth * 0.3).clamp(60.0, 90.0); // More space for type
            final identifierWidth = (availableWidth * 0.3).clamp(60.0, 90.0); // Prioritize identifier
            final frequencyWidth = (availableWidth * 0.2).clamp(50.0, 80.0); // Less space for frequency
            
            return Row(
              children: [
                // Type - responsive width
                SizedBox(
                  width: typeWidth,
                  child: Text(
                    navaid.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Identifier - responsive width
                SizedBox(
                  width: identifierWidth,
                  child: Text(
                    navaid.identifier,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Frequency - responsive width
                SizedBox(
                  width: frequencyWidth,
                  child: Text(
                    navaid.frequency,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
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
            );
          }
        },
      ),
    );
  }
  
  /// Build general navaid item with column layout
  Widget _buildGeneralNavaidItem(Navaid navaid) {
    // Get dynamic status from NOTAM analysis
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final navaidStatus = _analyzeNavaidStatus(navaid.identifier, navaid.type, flightProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 400;
        
        if (isCompact) {
          // Compact layout: Prioritize type and identifier, minimize frequency
          return _buildFacilityItem(
            name: Row(
              children: [
                // Type - more space for type
                Expanded(
                  flex: 2,
                  child: Text(
                    navaid.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Identifier - give it more space
                Expanded(
                  flex: 2,
                  child: Text(
                    navaid.identifier,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Frequency - minimal space
                SizedBox(
                  width: 50,
                  child: Text(
                    navaid.frequency,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            details: '',
            status: navaidStatus.statusText,
            statusColor: navaidStatus.statusColor,
          );
        } else {
          // Standard layout: Use responsive column widths with priority for important info
          final availableWidth = constraints.maxWidth - 100; // Reserve space for status badge
          final typeWidth = (availableWidth * 0.3).clamp(60.0, 90.0); // More space for type
          final identifierWidth = (availableWidth * 0.3).clamp(60.0, 90.0); // Prioritize identifier
          final frequencyWidth = (availableWidth * 0.2).clamp(50.0, 80.0); // Less space for frequency
          
          return _buildFacilityItem(
            name: Row(
              children: [
                // Type - responsive width
                SizedBox(
                  width: typeWidth,
                  child: Text(
                    navaid.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Identifier - responsive width
                SizedBox(
                  width: identifierWidth,
                  child: Text(
                    navaid.identifier,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Frequency - responsive width
                SizedBox(
                  width: frequencyWidth,
                  child: Text(
                    navaid.frequency,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            details: '',
            status: navaidStatus.statusText,
            statusColor: navaidStatus.statusColor,
          );
        }
      },
    );
  }

  Widget _buildLightingSection(AirportInfrastructure airportData, FlightProvider flightProvider) {
    final lighting = airportData.lighting;
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

  /// Get NOTAMs that affect a specific runway using two-stage filtering
  List<Notam> _getRunwayNotams(String runwayId, List<Notam> notams) {
    debugPrint('DEBUG: _getRunwayNotams called for $runwayId with ${notams.length} NOTAMs');
    
    final result = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      
      // Stage 1: Is this a runway-related NOTAM?
      if (!_isRunwayNotam(text)) {
        return false;
      }
      
      // Stage 2: Does this specific NOTAM affect our specific runway?
      return _doesNotamAffectRunway(text, runwayId);
    }).toList();
    
    debugPrint('DEBUG: _getRunwayNotams returning ${result.length} NOTAMs for $runwayId');
    return result;
  }

  /// Stage 1: Check if NOTAM is related to runways
  bool _isRunwayNotam(String notamText) {
    return notamText.contains('RWY') || 
           notamText.contains('RUNWAY') ||
           notamText.contains('TAXIWAY') ||
           notamText.contains('TWY') ||
           notamText.contains('APRON') ||
           notamText.contains('MOVEMENT AREA') ||
           notamText.contains('WIP'); // Work in Progress often affects runways
  }

  /// Stage 2: Check if this specific NOTAM affects our specific runway
  bool _doesNotamAffectRunway(String notamText, String runwayId) {
    final runwayIdUpper = runwayId.toUpperCase();
    
    // Extract runway identifiers from the NOTAM text
    final extractedRunways = _extractRunwayIdentifiers(notamText);
    
    // Check if any extracted runway matches our runway
    for (final extractedRunway in extractedRunways) {
      if (extractedRunway == runwayIdUpper) {
        debugPrint('DEBUG: Extracted runway match for $runwayIdUpper in: $notamText');
        return true;
      }
    }
    
    // Also check for direct mentions with common patterns
    if (notamText.contains('RWY $runwayIdUpper') || 
        notamText.contains('RUNWAY $runwayIdUpper')) {
      debugPrint('DEBUG: Direct runway mention for $runwayIdUpper in: $notamText');
      return true;
    }
    
    return false;
  }

  /// Extract runway identifiers from NOTAM text
  List<String> _extractRunwayIdentifiers(String notamText) {
    final runways = <String>[];
    
    // Pattern 1: "RWY 16L/34R" or "RWY 16L" or "RUNWAY 16L/34R"
    final pattern1 = RegExp(r'(RWY|RUNWAY)\s+([0-9]{2}[LRC]?/[0-9]{2}[LRC]?|[0-9]{2}[LRC]?)');
    final matches1 = pattern1.allMatches(notamText);
    for (final match in matches1) {
      final runway = match.group(2)!;
      runways.add(runway);
      
      // If it's a dual runway (e.g., "16L/34R"), also add individual runways
      if (runway.contains('/')) {
        final parts = runway.split('/');
        runways.add(parts[0]);
        runways.add(parts[1]);
      }
    }
    
    // Pattern 2: Standalone runway mentions "16L", "34R", etc.
    final pattern2 = RegExp(r'\b([0-9]{2}[LRC]?)\b');
    final matches2 = pattern2.allMatches(notamText);
    for (final match in matches2) {
      final runway = match.group(1)!;
      // Only add if it looks like a runway (2 digits, optionally followed by L/R/C)
      if (runway.length >= 2 && runway.length <= 3) {
        runways.add(runway);
      }
    }
    
    debugPrint('DEBUG: Extracted runways from "$notamText": $runways');
    return runways;
  }



  /// Show runway NOTAMs in a modal
  void _showRunwayNotams(String runwayId, List<Notam> notams) {
    if (notams.isEmpty) {
      showDialog(
      context: context,
        builder: (context) => AlertDialog(
          title: Text('NOTAMs for Runway $runwayId'),
          content: const Text('No NOTAMs affecting this runway'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (notams.length == 1) {
      // Single NOTAM - show directly
      _showNotamDetail(notams.first);
    } else {
      // Multiple NOTAMs - show with swipe functionality
      _showNotamSwipeView(notams, 'Runway $runwayId');
    }
  }

  /// Show multiple NOTAMs with swipe functionality
  void _showNotamSwipeView(List<Notam> notams, String title) {
    showDialog(
      context: context,
      builder: (context) => NotamSwipeView(
        notams: notams,
        title: title,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show detailed NOTAM information
  void _showNotamDetail(Notam notam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'NOTAM ${notam.id}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(notam.group),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryLabel(notam.group),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              // Validity Section (Prominent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Absolute validity times
                    Text(
                      'Valid: ${_formatDateTime(notam.validFrom)} - ${notam.isPermanent ? 'PERM' : '${_formatDateTime(notam.validTo)} UTC'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Relative status + countdown - match raw data page styling
                    Row(
                      children: [
                        // Left side: Start time or Active status (orange)
                        Expanded(
                          child: Text(
                            _getLeftSideText(notam),
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFF59E0B), // Orange to match list view
                              fontWeight: FontWeight.w400, // No bold
                            ),
                          ),
                        ),
                        // Right side: End time (green)
                        Text(
                          _getRightSideText(notam),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600, // Green to match list view
                            fontWeight: FontWeight.w400, // No bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Schedule Information (Field D) - only show if present
              if (notam.fieldD.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Schedule: ${notam.fieldD}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // NOTAM Text (Main Content) - Field E + Altitude Info (Fields F & G)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main NOTAM text (Field E)
                    Text(
                      notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    
                    // Altitude information (Fields F & G) - only show if present
                    if (notam.fieldF.isNotEmpty || notam.fieldG.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatAltitudeInfo(notam.fieldF, notam.fieldG),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Metadata Footer (Single line, small, muted)
              Text(
                'Q: ${notam.qCode ?? 'N/A'} • Type: ${notam.type.name} • Group: ${notam.group.name}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.day.toString().padLeft(2, '0')}/${utc.month.toString().padLeft(2, '0')} ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}Z';
  }

  String _getLeftSideText(Notam notam) {
    final now = DateTime.now().toUtc();
    final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
    final isFutureActive = notam.validFrom.isAfter(now);

    if (isCurrentlyActive) {
      return 'Active';
    } else if (isFutureActive) {
      final timeUntilStart = notam.validFrom.difference(now);
      if (timeUntilStart.inDays > 0) {
        return 'Starts in ${timeUntilStart.inDays}d ${timeUntilStart.inHours % 24}h';
      } else if (timeUntilStart.inHours > 0) {
        return 'Starts in ${timeUntilStart.inHours}h ${timeUntilStart.inMinutes % 60}m';
      } else if (timeUntilStart.inMinutes > 0) {
        return 'Starts in ${timeUntilStart.inMinutes}m';
      } else {
        return 'Starts soon';
      }
    } else {
      final timeSinceExpiry = now.difference(notam.validTo);
      if (timeSinceExpiry.inDays > 0) {
        return 'Expired ${timeSinceExpiry.inDays}d ${timeSinceExpiry.inHours % 24}h ago';
      } else if (timeSinceExpiry.inHours > 0) {
        return 'Expired ${timeSinceExpiry.inHours}h ${timeSinceExpiry.inMinutes % 60}m ago';
      } else if (timeSinceExpiry.inMinutes > 0) {
        return 'Expired ${timeSinceExpiry.inMinutes}m ago';
      } else {
        return 'Expired just now';
      }
    }
  }

  String _getRightSideText(Notam notam) {
    // Check if this is a permanent NOTAM
    if (notam.isPermanent) {
      return 'PERM';
    }
    
    final now = DateTime.now().toUtc();
    final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
    final isFutureActive = notam.validFrom.isAfter(now);

    if (isCurrentlyActive) {
      final timeUntilEnd = notam.validTo.difference(now);
      if (timeUntilEnd.inDays > 0) {
        return 'Ends in ${timeUntilEnd.inDays}d ${timeUntilEnd.inHours % 24}h';
      } else if (timeUntilEnd.inHours > 0) {
        return 'Ends in ${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m';
      } else if (timeUntilEnd.inMinutes > 0) {
        return 'Ends in ${timeUntilEnd.inMinutes}m';
      } else {
        return 'Ends soon';
      }
    } else if (isFutureActive) {
      final timeUntilEnd = notam.validTo.difference(now);
      if (timeUntilEnd.inDays > 0) {
        return 'Ends in ${timeUntilEnd.inDays}d ${timeUntilEnd.inHours % 24}h';
      } else if (timeUntilEnd.inHours > 0) {
        return 'Ends in ${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m';
      } else if (timeUntilEnd.inMinutes > 0) {
        return 'Ends in ${timeUntilEnd.inMinutes}m';
      } else {
        return 'Ends soon';
      }
    } else {
      return ''; // No end time for expired NOTAMs
    }
  }

  String _formatAltitudeInfo(String fieldF, String fieldG) {
    if (fieldF.isNotEmpty && fieldG.isNotEmpty) {
      return '$fieldF TO $fieldG';
    } else if (fieldF.isNotEmpty) {
      return fieldF;
    } else if (fieldG.isNotEmpty) {
      return fieldG;
    }
    return '';
  }

  Color _getCategoryColor(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return Colors.red;
      case NotamGroup.instrumentProcedures:
        return Colors.blue;
      case NotamGroup.lighting:
        return Colors.yellow.shade700;
      case NotamGroup.hazards:
        return Colors.orange;
      case NotamGroup.other:
        return Colors.grey;
      case NotamGroup.admin:
        return Colors.purple;
      case NotamGroup.taxiways:
        return Colors.cyan;
      case NotamGroup.airportServices:
        return Colors.teal;
    }
  }

  String _getCategoryLabel(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return 'RWY';
      case NotamGroup.instrumentProcedures:
        return 'NAV';
      case NotamGroup.lighting:
        return 'LGT';
      case NotamGroup.hazards:
        return 'HAZ';
      case NotamGroup.other:
        return 'OTH';
      case NotamGroup.admin:
        return 'ADM';
      case NotamGroup.taxiways:
        return 'TWY';
      case NotamGroup.airportServices:
        return 'SVC';
    }
  }


  /// Analyze NAVAID status based on NOTAMs
  NavaidStatusInfo _analyzeNavaidStatus(String navaidId, String navaidType, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific NAVAID
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    debugPrint('DEBUG: _analyzeNavaidStatus for $navaidId ($navaidType) - ${filteredNotams.length} filtered NOTAMs');
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract NAVAID-specific NOTAMs from the grouped results
    // NAVAID NOTAMs can be in multiple groups, so check all relevant ones
    final navaidGroupNotams = (groupedNotams[NotamGroup.instrumentProcedures] ?? []) +
                              (groupedNotams[NotamGroup.airportServices] ?? []) +
                              (groupedNotams[NotamGroup.runways] ?? []);
    debugPrint('DEBUG: _analyzeNavaidStatus for $navaidId ($navaidType) - ${navaidGroupNotams.length} NAVAID group NOTAMs');
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
        statusText = 'U/S';
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

  /// Get NOTAMs that affect a specific NAVAID using two-stage filtering
  List<Notam> _getNavaidNotams(String navaidId, String navaidType, List<Notam> notams) {
    debugPrint('DEBUG: _getNavaidNotams called for $navaidId ($navaidType) with ${notams.length} NOTAMs');
    
    final result = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      final navaidIdUpper = navaidId.toUpperCase();
      
      // Stage 1: Is this a NAVAID-related NOTAM?
      if (!_isNavaidNotam(text)) {
        return false;
      }
      
      // Stage 2: Does this specific NOTAM affect our specific NAVAID?
      return _doesNotamAffectNavaid(text, navaidIdUpper, navaidType);
    }).toList();
    
    debugPrint('DEBUG: _getNavaidNotams returning ${result.length} NOTAMs for $navaidId ($navaidType)');
    return result;
  }

  /// Stage 1: Check if NOTAM is related to NAVAIDs
  bool _isNavaidNotam(String notamText) {
    return notamText.contains('ILS') || 
           notamText.contains('DME') || 
           notamText.contains('VOR') || 
           notamText.contains('TACAN') || 
           notamText.contains('NDB') ||
           notamText.contains('NAVAID') ||
           notamText.contains('INSTRUMENT');
  }

  /// Stage 2: Check if this specific NOTAM affects our specific NAVAID
  bool _doesNotamAffectNavaid(String notamText, String navaidId, String navaidType) {
    final navaidTypeUpper = navaidType.toUpperCase();
    
    // First check for direct identifier match (highest confidence)
    if (notamText.contains(navaidId)) {
      debugPrint('DEBUG: Direct identifier match for $navaidId in: $notamText');
      return true;
    }
    
    // Extract NAVAID identifiers from the NOTAM text
    final extractedIds = _extractNavaidIdentifiers(notamText, navaidTypeUpper);
    
    // Check if any extracted identifier matches our NAVAID
    for (final extractedId in extractedIds) {
      if (extractedId == navaidId) {
        debugPrint('DEBUG: Extracted identifier match for $navaidId in: $notamText');
        return true;
      }
    }
    
    // Fallback: Check for quoted identifier match
    if (notamText.contains("'$navaidId'")) {
      debugPrint('DEBUG: Quoted identifier match for $navaidId in: $notamText');
      return true;
    }
    
    return false;
  }

  /// Extract NAVAID identifiers from NOTAM text using simple string parsing
  List<String> _extractNavaidIdentifiers(String notamText, String navaidType) {
    final identifiers = <String>[];
    
    // Simple approach: Look for common NAVAID patterns
    final words = notamText.split(' ');
    
    for (int i = 0; i < words.length - 1; i++) {
      final currentWord = words[i];
      final nextWord = words[i + 1];
      
      // Check for "ILS 'ISN'" or "ILS ISN" pattern
      if ((currentWord == 'ILS' || currentWord == 'DME' || currentWord == 'VOR' || 
           currentWord == 'TACAN' || currentWord == 'NDB') &&
          navaidType.contains(currentWord)) {
        
        // Clean the next word (remove quotes, punctuation)
        final cleanId = nextWord.replaceAll(RegExp(r'[^\w]'), '');
        if (cleanId.length >= 2 && cleanId.length <= 4) {
          identifiers.add(cleanId);
        }
      }
      
      // Check for "ILS/DME IKN" pattern
      if ((currentWord == 'ILS/DME' || currentWord == 'VOR/DME' || currentWord == 'ILS/DME/GP') &&
          (navaidType.contains('ILS') || navaidType.contains('DME') || navaidType.contains('VOR'))) {
        
        final cleanId = nextWord.replaceAll(RegExp(r'[^\w]'), '');
        if (cleanId.length >= 2 && cleanId.length <= 4) {
          identifiers.add(cleanId);
        }
      }
    }
    
    // Also look for quoted identifiers
    final quotePattern = RegExp(r"'([A-Z]{2,4})'");
    final matches = quotePattern.allMatches(notamText);
    for (final match in matches) {
      final id = match.group(1)!;
      if (_isLikelyNavaidIdentifier(id)) {
        identifiers.add(id);
      }
    }
    
    debugPrint('DEBUG: Extracted identifiers from "$notamText": $identifiers');
    return identifiers;
  }

  /// Check if a string is likely a NAVAID identifier
  bool _isLikelyNavaidIdentifier(String identifier) {
    // NAVAID identifiers are typically 2-4 letters
    if (identifier.length < 2 || identifier.length > 4) return false;
    
    // Common NAVAID patterns (can be expanded)
    final commonPatterns = [
      'ILS', 'DME', 'VOR', 'TACAN', 'NDB', 'LOC', 'GS', 'GP', 'MB'
    ];
    
    // Check if it matches common patterns
    for (final pattern in commonPatterns) {
      if (identifier.contains(pattern)) return true;
    }
    
    // Check if it's all letters (typical for NAVAID identifiers)
    return RegExp(r'^[A-Z]+$').hasMatch(identifier);
  }

  /// Show NAVAID NOTAMs in a modal
  void _showNavaidNotams(String navaidId, List<Notam> notams) {
    if (notams.isEmpty) {
      showDialog(
      context: context,
        builder: (context) => AlertDialog(
          title: Text('NOTAMs for $navaidId'),
          content: const Text('No NOTAMs affecting this NAVAID'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (notams.length == 1) {
      // Single NOTAM - show directly
      _showNotamDetail(notams.first);
    } else {
      // Multiple NOTAMs - show with swipe functionality
      _showNotamSwipeView(notams, navaidId);
    }
  }

  /// Analyze lighting status based on NOTAMs
  LightingStatusInfo _analyzeLightingStatus(String runwayEnd, List<Lighting> lights, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific runway end's lighting
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract lighting-specific NOTAMs from the grouped results
    // Look in lighting group first, then check runway group for lighting-related NOTAMs
    final lightingGroupNotams = (groupedNotams[NotamGroup.lighting] ?? []) + 
                                (groupedNotams[NotamGroup.airportServices] ?? []);
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
        statusText = 'U/S';
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

  /// Get NOTAMs that affect lighting for a specific runway end using two-stage filtering
  List<Notam> _getLightingNotams(String runwayEnd, List<Notam> notams) {
    debugPrint('DEBUG: _getLightingNotams called for $runwayEnd with ${notams.length} NOTAMs');
    
    final result = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      
      // Stage 1: Is this a lighting-related NOTAM?
      if (!_isLightingNotam(text)) {
        return false;
      }
      
      // Stage 2: Does this specific NOTAM affect our specific runway end's lighting?
      return _doesNotamAffectLighting(text, runwayEnd);
    }).toList();
    
    debugPrint('DEBUG: _getLightingNotams returning ${result.length} NOTAMs for $runwayEnd');
    return result;
  }

  /// Stage 1: Check if NOTAM is related to lighting
  bool _isLightingNotam(String notamText) {
    final lightingKeywords = [
      'LIGHT', 'LGT', 'LIGHTING', 'MIRL', 'HIRL', 'PAPI', 'RCLL', 'RTZL', 'HIAL',
      'APPROACH LIGHT', 'RUNWAY LIGHT', 'TAXIWAY LIGHT', 'EDGE LIGHT',
      'CENTERLINE LIGHT', 'THRESHOLD LIGHT', 'END LIGHT', 'BOUNDARY LIGHT',
      'VISUAL AIDS', 'NAVIGATION AIDS', 'MARKING', 'BEACON'
    ];
    
    return lightingKeywords.any((keyword) => notamText.contains(keyword));
  }

  /// Stage 2: Check if this specific NOTAM affects our specific runway end's lighting
  bool _doesNotamAffectLighting(String notamText, String runwayEnd) {
    final runwayEndUpper = runwayEnd.toUpperCase();
    
    // Extract runway identifiers from the NOTAM text
    final extractedRunways = _extractRunwayIdentifiers(notamText);
    
    // Check if any extracted runway matches our runway end
    for (final extractedRunway in extractedRunways) {
      if (extractedRunway == runwayEndUpper) {
        debugPrint('DEBUG: Lighting NOTAM runway match for $runwayEndUpper in: $notamText');
        return true;
      }
    }
    
    // Also check for direct mentions with common patterns
    if (notamText.contains('RWY $runwayEndUpper') || 
        notamText.contains('RUNWAY $runwayEndUpper') ||
        notamText.contains(runwayEndUpper)) {
      debugPrint('DEBUG: Lighting NOTAM direct runway mention for $runwayEndUpper in: $notamText');
      return true;
    }
    
    return false;
  }

  /// Analyze individual lighting component status based on NOTAMs
  String _analyzeIndividualLightingStatus(Lighting light, String runwayEnd, FlightProvider flightProvider) {
    // Filter NOTAMs for this specific runway end's lighting
    final filteredNotams = flightProvider.filterNotamsByTimeAndAirport(widget.notams, widget.icao);
    
    // Use NotamGroupingService to get properly grouped NOTAMs
    final groupedNotams = _groupingService.groupNotams(filteredNotams);
    
    // Extract lighting-specific NOTAMs from the grouped results
    final lightingGroupNotams = (groupedNotams[NotamGroup.lighting] ?? []) + 
                                (groupedNotams[NotamGroup.airportServices] ?? []);
    
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
    if (notams.isEmpty) {
      showDialog(
      context: context,
        builder: (context) => AlertDialog(
          title: Text('NOTAMs for RWY $runwayEnd Lighting'),
          content: const Text('No NOTAMs affecting this lighting system'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (notams.length == 1) {
      // Single NOTAM - show directly
      _showNotamDetail(notams.first);
    } else {
      // Multiple NOTAMs - show with swipe functionality
      _showNotamSwipeView(notams, 'RWY $runwayEnd Lighting');
    }
  }
}

/// Widget for swiping between multiple NOTAMs
class NotamSwipeView extends StatefulWidget {
  final List<Notam> notams;
  final String title;
  final VoidCallback onClose;

  const NotamSwipeView({
    Key? key,
    required this.notams,
    required this.title,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NotamSwipeView> createState() => _NotamSwipeViewState();
}

class _NotamSwipeViewState extends State<NotamSwipeView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header with title, page indicator, and close button
            Container(
        padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.notams.length > 1)
                          Text(
                            '${_currentIndex + 1} of ${widget.notams.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // PageView for swiping between NOTAMs
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.notams.length,
                itemBuilder: (context, index) {
                  final notam = widget.notams[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildNotamContent(notam),
                  );
                },
              ),
            ),
            
            // Navigation buttons (if multiple NOTAMs)
            if (widget.notams.length > 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      'Swipe to view other NOTAMs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentIndex < widget.notams.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotamContent(Notam notam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NOTAM Header with ID and category badge
        Row(
          children: [
            Expanded(
              child: Text(
                'NOTAM ${notam.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(notam.group),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getCategoryLabel(notam.group),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
                          ),
                        ],
                      ),
        const SizedBox(height: 12),
        
        // Validity Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valid: ${_formatDateTime(notam.validFrom)} - ${notam.isPermanent ? 'PERM' : '${_formatDateTime(notam.validTo)} UTC'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getLeftSideText(notam),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    _getRightSideText(notam),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Schedule Information (if present)
        if (notam.fieldD.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule: ${notam.fieldD}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // NOTAM Text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notam.fieldE.isNotEmpty ? notam.fieldE : notam.rawText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (notam.fieldF.isNotEmpty || notam.fieldG.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _formatAltitudeInfo(notam.fieldF, notam.fieldG),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Metadata Footer
        const SizedBox(height: 8),
        Text(
          'Q: ${notam.qCode ?? 'N/A'} • Type: ${notam.type.name} • Group: ${notam.group.name}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Helper methods (same as in the main widget)
  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return '${utc.day.toString().padLeft(2, '0')}/${utc.month.toString().padLeft(2, '0')} ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}Z';
  }

  String _getLeftSideText(Notam notam) {
    final now = DateTime.now().toUtc();
    final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
    final isFutureActive = notam.validFrom.isAfter(now);

    if (isCurrentlyActive) {
      return 'Active';
    } else if (isFutureActive) {
      final timeUntilStart = notam.validFrom.difference(now);
      if (timeUntilStart.inDays > 0) {
        return 'Starts in ${timeUntilStart.inDays}d ${timeUntilStart.inHours % 24}h';
      } else if (timeUntilStart.inHours > 0) {
        return 'Starts in ${timeUntilStart.inHours}h ${timeUntilStart.inMinutes % 60}m';
      } else if (timeUntilStart.inMinutes > 0) {
        return 'Starts in ${timeUntilStart.inMinutes}m';
      } else {
        return 'Starts soon';
      }
    } else {
      final timeSinceExpiry = now.difference(notam.validTo);
      if (timeSinceExpiry.inDays > 0) {
        return 'Expired ${timeSinceExpiry.inDays}d ${timeSinceExpiry.inHours % 24}h ago';
      } else if (timeSinceExpiry.inHours > 0) {
        return 'Expired ${timeSinceExpiry.inHours}h ${timeSinceExpiry.inMinutes % 60}m ago';
      } else if (timeSinceExpiry.inMinutes > 0) {
        return 'Expired ${timeSinceExpiry.inMinutes}m ago';
      } else {
        return 'Expired just now';
      }
    }
  }

  String _getRightSideText(Notam notam) {
    if (notam.isPermanent) {
      return 'PERM';
    }
    
    final now = DateTime.now().toUtc();
    final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
    final isFutureActive = notam.validFrom.isAfter(now);

    if (isCurrentlyActive) {
      final timeUntilEnd = notam.validTo.difference(now);
      if (timeUntilEnd.inDays > 0) {
        return 'Ends in ${timeUntilEnd.inDays}d ${timeUntilEnd.inHours % 24}h';
      } else if (timeUntilEnd.inHours > 0) {
        return 'Ends in ${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m';
      } else if (timeUntilEnd.inMinutes > 0) {
        return 'Ends in ${timeUntilEnd.inMinutes}m';
      } else {
        return 'Ends soon';
      }
    } else if (isFutureActive) {
      final timeUntilEnd = notam.validTo.difference(now);
      if (timeUntilEnd.inDays > 0) {
        return 'Ends in ${timeUntilEnd.inDays}d ${timeUntilEnd.inHours % 24}h';
      } else if (timeUntilEnd.inHours > 0) {
        return 'Ends in ${timeUntilEnd.inHours}h ${timeUntilEnd.inMinutes % 60}m';
      } else if (timeUntilEnd.inMinutes > 0) {
        return 'Ends in ${timeUntilEnd.inMinutes}m';
      } else {
        return 'Ends soon';
      }
    } else {
      return '';
    }
  }

  String _formatAltitudeInfo(String fieldF, String fieldG) {
    if (fieldF.isNotEmpty && fieldG.isNotEmpty) {
      return '$fieldF TO $fieldG';
    } else if (fieldF.isNotEmpty) {
      return fieldF;
    } else if (fieldG.isNotEmpty) {
      return fieldG;
    }
    return '';
  }

  Color _getCategoryColor(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return Colors.red;
      case NotamGroup.instrumentProcedures:
        return Colors.blue;
      case NotamGroup.lighting:
        return Colors.yellow.shade700;
      case NotamGroup.hazards:
        return Colors.orange;
      case NotamGroup.other:
        return Colors.grey;
      case NotamGroup.admin:
        return Colors.purple;
      case NotamGroup.taxiways:
        return Colors.cyan;
      case NotamGroup.airportServices:
        return Colors.teal;
    }
  }

  String _getCategoryLabel(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return 'RWY';
      case NotamGroup.instrumentProcedures:
        return 'NAV';
      case NotamGroup.lighting:
        return 'LGT';
      case NotamGroup.hazards:
        return 'HAZ';
      case NotamGroup.other:
        return 'OTH';
      case NotamGroup.admin:
        return 'ADM';
      case NotamGroup.taxiways:
        return 'TWY';
      case NotamGroup.airportServices:
        return 'SVC';
    }
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