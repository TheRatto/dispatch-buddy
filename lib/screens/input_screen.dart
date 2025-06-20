import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import 'summary_screen.dart';

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeController = TextEditingController();
  final _etdController = TextEditingController();
  final _flightLevelController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default values for testing
    _routeController.text = 'YPPH YSSY';
    _etdController.text = '2024-01-15 08:30';
    _flightLevelController.text = 'FL350';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Briefing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flight Plan Input Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flight Plan Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _routeController,
                        decoration: InputDecoration(
                          labelText: 'Route',
                          hintText: 'e.g., YPPH YSSY',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a route';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _etdController,
                        decoration: InputDecoration(
                          labelText: 'ETD',
                          hintText: 'YYYY-MM-DD HH:MM',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ETD';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _flightLevelController,
                        decoration: InputDecoration(
                          labelText: 'Flight Level',
                          hintText: 'e.g., FL350',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter flight level';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Quick Start with Mock Data
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Generate a sample briefing with realistic data for testing',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateMockBriefing,
                              icon: Icon(Icons.flight),
                              label: Text('YPPH → YSSY (Sample)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _generateMockBriefing2,
                              icon: Icon(Icons.flight),
                              label: Text('YMML → YBBN (Sample)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

  void _generateBriefing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse route
      final routeParts = _routeController.text.split(' ');
      if (routeParts.length < 2) {
        throw Exception('Invalid route format');
      }

      final departure = routeParts[0];
      final destination = routeParts[1];
      
      // Parse ETD - fix the parsing
      final etd = DateTime.parse(_etdController.text.replaceAll(' ', 'T'));

      // Create flight with mock data
      final flight = Flight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        route: _routeController.text,
        departure: departure,
        destination: destination,
        etd: etd,
        flightLevel: _flightLevelController.text,
        alternates: ['YSCB', 'YMML'],
        createdAt: DateTime.now(),
        airports: _generateMockAirports([departure, destination]),
        notams: _generateMockNotams([departure, destination]),
        weather: _generateMockWeather([departure, destination]),
      );

      // Save to provider
      context.read<FlightProvider>().createNewFlight(flight);

      // Navigate to summary
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SummaryScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateMockBriefing() {
    _routeController.text = 'YPPH YSSY';
    _etdController.text = '2024-01-15 08:30';
    _flightLevelController.text = 'FL350';
    _generateBriefing();
  }

  void _generateMockBriefing2() {
    _routeController.text = 'YMML YBBN';
    _etdController.text = '2024-01-15 14:00';
    _flightLevelController.text = 'FL380';
    _generateBriefing();
  }

  List<Airport> _generateMockAirports(List<String> icaoCodes) {
    final airportData = {
      'YPPH': {'name': 'Perth Airport', 'city': 'Perth'},
      'YSSY': {'name': 'Sydney Airport', 'city': 'Sydney'},
      'YMML': {'name': 'Melbourne Airport', 'city': 'Melbourne'},
      'YBBN': {'name': 'Brisbane Airport', 'city': 'Brisbane'},
    };

    return icaoCodes.map((icao) {
      final data = airportData[icao] ?? {'name': '$icao Airport', 'city': 'Unknown'};
      return Airport(
        icao: icao,
        name: data['name']!,
        city: data['city']!,
        latitude: -31.9522,
        longitude: 115.8589,
        systems: {
          'runways': SystemStatus.green,
          'navaids': SystemStatus.green,
          'taxiways': SystemStatus.green,
          'lighting': SystemStatus.green,
        },
        runways: ['06/24', '03/21'],
        navaids: ['ILS', 'VOR', 'DME'],
      );
    }).toList();
  }

  List<Notam> _generateMockNotams(List<String> icaoCodes) {
    final notams = <Notam>[];
    
    for (final icao in icaoCodes) {
      if (icao == 'YSSY') {
        notams.add(Notam(
          id: 'C1234/24',
          icao: icao,
          type: NotamType.runway,
          validFrom: DateTime.now(),
          validTo: DateTime.now().add(Duration(hours: 6)),
          rawText: 'C1234/24 NOTAMN Q) YSSY/QMRLC/IV/NBO/A/000/999/3355S15110E005 A) YSSY B) 2401150800 C) 2401151400 E) RWY16L ILS U/S DUE MAINT',
          decodedText: 'Runway 16L ILS is unavailable due to maintenance from 0800Z to 1400Z',
          affectedSystem: 'RWY16L ILS',
          isCritical: true,
        ));
      }
    }
    
    return notams;
  }

  List<Weather> _generateMockWeather(List<String> icaoCodes) {
    return icaoCodes.map((icao) {
      return Weather(
        icao: icao,
        timestamp: DateTime.now(),
        rawText: 'METAR $icao 150830Z 25015KT 9999 SCT030 BKN100 25/18 Q1013',
        decodedText: 'Wind 250° at 15 knots, visibility 10km, scattered cloud at 3000ft, broken cloud at 10000ft, temperature 25°C, dew point 18°C, QNH 1013',
        windDirection: 250,
        windSpeed: 15,
        visibility: 10000,
        cloudCover: 'SCT030 BKN100',
        temperature: 25.0,
        dewPoint: 18.0,
        qnh: 1013,
        conditions: 'Good',
      );
    }).toList();
  }

  @override
  void dispose() {
    _routeController.dispose();
    _etdController.dispose();
    _flightLevelController.dispose();
    super.dispose();
  }
} 