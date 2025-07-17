import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../widgets/zulu_time_widget.dart';
import 'briefing_tabs_screen.dart';
import '../services/api_service.dart';
import '../widgets/flight_plan_form_card.dart';
import '../widgets/quick_start_card.dart';
import '../widgets/date_time_picker_dialog.dart';
import '../services/airport_database.dart';

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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // TODO: Implement settings menu
            },
          ),
        ],
      ),
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
              
              // Quick Start with Mock Data
              QuickStartCard(
                isLoading: _isLoading,
                onGenerateMockBriefing1: _generateMockBriefing,
                onGenerateMockBriefing2: _generateMockBriefing2,
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
              
              // Debug Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runNetworkDiagnostics,
                      icon: const Icon(Icons.wifi_find, size: 16),
                      label: const Text('Network Test', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testFaaApiParameters,
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('FAA API Test', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
      final apiService = ApiService();

      final icaos = _routeController.text.toUpperCase().split(' ').where((s) => s.isNotEmpty).toSet().toList();
      
      // Fetch all data in parallel using the new batch methods
      // Use SATCOM-optimized NOTAM fetching with fallback strategies
      final notamsFuture = Future.wait(
        icaos.map((icao) => apiService.fetchNotamsWithSatcomFallback(icao).catchError((e) {
          print('Warning: All SATCOM NOTAM strategies failed for $icao: $e');
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

  void _generateMockBriefing() {
    // This is now a shortcut for a real flight
    _routeController.text = 'YPPH YSSY';
    _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
    _flightLevelController.text = 'FL350';
    _generateBriefing();
  }

  void _generateMockBriefing2() {
    // This is now a shortcut for a real flight
    _routeController.text = 'YMML YBBN';
    _selectedDateTime = DateTime.now().add(const Duration(hours: 3));
    _flightLevelController.text = 'FL380';
    _generateBriefing();
  }

  void _runNetworkDiagnostics() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      
      // Test basic connectivity
      final basicConnectivity = await apiService.testNetworkConnectivity();
      
      // Test FAA API access
      final faaAccess = await apiService.testFaaApiAccess();
      
      // Test a simple NOTAM fetch
      final testNotams = await apiService.fetchNotamsWithSatcomFallback('KJFK');
      
      String message = 'Network Diagnostics Results:\n\n';
      message += 'Basic Internet: ${basicConnectivity ? "✅ Working" : "❌ Failed"}\n';
      message += 'FAA API Health: ${faaAccess ? "✅ Accessible" : "❌ Blocked/Unreachable"}\n';
      message += 'NOTAM Fetch: ${testNotams.isNotEmpty ? "✅ Success (${testNotams.length} NOTAMs)" : "❌ Failed"}\n\n';
      
      if (!basicConnectivity) {
        message += 'SATCOM Issue: No basic internet connectivity detected.\n';
      } else if (!faaAccess) {
        message += 'SATCOM Issue: FAA API is blocked or unreachable via SATCOM.\n';
      } else if (testNotams.isEmpty) {
        message += 'SATCOM Issue: NOTAM API accessible but no data returned.\n';
      } else {
        message += '✅ All systems working normally!\n';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 8),
          backgroundColor: basicConnectivity && faaAccess ? Colors.green : Colors.orange,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testFaaApiParameters() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      
      // Test FAA NOTAM API parameters with a known airport
      final results = await apiService.testFaaNotamApiParameters('YPPH');
      
      String message = 'FAA API Parameter Test Results:\n\n';
      
      for (final entry in results.entries) {
        final testName = entry.key;
        final result = entry.value as Map<String, dynamic>;
        
        if (result['status'] == 'success') {
          message += '✅ $testName: ${result['notamCount']} NOTAMs (total: ${result['totalCount']})\n';
        } else {
          message += '❌ $testName: ${result['error']}\n';
        }
      }
      
      message += '\nCheck console for detailed logs.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 12),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parameter test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _routeController.dispose();
    _flightLevelController.dispose();
    super.dispose();
  }
} 