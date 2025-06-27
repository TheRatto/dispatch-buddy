import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import 'briefing_tabs_screen.dart';
import '../services/api_service.dart';

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
                          prefixIcon: Icon(Icons.route),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a route';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Local/Zulu Time Toggle
                      Row(
                        children: [
                          Text(
                            'Time Format:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToggleButton('Local', !_isZuluTime, () {
                                  setState(() => _isZuluTime = false);
                                }),
                                _buildToggleButton('Zulu', _isZuluTime, () {
                                  setState(() => _isZuluTime = true);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // ETD Date/Time Picker
                      InkWell(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.grey.shade600),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ETD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(_selectedDateTime),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_isZuluTime) ...[
                                      SizedBox(height: 2),
                                      Text(
                                        'Local: ${_formatLocalTime(_selectedDateTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ] else ...[
                                      SizedBox(height: 2),
                                      Text(
                                        'Zulu: ${_formatZuluTime(_selectedDateTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _flightLevelController,
                        decoration: InputDecoration(
                          labelText: 'Flight Level',
                          hintText: 'e.g., FL350',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight),
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

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _DateTimePickerDialog(
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

  String _formatDateTime(DateTime dateTime) {
    if (_isZuluTime) {
      return _formatZuluTime(dateTime);
    } else {
      return _formatLocalTime(dateTime);
    }
  }

  String _formatLocalTime(DateTime dateTime) {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time (Local)';
  }

  String _formatZuluTime(DateTime dateTime) {
    // Convert to UTC (Zulu time)
    final utcTime = dateTime.toUtc();
    final date = '${utcTime.day.toString().padLeft(2, '0')}/${utcTime.month.toString().padLeft(2, '0')}/${utcTime.year}';
    final time = '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}';
    return '$date at ${time}Z';
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

class _DateTimePickerDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final bool isZuluTime;

  const _DateTimePickerDialog({
    required this.initialDateTime,
    required this.isZuluTime,
  });

  @override
  _DateTimePickerDialogState createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<_DateTimePickerDialog> {
  late DateTime _selectedDateTime;
  late bool _isZuluTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _isZuluTime = widget.isZuluTime;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(12), // Reduced padding
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 500;

              final content = isWide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTitle(),
                              SizedBox(height: 12),
                              _buildTimeFormatToggle(),
                              SizedBox(height: 12),
                              _buildDatePickerWidget(),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 60),
                              _buildTimePickerWidget(),
                              SizedBox(height: 12),
                              _buildPreview(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTitle(),
                        SizedBox(height: 12),
                        _buildTimeFormatToggle(),
                        SizedBox(height: 12),
                        _buildDatePickerWidget(),
                        SizedBox(height: 12),
                        _buildTimePickerWidget(),
                        SizedBox(height: 16),
                        _buildPreview(),
                        SizedBox(height: 12),
                        _buildConfirmButton(),
                      ],
                    );

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  if (isWide) ...[
                    SizedBox(height: 12),
                    _buildConfirmButton(),
                  ]
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.schedule, color: Color(0xFF1E3A8A)),
        SizedBox(width: 12),
        Text(
          'Select ETD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFormatToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Time Format:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton('Local', !_isZuluTime, () {
                setState(() => _isZuluTime = false);
              }),
              _buildToggleButton('Zulu', _isZuluTime, () {
                setState(() => _isZuluTime = true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerWidget() {
    return Container(
      padding: EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 260, // Reduced height
            child: CalendarDatePicker(
              initialDate: _selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 365)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    _selectedDateTime.hour,
                    _selectedDateTime.minute,
                  );
                });
              },
              selectableDayPredicate: (date) =>
                  date.isAfter(DateTime.now().subtract(Duration(days: 1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerWidget() {
    return Container(
      padding: EdgeInsets.all(8), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 100, // Reduced height
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(
                      initialItem: 1000 + _selectedDateTime.hour,
                    ),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2000,
                      builder: (context, index) {
                        final hour = index % 24;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final hour = index % 24;
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          hour,
                          _selectedDateTime.minute,
                        );
                      });
                    },
                  ),
                ),
                Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 30,
                    physics: FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(
                      initialItem: 1000 + _selectedDateTime.minute,
                    ),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 2000,
                      builder: (context, index) {
                        final minute = index % 60;
                        return Center(
                          child: Text(
                            minute.toString().padLeft(2, '0'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final minute = index % 60;
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          _selectedDateTime.hour,
                          minute,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1E3A8A).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Preview',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
          ),
          SizedBox(height: 4),
          Text(
            _isZuluTime
                ? _formatZuluTime(_selectedDateTime)
                : _formatLocalTime(_selectedDateTime),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            _isZuluTime
                ? 'Local: ${_formatLocalTime(_selectedDateTime)}'
                : 'Zulu: ${_formatZuluTime(_selectedDateTime)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDateTime),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatLocalTime(DateTime dateTime) {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time (Local)';
  }

  String _formatZuluTime(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    final date = '${utcTime.day.toString().padLeft(2, '0')}/${utcTime.month.toString().padLeft(2, '0')}/${utcTime.year}';
    final time = '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}';
    return '$date at ${time}Z';
  }
} 