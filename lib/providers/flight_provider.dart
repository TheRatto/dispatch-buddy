import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';

class FlightProvider with ChangeNotifier {
  Flight? _currentFlight;
  List<Flight> _savedFlights = [];
  bool _isLoading = false;

  // Getters
  Flight? get currentFlight => _currentFlight;
  List<Flight> get savedFlights => _savedFlights;
  bool get isLoading => _isLoading;

  // Create new flight
  void createNewFlight(Flight flight) {
    _currentFlight = flight;
    notifyListeners();
  }

  // Save current flight
  void saveCurrentFlight() {
    if (_currentFlight != null) {
      _savedFlights.add(_currentFlight!);
      notifyListeners();
    }
  }

  // Load saved flight
  void loadFlight(Flight flight) {
    _currentFlight = flight;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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
      notifyListeners();
    }
  }
} 