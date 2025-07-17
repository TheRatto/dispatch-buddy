import '../models/notam.dart';
import '../models/airport.dart';
import 'notam_grouping_service.dart';

class AirportSystemAnalyzer {
  final NotamGroupingService _groupingService;
  
  AirportSystemAnalyzer() : _groupingService = NotamGroupingService();

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
} 