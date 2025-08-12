import 'package:flutter/foundation.dart';
import '../models/airport_infrastructure.dart';
import '../models/notam.dart';
import '../data/airport_infrastructure_data.dart';

/// Enhanced airport database service with infrastructure analysis capabilities
class AirportDatabaseService {
  static final AirportDatabaseService _instance = AirportDatabaseService._internal();
  factory AirportDatabaseService() => _instance;
  AirportDatabaseService._internal();

  /// Get detailed airport infrastructure for a specific ICAO code
  Future<AirportInfrastructure?> getAirportInfrastructure(String icao) async {
    try {
      final infrastructure = AirportInfrastructureData.getAirportInfrastructure(icao);
      if (infrastructure == null) {
        debugPrint('DEBUG: No infrastructure data found for $icao');
        return null;
      }
      
      debugPrint('DEBUG: Retrieved infrastructure data for $icao');
      return infrastructure;
    } catch (e) {
      debugPrint('ERROR: Failed to get airport infrastructure for $icao: $e');
      return null;
    }
  }

  /// Get operational alternatives for a specific component
  Future<List<OperationalAlternative>> getAlternatives(String icao, String component) async {
    final infrastructure = await getAirportInfrastructure(icao);
    if (infrastructure == null) return [];

    final alternatives = <OperationalAlternative>[];

    switch (component.toLowerCase()) {
      case 'runway':
        alternatives.addAll(_getRunwayAlternatives(infrastructure));
        break;
      case 'taxiway':
        alternatives.addAll(_getTaxiwayAlternatives(infrastructure));
        break;
      case 'navaid':
        alternatives.addAll(_getNavaidAlternatives(infrastructure));
        break;
      case 'approach':
        alternatives.addAll(_getApproachAlternatives(infrastructure));
        break;
    }

    return alternatives;
  }

  /// Calculate impact score based on NOTAMs and available alternatives
  double calculateImpactScore(String icao, List<Notam> notams) {
    final infrastructure = AirportInfrastructureData.getAirportInfrastructure(icao);
    if (infrastructure == null) return 0.0;

    // Calculate impact based on closed facilities vs available alternatives
    final closedRunways = infrastructure.closedRunways.length;
    final totalRunways = infrastructure.runways.length;
    final closedTaxiways = infrastructure.taxiways.where((t) => t.status == 'CLOSED').length;
    final totalTaxiways = infrastructure.taxiways.length;
    final closedNavaids = infrastructure.navaids.where((n) => n.status == 'U/S').length;
    final totalNavaids = infrastructure.navaids.length;

    // Weight the impact (runways are most critical)
    final runwayImpact = closedRunways / totalRunways * 0.5;
    final taxiwayImpact = closedTaxiways / totalTaxiways * 0.3;
    final navaidImpact = closedNavaids / totalNavaids * 0.2;

    return (runwayImpact + taxiwayImpact + navaidImpact) * 100; // Convert to percentage
  }

  /// Get facility status with specific component names
  Map<String, FacilityStatus> getFacilityStatus(String icao, List<Notam> notams) {
    final infrastructure = AirportInfrastructureData.getAirportInfrastructure(icao);
    if (infrastructure == null) return {};

    final status = <String, FacilityStatus>{};

    // Add runway status
    for (final runway in infrastructure.runways) {
      status['RWY ${runway.identifier}'] = FacilityStatus(
        component: 'RWY ${runway.identifier}',
        status: runway.status,
        statusEmoji: runway.statusEmoji,
        alternatives: _getRunwayAlternatives(infrastructure, runway),
        impact: _calculateRunwayImpact(runway, infrastructure),
      );
    }

    // Add taxiway status
    for (final taxiway in infrastructure.taxiways) {
      status['Taxiway ${taxiway.identifier}'] = FacilityStatus(
        component: 'Taxiway ${taxiway.identifier}',
        status: taxiway.status,
        statusEmoji: taxiway.statusEmoji,
        alternatives: _getTaxiwayAlternatives(infrastructure, taxiway),
        impact: _calculateTaxiwayImpact(taxiway, infrastructure),
      );
    }

    // Add NAVAID status
    for (final navaid in infrastructure.navaids) {
      status[navaid.identifier] = FacilityStatus(
        component: navaid.identifier,
        status: navaid.status,
        statusEmoji: navaid.statusEmoji,
        alternatives: _getNavaidAlternatives(infrastructure, navaid),
        impact: _calculateNavaidImpact(navaid, infrastructure),
      );
    }

    return status;
  }

  /// Get runway alternatives
  List<OperationalAlternative> _getRunwayAlternatives(AirportInfrastructure infrastructure, [Runway? specificRunway]) {
    final alternatives = <OperationalAlternative>[];
    final operationalRunways = infrastructure.operationalRunways;
    
    if (specificRunway != null && specificRunway.status == 'CLOSED') {
      // Find alternative runways for the closed runway
      for (final alternative in operationalRunways) {
        if (alternative.identifier != specificRunway.identifier) {
          alternatives.add(OperationalAlternative(
            component: 'RWY ${alternative.identifier}',
            type: 'Runway',
            status: 'Available',
            description: 'Use RWY ${alternative.identifier} as alternative to ${specificRunway.identifier}',
            impact: 'Low',
          ));
        }
      }
    } else {
      // General runway alternatives
      for (final runway in operationalRunways) {
        alternatives.add(OperationalAlternative(
          component: 'RWY ${runway.identifier}',
          type: 'Runway',
          status: 'Available',
          description: 'Operational runway ${runway.length}m long',
          impact: runway.isPrimary ? 'High' : 'Medium',
        ));
      }
    }

    return alternatives;
  }

  /// Get taxiway alternatives
  List<OperationalAlternative> _getTaxiwayAlternatives(AirportInfrastructure infrastructure, [Taxiway? specificTaxiway]) {
    final alternatives = <OperationalAlternative>[];
    final operationalTaxiways = infrastructure.operationalTaxiways;
    
    if (specificTaxiway != null && specificTaxiway.status == 'CLOSED') {
      // Find alternative taxiways for the closed taxiway
      for (final alternative in operationalTaxiways) {
        if (alternative.identifier != specificTaxiway.identifier) {
          alternatives.add(OperationalAlternative(
            component: 'Taxiway ${alternative.identifier}',
            type: 'Taxiway',
            status: 'Available',
            description: 'Use Taxiway ${alternative.identifier} as alternative to ${specificTaxiway.identifier}',
            impact: 'Low',
          ));
        }
      }
    } else {
      // General taxiway alternatives
      for (final taxiway in operationalTaxiways) {
        alternatives.add(OperationalAlternative(
          component: 'Taxiway ${taxiway.identifier}',
          type: 'Taxiway',
          status: 'Available',
          description: 'Operational taxiway connecting ${taxiway.connections.join(', ')}',
          impact: 'Medium',
        ));
      }
    }

    return alternatives;
  }

  /// Get NAVAID alternatives
  List<OperationalAlternative> _getNavaidAlternatives(AirportInfrastructure infrastructure, [Navaid? specificNavaid]) {
    final alternatives = <OperationalAlternative>[];
    final operationalNavaids = infrastructure.operationalNavaids;
    
    if (specificNavaid != null && specificNavaid.status == 'U/S') {
      // Find backup NAVAIDs for the unavailable one
      for (final alternative in operationalNavaids) {
        if (alternative.identifier != specificNavaid.identifier && 
            alternative.runway == specificNavaid.runway) {
          alternatives.add(OperationalAlternative(
            component: alternative.identifier,
            type: 'NAVAID',
            status: 'Backup',
            description: 'Use ${alternative.identifier} as backup to ${specificNavaid.identifier}',
            impact: 'Medium',
          ));
        }
      }
    } else {
      // General NAVAID alternatives
      for (final navaid in operationalNavaids) {
        alternatives.add(OperationalAlternative(
          component: navaid.identifier,
          type: 'NAVAID',
          status: 'Available',
          description: 'Operational ${navaid.type} for RWY ${navaid.runway}',
          impact: navaid.isPrimary ? 'High' : 'Medium',
        ));
      }
    }

    return alternatives;
  }

  /// Get approach alternatives
  List<OperationalAlternative> _getApproachAlternatives(AirportInfrastructure infrastructure) {
    final alternatives = <OperationalAlternative>[];
    final operationalApproaches = infrastructure.operationalApproaches;
    
    for (final approach in operationalApproaches) {
      alternatives.add(OperationalAlternative(
        component: approach.identifier,
        type: 'Approach',
        status: 'Available',
        description: '${approach.type} approach to RWY ${approach.runway} (min ${approach.minimums}ft)',
        impact: approach.type == 'ILS' ? 'High' : 'Medium',
      ));
    }

    return alternatives;
  }

  /// Calculate runway impact
  String _calculateRunwayImpact(Runway runway, AirportInfrastructure infrastructure) {
    if (runway.status == 'OPERATIONAL') return 'None';
    
    final operationalRunways = infrastructure.operationalRunways.length;
    final totalRunways = infrastructure.runways.length;
    
    if (operationalRunways == 0) return 'Critical';
    if (operationalRunways < totalRunways / 2) return 'High';
    return 'Medium';
  }

  /// Calculate taxiway impact
  String _calculateTaxiwayImpact(Taxiway taxiway, AirportInfrastructure infrastructure) {
    if (taxiway.status == 'OPERATIONAL') return 'None';
    
    final operationalTaxiways = infrastructure.operationalTaxiways.length;
    final totalTaxiways = infrastructure.taxiways.length;
    
    if (operationalTaxiways == 0) return 'Critical';
    if (operationalTaxiways < totalTaxiways / 2) return 'High';
    return 'Medium';
  }

  /// Calculate NAVAID impact
  String _calculateNavaidImpact(Navaid navaid, AirportInfrastructure infrastructure) {
    if (navaid.status == 'OPERATIONAL') return 'None';
    
    final operationalNavaids = infrastructure.operationalNavaids.length;
    final totalNavaids = infrastructure.navaids.length;
    
    if (operationalNavaids == 0) return 'Critical';
    if (operationalNavaids < totalNavaids / 2) return 'High';
    return 'Medium';
  }

  /// Get list of all available airports with infrastructure data
  List<String> getAvailableAirports() {
    return AirportInfrastructureData.getAvailableAirports();
  }

  /// Check if airport has infrastructure data
  bool hasAirportInfrastructure(String icao) {
    return AirportInfrastructureData.hasAirportInfrastructure(icao);
  }

  /// Get database size
  int get databaseSize => AirportInfrastructureData.databaseSize;
}

/// Represents an operational alternative for a facility
class OperationalAlternative {
  final String component;
  final String type;
  final String status;
  final String description;
  final String impact;

  OperationalAlternative({
    required this.component,
    required this.type,
    required this.status,
    required this.description,
    required this.impact,
  });

  @override
  String toString() {
    return 'OperationalAlternative(component: $component, type: $type, status: $status)';
  }
}

/// Represents the status of a specific facility
class FacilityStatus {
  final String component;
  final String status;
  final String statusEmoji;
  final List<OperationalAlternative> alternatives;
  final String impact;

  FacilityStatus({
    required this.component,
    required this.status,
    required this.statusEmoji,
    required this.alternatives,
    required this.impact,
  });

  @override
  String toString() {
    return 'FacilityStatus(component: $component, status: $status, impact: $impact)';
  }
} 