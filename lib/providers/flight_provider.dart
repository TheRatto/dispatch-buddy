import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/airport_system_analyzer.dart';

class FlightProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AirportSystemAnalyzer _systemAnalyzer = AirportSystemAnalyzer();
  Flight? _currentFlight;
  List<Flight> _savedFlights = [];
  bool _isLoading = false;
  Map<String, List<Weather>> _metarsByIcao = {};
  Map<String, List<Weather>> _tafsByIcao = {};
  String? _selectedAirport; // Shared airport selection across all tabs
  
  // Navigation state tracking
  int? _lastViewedSystemPage; // Index of last viewed system page (0 = Overview, 1 = Runways, etc.)
  int? _lastViewedRawDataTab; // Index of last viewed Raw Data tab (0 = NOTAMs, 1 = METARs, 2 = TAFs)
  String? _lastViewedAirport; // Last viewed airport for state persistence
  
  // Global time filter state
  String _selectedTimeFilter = '24 hours'; // Default to 24 hours
  final List<String> _timeFilterOptions = [
    '6 hours',
    '12 hours',
    '24 hours',
    '72 hours',
    'All Future:',
  ];

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
  String? get selectedAirport => _selectedAirport;
  
  // Time filter getters
  String get selectedTimeFilter => _selectedTimeFilter;
  List<String> get timeFilterOptions => _timeFilterOptions;
  
  // Navigation state getters
  int? get lastViewedSystemPage => _lastViewedSystemPage;
  int? get lastViewedRawDataTab => _lastViewedRawDataTab;
  String? get lastViewedAirport => _lastViewedAirport;

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set selected airport (shared across all tabs)
  void setSelectedAirport(String? icao) {
    _selectedAirport = icao;
    notifyListeners();
  }
  
  // Set time filter (shared across all pages)
  void setTimeFilter(String filter) {
    _selectedTimeFilter = filter;
    notifyListeners();
  }
  
  // Navigation state setters
  void setLastViewedSystemPage(int? index) {
    _lastViewedSystemPage = index;
    debugPrint('DEBUG: Navigation state - Set last viewed system page to: $index');
    notifyListeners();
  }
  
  void setLastViewedRawDataTab(int? index) {
    _lastViewedRawDataTab = index;
    debugPrint('DEBUG: Navigation state - Set last viewed Raw Data tab to: $index');
    notifyListeners();
  }
  
  void setLastViewedAirport(String? icao) {
    _lastViewedAirport = icao;
    debugPrint('DEBUG: Navigation state - Set last viewed airport to: $icao');
    notifyListeners();
  }
  
  // Clear navigation state (for new briefings)
  void clearNavigationState() {
    _lastViewedSystemPage = null;
    _lastViewedRawDataTab = null;
    _lastViewedAirport = null;
    debugPrint('DEBUG: Navigation state - Cleared all navigation state');
    notifyListeners();
  }
  
  // Filter NOTAMs by time and airport
  List<Notam> filterNotamsByTimeAndAirport(List<Notam> notams, String airportIcao) {
    // First filter by airport
    final airportNotams = notams.where((notam) => notam.icao == airportIcao).toList();
    
    if (_selectedTimeFilter == 'All Future:') {
      return airportNotams;
    }

    final now = DateTime.now();
    final hours = _getHoursFromFilter(_selectedTimeFilter);
    final cutoffTime = now.add(Duration(hours: hours));

    return airportNotams.where((notam) => 
      // Include NOTAMs that are currently active or will become active within the time period
      notam.validFrom.isBefore(cutoffTime) && notam.validTo.isAfter(now)
    ).toList();
  }
  
  // Helper method to get hours from filter string
  int _getHoursFromFilter(String filter) {
    switch (filter) {
      case '6 hours':
        return 6;
      case '12 hours':
        return 12;
      case '24 hours':
        return 24;
      case '72 hours':
        return 72;
      default:
        return 24;
    }
  }

  /// Calculate real-time system status for an airport based on its NOTAMs
  Map<String, SystemStatus> _calculateAirportSystemStatus(String icao, List<Notam> notams) {
    final airportNotams = notams.where((n) => n.icao == icao).toList();
    
    return {
      'runways': _systemAnalyzer.analyzeRunwayStatus(airportNotams, icao),
      'taxiways': _systemAnalyzer.analyzeTaxiwayStatus(airportNotams, icao),
      'navaids': _systemAnalyzer.analyzeNavaidStatus(airportNotams, icao),
      'lighting': _systemAnalyzer.analyzeLightingStatus(airportNotams, icao),
      'hazards': _systemAnalyzer.analyzeHazardStatus(airportNotams, icao),
      'admin': _systemAnalyzer.analyzeAdminStatus(airportNotams, icao),
      'other': _systemAnalyzer.analyzeOtherStatus(airportNotams, icao),
    };
  }

  /// Update system status for all airports based on current NOTAMs
  void _updateAllAirportSystemStatus() {
    if (_currentFlight == null) return;
    
    for (int i = 0; i < _currentFlight!.airports.length; i++) {
      final airport = _currentFlight!.airports[i];
      final updatedAirport = Airport(
        icao: airport.icao,
        name: airport.name,
        city: airport.city,
        latitude: airport.latitude,
        longitude: airport.longitude,
        systems: _calculateAirportSystemStatus(airport.icao, _currentFlight!.notams),
        runways: airport.runways,
        navaids: airport.navaids,
      );
      _currentFlight!.airports[i] = updatedAirport;
    }
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
    _updateAllAirportSystemStatus(); // Ensure system status is calculated
    clearNavigationState(); // Clear navigation state for new briefings
    notifyListeners();
  }

  // Load a specific flight from the saved list to be the current one
  void loadFlight(Flight flight) {
    _currentFlight = flight;
    _groupWeatherData();
    _updateAllAirportSystemStatus(); // Ensure system status is calculated
    notifyListeners();
  }

  // Save the current flight to the database
  Future<void> saveCurrentFlight() async {
    if (_currentFlight == null) return;
    
    await _dbService.saveFlight(_currentFlight!);
    
    // Refresh the list of saved flights from the DB
    await loadSavedFlights();
  }

  // Update flight data - NO CACHING
  void updateFlightData({
    List<Airport>? airports,
    List<Notam>? notams,
    List<Weather>? weather,
  }) {
    if (_currentFlight != null) {
      if (airports != null) _currentFlight!.airports = airports;
      if (notams != null) {
        print('DEBUG: 🔍 FlightProvider - Setting ${notams.length} fresh NOTAMs (no cache)');
        _currentFlight!.notams = notams;
        
        // Recalculate system status for all airports based on new NOTAMs
        _updateAllAirportSystemStatus();
      }
      if (weather != null) {
        print('DEBUG: 🔍 FlightProvider - Setting ${weather.length} fresh weather items (no cache)');
        _currentFlight!.weather = weather;
      }
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

  // Refresh flight data by refetching from APIs - NO CACHING
  Future<void> refreshFlightData() async {
    print('DEBUG: 🔄 refreshFlightData() called!');
    if (_currentFlight == null || _currentFlight!.airports.isEmpty) {
      print('DEBUG: ⚠️ No current flight or airports, skipping refresh');
      return;
    }

    print('DEBUG: 🔄 Force refreshing flight data - NO CACHING...');
    setLoading(true);
    
    try {
      // Clear existing data to force fresh fetch
      _currentFlight!.notams.clear();
      _currentFlight!.weather.clear();
      _metarsByIcao.clear();
      _tafsByIcao.clear();
      
      // Force notify listeners to clear UI
      notifyListeners();
      
      // Clear ALL database cache - no caching for aviation safety
      final dbService = DatabaseService();
      await dbService.clearAllData();
      
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
      
      print('DEBUG: 🔍 FlightProvider - Total NOTAMs after flattening: ${allNotams.length}');
      print('DEBUG: 🔍 FlightProvider - NOTAMs per airport:');
      for (int i = 0; i < icaos.length; i++) {
        print('DEBUG: 🔍   ${icaos[i]}: ${notamResults[i].length} NOTAMs');
      }
      
      // Update the current flight with fresh data
      updateFlightData(
        notams: allNotams,
        weather: allWeather,
      );
      
      // Ensure system status is recalculated after data refresh
      _updateAllAirportSystemStatus();
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
      
      // Create a new airport object with placeholder systems (will be updated after NOTAM fetch)
      final newAirport = Airport(
        icao: icao.toUpperCase(),
        name: 'Unknown Airport', // We could fetch this from an airport database later
        city: 'Unknown City', // Placeholder value
        latitude: 0.0, // Placeholder values
        longitude: 0.0,
        systems: {}, // Will be updated with real status after NOTAM fetch
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

      // Update airport system status with real NOTAM analysis
      final airportIndex = _currentFlight!.airports.indexWhere((airport) => airport.icao == icao.toUpperCase());
      if (airportIndex != -1) {
        final updatedAirport = Airport(
          icao: _currentFlight!.airports[airportIndex].icao,
          name: _currentFlight!.airports[airportIndex].name,
          city: _currentFlight!.airports[airportIndex].city,
          latitude: _currentFlight!.airports[airportIndex].latitude,
          longitude: _currentFlight!.airports[airportIndex].longitude,
          systems: _calculateAirportSystemStatus(icao.toUpperCase(), _currentFlight!.notams),
          runways: _currentFlight!.airports[airportIndex].runways,
          navaids: _currentFlight!.airports[airportIndex].navaids,
        );
        _currentFlight!.airports[airportIndex] = updatedAirport;
      }

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

      // Update system status for the updated airport
      final updatedAirport = Airport(
        icao: _currentFlight!.airports[airportIndex].icao,
        name: _currentFlight!.airports[airportIndex].name,
        city: _currentFlight!.airports[airportIndex].city,
        latitude: _currentFlight!.airports[airportIndex].latitude,
        longitude: _currentFlight!.airports[airportIndex].longitude,
        systems: _calculateAirportSystemStatus(newIcao.toUpperCase(), _currentFlight!.notams),
        runways: _currentFlight!.airports[airportIndex].runways,
        navaids: _currentFlight!.airports[airportIndex].navaids,
      );
      _currentFlight!.airports[airportIndex] = updatedAirport;

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