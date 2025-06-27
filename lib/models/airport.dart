import 'dart:convert';

enum SystemStatus { green, yellow, red }

class Airport {
  final String icao;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final Map<String, SystemStatus> systems;
  final List<String> runways;
  final List<String> navaids;

  Airport({
    required this.icao,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.systems,
    required this.runways,
    required this.navaids,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      icao: json['icao'],
      name: json['name'],
      city: json['city'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      systems: Map<String, SystemStatus>.from(
        json['systems'].map((key, value) => MapEntry(key, SystemStatus.values.firstWhere((e) => e.toString() == 'SystemStatus.$value'))),
      ),
      runways: List<String>.from(json['runways']),
      navaids: List<String>.from(json['navaids']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'name': name,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'systems': systems.map((key, value) => MapEntry(key, value.toString().split('.').last)),
      'runways': runways,
      'navaids': navaids,
    };
  }

  factory Airport.fromDbJson(Map<String, dynamic> json) {
    return Airport(
      icao: json['icao'],
      name: json['name'],
      city: json['city'],
      latitude: 0, // Not stored in DB for now
      longitude: 0, // Not stored in DB for now
      runways: [], // Not stored in DB for now
      navaids: [], // Not stored in DB for now
      systems: Map<String, SystemStatus>.from(
        jsonDecode(json['systemsJson']).map((key, value) => MapEntry(key, SystemStatus.values.firstWhere((e) => e.toString() == 'SystemStatus.$value'))),
      ),
    );
  }

  Map<String, dynamic> toDbJson(String flightId) {
    return {
      'flightId': flightId,
      'icao': icao,
      'name': name,
      'city': city,
      'systemsJson': jsonEncode(systems.map((key, value) => MapEntry(key, value.toString().split('.').last))),
    };
  }
} 