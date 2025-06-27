import 'airport.dart';
import 'notam.dart';
import 'weather.dart';
import 'dart:convert';

class Flight {
  final String id;
  final String route;
  final String departure;
  final String destination;
  final DateTime etd;
  final String flightLevel;
  final List<String> alternates;
  final DateTime createdAt;
  
  List<Airport> airports;
  List<Notam> notams;
  List<Weather> weather;

  Flight({
    required this.id,
    required this.route,
    required this.departure,
    required this.destination,
    required this.etd,
    required this.flightLevel,
    required this.alternates,
    required this.createdAt,
    this.airports = const [],
    this.notams = const [],
    this.weather = const [],
  });

  // Getter methods to filter weather by type
  List<Weather> get metars => weather.where((w) => w.type == 'METAR').toList();
  List<Weather> get tafs => weather.where((w) => w.type == 'TAF').toList();

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'],
      route: json['route'],
      departure: json['departure'],
      destination: json['destination'],
      etd: DateTime.parse(json['etd']),
      flightLevel: json['flightLevel'],
      alternates: List<String>.from(json['alternates']),
      createdAt: DateTime.parse(json['createdAt']),
      airports: (json['airports'] as List<dynamic>?)
          ?.map((a) => Airport.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      notams: (json['notams'] as List<dynamic>?)
          ?.map((n) => Notam.fromJson(n as Map<String, dynamic>))
          .toList() ?? [],
      weather: (json['weather'] as List<dynamic>?)
          ?.map((w) => Weather.fromJson(w as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route': route,
      'departure': departure,
      'destination': destination,
      'etd': etd.toIso8601String(),
      'flightLevel': flightLevel,
      'alternates': alternates,
      'createdAt': createdAt.toIso8601String(),
      'airports': airports.map((a) => a.toJson()).toList(),
      'notams': notams.map((n) => n.toJson()).toList(),
      'weather': weather.map((w) => w.toJson()).toList(),
    };
  }

  factory Flight.fromDb(
    Map<String, dynamic> flightMap,
    List<Map<String, dynamic>> airportMaps,
    List<Map<String, dynamic>> notamMaps,
    List<Map<String, dynamic>> weatherMaps,
  ) {
    return Flight(
      id: flightMap['id'],
      route: flightMap['route'],
      departure: flightMap['departure'],
      destination: flightMap['destination'],
      etd: DateTime.parse(flightMap['etd']),
      flightLevel: flightMap['flightLevel'],
      alternates: (jsonDecode(flightMap['alternates']) as List).cast<String>(),
      createdAt: DateTime.parse(flightMap['createdAt']),
      airports: airportMaps.map((map) => Airport.fromDbJson(map)).toList(),
      notams: notamMaps.map((map) => Notam.fromDbJson(map)).toList(),
      weather: weatherMaps.map((map) => Weather.fromDbJson(map)).toList(),
    );
  }

  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'route': route,
      'departure': departure,
      'destination': destination,
      'etd': etd.toIso8601String(),
      'flightLevel': flightLevel,
      'alternates': jsonEncode(alternates),
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 