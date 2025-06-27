import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/database_service.dart';

class FlightProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  Flight? _currentFlight;
  List<Flight> _savedFlights = [];
  bool _isLoading = false;
  Map<String, List<Weather>> _metarsByIcao = {};
  Map<String, List<Weather>> _tafsByIcao = {};

  FlightProvider() {
    // Load saved flights when the provider is initialized
    loadSavedFlights();
  }

  // Getters
  Flight? get currentFlight => _currentFlight;
  List<Flight> get savedFlights => _savedFlights;
  bool get isLoading => _isLoading;
  Map<String, List<Weather>> get metarsByIcao => _metarsByIcao;
  Map<String, List<Weather>> get tafsByIcao => _tafsByIcao;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Load all saved flights from the database
  Future<void> loadSavedFlights() async {
    _savedFlights = await _dbService.getSavedFlights();
    notifyListeners();
  }

  // Set the current flight (after generating a new one)
  void setCurrentFlight(Flight flight) {
    _currentFlight = flight;
    _groupWeatherData();
    notifyListeners();
  }

  // Load a specific flight from the saved list to be the current one
  void loadFlight(Flight flight) {
    _currentFlight = flight;
    _groupWeatherData();
    notifyListeners();
  }

  // Save the current flight to the database
  Future<void> saveCurrentFlight() async {
    if (_currentFlight == null) return;
    
    await _dbService.saveFlight(_currentFlight!);
    
    // Refresh the list of saved flights from the DB
    await loadSavedFlights();
  }

  // Update flight data
  void updateFlightData({
    List<Airport>? airports,
    List<Notam>? notams,
    List<Weather>? weather,
  }) {
    if (_currentFlight != null) {
      if (airports != null) _currentFlight!.airports = airports;
      if (notams != null) _currentFlight!.notams = notams;
      if (weather != null) _currentFlight!.weather = weather;
      _groupWeatherData();
      notifyListeners();
    }
  }

  void _groupWeatherData() {
    _metarsByIcao = {};
    _tafsByIcao = {};
    if (_currentFlight != null) {
      for (final weather in _currentFlight!.weather) {
        if (weather.type == 'METAR') {
          if (!_metarsByIcao.containsKey(weather.icao)) {
            _metarsByIcao[weather.icao] = [];
          }
          _metarsByIcao[weather.icao]!.add(weather);
        } else if (weather.type == 'TAF') {
          if (!_tafsByIcao.containsKey(weather.icao)) {
            _tafsByIcao[weather.icao] = [];
          }
          _tafsByIcao[weather.icao]!.add(weather);
        }
      }
      // Sort each list by timestamp descending
      _metarsByIcao.forEach((key, value) {
        value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
      _tafsByIcao.forEach((key, value) {
        value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }
} 