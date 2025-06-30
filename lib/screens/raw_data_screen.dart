import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/flight_provider.dart';
import '../models/flight.dart';
import '../models/airport.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/decoder_service.dart';
import '../services/taf_state_manager.dart';
import '../widgets/zulu_time_widget.dart';
import '../widgets/decoded_weather_card.dart';
import '../widgets/raw_taf_card.dart';
import '../widgets/taf_time_slider.dart';
import '../widgets/taf_airport_selector.dart';
import '../widgets/taf_empty_states.dart';
import '../widgets/metar_tab.dart';
import '../widgets/taf_tab.dart';
import '../constants/weather_colors.dart';

class RawDataScreen extends StatefulWidget {
  @override
  _RawDataScreenState createState() => _RawDataScreenState();
}

class _RawDataScreenState extends State<RawDataScreen> {
  String? _selectedAirport; // Track selected airport for TAFs2
  // Store slider positions per airport
  final Map<String, double> _sliderPositions = {};
  double _sliderValue = 0.0;
  List<TimePeriod> _timePeriods = [];
  List<DateTime> _timeline = [];
  Map<String, dynamic>? _activePeriods;
  Weather? _currentTaf;
  
  // Scroll controller for TAFs2 tab
  final ScrollController _tafs2ScrollController = ScrollController();
  
  // TAF State Manager - handles all business logic
  final TafStateManager _tafStateManager = TafStateManager();
  
  // Performance tracking for UI state
  String? _lastProcessedAirport;
  double? _lastProcessedSliderValue;
  String? _lastLoggedBuild; // Track last logged build to reduce debug output
  
  // Data change tracking for better cache management
  String? _lastTafHash; // Hash of the last processed TAF data
  String? _lastTimelineHash; // Hash of the last processed timeline
  
  // Cache keys
  String _getCacheKey(String airport, double sliderValue, String periodType) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}_$periodType';
  }
  
  String _getActivePeriodsCacheKey(String airport, double sliderValue) {
    return '${airport}_${sliderValue.toStringAsFixed(3)}';
  }
  
  // Generate hash for TAF data to detect changes
  String _generateTafHash(Weather taf) {
    return '${taf.rawText.hashCode}_${taf.decodedWeather?.forecastPeriods?.length ?? 0}';
  }
  
  // Generate hash for timeline to detect changes
  String _generateTimelineHash(List<DateTime> timeline) {
    return '${timeline.length}_${timeline.isNotEmpty ? timeline.first.hashCode : 0}_${timeline.isNotEmpty ? timeline.last.hashCode : 0}';
  }
  
  // Clear cache when switching airports or when data changes
  void _clearCache() {
    _tafStateManager.clearCache();
    _lastProcessedAirport = null;
    _lastProcessedSliderValue = null;
    _lastLoggedBuild = null;
    _lastTafHash = null;
    _lastTimelineHash = null;
  }
  
  // Smart cache clearing based on data changes
  void _clearCacheIfDataChanged(Weather taf, List<DateTime> timeline) {
    _tafStateManager.clearCacheIfDataChanged(taf, timeline);
    
    // Update local tracking
    _lastTafHash = _generateTafHash(taf);
    _lastTimelineHash = _generateTimelineHash(timeline);
  }
  
  // Limit cache size to prevent memory issues
  void _limitCacheSize() {
    // Cache size limiting is now handled by TafStateManager
  }
  
  // Performance monitoring
  void _logPerformanceStats() {
    final metrics = _tafStateManager.getPerformanceMetrics();
    debugPrint('DEBUG: Performance Stats - Weather Cache: ${metrics['weatherCacheSize']} entries');
    debugPrint('DEBUG: Performance Stats - Active Periods Cache: ${metrics['activePeriodsCacheSize']} entries');
    debugPrint('DEBUG: Performance Stats - Weather Cache Hit Rate: ${metrics['weatherCacheHitRate']}');
    debugPrint('DEBUG: Performance Stats - Active Periods Cache Hit Rate: ${metrics['activePeriodsCacheHitRate']}');
    debugPrint('DEBUG: Performance Stats - Last Airport: $_selectedAirport');
    debugPrint('DEBUG: Performance Stats - Last Slider Value: ${_sliderPositions[_selectedAirport!]}');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tafs2ScrollController.dispose();
    super.dispose();
  }

  void _initializeData(Weather taf) {
    if (taf.decodedWeather != null && taf.decodedWeather!.forecastPeriods != null) {
      final decoder = DecoderService();
      
      // Use the new timeline-based approach
      _timeline = taf.decodedWeather!.timeline;
      
      if (_timeline.isNotEmpty) {
        // Find active periods at the first time point
        _activePeriods = decoder.findActivePeriodsAtTime(_timeline.first, taf.decodedWeather!.forecastPeriods!);
      }
    }
  }

  void _onSliderChanged(double value, Weather taf) {
    setState(() {
      // Update the slider value for the current airport
      _sliderPositions[_selectedAirport!] = value;
      
      // Get timeline from the selected TAF
      final timeline = taf.decodedWeather?.timeline ?? [];
      final forecastPeriods = taf.decodedWeather?.forecastPeriods ?? [];
      
      if (timeline.isNotEmpty && forecastPeriods.isNotEmpty) {
        // Convert slider value to timeline index
        final index = (value * (timeline.length - 1)).round();
        final selectedTime = timeline[index];
        
        // Find active periods at this time
        final decoder = DecoderService();
        _activePeriods = decoder.findActivePeriodsAtTime(selectedTime, forecastPeriods);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Raw Data'),
          actions: const [
            ZuluTimeWidget(),
            SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            indicatorColor: Color(0xFFF97316), // Accent Orange
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'NOTAMs'),
              Tab(text: 'METARs'),
              Tab(text: 'TAFs'),
              Tab(text: 'TAFs2'),
            ],
          ),
        ),
        body: Consumer<FlightProvider>(
          builder: (context, flightProvider, child) {
            final flight = flightProvider.currentFlight;
            if (flight == null) {
              return Center(child: Text('No flight data available'));
            }
            return TabBarView(
              children: [
                _buildNotamsTab(context, flight.notams, flightProvider),
                RefreshIndicator(
                  onRefresh: () async {
                    await flightProvider.refreshFlightData();
                  },
                  child: MetarTab(metarsByIcao: flightProvider.metarsByIcao),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    await flightProvider.refreshFlightData();
                  },
                  child: TafTab(tafsByIcao: flightProvider.tafsByIcao),
                ),
                _buildTafs2Tab(context, flightProvider.tafsByIcao, flightProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotamsTab(BuildContext context, List<Notam> notams, FlightProvider flightProvider) {
    if (notams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'No NOTAMs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All systems operational',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await flightProvider.refreshFlightData();
      },
      child: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notams.length,
      itemBuilder: (context, index) {
        final notam = notams[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${notam.id} - ${notam.affectedSystem}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
                '${notam.icao} | ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}',
            ),
            leading: Icon(
              notam.isCritical ? Icons.error : Icons.warning,
              color: notam.isCritical ? Color(0xFFEF4444) : Color(0xFFF59E0B),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw NOTAM:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notam.rawText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Decoded:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(notam.decodedText),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _buildMetarsTab(BuildContext context, Map<String, List<Weather>> metarsByIcao, FlightProvider flightProvider) {
    if (metarsByIcao.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No METARs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No current weather observations',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final icaos = metarsByIcao.keys.toList();
    return RefreshIndicator(
      onRefresh: () async {
        await flightProvider.refreshFlightData();
      },
      child: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: icaos.length,
      itemBuilder: (context, index) {
        final icao = icaos[index];
        final metar = metarsByIcao[icao]!.first;
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
              title: Row(
                  children: [
                    Icon(Icons.cloud, color: Color(0xFF3B82F6), size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        icao,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              subtitle: Text(
                _formatDateTime(metar.timestamp),
                style: TextStyle(color: Colors.grey[600]),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw METAR:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        metar.rawText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _buildTafsTab(BuildContext context, Map<String, List<Weather>> tafsByIcao, FlightProvider flightProvider) {
    if (tafsByIcao.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No terminal area forecasts available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final icaos = tafsByIcao.keys.toList();
    return RefreshIndicator(
      onRefresh: () async {
        await flightProvider.refreshFlightData();
      },
      child: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: icaos.length,
      itemBuilder: (context, index) {
        final icao = icaos[index];
        final taf = tafsByIcao[icao]!.first;
        final decodedTaf = taf.decodedWeather;
        
        if (decodedTaf == null || decodedTaf.forecastPeriods == null || decodedTaf.forecastPeriods!.isEmpty) {
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(icao, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Could not decode TAF.'),
            ),
          );
        }

        final initialPeriod = decodedTaf.forecastPeriods!.firstWhere((p) => p.type == 'INITIAL');
        
        // Create TimePeriod objects for the old tab display
        final timePeriods = decodedTaf.forecastPeriods!.map((period) => TimePeriod(
          startTime: period.startTime ?? DateTime.now(),
          endTime: period.endTime ?? DateTime.now().add(Duration(hours: 1)),
          baselinePeriod: period,
          concurrentPeriods: [],
          rawTafSection: period.rawSection ?? '',
        )).toList();
        
        final timePeriodStrings = _getTafTimePeriods(timePeriods);
        final initialTimePeriod = timePeriodStrings.isNotEmpty ? timePeriodStrings.first : '';

        // Create TimePeriod for initial period
        final initialTimePeriodObj = TimePeriod(
          startTime: initialPeriod.startTime ?? DateTime.now(),
          endTime: initialPeriod.endTime ?? DateTime.now().add(Duration(hours: 1)),
          baselinePeriod: initialPeriod,
          concurrentPeriods: [],
          rawTafSection: initialPeriod.rawSection ?? '',
        );

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Color(0xFF3B82F6), size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        icao,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  initialTimePeriod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                _buildTafCompactDetails(
                  initialTimePeriodObj.baselinePeriod, 
                  initialTimePeriodObj.baselinePeriod.weather, 
                  initialTimePeriodObj.concurrentPeriods
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show all forecast periods
                    ...decodedTaf.forecastPeriods!.map((period) {
                      // Create a simple TimePeriod for display purposes
                      final timePeriod = TimePeriod(
                        startTime: period.startTime ?? DateTime.now(),
                        endTime: period.endTime ?? DateTime.now().add(Duration(hours: 1)),
                        baselinePeriod: period,
                        concurrentPeriods: [],
                        rawTafSection: period.rawSection ?? '',
                      );
                      return _buildTafPeriodCard(context, timePeriod, timePeriodStrings, timePeriods);
                    }).toList(),
                    
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 8),
                    
                    // Raw TAF at bottom
                    Text(
                      'Raw TAF:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        taf.rawText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  Widget _buildTafs2Tab(BuildContext context, Map<String, List<Weather>> tafsByIcao, FlightProvider flightProvider) {
    print('DEBUG: TAFs2 tab - METHOD CALLED!');
    
    if (tafsByIcao.isEmpty) {
      print('DEBUG: TAFs2 tab - No TAFs available, showing empty state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No terminal area forecasts available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Initialize selected airport if not set
    if (_selectedAirport == null || !tafsByIcao.containsKey(_selectedAirport)) {
      _selectedAirport = tafsByIcao.keys.first;
      print('DEBUG: TAFs2 tab - Selected airport: $_selectedAirport');
    }

    final selectedTaf = tafsByIcao[_selectedAirport!]!.first;
    final decodedTaf = selectedTaf.decodedWeather;
    print('DEBUG: TAFs2 tab - Selected TAF: ${selectedTaf.icao}');
    print('DEBUG: TAFs2 tab - Decoded TAF: ${decodedTaf != null}');

    // Get slider position for this airport
    final forecastPeriods = decodedTaf?.forecastPeriods ?? [];
    double sliderValue = _sliderPositions[_selectedAirport!] ?? 0.0;
    
    print('DEBUG: Main build - forecastPeriods length: ${forecastPeriods.length}');
    print('DEBUG: Main build - forecastPeriods types: ${forecastPeriods.map((p) => '${p.type} (concurrent: ${p.isConcurrent})').toList()}');

    if (forecastPeriods.isNotEmpty) {
      // Calculate active periods for the current slider position
      final decoder = DecoderService();
      final timeline = selectedTaf.decodedWeather?.timeline ?? [];
      
      if (timeline.isNotEmpty) {
        final index = (sliderValue * (timeline.length - 1)).round();
        final selectedTime = timeline[index];
        _activePeriods = decoder.findActivePeriodsAtTime(selectedTime, forecastPeriods);
        print('DEBUG: TAFs2 tab - Active periods: $_activePeriods');
      }
    }
    
    print('DEBUG: TAFs2 tab - Building RefreshIndicator with SingleChildScrollView');
    return RefreshIndicator(
      onRefresh: () async {
        print('DEBUG: TAFs2 tab - Refresh triggered');
        
        // Get current scroll position to lock it
        final currentOffset = _tafs2ScrollController.offset;
        print('DEBUG: TAFs2 tab - Current scroll offset: $currentOffset');
        
        // Keep content locked in pulled-down position for a minimum duration
        await Future.delayed(Duration(milliseconds: 1500));
        
        // Manually maintain scroll position during refresh
        if (_tafs2ScrollController.hasClients) {
          _tafs2ScrollController.jumpTo(currentOffset);
        }
        
        // Then perform the actual refresh
        await flightProvider.refreshFlightData();
        
        // Add a small delay after refresh completes for smooth transition
        await Future.delayed(Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _tafs2ScrollController,
        child: Padding(
      padding: const EdgeInsets.all(8.0),
          child: Column(
        children: [
              // Airport selector
              SizedBox(
                height: 40,
                child: RepaintBoundary(
                  child: TafAirportSelector(
                    airports: tafsByIcao.keys.toList(),
                    selectedAirport: _selectedAirport!,
                    onAirportSelected: (String airport) {
                      print('DEBUG: TAFs2 tab - Airport selected: $airport');
                      setState(() {
                        _selectedAirport = airport;
                        sliderValue = _sliderPositions[airport] ?? 0.0;
                      });
                    },
                    onAddAirport: _showAddAirportDialog,
                    onAirportLongPress: _showEditAirportDialog,
                  ),
                ),
              ),
              SizedBox(height: 4),
              
              // Decoded weather card
              SizedBox(
                height: 290,
                child: RepaintBoundary(
                  child: _activePeriods != null && _activePeriods!['baseline'] != null
                      ? DecodedWeatherCard(
                          baseline: _activePeriods!['baseline'] as DecodedForecastPeriod,
                          completeWeather: _getCompleteWeatherForPeriod(_activePeriods!['baseline'] as DecodedForecastPeriod, selectedTaf.decodedWeather?.timeline ?? []),
                          concurrentPeriods: _activePeriods!['concurrent'] as List<DecodedForecastPeriod>,
                          airport: _selectedAirport,
                          sliderValue: sliderValue,
                          allPeriods: forecastPeriods,
                        )
                      : Center(child: Text('No decoded data available')),
                ),
              ),
              SizedBox(height: 4),
              
              // Raw TAF card
              SizedBox(
                height: 240,
                child: RepaintBoundary(
                  child: RawTafCard(
                    taf: selectedTaf,
                    activePeriods: _activePeriods,
                  ),
                ),
              ),
              
              // Time Slider - now part of scrollable content
              SizedBox(
            height: 89,
                child: RepaintBoundary(
                  child: selectedTaf.decodedWeather?.timeline.isNotEmpty == true
                      ? TafTimeSlider(
                          timeline: selectedTaf.decodedWeather!.timeline,
                          sliderValue: sliderValue,
                          onChanged: (value) => _onSliderChanged(value, selectedTaf),
                        )
                      : Container(
                          height: 89,
                          child: Center(child: Text('No timeline available')),
                        ),
                ),
              ),
              
              // Bottom padding for pull-to-refresh
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}Z';
  }

  DecodedForecastPeriod? _getActiveBaselinePeriod(List<DecodedForecastPeriod> periods, DateTime time) {
    // Use TafStateManager to get active baseline period
    return _tafStateManager.getActiveBaselinePeriod(periods, time);
  }

  Widget _buildEmptyDecodedCard() {
    return TafEmptyStates.emptyDecodedCard();
  }

  Widget _buildEmptyTimeSlider() {
    return TafTimeSlider(
      timeline: [],
      sliderValue: 0.0,
      onChanged: (value) {},
    );
  }

  Widget _buildAirportBubbles(List<String> airports) {
    return TafAirportSelector(
      airports: airports,
      selectedAirport: _selectedAirport,
      onAirportSelected: (icao) {
              setState(() {
                _selectedAirport = icao;
              });
            },
      onCacheClear: _clearCache,
    );
  }

  Widget _buildDecodedCardFromActivePeriods(Map<String, dynamic> activePeriods, List<DateTime> timeline, [List<DecodedForecastPeriod>? allPeriods]) {
    final baseline = activePeriods['baseline'] as DecodedForecastPeriod?;
    final concurrent = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
    print('DEBUG: Decoded card - Received activePeriods: $activePeriods');
    print('DEBUG: Decoded card - Baseline: ${baseline?.type}');
    print('DEBUG: Decoded card - Concurrent: ${concurrent.map((p) => p.type).toList()}');
    print('DEBUG: Decoded card - Concurrent length: ${concurrent.length}');
    if (baseline == null) {
      return _buildEmptyDecodedCard();
    }
    // Get complete weather for the baseline period
    final completeWeather = _getCompleteWeatherForPeriod(baseline, timeline, allPeriods);
    // Return the card with period information for highlighting
    return _buildDecodedCardWithHighlightingInfo(baseline, completeWeather, concurrent, allPeriods);
  }
  
  Widget _buildDecodedCardWithHighlightingInfo(DecodedForecastPeriod baseline, Map<String, String> completeWeather, List<DecodedForecastPeriod> concurrentPeriods, List<DecodedForecastPeriod>? allPeriods) {
    return DecodedWeatherCard(
      baseline: baseline,
      completeWeather: completeWeather,
      concurrentPeriods: concurrentPeriods,
      tafStateManager: _tafStateManager,
      airport: _selectedAirport,
      sliderValue: _sliderPositions[_selectedAirport!],
      allPeriods: allPeriods,
    );
  }

  Map<String, String> _getCompleteWeatherForPeriod(DecodedForecastPeriod period, List<DateTime> timeline, [List<DecodedForecastPeriod>? allPeriods]) {
    // Use TafStateManager to get complete weather with inheritance
    return _tafStateManager.getCompleteWeatherForPeriod(
      period,
      _selectedAirport ?? '',
      _sliderPositions[_selectedAirport!] ?? 0.0,
      allPeriods ?? [],
    );
  }

  Widget _buildTafCompactDetails(DecodedForecastPeriod baseline, Map<String, String> completeWeather, List<DecodedForecastPeriod> concurrentPeriods) {
    return Column(
      children: [
        // Baseline weather with integrated TEMPO/INTER
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Wind', completeWeather['Wind'], concurrentPeriods, 'Wind'),
              SizedBox(width: 16),
              _buildGridItemWithConcurrent('Visibility', completeWeather['Visibility'], concurrentPeriods, 'Visibility'),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Weather', completeWeather['Weather'], concurrentPeriods, 'Weather', isPhenomenaOrRemark: true),
              SizedBox(width: 16),
              _buildGridItemWithConcurrent('Cloud', completeWeather['Cloud'], concurrentPeriods, 'Cloud'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItemWithConcurrent(String label, String? value, List<DecodedForecastPeriod> concurrentPeriods, String weatherType, {bool isPhenomenaOrRemark = false}) {
    String displayValue = value ?? '-';
    if (isPhenomenaOrRemark) {
      if (value == null || value.isEmpty || value == 'No significant weather') {
        displayValue = '-';
      }
    } else {
      if (value == null || value.isEmpty || value.contains('unavailable') || value.contains('No cloud information')) {
        displayValue = '-'; // Show - instead of N/A to match weather heading
      }
    }
    
    // Performance optimization: Only log once per build cycle
    final currentBuild = '${_selectedAirport}_${_sliderPositions[_selectedAirport!] ?? 0.0}_$label';
    if (_lastLoggedBuild != currentBuild) {
      print('DEBUG: Building grid item for $label (weatherType: $weatherType)');
      print('DEBUG: Concurrent periods count: ${concurrentPeriods.length}');
      print('DEBUG: Concurrent periods: ${concurrentPeriods.map((p) => '${p.type} (${p.changedElements})').toList()}');
      _lastLoggedBuild = currentBuild;
    }
    
    // Find concurrent periods that have changes for this weather type
    final relevantConcurrentPeriods = concurrentPeriods.where((period) => 
      period.changedElements.contains(weatherType)
    ).toList();
    
    if (_lastLoggedBuild == currentBuild) {
      print('DEBUG: Relevant concurrent periods for $weatherType: ${relevantConcurrentPeriods.map((p) => '${p.type} (${p.weather[weatherType]})').toList()}');
    }
    
    // Memoize concurrent period widgets to prevent unnecessary rebuilds
    final concurrentWidgets = relevantConcurrentPeriods.map((period) {
      final color = WeatherColors.getColorForProbCombination(period.type);
      final label = period.type; // Use the full period type instead of just 'TEMPO' or 'INTER'
      final concurrentValue = period.weather[weatherType];
      
      if (_lastLoggedBuild == currentBuild) {
        print('DEBUG: Processing concurrent period ${period.type} for $weatherType: "$concurrentValue"');
        print('DEBUG: Color key label for ${period.type}: "$label"');
      }
      
      if (concurrentValue == null || concurrentValue.isEmpty || 
          (isPhenomenaOrRemark && (concurrentValue == 'No significant weather'))) {
        if (_lastLoggedBuild == currentBuild) {
          print('DEBUG: Skipping concurrent period ${period.type} - value is empty or "No significant weather"');
        }
        return const SizedBox.shrink();
      }
      
      if (_lastLoggedBuild == currentBuild) {
        print('DEBUG: Displaying concurrent period ${period.type} for $weatherType: "$concurrentValue"');
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          concurrentValue,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
        ),
      ),
    );
    }).toList();
    
    return Expanded(
      child: RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
              style: const TextStyle(
              fontSize: 10,
                color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
            const SizedBox(height: 2),
          Text(
            displayValue,
              style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
            // Add TEMPO/INTER lines if they have changes for this weather type
            ...concurrentWidgets,
        ],
        ),
      ),
    );
  }

  Widget _buildRawCardFromActivePeriods(Weather taf, Map<String, dynamic>? activePeriods) {
    return RawTafCard(
      taf: taf,
      activePeriods: activePeriods,
    );
  }

  Widget _buildWeatherInfo(Map<String, String> weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weather['Wind'] != null) ...[
          Text('Wind: ${weather['Wind']}'),
          SizedBox(height: 2),
        ],
        if (weather['Visibility'] != null) ...[
          Text('Visibility: ${weather['Visibility']}'),
          SizedBox(height: 2),
        ],
        if (weather['Cloud'] != null) ...[
          Text('Cloud: ${weather['Cloud']}'),
          SizedBox(height: 2),
        ],
        if (weather['Weather'] != null) ...[
          Text('Weather: ${weather['Weather']}'),
          SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildTimeSlider(List<TimePeriod> periods, double sliderValue, ValueChanged<double> onChanged) {
    // This method is no longer used - replaced by TafTimeSlider component instead
    throw UnimplementedError('Use TafTimeSlider component instead');
  }

  List<String> _getTafTimePeriods(List<TimePeriod> periods) {
    final timePeriods = <String>[];
    
    for (final period in periods) {
      final day = period.startTime.day.toString().padLeft(2, '0');
      final hour = period.startTime.hour.toString().padLeft(2, '0');
      timePeriods.add('$day/$hour');
    }
    
    return timePeriods;
  }

  String _extractTafStartTime(List<TimePeriod> periods) {
    if (periods.isNotEmpty) {
      final firstPeriod = periods.first;
      final day = firstPeriod.startTime.day.toString().padLeft(2, '0');
      final hour = firstPeriod.startTime.hour.toString().padLeft(2, '0');
      return '$day/$hour';
    }
    return 'N/A';
  }

  Widget _buildTafPeriodCard(BuildContext context, TimePeriod period, List<String> timePeriods, List<TimePeriod> allPeriods) {
    final isInitial = period.baselinePeriod.type == 'INITIAL';
    final isTempo = period.baselinePeriod.type == 'TEMPO';
    final isInter = period.baselinePeriod.type == 'INTER';
    final isBecmg = period.baselinePeriod.type == 'BECMG';
    final isFm = period.baselinePeriod.type == 'FM';
    
    final weather = period.baselinePeriod.weather;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period.baselinePeriod.type,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: WeatherColors.getColorForPeriodType(period.baselinePeriod.type),
                  ),
                ),
                Text(
                  period.baselinePeriod.time ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGridItem('Wind', weather['Wind'], isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Wind')),
                SizedBox(width: 16),
                _buildGridItem('Visibility', weather['Visibility'], isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Visibility')),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGridItem('Weather', weather['Weather'], isPhenomenaOrRemark: true),
                SizedBox(width: 16),
                _buildGridItem('Cloud', weather['Cloud'], isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Cloud')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSliderFromTimeline(List<DateTime> timeline, double sliderValue, ValueChanged<double> onChanged) {
    return TafTimeSlider(
      timeline: timeline,
      sliderValue: sliderValue,
      onChanged: onChanged,
    );
  }

  Widget _buildGridItem(String label, String? value, {bool isPhenomenaOrRemark = false}) {
    String displayValue = value ?? '-';
    if (isPhenomenaOrRemark) {
      if (value == null || value.isEmpty || value == 'No significant weather') {
        displayValue = '-';
      }
    } else {
      if (value == null || value.isEmpty || value.contains('unavailable') || value.contains('No cloud information')) {
        displayValue = '-'; // Show - instead of N/A to match weather heading
      }
    }
    
    return Expanded(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
            Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            ),
          ],
        ),
    );
  }

  void _showAddAirportDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the ICAO code for the airport you want to add:'),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'ICAO Code',
                  hintText: 'e.g., KJFK',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                onChanged: (value) {
                  // Auto-capitalize and limit to 4 characters
                  if (value.length > 4) {
                    controller.text = value.substring(0, 4).toUpperCase();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final icao = controller.text.trim().toUpperCase();
                if (icao.length == 4) {
                  Navigator.of(context).pop();
                  
                  // Get the FlightProvider and add the airport
                  final flightProvider = context.read<FlightProvider>();
                  final success = await flightProvider.addAirportToFlight(icao);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Airport $icao added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Check if it's because the airport already exists
                    final currentFlight = flightProvider.currentFlight;
                    if (currentFlight?.airports.any((airport) => airport.icao == icao) == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Airport $icao is already in your flight plan'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add airport $icao. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid 4-letter ICAO code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAirportDialog(BuildContext context, String airport) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What would you like to do with airport $airport?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditAirportCodeDialog(context, airport);
                      },
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showRemoveAirportDialog(context, airport);
                      },
                      icon: Icon(Icons.delete, size: 16),
                      label: Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAirportCodeDialog(BuildContext context, String oldAirport) {
    final TextEditingController controller = TextEditingController(text: oldAirport);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Airport Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the new ICAO code for airport $oldAirport:'),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'ICAO Code',
                  hintText: 'e.g., KJFK',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                onChanged: (value) {
                  // Auto-capitalize and limit to 4 characters
                  if (value.length > 4) {
                    controller.text = value.substring(0, 4).toUpperCase();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newIcao = controller.text.trim().toUpperCase();
                if (newIcao.length == 4 && newIcao != oldAirport) {
                  Navigator.of(context).pop();
                  
                  // Get the FlightProvider and update the airport
                  final flightProvider = context.read<FlightProvider>();
                  final success = await flightProvider.updateAirportCode(oldAirport, newIcao);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Airport updated from $oldAirport to $newIcao successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update airport. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (newIcao == oldAirport) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No changes made'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid 4-letter ICAO code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveAirportDialog(BuildContext context, String airport) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to remove airport $airport from your flight plan?',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'This will also remove all associated weather data.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Get the FlightProvider and remove the airport
                final flightProvider = context.read<FlightProvider>();
                final success = await flightProvider.removeAirportFromFlight(airport);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Airport $airport removed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove airport. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }
} 