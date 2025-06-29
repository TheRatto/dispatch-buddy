import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import 'briefing_tabs_screen.dart';
import '../services/api_service.dart';
import '../widgets/flight_plan_form_card.dart';
import '../widgets/quick_start_card.dart';
import '../widgets/date_time_picker_dialog.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _flightLevelController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(Duration(hours: 1));
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
        title: Text('New Briefing'),
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
              
              SizedBox(height: 24),
              
              // Quick Start with Mock Data
              QuickStartCard(
                isLoading: _isLoading,
                onGenerateMockBriefing1: _generateMockBriefing,
                onGenerateMockBriefing2: _generateMockBriefing2,
              ),
              
              SizedBox(height: 24),
              
              // Generate Briefing Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateBriefing,
                icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.analytics),
                label: Text(
                  _isLoading ? 'Generating Briefing...' : 'Generate Briefing',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
      
      final newFlight = Flight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        route: _routeController.text,
        departure: icaos.first,
        destination: icaos.last,
        etd: _selectedDateTime,
        flightLevel: _flightLevelController.text,
        alternates: [], // Can be parsed from route later
        createdAt: DateTime.now(),
        airports: icaos.map((icao) => Airport(
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
        )).toList(),
        notams: allNotams,
        weather: allWeather,
      );

      // Save to provider
      context.read<FlightProvider>().setCurrentFlight(newFlight);

      // Navigate to summary
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BriefingTabsScreen()),
      );
    } catch (e, stackTrace) {
      debugPrint('Error generating briefing: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate briefing. Check console for details.')),
      );
    } finally {
      setState(() => _isLoading = false);
      context.read<FlightProvider>().setLoading(false);
    }
  }

  void _generateMockBriefing() {
    // This is now a shortcut for a real flight
    _routeController.text = 'YPPH YSSY';
    _selectedDateTime = DateTime.now().add(Duration(hours: 2));
    _flightLevelController.text = 'FL350';
    _generateBriefing();
  }

  void _generateMockBriefing2() {
    // This is now a shortcut for a real flight
    _routeController.text = 'YMML YBBN';
    _selectedDateTime = DateTime.now().add(Duration(hours: 3));
    _flightLevelController.text = 'FL380';
    _generateBriefing();
  }

  @override
  void dispose() {
    _routeController.dispose();
    _flightLevelController.dispose();
    super.dispose();
  }
} 