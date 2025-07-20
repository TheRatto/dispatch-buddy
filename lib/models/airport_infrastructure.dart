/// Represents a runway at an airport with comprehensive details
class Runway {
  final String identifier; // "07/25", "16L/34R"
  final double length; // in meters
  final String surface; // "Asphalt", "Concrete", "Grass"
  final List<Approach> approaches; // ILS, VOR, etc.
  final bool hasLighting;
  final double width; // in meters
  final String status; // "OPERATIONAL", "CLOSED", "MAINTENANCE"
  final String? restrictions; // Weight limits, etc.
  final bool isPrimary; // Is this the primary runway
  final bool isActive; // Currently in use

  Runway({
    required this.identifier,
    required this.length,
    required this.surface,
    required this.approaches,
    required this.hasLighting,
    required this.width,
    this.status = 'OPERATIONAL',
    this.restrictions,
    this.isPrimary = false,
    this.isActive = true,
  });

  /// Create a Runway from JSON data
  factory Runway.fromJson(Map<String, dynamic> json) {
    return Runway(
      identifier: json['identifier'],
      length: json['length'].toDouble(),
      surface: json['surface'],
      approaches: (json['approaches'] as List)
          .map((approach) => Approach.fromJson(approach))
          .toList(),
      hasLighting: json['hasLighting'] ?? false,
      width: json['width']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'OPERATIONAL',
      restrictions: json['restrictions'],
      isPrimary: json['isPrimary'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  /// Convert Runway to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'length': length,
      'surface': surface,
      'approaches': approaches.map((approach) => approach.toJson()).toList(),
      'hasLighting': hasLighting,
      'width': width,
      'status': status,
      'restrictions': restrictions,
      'isPrimary': isPrimary,
      'isActive': isActive,
    };
  }

  /// Get available approaches for this runway
  List<Approach> get availableApproaches {
    return approaches.where((approach) => approach.status == 'OPERATIONAL').toList();
  }

  /// Check if runway has ILS approach
  bool get hasILS {
    return approaches.any((approach) => 
        approach.type == 'ILS' && approach.status == 'OPERATIONAL');
  }

  /// Check if runway has VOR approach
  bool get hasVOR {
    return approaches.any((approach) => 
        approach.type == 'VOR' && approach.status == 'OPERATIONAL');
  }

  /// Get runway status emoji
  String get statusEmoji {
    switch (status) {
      case 'OPERATIONAL':
        return '🟢';
      case 'CLOSED':
        return '🔴';
      case 'MAINTENANCE':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'Runway(identifier: $identifier, status: $status, length: ${length}m)';
  }
}

/// Represents a taxiway at an airport
class Taxiway {
  final String identifier; // "A", "B", "C"
  final List<String> connections; // connected runways
  final double width; // in meters
  final bool hasLighting;
  final List<String> restrictions; // weight limits, etc.
  final String status; // "OPERATIONAL", "CLOSED", "RESTRICTED"
  final String? notes; // Additional information

  Taxiway({
    required this.identifier,
    required this.connections,
    required this.width,
    required this.hasLighting,
    this.restrictions = const [],
    this.status = 'OPERATIONAL',
    this.notes,
  });

  /// Create a Taxiway from JSON data
  factory Taxiway.fromJson(Map<String, dynamic> json) {
    return Taxiway(
      identifier: json['identifier'],
      connections: List<String>.from(json['connections']),
      width: json['width']?.toDouble() ?? 0.0,
      hasLighting: json['hasLighting'] ?? false,
      restrictions: List<String>.from(json['restrictions'] ?? []),
      status: json['status'] ?? 'OPERATIONAL',
      notes: json['notes'],
    );
  }

  /// Convert Taxiway to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'connections': connections,
      'width': width,
      'hasLighting': hasLighting,
      'restrictions': restrictions,
      'status': status,
      'notes': notes,
    };
  }

  /// Get taxiway status emoji
  String get statusEmoji {
    switch (status) {
      case 'OPERATIONAL':
        return '🟢';
      case 'CLOSED':
        return '🔴';
      case 'RESTRICTED':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'Taxiway(identifier: $identifier, status: $status, connections: $connections)';
  }
}

/// Represents a navigation aid at an airport
class Navaid {
  final String identifier; // "ILS", "VOR", "NDB"
  final String frequency; // Frequency in MHz
  final String runway; // associated runway
  final String type; // "ILS", "VOR", "NDB", "DME"
  final bool isPrimary;
  final bool isBackup;
  final String status; // "OPERATIONAL", "U/S", "MAINTENANCE"
  final String? notes; // Additional information

  Navaid({
    required this.identifier,
    required this.frequency,
    required this.runway,
    required this.type,
    this.isPrimary = false,
    this.isBackup = false,
    this.status = 'OPERATIONAL',
    this.notes,
  });

  /// Create a Navaid from JSON data
  factory Navaid.fromJson(Map<String, dynamic> json) {
    return Navaid(
      identifier: json['identifier'],
      frequency: json['frequency'],
      runway: json['runway'],
      type: json['type'],
      isPrimary: json['isPrimary'] ?? false,
      isBackup: json['isBackup'] ?? false,
      status: json['status'] ?? 'OPERATIONAL',
      notes: json['notes'],
    );
  }

  /// Convert Navaid to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'frequency': frequency,
      'runway': runway,
      'type': type,
      'isPrimary': isPrimary,
      'isBackup': isBackup,
      'status': status,
      'notes': notes,
    };
  }

  /// Get navaid status emoji
  String get statusEmoji {
    switch (status) {
      case 'OPERATIONAL':
        return '🟢';
      case 'U/S':
        return '🔴';
      case 'MAINTENANCE':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'Navaid(identifier: $identifier, type: $type, status: $status, runway: $runway)';
  }
}

/// Represents an approach procedure for a runway
class Approach {
  final String identifier; // "ILS 07", "VOR 25"
  final String type; // "ILS", "VOR", "NDB", "Visual"
  final String runway; // associated runway
  final double minimums; // decision height/altitude in feet
  final String status; // "OPERATIONAL", "U/S", "MAINTENANCE"
  final String? notes; // Additional information

  Approach({
    required this.identifier,
    required this.type,
    required this.runway,
    required this.minimums,
    this.status = 'OPERATIONAL',
    this.notes,
  });

  /// Create an Approach from JSON data
  factory Approach.fromJson(Map<String, dynamic> json) {
    return Approach(
      identifier: json['identifier'],
      type: json['type'],
      runway: json['runway'],
      minimums: json['minimums']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'OPERATIONAL',
      notes: json['notes'],
    );
  }

  /// Convert Approach to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'type': type,
      'runway': runway,
      'minimums': minimums,
      'status': status,
      'notes': notes,
    };
  }

  /// Get approach status emoji
  String get statusEmoji {
    switch (status) {
      case 'OPERATIONAL':
        return '🟢';
      case 'U/S':
        return '🔴';
      case 'MAINTENANCE':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'Approach(identifier: $identifier, type: $type, status: $status, runway: $runway)';
  }
}

/// Represents a taxiway route between facilities
class TaxiwayRoute {
  final String identifier; // "A-B", "C-D-E"
  final List<String> taxiways; // List of taxiways in route
  final String startPoint; // Starting facility
  final String endPoint; // Ending facility
  final String status; // "OPERATIONAL", "CLOSED", "RESTRICTED"
  final String? alternative; // Alternative route

  TaxiwayRoute({
    required this.identifier,
    required this.taxiways,
    required this.startPoint,
    required this.endPoint,
    this.status = 'OPERATIONAL',
    this.alternative,
  });

  /// Create a TaxiwayRoute from JSON data
  factory TaxiwayRoute.fromJson(Map<String, dynamic> json) {
    return TaxiwayRoute(
      identifier: json['identifier'],
      taxiways: List<String>.from(json['taxiways']),
      startPoint: json['startPoint'],
      endPoint: json['endPoint'],
      status: json['status'] ?? 'OPERATIONAL',
      alternative: json['alternative'],
    );
  }

  /// Convert TaxiwayRoute to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'taxiways': taxiways,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'status': status,
      'alternative': alternative,
    };
  }

  /// Get route status emoji
  String get statusEmoji {
    switch (status) {
      case 'OPERATIONAL':
        return '🟢';
      case 'CLOSED':
        return '🔴';
      case 'RESTRICTED':
        return '🟡';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'TaxiwayRoute(identifier: $identifier, status: $status, start: $startPoint, end: $endPoint)';
  }
}

/// Represents the complete infrastructure of an airport
class AirportInfrastructure {
  final String icao;
  final List<Runway> runways;
  final List<Taxiway> taxiways;
  final List<Navaid> navaids;
  final List<Approach> approaches;
  final List<TaxiwayRoute> routes;
  final Map<String, String> facilityStatus; // Current status of facilities

  AirportInfrastructure({
    required this.icao,
    required this.runways,
    required this.taxiways,
    required this.navaids,
    required this.approaches,
    required this.routes,
    required this.facilityStatus,
  });

  /// Create AirportInfrastructure from JSON data
  factory AirportInfrastructure.fromJson(Map<String, dynamic> json) {
    return AirportInfrastructure(
      icao: json['icao'],
      runways: (json['runways'] as List)
          .map((runway) => Runway.fromJson(runway))
          .toList(),
      taxiways: (json['taxiways'] as List)
          .map((taxiway) => Taxiway.fromJson(taxiway))
          .toList(),
      navaids: (json['navaids'] as List)
          .map((navaid) => Navaid.fromJson(navaid))
          .toList(),
      approaches: (json['approaches'] as List)
          .map((approach) => Approach.fromJson(approach))
          .toList(),
      routes: (json['routes'] as List?)
          ?.map((route) => TaxiwayRoute.fromJson(route))
          .toList() ?? [],
      facilityStatus: Map<String, String>.from(json['facilityStatus'] ?? {}),
    );
  }

  /// Convert AirportInfrastructure to JSON
  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'runways': runways.map((runway) => runway.toJson()).toList(),
      'taxiways': taxiways.map((taxiway) => taxiway.toJson()).toList(),
      'navaids': navaids.map((navaid) => navaid.toJson()).toList(),
      'approaches': approaches.map((approach) => approach.toJson()).toList(),
      'routes': routes.map((route) => route.toJson()).toList(),
      'facilityStatus': facilityStatus,
    };
  }

  /// Get operational runways
  List<Runway> get operationalRunways {
    return runways.where((runway) => runway.status == 'OPERATIONAL').toList();
  }

  /// Get closed runways
  List<Runway> get closedRunways {
    return runways.where((runway) => runway.status == 'CLOSED').toList();
  }

  /// Get operational taxiways
  List<Taxiway> get operationalTaxiways {
    return taxiways.where((taxiway) => taxiway.status == 'OPERATIONAL').toList();
  }

  /// Get operational NAVAIDs
  List<Navaid> get operationalNavaids {
    return navaids.where((navaid) => navaid.status == 'OPERATIONAL').toList();
  }

  /// Get operational approaches
  List<Approach> get operationalApproaches {
    return approaches.where((approach) => approach.status == 'OPERATIONAL').toList();
  }

  /// Get primary runways
  List<Runway> get primaryRunways {
    return runways.where((runway) => runway.isPrimary).toList();
  }

  /// Get backup NAVAIDs
  List<Navaid> get backupNavaids {
    return navaids.where((navaid) => navaid.isBackup).toList();
  }

  /// Calculate overall airport status
  String get overallStatus {
    final closedRunwaysCount = closedRunways.length;
    final totalRunways = runways.length;
    
    if (closedRunwaysCount == totalRunways) {
      return 'CRITICAL';
    } else if (closedRunwaysCount > 0) {
      return 'PARTIAL';
    } else {
      return 'OPERATIONAL';
    }
  }

  /// Get overall status emoji
  String get overallStatusEmoji {
    switch (overallStatus) {
      case 'OPERATIONAL':
        return '🟢';
      case 'PARTIAL':
        return '🟡';
      case 'CRITICAL':
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'AirportInfrastructure(icao: $icao, runways: ${runways.length}, taxiways: ${taxiways.length}, navaids: ${navaids.length})';
  }
} 