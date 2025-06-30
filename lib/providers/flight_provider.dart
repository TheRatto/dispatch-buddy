import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

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

  // Refresh flight data by refetching from APIs
  Future<void> refreshFlightData() async {
    if (_currentFlight == null || _currentFlight!.airports.isEmpty) {
      return;
    }

    setLoading(true);
    
    try {
      final apiService = ApiService();
      final icaos = _currentFlight!.airports.map((airport) => airport.icao).toList();
      
      // Fetch all data in parallel using the batch methods
      final notamsFuture = Future.wait(icaos.map((icao) => apiService.fetchNotams(icao)));
      final weatherFuture = apiService.fetchWeather(icaos);
      final tafsFuture = apiService.fetchTafs(icaos);

      final results = await Future.wait([notamsFuture, weatherFuture, tafsFuture]);

      final List<List<Notam>> notamResults = results[0] as List<List<Notam>>;
      final List<Weather> metars = results[1] as List<Weather>;
      final List<Weather> tafs = results[2] as List<Weather>;

      // Flatten the list of lists into a single list
      final List<Notam> allNotams = notamResults.expand((notamList) => notamList).toList();
      final List<Weather> allWeather = [...metars, ...tafs];
      
      // Update the current flight with fresh data
      updateFlightData(
        notams: allNotams,
        weather: allWeather,
      );
    } catch (e) {
      print('Error refreshing flight data: $e');
      // Don't throw - let the UI handle the error gracefully
    } finally {
      setLoading(false);
    }
  }

  // Add a new airport to the current flight and fetch its data
  Future<bool> addAirportToFlight(String icao) async {
    if (_currentFlight == null) {
      return false;
    }

    // Check if airport already exists
    if (_currentFlight!.airports.any((airport) => airport.icao == icao.toUpperCase())) {
      return false; // Airport already exists
    }

    setLoading(true);
    
    try {
      final apiService = ApiService();
      
      // Create a new airport object
      final newAirport = Airport(
        icao: icao.toUpperCase(),
        name: 'Unknown Airport', // We could fetch this from an airport database later
        city: 'Unknown City', // Placeholder value
        latitude: 0.0, // Placeholder values
        longitude: 0.0,
        systems: {}, // Empty systems map
        runways: [], // Empty runways list
        navaids: [], // Empty navaids list
      );

      // Add the airport to the current flight
      _currentFlight!.airports.add(newAirport);

      // Fetch data for the new airport
      final notamsFuture = apiService.fetchNotams(icao);
      final weatherFuture = apiService.fetchWeather([icao]);
      final tafsFuture = apiService.fetchTafs([icao]);

      final results = await Future.wait([notamsFuture, weatherFuture, tafsFuture]);

      final List<Notam> newNotams = results[0] as List<Notam>;
      final List<Weather> newMetars = results[1] as List<Weather>;
      final List<Weather> newTafs = results[2] as List<Weather>;

      // Add new data to existing data
      _currentFlight!.notams.addAll(newNotams);
      _currentFlight!.weather.addAll([...newMetars, ...newTafs]);

      // Regroup weather data to include the new airport
      _groupWeatherData();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding airport $icao: $e');
      // Remove the airport if data fetching failed
      _currentFlight!.airports.removeWhere((airport) => airport.icao == icao.toUpperCase());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Update an airport's ICAO code and fetch new data
  Future<bool> updateAirportCode(String oldIcao, String newIcao) async {
    if (_currentFlight == null) {
      return false;
    }

    // Check if new airport already exists
    if (_currentFlight!.airports.any((airport) => airport.icao == newIcao.toUpperCase())) {
      return false; // New airport already exists
    }

    setLoading(true);
    
    try {
      final apiService = ApiService();
      
      // Find and update the airport
      final airportIndex = _currentFlight!.airports.indexWhere((airport) => airport.icao == oldIcao.toUpperCase());
      if (airportIndex == -1) {
        return false; // Airport not found
      }

      // Update the airport ICAO
      _currentFlight!.airports[airportIndex] = Airport(
        icao: newIcao.toUpperCase(),
        name: _currentFlight!.airports[airportIndex].name,
        city: _currentFlight!.airports[airportIndex].city,
        latitude: _currentFlight!.airports[airportIndex].latitude,
        longitude: _currentFlight!.airports[airportIndex].longitude,
        systems: _currentFlight!.airports[airportIndex].systems,
        runways: _currentFlight!.airports[airportIndex].runways,
        navaids: _currentFlight!.airports[airportIndex].navaids,
      );

      // Remove old data
      _currentFlight!.notams.removeWhere((notam) => notam.icao == oldIcao.toUpperCase());
      _currentFlight!.weather.removeWhere((weather) => weather.icao == oldIcao.toUpperCase());

      // Fetch new data for the updated airport
      final notamsFuture = apiService.fetchNotams(newIcao);
      final weatherFuture = apiService.fetchWeather([newIcao]);
      final tafsFuture = apiService.fetchTafs([newIcao]);

      final results = await Future.wait([notamsFuture, weatherFuture, tafsFuture]);

      final List<Notam> newNotams = results[0] as List<Notam>;
      final List<Weather> newMetars = results[1] as List<Weather>;
      final List<Weather> newTafs = results[2] as List<Weather>;

      // Add new data
      _currentFlight!.notams.addAll(newNotams);
      _currentFlight!.weather.addAll([...newMetars, ...newTafs]);

      // Regroup weather data
      _groupWeatherData();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating airport from $oldIcao to $newIcao: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Remove an airport from the current flight
  Future<bool> removeAirportFromFlight(String icao) async {
    if (_currentFlight == null) {
      return false;
    }

    setLoading(true);
    
    try {
      // Remove the airport
      _currentFlight!.airports.removeWhere((airport) => airport.icao == icao.toUpperCase());
      
      // Remove associated data
      _currentFlight!.notams.removeWhere((notam) => notam.icao == icao.toUpperCase());
      _currentFlight!.weather.removeWhere((weather) => weather.icao == icao.toUpperCase());

      // Regroup weather data
      _groupWeatherData();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error removing airport $icao: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
} 