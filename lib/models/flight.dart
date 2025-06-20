import 'airport.dart';
import 'notam.dart';
import 'weather.dart';

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
      airports: (json['airports'] as List?)
          ?.map((a) => Airport.fromJson(a))
          .toList() ?? [],
      notams: (json['notams'] as List?)
          ?.map((n) => Notam.fromJson(n))
          .toList() ?? [],
      weather: (json['weather'] as List?)
          ?.map((w) => Weather.fromJson(w))
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
} 