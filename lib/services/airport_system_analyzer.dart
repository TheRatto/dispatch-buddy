import '../models/notam.dart';
import '../models/airport.dart';
import '../models/airport_infrastructure.dart';
import 'notam_grouping_service.dart';
import 'facility_notam_mapper.dart';

class AirportSystemAnalyzer {
  final NotamGroupingService _groupingService;
  final FacilityNotamMapper _facilityMapper;
  
  AirportSystemAnalyzer() : 
    _groupingService = NotamGroupingService(),
    _facilityMapper = FacilityNotamMapper();

  /// Analyze runway system status based on NOTAMs
  SystemStatus analyzeRunwayStatus(List<Notam> notams, String icao) {
    // Get runway NOTAMs directly
    final runwayNotams = _getRunwayNotams(notams, icao);
    
    return _calculateSystemStatus(runwayNotams);
  }

  /// Analyze navaid system status based on NOTAMs
  SystemStatus analyzeNavaidStatus(List<Notam> notams, String icao) {
    // Get instrument procedure NOTAMs (includes navaids)
    final instrumentNotams = _getInstrumentProcedureNotams(notams, icao);
    
    return _calculateSystemStatus(instrumentNotams);
  }

  /// Analyze taxiway system status based on NOTAMs
  SystemStatus analyzeTaxiwayStatus(List<Notam> notams, String icao) {
    // Get taxiway NOTAMs directly
    final taxiwayNotams = _getTaxiwayNotams(notams, icao);
    
    return _calculateSystemStatus(taxiwayNotams);
  }

  /// Analyze lighting system status based on NOTAMs
  SystemStatus analyzeLightingStatus(List<Notam> notams, String icao) {
    // Get airport service NOTAMs (includes lighting)
    final airportServiceNotams = _getAirportServiceNotams(notams, icao);
    
    // Filter for lighting-specific NOTAMs
    final lightingNotams = _filterLightingNotams(airportServiceNotams);
    
    return _calculateSystemStatus(lightingNotams);
  }

  /// Analyze hazard system status based on NOTAMs
  SystemStatus analyzeHazardStatus(List<Notam> notams, String icao) {
    // Get hazard NOTAMs directly
    final hazardNotams = _getHazardNotams(notams, icao);
    
    return _calculateSystemStatus(hazardNotams);
  }

  /// Analyze admin system status based on NOTAMs
  SystemStatus analyzeAdminStatus(List<Notam> notams, String icao) {
    // Get admin NOTAMs directly
    final adminNotams = _getAdminNotams(notams, icao);
    
    return _calculateSystemStatus(adminNotams);
  }

  /// Analyze other system status based on NOTAMs
  SystemStatus analyzeOtherStatus(List<Notam> notams, String icao) {
    // Get other NOTAMs directly
    final otherNotams = _getOtherNotams(notams, icao);
    
    return _calculateSystemStatus(otherNotams);
  }

  /// Get runway NOTAMs using existing grouping service
  List<Notam> _getRunwayNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get runway NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.runways] ?? [];
  }

  /// Get taxiway NOTAMs using existing grouping service
  List<Notam> _getTaxiwayNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get taxiway NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.taxiways] ?? [];
  }

  /// Get instrument procedure NOTAMs using existing grouping service
  List<Notam> _getInstrumentProcedureNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get instrument procedure NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.instrumentProcedures] ?? [];
  }

  /// Get airport service NOTAMs using existing grouping service
  List<Notam> _getAirportServiceNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get airport service NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.airportServices] ?? [];
  }

  /// Get hazard NOTAMs using existing grouping service
  List<Notam> _getHazardNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get hazard NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.hazards] ?? [];
  }

  /// Get admin NOTAMs using existing grouping service
  List<Notam> _getAdminNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get admin NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.admin] ?? [];
  }

  /// Get other NOTAMs using existing grouping service
  List<Notam> _getOtherNotams(List<Notam> notams, String icao) {
    // Filter NOTAMs for the specific airport
    final airportNotams = notams.where((notam) => notam.icao == icao).toList();
    
    // Use existing grouping service to get other NOTAMs
    final groupedNotams = _groupingService.groupNotams(airportNotams);
    
    return groupedNotams[NotamGroup.other] ?? [];
  }



  /// Filter lighting NOTAMs for general lighting
  List<Notam> _filterLightingNotams(List<Notam> airportServiceNotams) {
    return airportServiceNotams.where((notam) {
      final text = notam.rawText.toUpperCase();
      return text.contains('LIGHTING') ||
             text.contains('LIGHTS') ||
             text.contains('BEACON') ||
             text.contains('APPROACH LIGHTING') ||
             text.contains('AERODROME BEACON');
    }).toList();
  }

  /// Calculate system status based on NOTAM severity and criticality
  SystemStatus _calculateSystemStatus(List<Notam> notams) {
    if (notams.isEmpty) {
      return SystemStatus.green;
    }

    // Check for critical NOTAMs (RED status)
    final criticalNotams = notams.where((notam) => notam.isCritical).toList();
    if (criticalNotams.isNotEmpty) {
      return SystemStatus.red;
    }

    // Check for closures or unserviceable items (RED status)
    final closureNotams = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      return text.contains('CLOSED') ||
             text.contains('U/S') ||
             text.contains('UNSERVICEABLE') ||
             text.contains('NOT AVAILABLE') ||
             text.contains('NOT AVBL');
    }).toList();
    
    if (closureNotams.isNotEmpty) {
      return SystemStatus.red;
    }

    // Check for maintenance or limited operations (YELLOW status)
    final maintenanceNotams = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      return text.contains('MAINTENANCE') ||
             text.contains('LIMITED') ||
             text.contains('RESTRICTED') ||
             text.contains('CONSTRUCTION') ||
             text.contains('WORK');
    }).toList();
    
    if (maintenanceNotams.isNotEmpty) {
      return SystemStatus.yellow;
    }

    // If no critical issues, check if there are any operational NOTAMs (YELLOW status)
    if (notams.isNotEmpty) {
      return SystemStatus.yellow;
    }

    // Default to green if no issues found
    return SystemStatus.green;
  }

  /// Get all NOTAMs for a specific system (for detailed view)
  Map<String, List<Notam>> getSystemNotams(List<Notam> notams, String icao) {
    return {
      'runways': _getRunwayNotams(notams, icao),
      'navaids': _getInstrumentProcedureNotams(notams, icao),
      'taxiways': _getTaxiwayNotams(notams, icao),
      'lighting': _filterLightingNotams(_getAirportServiceNotams(notams, icao)),
      'hazards': _getHazardNotams(notams, icao),
      'admin': _getAdminNotams(notams, icao),
      'other': _getOtherNotams(notams, icao),
    };
  }

  // ============================================================================
  // FACILITY-SPECIFIC ANALYSIS METHODS (NEW)
  // ============================================================================

  /// Analyze status for a specific runway
  /// 
  /// [notams] - All NOTAMs for the airport
  /// [runwayId] - Runway identifier (e.g., "07/25", "16L/34R")
  /// [icao] - Airport ICAO code
  /// 
  /// Returns the operational status of the specific runway
  SystemStatus analyzeRunwayFacilityStatus(List<Notam> notams, String runwayId, String icao) {
    final runwayNotams = _facilityMapper.getAllRunwayAffectingNotams(notams, runwayId);
    return _calculateFacilityStatus(runwayNotams);
  }

  /// Analyze status for a specific NAVAID
  /// 
  /// [notams] - All NOTAMs for the airport
  /// [navaidId] - NAVAID identifier (e.g., "ILS 07", "VOR PH")
  /// [icao] - Airport ICAO code
  /// 
  /// Returns the operational status of the specific NAVAID
  SystemStatus analyzeNavaidFacilityStatus(List<Notam> notams, String navaidId, String icao) {
    final navaidNotams = _facilityMapper.getNavaidNotams(notams, navaidId);
    return _calculateFacilityStatus(navaidNotams);
  }

  /// Analyze status for a specific taxiway
  /// 
  /// [notams] - All NOTAMs for the airport
  /// [taxiwayId] - Taxiway identifier (e.g., "A", "B")
  /// [icao] - Airport ICAO code
  /// 
  /// Returns the operational status of the specific taxiway
  SystemStatus analyzeTaxiwayFacilityStatus(List<Notam> notams, String taxiwayId, String icao) {
    final taxiwayNotams = _facilityMapper.getTaxiwayNotams(notams, taxiwayId);
    return _calculateFacilityStatus(taxiwayNotams);
  }

  /// Analyze status for a specific lighting system
  /// 
  /// [notams] - All NOTAMs for the airport
  /// [lightingId] - Lighting system identifier (e.g., "PAPI", "HIRL")
  /// [icao] - Airport ICAO code
  /// 
  /// Returns the operational status of the specific lighting system
  SystemStatus analyzeLightingFacilityStatus(List<Notam> notams, String lightingId, String icao) {
    final lightingNotams = _facilityMapper.getLightingNotams(notams, lightingId);
    return _calculateFacilityStatus(lightingNotams);
  }

  /// Get descriptive status text for a facility
  /// 
  /// [status] - The system status
  /// [notams] - NOTAMs affecting the facility
  /// [facilityId] - Facility identifier
  /// 
  /// Returns a human-readable status description
  String getFacilityStatusText(SystemStatus status, List<Notam> notams, String facilityId) {
    if (notams.isEmpty) {
      return 'Operational';
    }

    // Get the most critical NOTAM for status description
    final criticalNotam = notams.firstWhere(
      (notam) => notam.isCritical,
      orElse: () => notams.first,
    );

    switch (status) {
      case SystemStatus.red:
        return _getRedStatusText(criticalNotam, facilityId);
      case SystemStatus.yellow:
        return _getYellowStatusText(criticalNotam, facilityId);
      case SystemStatus.green:
        return 'Operational';
    }
  }

  /// Get critical NOTAMs for a facility (for detailed view)
  /// 
  /// [notams] - All NOTAMs affecting the facility
  /// 
  /// Returns list of critical NOTAMs sorted by priority
  List<Notam> getCriticalFacilityNotams(List<Notam> notams) {
    // Sort by criticality first, then by group priority
    return notams.toList()
      ..sort((a, b) {
        // Critical NOTAMs first
        if (a.isCritical != b.isCritical) {
          return a.isCritical ? -1 : 1;
        }
        // Then by group priority (runways > navaids > taxiways > lighting)
        final aPriority = _getGroupPriority(a.group);
        final bPriority = _getGroupPriority(b.group);
        return aPriority.compareTo(bPriority);
      });
  }

  /// Analyze all facilities for an airport infrastructure
  /// 
  /// [notams] - All NOTAMs for the airport
  /// [infrastructure] - Airport infrastructure data
  /// [icao] - Airport ICAO code
  /// 
  /// Returns map of facility ID to status and affecting NOTAMs
  Map<String, Map<String, dynamic>> analyzeAllFacilities(
    List<Notam> notams, 
    AirportInfrastructure infrastructure, 
    String icao
  ) {
    final facilityStatuses = <String, Map<String, dynamic>>{};

    // Analyze runways
    for (final runway in infrastructure.runways) {
      final runwayNotams = _facilityMapper.getAllRunwayAffectingNotams(notams, runway.identifier);
      final status = _calculateFacilityStatus(runwayNotams);
      final statusText = getFacilityStatusText(status, runwayNotams, runway.identifier);
      final criticalNotams = getCriticalFacilityNotams(runwayNotams);

      facilityStatuses['runway_${runway.identifier}'] = {
        'status': status,
        'statusText': statusText,
        'notams': runwayNotams,
        'criticalNotams': criticalNotams,
        'facility': runway,
      };
    }

    // Analyze NAVAIDs
    for (final navaid in infrastructure.navaids) {
      final navaidId = '${navaid.type} ${navaid.runway}';
      final navaidNotams = _facilityMapper.getNavaidNotams(notams, navaidId);
      final status = _calculateFacilityStatus(navaidNotams);
      final statusText = getFacilityStatusText(status, navaidNotams, navaidId);
      final criticalNotams = getCriticalFacilityNotams(navaidNotams);

      facilityStatuses['navaid_${navaid.type}_${navaid.runway}'] = {
        'status': status,
        'statusText': statusText,
        'notams': navaidNotams,
        'criticalNotams': criticalNotams,
        'facility': navaid,
      };
    }

    // Analyze taxiways
    for (final taxiway in infrastructure.taxiways) {
      final taxiwayNotams = _facilityMapper.getTaxiwayNotams(notams, taxiway.identifier);
      final status = _calculateFacilityStatus(taxiwayNotams);
      final statusText = getFacilityStatusText(status, taxiwayNotams, taxiway.identifier);
      final criticalNotams = getCriticalFacilityNotams(taxiwayNotams);

      facilityStatuses['taxiway_${taxiway.identifier}'] = {
        'status': status,
        'statusText': statusText,
        'notams': taxiwayNotams,
        'criticalNotams': criticalNotams,
        'facility': taxiway,
      };
    }

    return facilityStatuses;
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Calculate facility-specific status based on NOTAMs
  /// Enhanced with Q-code status analysis for more precise impact assessment
  SystemStatus _calculateFacilityStatus(List<Notam> notams) {
    if (notams.isEmpty) {
      return SystemStatus.green;
    }

    // Check for critical NOTAMs (RED status)
    final criticalNotams = notams.where((notam) => notam.isCritical).toList();
    if (criticalNotams.isNotEmpty) {
      return SystemStatus.red;
    }

    // Enhanced Q-code status analysis for more precise impact assessment
    for (final notam in notams) {
      final qCodeImpact = _getQCodeImpact(notam.qCode);
      if (qCodeImpact == 'closed' || qCodeImpact == 'unserviceable') {
        return SystemStatus.red; // Immediate red - facility is unusable
      }
    }

    // Check for closures or unserviceable items (RED status) - text-based fallback
    final closureNotams = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      return text.contains('CLOSED') ||
             text.contains('U/S') ||
             text.contains('UNSERVICEABLE') ||
             text.contains('NOT AVAILABLE') ||
             text.contains('NOT AVBL');
    }).toList();
    
    if (closureNotams.isNotEmpty) {
      return SystemStatus.red;
    }

    // Enhanced Q-code status analysis for YELLOW status
    for (final notam in notams) {
      final qCodeImpact = _getQCodeImpact(notam.qCode);
      if (qCodeImpact == 'limited' || qCodeImpact == 'maintenance' || 
          qCodeImpact == 'displaced' || qCodeImpact == 'reduced') {
        return SystemStatus.yellow; // Facility has operational limitations
      }
    }

    // Check for maintenance or limited operations (YELLOW status) - text-based fallback
    final maintenanceNotams = notams.where((notam) {
      final text = notam.rawText.toUpperCase();
      return text.contains('MAINTENANCE') ||
             text.contains('LIMITED') ||
             text.contains('RESTRICTED') ||
             text.contains('CONSTRUCTION') ||
             text.contains('WORK') ||
             text.contains('DISPLACED') ||
             text.contains('REDUCED');
    }).toList();
    
    if (maintenanceNotams.isNotEmpty) {
      return SystemStatus.yellow;
    }

    // Enhanced Q-code status analysis for GREEN status (operational NOTAMs)
    bool allOperational = true;
    for (final notam in notams) {
      final qCodeImpact = _getQCodeImpact(notam.qCode);
      if (qCodeImpact != 'operational' && qCodeImpact != 'active' && qCodeImpact != 'unknown') {
        allOperational = false;
        break;
      }
    }
    
    // If all NOTAMs indicate operational status, return green
    if (allOperational && notams.isNotEmpty) {
      return SystemStatus.green;
    }

    // If no critical issues but some operational limitations, return yellow
    if (notams.isNotEmpty) {
      return SystemStatus.yellow;
    }

    // Default to green if no issues found
    return SystemStatus.green;
  }

  /// Get descriptive text for RED status
  /// Enhanced with Q-code status analysis for more precise descriptions
  String _getRedStatusText(Notam notam, String facilityId) {
    // First try Q-code status for precise description
    final qCodeImpact = _getQCodeImpact(notam.qCode);
    if (qCodeImpact == 'closed') {
      return 'Closed';
    } else if (qCodeImpact == 'unserviceable') {
      return 'Unserviceable';
    }
    
    // Fallback to text analysis
    final text = notam.rawText.toUpperCase();
    
    if (text.contains('CLOSED')) {
      return 'Closed';
    } else if (text.contains('U/S') || text.contains('UNSERVICEABLE')) {
      return 'Unserviceable';
    } else if (text.contains('NOT AVAILABLE') || text.contains('NOT AVBL')) {
      return 'Not Available';
    } else {
      return 'Critical Issue';
    }
  }

  /// Get descriptive text for YELLOW status
  /// Enhanced with Q-code status analysis for more precise descriptions
  String _getYellowStatusText(Notam notam, String facilityId) {
    // First try Q-code status for precise description
    final qCodeImpact = _getQCodeImpact(notam.qCode);
    if (qCodeImpact == 'displaced') {
      return 'Displaced Threshold';
    } else if (qCodeImpact == 'maintenance') {
      return 'Maintenance';
    } else if (qCodeImpact == 'limited') {
      return 'Limited';
    } else if (qCodeImpact == 'reduced') {
      return 'Reduced Capability';
    }
    
    // Fallback to text analysis
    final text = notam.rawText.toUpperCase();
    
    // Check more specific terms first
    if (text.contains('CONSTRUCTION')) {
      return 'Construction';
    } else if (text.contains('DISPLACED')) {
      return 'Displaced Threshold';
    } else if (text.contains('MAINTENANCE')) {
      return 'Maintenance';
    } else if (text.contains('LIMITED')) {
      return 'Limited';
    } else if (text.contains('RESTRICTED')) {
      return 'Restricted';
    } else if (text.contains('REDUCED')) {
      return 'Reduced Capability';
    } else {
      return 'Operational Limitation';
    }
  }

  /// Get priority value for NOTAM groups
  int _getGroupPriority(NotamGroup group) {
    switch (group) {
      case NotamGroup.runways:
        return 1;
      case NotamGroup.instrumentProcedures:
        return 2;
      case NotamGroup.taxiways:
        return 3;
      case NotamGroup.airportServices:
        return 4;
      case NotamGroup.lighting:
        return 5;
      case NotamGroup.hazards:
        return 6;
      case NotamGroup.admin:
        return 7;
      case NotamGroup.other:
        return 8;
    }
  }

  /// Get operational impact level from Q-code status letters (4th & 5th letters)
  /// 
  /// [qCode] - The 5-letter Q-code (e.g., "QMRLC", "QICAS")
  /// 
  /// Returns impact level: 'closed', 'unserviceable', 'limited', 'maintenance', 
  /// 'displaced', 'reduced', 'operational', or 'unknown'
  String _getQCodeImpact(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return 'unknown';
    }
    
    // Extract status identifier (4th and 5th letters)
    final status = qCode.substring(3, 5).toUpperCase();
    
    switch (status) {
      // RED Status - Facility is unusable
      case 'LC': return 'closed';        // QMRLC = Runway Closed
      case 'AS': return 'unserviceable'; // QICAS = ILS Unserviceable
      case 'CC': return 'closed';        // QFACC = Facility Closed
      case 'UC': return 'unserviceable'; // QICUC = Instrument Unserviceable
      
      // YELLOW Status - Facility has operational limitations
      case 'LT': return 'limited';       // QMRLT = Runway Limited
      case 'MT': return 'maintenance';   // QMRMT = Runway Maintenance
      case 'DP': return 'displaced';     // QMRDP = Runway Displaced Threshold
      case 'RD': return 'reduced';       // QMRRD = Runway Reduced
      case 'LM': return 'limited';       // QICLM = ILS Limited
      case 'MM': return 'maintenance';   // QICMM = ILS Maintenance
      case 'LR': return 'limited';       // QOLR = Lighting Limited
      case 'MR': return 'maintenance';   // QOLMR = Lighting Maintenance
      case 'CR': return 'reduced';       // QFACR = Facility Reduced
      case 'CM': return 'maintenance';   // QFACM = Facility Maintenance
      
      // GREEN Status - No operational impact
      case 'OP': return 'operational';   // QMROP = Runway Operational
      case 'AC': return 'active';        // QICAC = ILS Active
      case 'OK': return 'operational';   // QFAOK = Facility Operational
      
      // Default to unknown for unmapped status codes
      default: return 'unknown';
    }
  }

  /// Get human-readable description of Q-code status
  /// 
  /// [qCode] - The 5-letter Q-code (e.g., "QMRLC", "QICAS")
  /// 
  /// Returns human-readable status description
  String getQCodeStatusDescription(String? qCode) {
    if (qCode == null || qCode.length != 5 || !qCode.startsWith('Q')) {
      return 'Unknown Status';
    }
    
    final subject = qCode.substring(1, 3).toUpperCase(); // 2nd & 3rd letters
    final status = qCode.substring(3, 5).toUpperCase();  // 4th & 5th letters
    
    // Combine subject and status for meaningful description
    String subjectDesc = _getQCodeSubjectDescription(subject);
    String statusDesc = _getQCodeStatusDescription(status);
    
    return '$subjectDesc - $statusDesc';
  }
  
  /// Get subject description from Q-code subject letters (2nd & 3rd letters)
  String _getQCodeSubjectDescription(String subject) {
    switch (subject) {
      case 'MR': return 'Runway';
      case 'MS': return 'Stopway';
      case 'MT': return 'Threshold';
      case 'IC': return 'ILS';
      case 'ID': return 'ILS DME';
      case 'IG': return 'Glide Path';
      case 'NA': return 'Navigation';
      case 'OL': return 'Obstacle Lighting';
      case 'LA': return 'Approach Lighting';
      case 'MX': return 'Taxiway';
      case 'FA': return 'Facility';
      default: return 'Facility';
    }
  }
  
  /// Get status description from Q-code status letters (4th & 5th letters)
  String _getQCodeStatusDescription(String status) {
    switch (status) {
      case 'LC': return 'Closed';
      case 'AS': return 'Unserviceable';
      case 'LT': return 'Limited';
      case 'MT': return 'Maintenance';
      case 'DP': return 'Displaced';
      case 'RD': return 'Reduced';
      case 'OP': return 'Operational';
      case 'AC': return 'Active';
      case 'OK': return 'Operational';
      default: return 'Status Unknown';
    }
  }
} 