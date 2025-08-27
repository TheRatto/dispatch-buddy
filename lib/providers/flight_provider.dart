import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/briefing.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/airport_system_analyzer.dart';
import '../services/briefing_conversion_service.dart';
import '../services/taf_state_manager.dart';
import '../services/briefing_refresh_service.dart'; // Added for refreshCurrentBriefing
import '../services/briefing_storage_service.dart'; // Added for loadBriefing
import '../services/cache_manager.dart'; // Added for cache clearing
import '../services/airport_database.dart'; // Added for airport lookup
import '../providers/settings_provider.dart'; // Added for NAIPS settings

class FlightProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AirportSystemAnalyzer _systemAnalyzer = AirportSystemAnalyzer();
  Flight? _currentFlight;
  Briefing? _currentBriefing; // Track the currently loaded briefing
  List<Flight> _savedFlights = [];
  bool _isLoading = false;
  Map<String, List<Weather>> _metarsByIcao = {};
  Map<String, List<Weather>> _tafsByIcao = {};
  String? _selectedAirport; // Shared airport selection across all tabs
  bool _naipsFallbackUsed = false; // One-time snackbar flag for NAIPS fallback
  
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

  // Timer-based status updates
  Timer? _statusUpdateTimer;
  static const Duration _statusUpdateInterval = Duration(minutes: 15);
  bool _isStatusUpdateEnabled = true;

  FlightProvider() {
    // Load saved flights when the provider is initialized
    loadSavedFlights();
    // Start the status update timer
    _startStatusUpdateTimer();
  }

  @override
  void dispose() {
    _stopStatusUpdateTimer();
    super.dispose();
  }

  // Timer management methods
  void _startStatusUpdateTimer() {
    if (_statusUpdateTimer != null) {
      _statusUpdateTimer!.cancel();
    }
    
    _statusUpdateTimer = Timer.periodic(_statusUpdateInterval, (timer) {
      if (_isStatusUpdateEnabled && _currentFlight != null) {
        _refreshAllAirportSystemStatus();
        debugPrint('DEBUG: 🔄 Status update timer triggered - refreshed system status for ${_currentFlight!.airports.length} airports');
      }
    });
    
    debugPrint('DEBUG: 🔄 Status update timer started - interval: ${_statusUpdateInterval.inMinutes} minutes');
  }

  void _stopStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
    debugPrint('DEBUG: 🔄 Status update timer stopped');
  }

  void _refreshAllAirportSystemStatus() {
    if (_currentFlight == null) return;
    
    // Update system status for all airports
    _updateAllAirportSystemStatus();
    
    // Notify listeners that status has been updated
    notifyListeners();
  }

  // Public method to manually refresh status (for pull-to-refresh)
  void refreshSystemStatus() {
    debugPrint('DEBUG: 🔄 Manual system status refresh requested');
    _refreshAllAirportSystemStatus();
  }

  // Public method to enable/disable automatic updates
  void setStatusUpdateEnabled(bool enabled) {
    _isStatusUpdateEnabled = enabled;
    if (enabled) {
      _startStatusUpdateTimer();
    } else {
      _stopStatusUpdateTimer();
    }
    debugPrint('DEBUG: 🔄 Status updates ${enabled ? 'enabled' : 'disabled'}');
  }

  // Getters
  Flight? get currentFlight => _currentFlight;
  Briefing? get currentBriefing => _currentBriefing; // Get the currently loaded briefing
  List<Flight> get savedFlights => _savedFlights;
  bool get isLoading => _isLoading;
  Map<String, List<Weather>> get metarsByIcao => _metarsByIcao;
  Map<String, List<Weather>> get tafsByIcao => _tafsByIcao;
  String? get selectedAirport => _selectedAirport;
  // UI can call this after refresh to show a one-time snackbar if true
  bool consumeNaipsFallbackUsed() {
    final used = _naipsFallbackUsed;
    _naipsFallbackUsed = false;
    return used;
  }
  
  // Time filter getters
  String get selectedTimeFilter => _selectedTimeFilter;
  List<String> get timeFilterOptions => _timeFilterOptions;
  
  // Timer status getters
  bool get isStatusUpdateEnabled => _isStatusUpdateEnabled;
  Duration get statusUpdateInterval => _statusUpdateInterval;
  
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
    debugPrint('DEBUG: Navigation state cleared for new briefing');
    notifyListeners();
  }
  
  // Filter NOTAMs by time and airport
  List<Notam> filterNotamsByTimeAndAirport(List<Notam> notams, String airportIcao) {
    // First filter by airport
    final airportNotams = notams.where((notam) => notam.icao == airportIcao).toList();
    
    // Filter out CNL (Cancellation) NOTAMs - they don't provide useful operational information
    final activeNotams = airportNotams.where((notam) => 
      !notam.rawText.toUpperCase().contains('CNL NOTAM')
    ).toList();
    
    if (_selectedTimeFilter == 'All Future:') {
      return activeNotams;
    }

    final now = DateTime.now();
    final hours = _getHoursFromFilter(_selectedTimeFilter);
    final cutoffTime = now.add(Duration(hours: hours));

    return activeNotams.where((notam) => 
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

  // Load a briefing as the current flight (from saved/cached data)
  Future<void> loadBriefing(Briefing briefing) async {
    debugPrint('DEBUG: FlightProvider.loadBriefing called for briefing ${briefing.id}');
    debugPrint('DEBUG: Briefing name: ${briefing.displayName}');
    debugPrint('DEBUG: Briefing airports: ${briefing.airports}');
    debugPrint('DEBUG: Briefing NOTAM count: ${briefing.notams.length}');
    debugPrint('DEBUG: Briefing weather count: ${briefing.weather.length}');
    
    // Set the current briefing
    _currentBriefing = briefing;
    
    // Debug: Print sample data from briefing storage
    if (briefing.notams.isNotEmpty) {
      final sampleNotamKey = briefing.notams.keys.first;
      final sampleNotam = briefing.notams[sampleNotamKey];
      debugPrint('DEBUG: Sample stored NOTAM - Key: $sampleNotamKey, Type: ${sampleNotam['type']}, ICAO: ${sampleNotam['icao']}');
    } else {
      debugPrint('DEBUG: No NOTAMs found in briefing storage');
    }
    if (briefing.weather.isNotEmpty) {
      final sampleWeatherKey = briefing.weather.keys.first;
      final sampleWeather = briefing.weather[sampleWeatherKey];
      final rawText = sampleWeather['rawText']?.toString() ?? '';
      final preview = rawText.length > 30 ? '${rawText.substring(0, 30)}...' : rawText;
      debugPrint('DEBUG: Sample stored Weather - Key: $sampleWeatherKey, Type: ${sampleWeather['type']}, Raw: $preview');
    } else {
      debugPrint('DEBUG: No weather found in briefing storage');
    }
    
    // Convert briefing to flight using the new async method with versioned data support
    final flight = await BriefingConversionService.briefingToFlight(briefing);
    
    debugPrint('DEBUG: FlightProvider - Converted flight has ${flight.notams.length} NOTAMs and ${flight.weather.length} weather items');
    
    // Debug: Print sample converted data
    if (flight.notams.isNotEmpty) {
      final sampleNotam = flight.notams.first;
      debugPrint('DEBUG: Sample converted NOTAM - ID: ${sampleNotam.id}, Type: ${sampleNotam.type}, ICAO: ${sampleNotam.icao}');
    } else {
      debugPrint('DEBUG: No NOTAMs found after conversion');
    }
    if (flight.weather.isNotEmpty) {
      final sampleWeather = flight.weather.first;
      final preview = sampleWeather.rawText.length > 30 ? '${sampleWeather.rawText.substring(0, 30)}...' : sampleWeather.rawText;
      debugPrint('DEBUG: Sample converted Weather - Type: ${sampleWeather.type}, ICAO: ${sampleWeather.icao}, Raw: $preview');
    } else {
      debugPrint('DEBUG: No weather found after conversion');
    }
    
    // Clear any UI-level caches that might interfere with loaded briefing data
    debugPrint('DEBUG: Clearing UI caches before loading briefing data');
    
    // Import and clear TAF state manager cache
    try {
      final tafStateManager = TafStateManager();
      tafStateManager.clearCache();
      debugPrint('DEBUG: Cleared TAF state manager cache');
    } catch (e) {
      debugPrint('DEBUG: Failed to clear TAF cache: $e');
    }
    
    setCurrentFlight(flight);
    debugPrint('DEBUG: FlightProvider - Loaded briefing ${briefing.id} as current flight');
  }

  /// Unified refresh method that can refresh any briefing by ID
  /// This method fetches fresh data from APIs and replaces the entire briefing
  /// Used by card refresh when the briefing is not currently loaded
  Future<bool> refreshBriefingByIdUnified(String briefingId) async {
    debugPrint('DEBUG: 🚀 refreshBriefingByIdUnified called for briefing $briefingId');
    
    try {
      // Load the briefing from storage first
      final briefing = await BriefingStorageService.loadBriefing(briefingId);
      if (briefing == null) {
        debugPrint('DEBUG: Briefing $briefingId not found in storage');
        return false;
      }
      
      // Use the working BriefingRefreshService instead of the broken BriefingReplaceService
      final success = await BriefingRefreshService.refreshBriefing(briefing);
      
      if (success) {
        // Always load the refreshed briefing into the UI
        final refreshedBriefing = await BriefingStorageService.loadBriefing(briefingId);
        if (refreshedBriefing != null) {
          _currentBriefing = refreshedBriefing;
          await loadBriefing(refreshedBriefing);
          debugPrint('DEBUG: Successfully loaded refreshed briefing $briefingId into UI');
          // Evaluate NAIPS fallback on loaded data
          try {
            final settingsProvider = SettingsProvider();
            await settingsProvider.initialize();
            if (settingsProvider.naipsEnabled) {
              final weatherList = _currentFlight?.weather ?? [];
              final usedNaips = weatherList.any((w) => w.source == 'naips');
              _naipsFallbackUsed = !usedNaips;
              debugPrint('DEBUG: NAIPS fallback used (post-refresh load): $_naipsFallbackUsed');
            } else {
              _naipsFallbackUsed = false;
            }
          } catch (e) {
            debugPrint('DEBUG: Failed to evaluate NAIPS fallback flag after refresh: $e');
          }
        } else {
          debugPrint('DEBUG: Failed to load refreshed briefing $briefingId from storage');
        }
        
        debugPrint('DEBUG: Successfully completed unified refresh for briefing $briefingId');
        return true;
      } else {
        debugPrint('DEBUG: Unified refresh failed - refresh operation returned false');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: Unified refresh failed with error: $e');
      return false;
    }
  }

  /// Bulk refresh method that refreshes a briefing without loading it into the UI
  /// This is used for "Refresh All" functionality to avoid UI conflicts
  Future<bool> refreshBriefingByIdForBulk(String briefingId) async {
    debugPrint('DEBUG: 🚀 refreshBriefingByIdForBulk called for briefing $briefingId');
    
    try {
      // Load the briefing from storage first
      final briefing = await BriefingStorageService.loadBriefing(briefingId);
      if (briefing == null) {
        debugPrint('DEBUG: Briefing $briefingId not found in storage');
        return false;
      }
      
      // Use the working BriefingRefreshService instead of the broken BriefingReplaceService
      final success = await BriefingRefreshService.refreshBriefing(briefing);
      
      if (success) {
        // Debug: Check what data was stored after refresh
        final refreshedBriefing = await BriefingStorageService.loadBriefing(briefingId);
        if (refreshedBriefing != null) {
          debugPrint('DEBUG: Bulk refresh - Stored briefing has ${refreshedBriefing.notams.length} NOTAM entries');
          debugPrint('DEBUG: Bulk refresh - Stored briefing has ${refreshedBriefing.weather.length} weather entries');
          
          // Check if NOTAMs are actually stored
          if (refreshedBriefing.notams.isNotEmpty) {
            final sampleNotamKey = refreshedBriefing.notams.keys.first;
            final sampleNotam = refreshedBriefing.notams[sampleNotamKey];
            debugPrint('DEBUG: Bulk refresh - Sample NOTAM stored: Key=$sampleNotamKey, Type=${sampleNotam['type']}, ICAO=${sampleNotam['icao']}');
          }
        }
        
        // Clear caches to ensure fresh data is loaded when viewing the briefing
        debugPrint('DEBUG: Clearing caches after bulk refresh');
        try {
          // Clear TAF state manager cache
          final tafStateManager = TafStateManager();
          tafStateManager.clearCache();
          debugPrint('DEBUG: Cleared TAF state manager cache');
          
          // Clear NOTAM cache by invalidating the cache manager
          // This will force the raw data screen to reload NOTAMs from fresh data
          final cacheManager = CacheManager();
          cacheManager.clear(); // Clear all caches to be safe
          debugPrint('DEBUG: Cleared all caches');
        } catch (e) {
          debugPrint('DEBUG: Failed to clear caches: $e');
        }
        
        debugPrint('DEBUG: Successfully completed bulk refresh for briefing $briefingId');
        return true;
      } else {
        debugPrint('DEBUG: Bulk refresh failed - refresh operation returned false');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: Bulk refresh failed with error: $e');
      return false;
    }
  }

  /// Unified refresh method that replaces the current briefing with fresh data
  /// This method fetches fresh data from APIs and replaces the entire briefing
  /// Used by all refresh triggers (card refresh, pull-to-refresh, "Refresh All")
  Future<bool> refreshCurrentBriefingUnified() async {
    if (_currentBriefing == null) {
      debugPrint('DEBUG: No current briefing to refresh');
      return false;
    }

    debugPrint('DEBUG: Starting unified refresh for briefing ${_currentBriefing!.id}');
    
    try {
      // Use the working BriefingRefreshService instead of the broken BriefingReplaceService
      final success = await BriefingRefreshService.refreshBriefing(_currentBriefing!);
      
      if (success) {
        // Load the refreshed briefing from storage
        final refreshedBriefing = await BriefingStorageService.loadBriefing(_currentBriefing!.id);
        
        if (refreshedBriefing != null) {
          // Update the current briefing and convert to flight
          _currentBriefing = refreshedBriefing;
          await loadBriefing(refreshedBriefing);
          
          debugPrint('DEBUG: Successfully completed unified refresh');
          return true;
        } else {
          debugPrint('DEBUG: Unified refresh failed - no refreshed briefing returned');
          return false;
        }
      } else {
        debugPrint('DEBUG: Unified refresh failed - refresh operation returned false');
        return false;
      }
    } catch (e) {
      debugPrint('DEBUG: Unified refresh failed with error: $e');
      return false;
    }
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
        debugPrint('DEBUG: 🔍 FlightProvider - Setting ${notams.length} fresh NOTAMs (no cache)');
        _currentFlight!.notams = notams;
        
        // Recalculate system status for all airports based on new NOTAMs
        _updateAllAirportSystemStatus();
      }
      if (weather != null) {
        debugPrint('DEBUG: 🔍 FlightProvider - Setting ${weather.length} fresh weather items (no cache)');
        _currentFlight!.weather = weather;
      }
      _groupWeatherData();
      notifyListeners();
    }
  }

  void _groupWeatherData() {
    debugPrint('DEBUG: _groupWeatherData called with ${_currentFlight?.weather.length ?? 0} weather items');
    _metarsByIcao = {};
    _tafsByIcao = {};
    if (_currentFlight != null) {
      // Debug: Show total weather breakdown
      final metars = _currentFlight!.weather.where((w) => w.type == 'METAR').toList();
      final tafs = _currentFlight!.weather.where((w) => w.type == 'TAF').toList();
      final atis = _currentFlight!.weather.where((w) => w.type == 'ATIS').toList();
      debugPrint('DEBUG: Total weather breakdown - METARs: ${metars.length}, TAFs: ${tafs.length}, ATIS: ${atis.length}');
      
      for (final weather in _currentFlight!.weather) {
        debugPrint('DEBUG: Processing weather - Type: ${weather.type}, ICAO: ${weather.icao}, Timestamp: ${weather.timestamp}');
        if (weather.type == 'METAR') {
          final preview = weather.rawText.length > 30 ? '${weather.rawText.substring(0, 30)}...' : weather.rawText;
          debugPrint('DEBUG: Adding METAR for ${weather.icao} - Timestamp: ${weather.timestamp}, Raw: $preview');
          if (!_metarsByIcao.containsKey(weather.icao)) {
            _metarsByIcao[weather.icao] = [];
          }
          _metarsByIcao[weather.icao]!.add(weather);
        } else if (weather.type == 'TAF') {
          final preview = weather.rawText.length > 30 ? '${weather.rawText.substring(0, 30)}...' : weather.rawText;
          debugPrint('DEBUG: Adding TAF for ${weather.icao} - Timestamp: ${weather.timestamp}, Raw: $preview');
          if (!_tafsByIcao.containsKey(weather.icao)) {
            _tafsByIcao[weather.icao] = [];
          }
          _tafsByIcao[weather.icao]!.add(weather);
        } else if (weather.type == 'ATIS') {
          final preview = weather.rawText.length > 30 ? '${weather.rawText.substring(0, 30)}...' : weather.rawText;
          debugPrint('DEBUG: Adding ATIS for ${weather.icao} - Timestamp: ${weather.timestamp}, Code: ${weather.atisCode}, Raw: $preview');
          // ATIS is stored in the main weather list, no separate grouping needed
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
  Future<void> refreshFlightData({bool? naipsEnabled, String? naipsUsername, String? naipsPassword}) async {
    debugPrint('DEBUG: 🔄 refreshFlightData() called!');
    if (_currentFlight == null || _currentFlight!.airports.isEmpty) {
      debugPrint('DEBUG: ⚠️ No current flight or airports, skipping refresh');
      return;
    }

    debugPrint('DEBUG: 🔄 Force refreshing flight data - NO CACHING...');
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
      
      // Ensure SettingsProvider is properly initialized before calling API service
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      final apiService = ApiService();
      final icaos = _currentFlight!.airports.map((airport) => airport.icao).toList();
      
      // Use provided NAIPS settings or load from SettingsProvider if not provided
      naipsEnabled ??= settingsProvider.naipsEnabled;
      naipsUsername ??= settingsProvider.naipsUsername;
      naipsPassword ??= settingsProvider.naipsPassword;
      
      debugPrint('DEBUG: 🔄 FlightProvider - NAIPS settings being passed to API: enabled=$naipsEnabled, username=${naipsUsername != null ? "SET" : "NOT SET"}, password=${naipsPassword != null ? "SET" : "NOT SET"}');
      
      // Fetch all data in parallel using the new separate methods
      final notamsFuture = Future.wait(icaos.map((icao) => apiService.fetchNotams(icao)));
      final metarsFuture = apiService.fetchMetars(icaos);
      final atisFuture = apiService.fetchAtis(icaos);
      final tafsFuture = apiService.fetchTafs(icaos);

      final results = await Future.wait([notamsFuture, metarsFuture, atisFuture, tafsFuture]);

      final List<List<Notam>> notamResults = results[0] as List<List<Notam>>;
      final List<Weather> metars = results[1] as List<Weather>;
      final List<Weather> atis = results[2] as List<Weather>;
      final List<Weather> tafs = results[3] as List<Weather>;

      // Flatten the list of lists into a single list
      final List<Notam> allNotams = notamResults.expand((notamList) => notamList).toList();

      // Deduplicate by ICAO and latest timestamp, per type, to avoid multiple cards per airport
      final Map<String, Weather> latestMetarByIcao = {};
      for (final m in metars.where((w) => w.type == 'METAR')) {
        final existing = latestMetarByIcao[m.icao];
        if (existing == null || m.timestamp.isAfter(existing.timestamp)) {
          latestMetarByIcao[m.icao] = m;
        }
      }

      final Map<String, Weather> latestAtisByIcao = {};
      for (final a in atis.where((w) => w.type == 'ATIS')) {
        final existing = latestAtisByIcao[a.icao];
        if (existing == null || a.timestamp.isAfter(existing.timestamp)) {
          latestAtisByIcao[a.icao] = a;
        }
      }

      final Map<String, Weather> latestTafByIcao = {};
      for (final t in tafs.where((w) => w.type == 'TAF')) {
        final existing = latestTafByIcao[t.icao];
        if (existing == null || t.timestamp.isAfter(existing.timestamp)) {
          latestTafByIcao[t.icao] = t;
        }
      }

      final List<Weather> allWeather = [
        ...latestMetarByIcao.values,
        ...latestAtisByIcao.values,
        ...latestTafByIcao.values,
      ];

      debugPrint('DEBUG: 🔍 FlightProvider - Weather breakdown (deduped):');
      debugPrint('DEBUG: 🔍   - METARs (latest per ICAO): ${latestMetarByIcao.length}');
      debugPrint('DEBUG: 🔍   - ATIS (latest per ICAO): ${latestAtisByIcao.length}');
      debugPrint('DEBUG: 🔍   - TAFs (latest per ICAO): ${latestTafByIcao.length}');
      debugPrint('DEBUG: 🔍   - Total weather: ${allWeather.length}');
      
      debugPrint('DEBUG: 🔍 FlightProvider - Total NOTAMs after flattening: ${allNotams.length}');
      debugPrint('DEBUG: 🔍 FlightProvider - NOTAMs per airport:');
      for (int i = 0; i < icaos.length; i++) {
        debugPrint('DEBUG: 🔍   ${icaos[i]}: ${notamResults[i].length} NOTAMs');
      }
      
      // Update the current flight with fresh data
      updateFlightData(
        notams: allNotams,
        weather: allWeather,
      );
      
      // Ensure system status is recalculated after data refresh
      _updateAllAirportSystemStatus();

      // Evaluate NAIPS fallback: if NAIPS is enabled but no NAIPS weather present
      try {
        final settingsProvider = SettingsProvider();
        await settingsProvider.initialize();
        if (settingsProvider.naipsEnabled) {
          final usedNaips = allWeather.any((w) => w.source == 'naips');
          _naipsFallbackUsed = !usedNaips;
          debugPrint('DEBUG: NAIPS fallback used flag set to: $_naipsFallbackUsed');
        } else {
          _naipsFallbackUsed = false;
        }
      } catch (e) {
        debugPrint('DEBUG: Could not evaluate NAIPS fallback flag: $e');
      }
    } catch (e) {
      debugPrint('Error refreshing flight data: $e');
      // Don't throw - let the UI handle the error gracefully
    } finally {
      setLoading(false);
    }
  }

  // Add an airport to the current flight
  Future<bool> addAirportToFlight(String icao, {bool? naipsEnabled, String? naipsUsername, String? naipsPassword}) async {
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
      
      // Use provided NAIPS settings or defaults
      naipsEnabled ??= false;
      naipsUsername ??= null;
      naipsPassword ??= null;
      
      debugPrint('DEBUG: 🔄 FlightProvider.addAirportToFlight - NAIPS settings: enabled=$naipsEnabled, username=${naipsUsername != null ? "SET" : "NOT SET"}, password=${naipsPassword != null ? "SET" : "NOT SET"}');
      
      // Ensure SettingsProvider is properly initialized before calling API service
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      // Get proper airport data from database
      final airportData = await AirportDatabase.getAirportWithFallback(icao);
      final airportName = airportData?.name ?? '$icao Airport';
      final airportCity = airportData?.city ?? 'Unknown City';
      
      // Create a new airport object with proper data
      final newAirport = Airport(
        icao: icao.toUpperCase(),
        name: airportName,
        city: airportCity,
        latitude: airportData?.latitude ?? 0.0,
        longitude: airportData?.longitude ?? 0.0,
        systems: {}, // Will be updated with real status after NOTAM fetch
        runways: airportData?.runways ?? [],
        navaids: airportData?.navaids ?? [],
      );

      // Add the airport to the current flight
      _currentFlight!.airports.add(newAirport);

      // Fetch data for the new airport
      debugPrint('DEBUG: 🔄 FlightProvider.addAirportToFlight - Calling API service with NAIPS enabled: $naipsEnabled');
      
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
      debugPrint('Error adding airport $icao: $e');
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

      // Get proper airport data for the new ICAO
      final airportData = await AirportDatabase.getAirportWithFallback(newIcao);
      final airportName = airportData?.name ?? '$newIcao Airport';
      final airportCity = airportData?.city ?? 'Unknown City';

      // Update the airport ICAO with proper data
      _currentFlight!.airports[airportIndex] = Airport(
        icao: newIcao.toUpperCase(),
        name: airportName,
        city: airportCity,
        latitude: airportData?.latitude ?? 0.0,
        longitude: airportData?.longitude ?? 0.0,
        systems: _currentFlight!.airports[airportIndex].systems,
        runways: airportData?.runways ?? [],
        navaids: airportData?.navaids ?? [],
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
      debugPrint('Error updating airport from $oldIcao to $newIcao: $e');
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
      debugPrint('Error removing airport $icao: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Refresh airport names in the current flight
  Future<void> refreshAirportNames() async {
    if (_currentFlight == null) return;
    
    for (int i = 0; i < _currentFlight!.airports.length; i++) {
      final airport = _currentFlight!.airports[i];
      
      // Skip if airport already has a proper name (not a placeholder)
      if (airport.name != '${airport.icao} Airport' && airport.name.isNotEmpty) {
        continue;
      }
      
      // Get proper airport data from database
      final airportData = await AirportDatabase.getAirportWithFallback(airport.icao);
      if (airportData != null) {
        final updatedAirport = Airport(
          icao: airport.icao,
          name: airportData.name,
          city: airportData.city,
          latitude: airportData.latitude,
          longitude: airportData.longitude,
          systems: airport.systems,
          runways: airportData.runways,
          navaids: airportData.navaids,
        );
        _currentFlight!.airports[i] = updatedAirport;
      }
    }
    
    notifyListeners();
  }

    /// Unified refresh method that handles both current and previous briefings
  /// Uses BriefingRefreshService for consistent behavior with refresh buttons
  Future<void> refreshCurrentData({
    bool? naipsEnabled,
    String? naipsUsername,
    String? naipsPassword,
  }) async {
    if (_currentBriefing != null) {
      // For previous briefings, use the briefing refresh method
      await refreshBriefingByIdUnified(_currentBriefing!.id);
    } else {
      // For current briefings, first refresh flight data to get fresh data
      await refreshFlightData(
        naipsEnabled: naipsEnabled,
        naipsUsername: naipsUsername,
        naipsPassword: naipsPassword,
      );
      
      // Then use BriefingRefreshService to properly save and version the data
      if (_currentFlight != null) {
        // Create a briefing from the current flight
        final briefing = Briefing(
          id: _currentFlight!.id,
          airports: _currentFlight!.airports.map((a) => a.icao).toList(),
          timestamp: _currentFlight!.createdAt,
          notams: _currentFlight!.notams.fold<Map<String, Map<String, dynamic>>>(
            {},
            (map, notam) {
              map[notam.id] = {
                'id': notam.id,
                'icao': notam.icao,
                'type': notam.type.toString(),
                'validFrom': notam.validFrom.toIso8601String(),
                'validTo': notam.validTo.toIso8601String(),
                'rawText': notam.rawText,
                'fieldD': notam.fieldD,
                'fieldE': notam.fieldE,
                'fieldF': notam.fieldF,
                'fieldG': notam.fieldG,
                'qCode': notam.qCode,
                'group': notam.group.name,
                'isPermanent': notam.isPermanent,
                'source': notam.source,
                'isCritical': notam.isCritical,
              };
              return map;
            },
          ),
          weather: _currentFlight!.weather.fold<Map<String, Map<String, dynamic>>>(
            {},
            (map, weather) {
              map['${weather.icao}_${weather.type}_${weather.timestamp.millisecondsSinceEpoch}'] = {
                'icao': weather.icao,
                'timestamp': weather.timestamp.toIso8601String(),
                'rawText': weather.rawText,
                'decodedText': weather.decodedText,
                'windDirection': weather.windDirection,
                'windSpeed': weather.windSpeed,
                'visibility': weather.visibility,
                'cloudCover': weather.cloudCover,
                'temperature': weather.temperature,
                'dewPoint': weather.dewPoint,
                'qnh': weather.qnh,
                'conditions': weather.conditions,
                'type': weather.type,
                'source': weather.source,
              };
              return map;
            },
          ),
        );
        
        // Use BriefingRefreshService to properly refresh and version the briefing
        debugPrint('DEBUG: Using BriefingRefreshService for current briefing refresh');
        final success = await BriefingRefreshService.refreshBriefing(briefing);
        
        if (success) {
          debugPrint('DEBUG: Successfully refreshed current briefing using BriefingRefreshService');
          // Load the refreshed briefing into the UI
          final refreshedBriefing = await BriefingStorageService.loadBriefing(briefing.id);
          if (refreshedBriefing != null) {
            _currentBriefing = refreshedBriefing;
            await loadBriefing(refreshedBriefing);
            debugPrint('DEBUG: Loaded refreshed current briefing into UI');
          }
        } else {
          debugPrint('DEBUG: Failed to refresh current briefing using BriefingRefreshService');
        }
      }
    }
  }

  // Get NOTAMs for display - now simplified since all NOTAMs are from FAA API
  List<Notam> getDisplayNotams() {
    if (_currentFlight == null) return [];
    
    // All NOTAMs are now from FAA API, so return them all
    debugPrint('DEBUG: 🔍 FlightProvider - Display NOTAMs: ${_currentFlight!.notams.length} FAA API NOTAMs');
    
    return _currentFlight!.notams;
  }

  // Get all NOTAMs (including NAIPS) - for system analysis
  List<Notam> getAllNotams() {
    if (_currentFlight == null) return [];
    return _currentFlight!.notams;
  }

  // Get NOTAMs by source for analysis
  Map<String, List<Notam>> getNotamsBySource() {
    if (_currentFlight == null) return {};
    
    final notamsBySource = <String, List<Notam>>{};
    for (final notam in _currentFlight!.notams) {
      notamsBySource.putIfAbsent(notam.source, () => []).add(notam);
    }
    
    return notamsBySource;
  }

  // Get NOTAM statistics by source
  Map<String, int> getNotamSourceStats() {
    if (_currentFlight == null) return {};
    
    final stats = <String, int>{};
    for (final notam in _currentFlight!.notams) {
      stats[notam.source] = (stats[notam.source] ?? 0) + 1;
    }
    
    return stats;
  }
} 