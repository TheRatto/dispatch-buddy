import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/global_drawer.dart';
import '../widgets/zulu_time_widget.dart';
import '../widgets/flight_plan_form_card.dart';
import '../widgets/quick_start_card.dart';
import '../widgets/date_time_picker_dialog.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/weather.dart';
import '../models/notam.dart';
import '../models/briefing.dart';
import '../services/api_service.dart';
import '../services/airport_database.dart';
import '../services/briefing_storage_service.dart';
import '../services/airport_selection_service.dart';
import 'briefing_tabs_screen.dart';
import 'package:flutter/foundation.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _flightLevelController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;
  bool _isZuluTime = false; // Toggle between local and Zulu time

  @override
  void initState() {
    super.initState();
    
    // Check if there's existing flight data to pre-populate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flightProvider = context.read<FlightProvider>();
      final currentFlight = flightProvider.currentFlight;
      
      if (currentFlight != null) {
        // Pre-populate with existing data
        _routeController.text = currentFlight.route;
        _selectedDateTime = currentFlight.etd;
        _flightLevelController.text = currentFlight.flightLevel;
        setState(() {}); // Update the UI
      } else {
        // Set default values for testing
        _routeController.text = 'YPPH YSSY WSSS KJFK CYYZ EGLL';
        _flightLevelController.text = 'FL350';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
            SizedBox(height: 2),
            Text(
              'New Briefing',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                debugPrint('DEBUG: Hamburger menu pressed - opening end drawer');
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const GlobalDrawer(currentScreen: '/raw'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flight Plan Input Section
              FlightPlanFormCard(
                routeController: _routeController,
                flightLevelController: _flightLevelController,
                selectedDateTime: _selectedDateTime,
                isZuluTime: _isZuluTime,
                onTimeFormatChanged: () {
                  setState(() => _isZuluTime = !_isZuluTime);
                },
                onDateTimeTap: _selectDateTime,
              ),
              
              const SizedBox(height: 24),
              
              // Quick Start with Airport Selection
              QuickStartCard(
                isLoading: _isLoading,
                onAirportsSelected: _handleAirportSelection,
              ),
              
              const SizedBox(height: 24),
              
              // Generate Briefing Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateBriefing,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(
                  _isLoading ? 'Generating Briefing...' : 'Generate Briefing',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DateTimePickerDialog(
          initialDateTime: _selectedDateTime,
          isZuluTime: _isZuluTime,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDateTime = result;
      });
    }
  }

  void _generateBriefing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    context.read<FlightProvider>().setLoading(true);

    try {
      // Get NAIPS settings from SettingsProvider
      final settingsProvider = SettingsProvider();
      await settingsProvider.initialize();
      
      debugPrint('DEBUG: 🔄 InputScreen - NAIPS settings from SettingsProvider: enabled=${settingsProvider.naipsEnabled}, username=${settingsProvider.naipsUsername != null ? "SET" : "NOT SET"}, password=${settingsProvider.naipsPassword != null ? "SET" : "NOT SET"}');
      
      // Debug: Check if NAIPS is actually enabled
      if (settingsProvider.naipsEnabled) {
        debugPrint('DEBUG: 🔄 InputScreen - NAIPS is ENABLED, will attempt to fetch from NAIPS');
      } else {
        debugPrint('DEBUG: 🔄 InputScreen - NAIPS is DISABLED, will only use aviationweather.gov');
      }

      final apiService = ApiService();

      final icaos = _routeController.text.toUpperCase().split(' ').where((s) => s.isNotEmpty).toSet().toList();
      
      // Fetch all data in parallel using the new batch methods
      // Use SATCOM-optimized NOTAM fetching with fallback strategies
      final notamsFuture = Future.wait(
        icaos.map((icao) => apiService.fetchNotams(icao).catchError((e) {
          debugPrint('Warning: All SATCOM NOTAM strategies failed for $icao: $e');
          return <Notam>[]; // Return empty list on error
        }))
      );
      final weatherFuture = apiService.fetchWeather(icaos);
      final tafsFuture = apiService.fetchTafs(icaos);

      final results = await Future.wait([notamsFuture, weatherFuture, tafsFuture]);

      final List<List<Notam>> notamResults = results[0] as List<List<Notam>>;
      final List<Weather> metars = results[1] as List<Weather>;
      final List<Weather> tafs = results[2] as List<Weather>;

      // Flatten the list of lists into a single list
      final List<Notam> allNotams = notamResults.expand((notamList) => notamList).toList();
      final List<Weather> allWeather = [...metars, ...tafs];
      
      final newFlight = Flight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        route: _routeController.text,
        departure: icaos.first,
        destination: icaos.last,
        etd: _selectedDateTime,
        flightLevel: _flightLevelController.text,
        alternates: [], // Can be parsed from route later
        createdAt: DateTime.now(),
        airports: await Future.wait(icaos.map((icao) async {
          final airport = await AirportDatabase.getAirportWithFallback(icao);
          if (airport != null) {
            return airport;
          }
          // Fallback to placeholder if not in database or API
          return Airport(
            icao: icao,
            name: '$icao Airport',
            city: 'Unknown',
            latitude: 0,
            longitude: 0,
            systems: {
              'runways': SystemStatus.green,
              'navaids': SystemStatus.green,
              'taxiways': SystemStatus.green,
              'lighting': SystemStatus.green,
            },
            runways: [],
            navaids: [],
          );
        })),
        notams: allNotams,
        weather: allWeather,
      );

      // Save to provider
      context.read<FlightProvider>().setCurrentFlight(newFlight);

      // Auto-save briefing to storage
      debugPrint('DEBUG: About to auto-save briefing...');
      await _autoSaveBriefing(newFlight, allNotams, allWeather);
      debugPrint('DEBUG: Auto-save briefing completed');

      // Navigate to summary
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BriefingTabsScreen()),
      );
    } catch (e, stackTrace) {
      debugPrint('Error generating briefing: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Check if this is a network-related error
      String errorMessage = 'Failed to generate briefing. Check console for details.';
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('nodename nor servname provided')) {
        errorMessage = 'Network connectivity issue detected. This may be due to SATCOM limitations. Weather data may still be available.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      context.read<FlightProvider>().setLoading(false);
    }
  }

  /// Handle airport selection from Quick Start modal
  Future<void> _handleAirportSelection(List<String> airports) async {
    if (airports.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('InputScreen: Handling airport selection: $airports');
      
      // Get flight provider
      final flightProvider = context.read<FlightProvider>();
      
      // Generate briefing from selected airports
      final success = await AirportSelectionService.generateBriefingFromAirports(
        airports,
        flightProvider,
      );
      
      if (success) {
        debugPrint('InputScreen: Briefing generated successfully, navigating to results');
        
        // Navigate to briefing results
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BriefingTabsScreen(),
            ),
          );
        }
      } else {
        debugPrint('InputScreen: Failed to generate briefing');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate briefing. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('InputScreen: Error handling airport selection: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Auto-save briefing to storage with smart naming
  Future<void> _autoSaveBriefing(Flight flight, List<Notam> notams, List<Weather> weather) async {
    try {
      debugPrint('DEBUG: _autoSaveBriefing called with ${notams.length} NOTAMs and ${weather.length} weather items');
      
      // Generate smart name for the briefing
      final name = _generateBriefingName(flight);
      debugPrint('DEBUG: Generated briefing name: $name');
      debugPrint('DEBUG: Converting ${notams.length} NOTAMs and ${weather.length} weather items to storage format');
      
      // Convert data to storage format
      final notamsMap = <String, dynamic>{
        for (final notam in notams)
          notam.id: {
            'id': notam.id,
            'icao': notam.icao,
            'rawText': notam.rawText,
            'fieldD': notam.fieldD,
            'fieldE': notam.fieldE,
            'fieldF': notam.fieldF,
            'fieldG': notam.fieldG,
            'validFrom': notam.validFrom.toIso8601String(),
            'validTo': notam.validTo.toIso8601String(),
            'isCritical': notam.isCritical,
            'type': notam.type.name,
            'group': notam.group.name,
            'qCode': notam.qCode,
            'source': notam.source,
            'isPermanent': notam.isPermanent,
          }
      };

      // Generate a unique briefing ID for weather keys
      final briefingId = 'briefing_${DateTime.now().millisecondsSinceEpoch}';
      
      // Store weather data with composite key: <TYPE>_<ICAO>_<briefingId>
      // Example: METAR_YSSY_briefing_1753416661996 or TAF_YSSY_briefing_1753416661996
      // This ensures both METAR and TAF for the same airport/briefing are preserved and do not overwrite each other.
      final weatherMap = <String, dynamic>{
        for (final w in weather)
          '${w.type}_${w.icao}_$briefingId': {
            'icao': w.icao,
            'rawText': w.rawText,
            'decodedText': w.decodedText,
            'timestamp': w.timestamp.toIso8601String(),
            'type': w.type,
            'windDirection': w.windDirection,
            'windSpeed': w.windSpeed,
            'visibility': w.visibility,
            'cloudCover': w.cloudCover,
            'temperature': w.temperature,
            'dewPoint': w.dewPoint,
            'qnh': w.qnh,
            'conditions': w.conditions,
            'decodedWeather': w.decodedWeather?.toJson(),
          },
      };

      debugPrint('DEBUG: Converted ${notamsMap.length} NOTAMs and ${weatherMap.length} weather items to storage format');
      
      // Debug: Print detailed weather breakdown
      final metars = weather.where((w) => w.type == 'METAR').toList();
      final tafs = weather.where((w) => w.type == 'TAF').toList();
      debugPrint('DEBUG: Weather breakdown - METARs: ${metars.length}, TAFs: ${tafs.length}');
      
      for (final metar in metars) {
        final preview = metar.rawText.length > 30 ? '${metar.rawText.substring(0, 30)}...' : metar.rawText;
        debugPrint('DEBUG: METAR - ICAO: ${metar.icao}, Raw: $preview');
      }
      for (final taf in tafs) {
        final preview = taf.rawText.length > 30 ? '${taf.rawText.substring(0, 30)}...' : taf.rawText;
        debugPrint('DEBUG: TAF - ICAO: ${taf.icao}, Raw: $preview');
      }
      
      // Debug: Print some sample data to verify format
      if (notamsMap.isNotEmpty) {
        final sampleNotam = notamsMap.values.first;
        debugPrint('DEBUG: Sample NOTAM - Type: ${sampleNotam['type']}, Group: ${sampleNotam['group']}, ICAO: ${sampleNotam['icao']}');
      }
      if (weatherMap.isNotEmpty) {
        final sampleWeather = weatherMap.values.first;
        final sampleKey = weatherMap.keys.first;
        debugPrint('DEBUG: Sample Weather - Type: ${sampleWeather['type']}, ICAO: ${sampleWeather['icao']}');
        debugPrint('DEBUG: Sample weather key format: $sampleKey');
      }

      // Create and save briefing
      final briefing = Briefing.create(
        name: name,
        airports: flight.airports.map((a) => a.icao).toList(),
        notams: notamsMap,
        weather: weatherMap,
      );

      debugPrint('DEBUG: Created briefing object, about to save...');
      await BriefingStorageService.saveBriefing(briefing);
      debugPrint('DEBUG: BriefingStorageService.saveBriefing completed');
      
      debugPrint('DEBUG: Auto-saved briefing: $name');
    } catch (e) {
      debugPrint('DEBUG: Failed to auto-save briefing: $e');
      // Don't show error to user - auto-save should be silent
    }
  }

  /// Generate a smart name for the briefing
  String _generateBriefingName(Flight flight) {
    final departure = flight.departure;
    final destination = flight.destination;
    final date = flight.etd;
    
    // Format: "YSSY→YPPH 24/07" or "YSSY→YPPH→YMML 24/07"
    if (flight.airports.length <= 2) {
      return '$departure→$destination ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } else {
      // For multi-stop flights, show first and last
      return '$departure→...→$destination ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }


  @override
  void dispose() {
    _routeController.dispose();
    _flightLevelController.dispose();
    super.dispose();
  }
} 