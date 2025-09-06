/// Flight Context Model
/// 
/// Contains all the contextual information needed to generate
/// a personalized AI briefing for a specific flight.
class FlightContext {
  final String departureIcao;
  final String destinationIcao;
  final List<String> alternateIcaos;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String aircraftType;
  final String flightRules;
  final String pilotExperience;
  final String briefingStyle;
  final String? route;
  final String? altitude;
  final String? flightNumber;
  final String? operator;

  const FlightContext({
    required this.departureIcao,
    required this.destinationIcao,
    required this.alternateIcaos,
    required this.departureTime,
    required this.arrivalTime,
    required this.aircraftType,
    required this.flightRules,
    required this.pilotExperience,
    required this.briefingStyle,
    this.route,
    this.altitude,
    this.flightNumber,
    this.operator,
  });

  /// Create a default flight context for testing
  factory FlightContext.defaultTest() {
    final now = DateTime.now().toUtc();
    return FlightContext(
      departureIcao: 'YPPH',
      destinationIcao: 'YSSY',
      alternateIcaos: ['YBBN', 'YMML'],
      departureTime: now.add(const Duration(hours: 2)),
      arrivalTime: now.add(const Duration(hours: 4)),
      aircraftType: 'B737-800',
      flightRules: 'IFR',
      pilotExperience: 'ATP',
      briefingStyle: 'comprehensive',
      route: 'Direct',
      altitude: 'FL370',
      flightNumber: 'QF123',
      operator: 'Qantas',
    );
  }

  /// Create flight context from current flight data
  factory FlightContext.fromCurrentFlight({
    required String departureIcao,
    required String destinationIcao,
    List<String> alternateIcaos = const [],
    required DateTime departureTime,
    required DateTime arrivalTime,
    String aircraftType = 'B737-800',
    String flightRules = 'IFR',
    String pilotExperience = 'ATP',
    String briefingStyle = 'comprehensive',
    String? route,
    String? altitude,
    String? flightNumber,
    String? operator,
  }) {
    return FlightContext(
      departureIcao: departureIcao,
      destinationIcao: destinationIcao,
      alternateIcaos: alternateIcaos,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      aircraftType: aircraftType,
      flightRules: flightRules,
      pilotExperience: pilotExperience,
      briefingStyle: briefingStyle,
      route: route,
      altitude: altitude,
      flightNumber: flightNumber,
      operator: operator,
    );
  }

  /// Get flight duration in hours
  double get flightDurationHours {
    return arrivalTime.difference(departureTime).inHours.toDouble();
  }

  /// Get flight duration in minutes
  int get flightDurationMinutes {
    return arrivalTime.difference(departureTime).inMinutes;
  }

  /// Check if flight is domestic (same country)
  bool get isDomestic {
    // Simple check - in real implementation, you'd check country codes
    return departureIcao.substring(0, 2) == destinationIcao.substring(0, 2);
  }

  /// Get all airports involved in the flight
  List<String> get allAirports {
    return [departureIcao, destinationIcao, ...alternateIcaos];
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'departureIcao': departureIcao,
      'destinationIcao': destinationIcao,
      'alternateIcaos': alternateIcaos,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'aircraftType': aircraftType,
      'flightRules': flightRules,
      'pilotExperience': pilotExperience,
      'briefingStyle': briefingStyle,
      'route': route,
      'altitude': altitude,
      'flightNumber': flightNumber,
      'operator': operator,
    };
  }

  /// Create from JSON
  factory FlightContext.fromJson(Map<String, dynamic> json) {
    return FlightContext(
      departureIcao: json['departureIcao'] as String,
      destinationIcao: json['destinationIcao'] as String,
      alternateIcaos: List<String>.from(json['alternateIcaos'] as List),
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      aircraftType: json['aircraftType'] as String,
      flightRules: json['flightRules'] as String,
      pilotExperience: json['pilotExperience'] as String,
      briefingStyle: json['briefingStyle'] as String,
      route: json['route'] as String?,
      altitude: json['altitude'] as String?,
      flightNumber: json['flightNumber'] as String?,
      operator: json['operator'] as String?,
    );
  }

  @override
  String toString() {
    return 'FlightContext(departure: $departureIcao, destination: $destinationIcao, '
           'departureTime: $departureTime, arrivalTime: $arrivalTime, '
           'aircraft: $aircraftType, rules: $flightRules)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightContext &&
        other.departureIcao == departureIcao &&
        other.destinationIcao == destinationIcao &&
        other.departureTime == departureTime &&
        other.arrivalTime == arrivalTime;
  }

  @override
  int get hashCode {
    return departureIcao.hashCode ^
           destinationIcao.hashCode ^
           departureTime.hashCode ^
           arrivalTime.hashCode;
  }
}
