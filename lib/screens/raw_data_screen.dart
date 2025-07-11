import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flight_provider.dart';
import '../models/notam.dart';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import '../services/decoder_service.dart';
import '../services/taf_state_manager.dart';
import '../services/cache_manager.dart';
import '../widgets/zulu_time_widget.dart';
import '../widgets/decoded_weather_card.dart';
import '../widgets/raw_taf_card.dart';
import '../widgets/taf_time_slider.dart';
import '../widgets/taf_airport_selector.dart';
import '../widgets/taf_empty_states.dart';
import '../widgets/metar_tab.dart';
import '../widgets/taf_tab.dart';
import '../constants/weather_colors.dart';
import '../widgets/notam_grouped_list.dart';

class RawDataScreen extends StatefulWidget {
  const RawDataScreen({super.key});

  @override
  _RawDataScreenState createState() => _RawDataScreenState();
}

class _RawDataScreenState extends State<RawDataScreen> {
  // Airport selection is now managed by FlightProvider
  // Store slider positions per airport
  final Map<String, double> _sliderPositions = {};
  final double _sliderValue = 0.0;
  final List<TimePeriod> _timePeriods = [];
  List<DateTime> _timeline = [];
  Map<String, dynamic>? _activePeriods;
  Weather? _currentTaf;
  
  // Time filter for NOTAMs
  String _selectedTimeFilter = '24 hours'; // Default to 24 hours
  final List<String> _timeFilterOptions = [
    '6 hours',
    '12 hours', 
    '24 hours',
    '72 hours',
    'All NOTAMs'
  ];
  
  // Scroll controller for TAFs2 tab
  final ScrollController _tafs2ScrollController = ScrollController();
  
  // TAF State Manager - handles all business logic
  final TafStateManager _tafStateManager = TafStateManager();
  
  // Unified cache manager for UI-level caching
  final CacheManager _cacheManager = CacheManager();
  
  // Performance tracking for UI state
  String? _lastProcessedAirport;
  double? _lastProcessedSliderValue;
  String? _lastLoggedBuild; // Track last logged build to reduce debug output
  
  // Data change tracking for better cache management
  String? _lastTafHash; // Hash of the last processed TAF data
  String? _lastTimelineHash; // Hash of the last processed timeline
  
  
  

  
  // Generate hash for TAF data to detect changes
  String _generateTafHash(Weather taf) {
    return '${taf.rawText.hashCode}_${taf.decodedWeather?.forecastPeriods?.length ?? 0}';
  }
  
  // Generate hash for timeline to detect changes
  String _generateTimelineHash(List<DateTime> timeline) {
    return '${timeline.length}_${timeline.isNotEmpty ? timeline.first.hashCode : 0}_${timeline.isNotEmpty ? timeline.last.hashCode : 0}';
  }
  
  // Generate hash for NOTAM data to detect changes
  String _generateNotamHash(List<Notam> notams) {
    if (notams.isEmpty) return 'empty';
    return '${notams.length}_${notams.first.hashCode}_${notams.last.hashCode}';
  }
  
  // Clear cache when switching airports or when data changes
  void _clearCache() {
    _tafStateManager.clearCache();
    _cacheManager.clearPrefix('notam_');
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
  void _logPerformanceStats(FlightProvider flightProvider) {
    final tafMetrics = _tafStateManager.getPerformanceMetrics();
    final cacheStats = _cacheManager.getStats();
    
    debugPrint('DEBUG: Performance Stats - Unified Cache: ${cacheStats['size']} entries, ${cacheStats['hitRate']}% hit rate');
    debugPrint('DEBUG: Performance Stats - TAF Cache: ${tafMetrics['cacheSize']} entries, ${tafMetrics['cacheHitRate']}');
    debugPrint('DEBUG: Performance Stats - Last Airport: ${flightProvider.selectedAirport}');
    debugPrint('DEBUG: Performance Stats - Last Slider Value: ${_sliderPositions[flightProvider.selectedAirport!]}');
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

  void _onSliderChanged(double value, Weather taf, FlightProvider flightProvider) {
    setState(() {
      // Update the slider value for the current airport
      _sliderPositions[flightProvider.selectedAirport!] = value;
      
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
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ZuluTimeWidget(showIcon: false, compact: true, fontSize: 13),
              SizedBox(height: 2),
              Text(
                'Raw Data',
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
          bottom: const TabBar(
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
              Tab(text: 'NOTAMs2'),
            ],
          ),
        ),
        body: Consumer<FlightProvider>(
          builder: (context, flightProvider, child) {
            final flight = flightProvider.currentFlight;
            if (flight == null) {
              return const Center(child: Text('No flight data available'));
            }
            
            // Get airports from TAFs (most comprehensive source)
            final airports = flightProvider.tafsByIcao.keys.toList();
            
            // Initialize selected airport if not set
            if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
              if (airports.isNotEmpty) {
                flightProvider.setSelectedAirport(airports.first);
              }
            }
            
            return Column(
              children: [
                // Fixed airport selector at top
                if (airports.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: RepaintBoundary(
                      child: Center(
                        child: TafAirportSelector(
                          airports: airports,
                          selectedAirport: flightProvider.selectedAirport ?? airports.first,
                          onAirportSelected: (String airport) {
                            _clearCache(); // Clear NOTAM cache when airport changes
                            flightProvider.setSelectedAirport(airport);
                          },
                          onAddAirport: _showAddAirportDialog,
                          onAirportLongPress: _showEditAirportDialog,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                
                // Tab content below
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNotamsTab(context, flight.notams, flightProvider),
                      RefreshIndicator(
                        onRefresh: () async {
                          _clearCache();
                          await flightProvider.refreshFlightData();
                        },
                        child: MetarTab(metarsByIcao: flightProvider.metarsByIcao),
                      ),
                      RefreshIndicator(
                        onRefresh: () async {
                          _clearCache();
                          await flightProvider.refreshFlightData();
                        },
                        child: TafTab(tafsByIcao: flightProvider.tafsByIcao),
                      ),
                      _buildTafs2Tab(context, flightProvider.tafsByIcao, flightProvider),
                      // New NOTAMs2 tab: grouped NOTAMs for selected airport
                      _buildNotams2Tab(context, flight.notams, flightProvider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotamsTab(BuildContext context, List<Notam> notams, FlightProvider flightProvider) {
    // Get unique airports from NOTAMs and normalize them to match other tabs
    final airports = notams.map((notam) => _normalizeAirportCode(notam.icao)).toSet().toList();
    
    // Initialize selected airport if not set
    if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
      if (airports.isNotEmpty) {
        flightProvider.setSelectedAirport(airports.first);
      }
    }
    
    // Get filtered NOTAMs using caching to prevent unnecessary processing
    final filteredNotamsByTime = _getFilteredNotams(notams, flightProvider);

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('DEBUG: 🔄 NOTAMs tab refresh triggered!');
        // Clear all caches for fresh data
        _clearCache();
        await flightProvider.refreshFlightData();
        debugPrint('DEBUG: 🔄 NOTAMs tab refresh completed!');
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            
            // Time filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  const Text(
                    'Show NOTAMs for next:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedTimeFilter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _selectedTimeFilter = value;
                        // Clear NOTAM cache when filter changes
                        _cacheManager.clearPrefix('notam_');
                      });
                    },
                    itemBuilder: (BuildContext context) => _timeFilterOptions.map((option) {
                      return PopupMenuItem<String>(
                        value: option,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: _selectedTimeFilter == option 
                                  ? const Color(0xFF1E3A8A) 
                                  : Colors.transparent,
                            ),
                            const SizedBox(width: 8),
                            Text(option),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: filteredNotamsByTime.isEmpty 
                          ? Colors.grey[200] 
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filteredNotamsByTime.isEmpty 
                              ? Icons.check_circle 
                              : Icons.warning,
                          size: 14,
                          color: filteredNotamsByTime.isEmpty 
                              ? Colors.grey[600] 
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredNotamsByTime.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: filteredNotamsByTime.isEmpty 
                                ? Colors.grey[600] 
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // NOTAMs list
          Expanded(
            child: filteredNotamsByTime.isEmpty
                ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                        const Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
                        const SizedBox(height: 16),
            Text(
                          _selectedTimeFilter == 'All NOTAMs' 
                              ? 'No NOTAMs available'
                              : 'No NOTAMs for the next $_selectedTimeFilter',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                        const SizedBox(height: 8),
            Text(
                          _selectedTimeFilter == 'All NOTAMs'
                              ? 'No NOTAMs for ${flightProvider.selectedAirport}'
                              : 'No active or upcoming NOTAMs in the next $_selectedTimeFilter for ${flightProvider.selectedAirport}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotamsByTime.length,
      itemBuilder: (context, index) {
          final notam = filteredNotamsByTime[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              '${notam.id} - ${notam.affectedSystem}${notam.qCode != null ? ' (${notam.qCode})' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                '${notam.icao} | ${_formatDateTime(notam.validFrom)} - ${_formatDateTime(notam.validTo)}',
                ),
                if (notam.qCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${Notam.getQCodeSubjectDescription(notam.qCode)} - ${Notam.getQCodeStatusDescription(notam.qCode)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            leading: Icon(
              notam.isCritical ? Icons.error : Icons.warning,
              color: notam.isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raw NOTAM Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRawInfoRow('NOTAM ID', notam.id),
                          _buildRawInfoRow('ICAO', notam.icao),
                          _buildRawInfoRow('Type', notam.type.toString().split('.').last),
                          if (notam.qCode != null) ...[
                            _buildRawInfoRow('Q Code', notam.qCode!),
                            _buildRawInfoRow('Q Code Subject', Notam.getQCodeSubjectDescription(notam.qCode)),
                            _buildRawInfoRow('Q Code Status', Notam.getQCodeStatusDescription(notam.qCode)),
                          ],
                          _buildRawInfoRow('Affected System', notam.affectedSystem),
                          _buildRawInfoRow('Critical', notam.isCritical ? 'Yes' : 'No'),
                          _buildRawInfoRow('Valid From', notam.validFrom.toIso8601String()),
                          _buildRawInfoRow('Valid To', notam.validTo.toIso8601String()),
                          const SizedBox(height: 12),
                          Text(
                            'Raw Text:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            notam.displayRawText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.3,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Decoded:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(notam.displayDecodedText),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMetarsTab(BuildContext context, Map<String, List<Weather>> metarsByIcao, FlightProvider flightProvider) {
    // Get unique airports from METARs
    final airports = metarsByIcao.keys.toList();
    
    // Initialize selected airport if not set
    if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
      if (airports.isNotEmpty) {
        flightProvider.setSelectedAirport(airports.first);
      }
    }
    
    // Filter METARs by selected airport
    final filteredMetars = flightProvider.selectedAirport != null 
        ? metarsByIcao[flightProvider.selectedAirport!] ?? []
        : [];
    
    if (metarsByIcao.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No METARs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No current weather observations',
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Airport selector
            if (airports.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: RepaintBoundary(
                  child: TafAirportSelector(
                    airports: airports,
                    selectedAirport: flightProvider.selectedAirport ?? airports.first,
                    onAirportSelected: (String airport) {
                      flightProvider.setSelectedAirport(airport);
                    },
                    onAddAirport: _showAddAirportDialog,
                    onAirportLongPress: _showEditAirportDialog,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            // METARs list
            Expanded(
              child: filteredMetars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No METARs Available',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No METARs for ${flightProvider.selectedAirport}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMetars.length,
      itemBuilder: (context, index) {
          final metar = filteredMetars[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
              title: Row(
                  children: [
                    const Icon(Icons.cloud, color: Color(0xFF3B82F6), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        metar.icao,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        metar.rawText,
                        style: const TextStyle(
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
          ),
        ],
        ),
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
            const SizedBox(height: 16),
            const Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(16),
      itemCount: icaos.length,
      itemBuilder: (context, index) {
        final icao = icaos[index];
        final taf = tafsByIcao[icao]!.first;
        final decodedTaf = taf.decodedWeather;
        
        if (decodedTaf == null || decodedTaf.forecastPeriods == null || decodedTaf.forecastPeriods!.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(icao, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Could not decode TAF.'),
            ),
          );
        }

        final initialPeriod = decodedTaf.forecastPeriods!.firstWhere((p) => p.type == 'INITIAL');
        
        // Create TimePeriod objects for the old tab display
        final timePeriods = decodedTaf.forecastPeriods!.map((period) => TimePeriod(
          startTime: period.startTime ?? DateTime.now(),
          endTime: period.endTime ?? DateTime.now().add(const Duration(hours: 1)),
          baselinePeriod: period,
          concurrentPeriods: [],
          rawTafSection: period.rawSection ?? '',
        )).toList();
        
        final timePeriodStrings = _getTafTimePeriods(timePeriods);
        final initialTimePeriod = timePeriodStrings.isNotEmpty ? timePeriodStrings.first : '';

        // Create TimePeriod for initial period
        final initialTimePeriodObj = TimePeriod(
          startTime: initialPeriod.startTime ?? DateTime.now(),
          endTime: initialPeriod.endTime ?? DateTime.now().add(const Duration(hours: 1)),
          baselinePeriod: initialPeriod,
          concurrentPeriods: [],
          rawTafSection: initialPeriod.rawSection ?? '',
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF3B82F6), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        icao,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  initialTimePeriod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTafCompactDetails(
                  initialTimePeriodObj.baselinePeriod, 
                  initialTimePeriodObj.baselinePeriod.weather, 
                  initialTimePeriodObj.concurrentPeriods,
                  flightProvider
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
                        endTime: period.endTime ?? DateTime.now().add(const Duration(hours: 1)),
                        baselinePeriod: period,
                        concurrentPeriods: [],
                        rawTafSection: period.rawSection ?? '',
                      );
                      return _buildTafPeriodCard(context, timePeriod, timePeriodStrings, timePeriods);
                    }),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Raw TAF at bottom
                    Text(
                      'Raw TAF:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        taf.rawText,
                        style: const TextStyle(
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
            const SizedBox(height: 16),
            const Text(
              'No TAFs Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No terminal area forecasts available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Initialize selected airport if not set
    if (flightProvider.selectedAirport == null || !tafsByIcao.containsKey(flightProvider.selectedAirport)) {
      flightProvider.setSelectedAirport(tafsByIcao.keys.first);
      print('DEBUG: TAFs2 tab - Selected airport: ${flightProvider.selectedAirport}');
    }

    final selectedTaf = tafsByIcao[flightProvider.selectedAirport!]!.first;
    final decodedTaf = selectedTaf.decodedWeather;
    print('DEBUG: TAFs2 tab - Selected TAF: ${selectedTaf.icao}');
    print('DEBUG: TAFs2 tab - Decoded TAF: ${decodedTaf != null}');

    // Get slider position for this airport
    final forecastPeriods = decodedTaf?.forecastPeriods ?? [];
    double sliderValue = _sliderPositions[flightProvider.selectedAirport!] ?? 0.0;
    
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
        
        // Clear all caches for fresh data
        _clearCache();
        
        // Get current scroll position to lock it
        final currentOffset = _tafs2ScrollController.offset;
        print('DEBUG: TAFs2 tab - Current scroll offset: $currentOffset');
        
        // Keep content locked in pulled-down position for a minimum duration
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Manually maintain scroll position during refresh
        if (_tafs2ScrollController.hasClients) {
          _tafs2ScrollController.jumpTo(currentOffset);
        }
        
        // Then perform the actual refresh
        await flightProvider.refreshFlightData();
        
        // Add a small delay after refresh completes for smooth transition
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _tafs2ScrollController,
        child: Padding(
      padding: const EdgeInsets.all(8.0),
          child: Column(
        children: [
              
              // Decoded weather card
              SizedBox(
                height: 290,
                child: RepaintBoundary(
                  child: _activePeriods != null && _activePeriods!['baseline'] != null
                      ? DecodedWeatherCard(
                          key: ValueKey('decoded_${flightProvider.selectedAirport}'),
                          baseline: _activePeriods!['baseline'] as DecodedForecastPeriod,
                          completeWeather: _getCompleteWeatherForPeriod(
                            _activePeriods!['baseline'] as DecodedForecastPeriod,
                            selectedTaf.decodedWeather?.timeline ?? [],
                            forecastPeriods,
                            flightProvider,
                          ),
                          concurrentPeriods: _activePeriods!['concurrent'] as List<DecodedForecastPeriod>,
                          airport: flightProvider.selectedAirport,
                          sliderValue: sliderValue,
                          allPeriods: forecastPeriods,
                          taf: selectedTaf,
                          timeline: selectedTaf.decodedWeather?.timeline,
                        )
                      : const Center(child: Text('No decoded data available')),
                ),
              ),
              const SizedBox(height: 4),
              
              // Raw TAF card
              SizedBox(
                height: 240,
                child: RepaintBoundary(
                  child: RawTafCard(
                    key: ValueKey('raw_${flightProvider.selectedAirport}'),
                    taf: selectedTaf,
                    activePeriods: _activePeriods,
                  ),
                ),
              ),
              
              // Time Slider - now part of scrollable content
              const SizedBox(height: 4),
              SizedBox(
            height: 89,
                child: RepaintBoundary(
                  child: selectedTaf.decodedWeather?.timeline.isNotEmpty == true
                      ? TafTimeSlider(
                          timeline: selectedTaf.decodedWeather!.timeline,
                          sliderValue: sliderValue,
                          onChanged: (value) => _onSliderChanged(value, selectedTaf, flightProvider),
                        )
                      : const SizedBox(
                          height: 89,
                          child: Center(child: Text('No timeline available')),
                        ),
                ),
              ),
              
              // Bottom padding for pull-to-refresh
              const SizedBox(height: 20),
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
      timeline: const [],
      sliderValue: 0.0,
      onChanged: (value) {},
    );
  }

  Widget _buildAirportBubbles(List<String> airports, FlightProvider flightProvider) {
    return TafAirportSelector(
      airports: airports,
      selectedAirport: flightProvider.selectedAirport,
      onAirportSelected: (icao) {
              flightProvider.setSelectedAirport(icao);
            },
      onCacheClear: _clearCache,
    );
  }

  Widget _buildDecodedCardFromActivePeriods(Map<String, dynamic> activePeriods, List<DateTime> timeline, [List<DecodedForecastPeriod>? allPeriods, FlightProvider? flightProvider]) {
    final baseline = activePeriods['baseline'] as DecodedForecastPeriod?;
    final concurrent = activePeriods['concurrent'] as List<DecodedForecastPeriod>;
    
    if (baseline == null) {
      return _buildEmptyDecodedCard();
    }
    // Get complete weather for the baseline period
    final completeWeather = _getCompleteWeatherForPeriod(baseline, timeline, allPeriods, flightProvider);
    // Return the card with period information for highlighting
    return _buildDecodedCardWithHighlightingInfo(baseline, completeWeather, concurrent, allPeriods, flightProvider!);
  }
  
  Widget _buildDecodedCardWithHighlightingInfo(DecodedForecastPeriod baseline, Map<String, String> completeWeather, List<DecodedForecastPeriod> concurrentPeriods, List<DecodedForecastPeriod>? allPeriods, FlightProvider flightProvider) {
    return DecodedWeatherCard(
      baseline: baseline,
      completeWeather: completeWeather,
      concurrentPeriods: concurrentPeriods,
      tafStateManager: _tafStateManager,
      airport: flightProvider.selectedAirport,
      sliderValue: _sliderPositions[flightProvider.selectedAirport!],
      allPeriods: allPeriods,
      taf: null, // This method is not used in the current implementation
      timeline: null, // This method is not used in the current implementation
    );
  }

  Map<String, String> _getCompleteWeatherForPeriod(DecodedForecastPeriod period, List<DateTime> timeline, [List<DecodedForecastPeriod>? allPeriods, FlightProvider? flightProvider]) {
    // Use TafStateManager to get complete weather with inheritance
    return _tafStateManager.getCompleteWeatherForPeriod(
      period,
      flightProvider?.selectedAirport ?? '',
      _sliderPositions[flightProvider?.selectedAirport!] ?? 0.0,
      allPeriods ?? [],
    );
  }

  Widget _buildTafCompactDetails(DecodedForecastPeriod baseline, Map<String, String> completeWeather, List<DecodedForecastPeriod> concurrentPeriods, FlightProvider flightProvider) {
    return Column(
      children: [
        // Baseline weather with integrated TEMPO/INTER
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Wind', completeWeather['Wind'], concurrentPeriods, 'Wind', flightProvider),
              const SizedBox(width: 16),
              _buildGridItemWithConcurrent('Visibility', completeWeather['Visibility'], concurrentPeriods, 'Visibility', flightProvider),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Weather', completeWeather['Weather'], concurrentPeriods, 'Weather', flightProvider, isPhenomenaOrRemark: true),
              const SizedBox(width: 16),
              _buildGridItemWithConcurrent('Cloud', completeWeather['Cloud'], concurrentPeriods, 'Cloud', flightProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItemWithConcurrent(String label, String? value, List<DecodedForecastPeriod> concurrentPeriods, String weatherType, FlightProvider flightProvider, {bool isPhenomenaOrRemark = false}) {
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
    final currentBuild = '${flightProvider.selectedAirport}_${_sliderPositions[flightProvider.selectedAirport!] ?? 0.0}_$label';
    if (_lastLoggedBuild != currentBuild) {
      _lastLoggedBuild = currentBuild;
    }
    
    // Find concurrent periods that have changes for this weather type
    final relevantConcurrentPeriods = concurrentPeriods.where((period) => 
      period.changedElements.contains(weatherType)
    ).toList();
    
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
          const SizedBox(height: 2),
        ],
        if (weather['Visibility'] != null) ...[
          Text('Visibility: ${weather['Visibility']}'),
          const SizedBox(height: 2),
        ],
        if (weather['Cloud'] != null) ...[
          Text('Cloud: ${weather['Cloud']}'),
          const SizedBox(height: 2),
        ],
        if (weather['Weather'] != null) ...[
          Text('Weather: ${weather['Weather']}'),
          const SizedBox(height: 2),
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
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGridItem('Wind', weather['Wind'], isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Wind')),
                const SizedBox(width: 16),
                _buildGridItem('Visibility', weather['Visibility'], isPhenomenaOrRemark: !isInitial && period.baselinePeriod.changedElements.contains('Visibility')),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGridItem('Weather', weather['Weather'], isPhenomenaOrRemark: true),
                const SizedBox(width: 16),
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
          const SizedBox(height: 2),
            Text(
            displayValue,
            style: const TextStyle(
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
          title: const Text('Add Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the ICAO code for the airport you want to add:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
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
              child: const Text('Cancel'),
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
                    const SnackBar(
                      content: Text('Please enter a valid 4-letter ICAO code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
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
          title: const Text('Edit Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What would you like to do with airport $airport?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditAirportCodeDialog(context, airport);
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showRemoveAirportDialog(context, airport);
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Remove'),
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
              child: const Text('Cancel'),
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
          title: const Text('Edit Airport Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the new ICAO code for airport $oldAirport:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
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
              child: const Text('Cancel'),
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
                      const SnackBar(
                        content: Text('Failed to update airport. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (newIcao == oldAirport) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No changes made'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid 4-letter ICAO code'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
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
          title: const Text('Remove Airport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to remove airport $airport from your flight plan?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
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
              child: const Text('Cancel'),
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
                    const SnackBar(
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRawInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[900],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get filtered NOTAMs with caching to prevent unnecessary processing
  List<Notam> _getFilteredNotams(List<Notam> notams, FlightProvider flightProvider) {
    // Generate cache key using unified cache manager
    final cacheKey = CacheManager.generateKey('notam_filtered', {
      'notamHash': _generateNotamHash(notams),
      'airport': flightProvider.selectedAirport ?? '',
      'timeFilter': _selectedTimeFilter,
    });
    
    // Check cache first
    final cachedResult = _cacheManager.get<List<Notam>>(cacheKey);
    if (cachedResult != null) {
      debugPrint('DEBUG: Using cached filtered NOTAMs (${cachedResult.length} NOTAMs)');
      debugPrint('DEBUG: Filtered NOTAM IDs (cached): ${cachedResult.map((n) => n.id).join(", ")}');
      return cachedResult;
    }
    
    // Process NOTAMs and cache results
    debugPrint('DEBUG: Processing NOTAMs (cache miss) - airport: ${flightProvider.selectedAirport}, filter: $_selectedTimeFilter');
    
    // Filter by airport first
    final airportFilteredNotams = flightProvider.selectedAirport != null 
        ? notams.where((notam) => _normalizeAirportCode(notam.icao) == flightProvider.selectedAirport).toList()
        : notams;
    debugPrint('DEBUG: After airport filter: ${airportFilteredNotams.length} NOTAMs');
    debugPrint('DEBUG: Airport filtered NOTAM IDs: ${airportFilteredNotams.map((n) => n.id).join(", ")}');
    
    // Filter by time
    final timeFilteredNotams = _filterNotamsByTime(airportFilteredNotams);
    debugPrint('DEBUG: After time filter: ${timeFilteredNotams.length} NOTAMs');
    debugPrint('DEBUG: Time filtered NOTAM IDs: ${timeFilteredNotams.map((n) => n.id).join(", ")}');
    
    // Cache the result
    _cacheManager.set(cacheKey, timeFilteredNotams);
    
    debugPrint('DEBUG: Cached ${timeFilteredNotams.length} filtered NOTAMs');
    return timeFilteredNotams;
  }

  // Filter NOTAMs based on selected time filter
  List<Notam> _filterNotamsByTime(List<Notam> notams) {
    debugPrint('DEBUG: _filterNotamsByTime called with ${notams.length} NOTAMs, filter: $_selectedTimeFilter');
    
    if (_selectedTimeFilter == 'All NOTAMs') {
      debugPrint('DEBUG: Returning all ${notams.length} NOTAMs (All NOTAMs filter)');
      return notams;
    }
    
    final now = DateTime.now().toUtc(); // Use UTC time consistently
    Duration filterDuration;
    
    switch (_selectedTimeFilter) {
      case '6 hours':
        filterDuration = const Duration(hours: 6);
        break;
      case '12 hours':
        filterDuration = const Duration(hours: 12);
        break;
      case '24 hours':
        filterDuration = const Duration(hours: 24);
        break;
      case '72 hours':
        filterDuration = const Duration(hours: 72);
        break;
      default:
        debugPrint('DEBUG: Unknown filter, returning all ${notams.length} NOTAMs');
        return notams;
    }
    
    final filterEndTime = now.add(filterDuration);
    
    debugPrint('DEBUG: Current UTC time: ${now.toIso8601String()}');
    debugPrint('DEBUG: Filter end time: ${filterEndTime.toIso8601String()}');
    debugPrint('DEBUG: Filter duration: ${filterDuration.inHours} hours');
    
    // Only log NOTAMs occasionally to reduce console spam
    if (notams.length <= 5) {
      // Log all NOTAMs if there are 5 or fewer
      for (int i = 0; i < notams.length; i++) {
        final notam = notams[i];
        final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
        final isFutureActive = notam.validFrom.isAfter(now) && notam.validFrom.isBefore(filterEndTime);
        final passesFilter = isCurrentlyActive || isFutureActive;
        
        debugPrint('DEBUG: NOTAM ${i + 1}/${notams.length}: ${notam.id} (${notam.icao})');
        debugPrint('DEBUG:   Valid from: ${notam.validFrom.toIso8601String()}');
        debugPrint('DEBUG:   Valid to: ${notam.validTo.toIso8601String()}');
        debugPrint('DEBUG:   Currently active: $isCurrentlyActive');
        debugPrint('DEBUG:   Future active: $isFutureActive');
        debugPrint('DEBUG:   Passes filter: $passesFilter');
      }
    } else {
      // Log only first 3 and last 3 NOTAMs if there are more than 5
      for (int i = 0; i < 3; i++) {
        final notam = notams[i];
        final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
        final isFutureActive = notam.validFrom.isAfter(now) && notam.validFrom.isBefore(filterEndTime);
        final passesFilter = isCurrentlyActive || isFutureActive;
        
        debugPrint('DEBUG: NOTAM ${i + 1}/${notams.length}: ${notam.id} (${notam.icao})');
        debugPrint('DEBUG:   Valid from: ${notam.validFrom.toIso8601String()}');
        debugPrint('DEBUG:   Valid to: ${notam.validTo.toIso8601String()}');
        debugPrint('DEBUG:   Currently active: $isCurrentlyActive');
        debugPrint('DEBUG:   Future active: $isFutureActive');
        debugPrint('DEBUG:   Passes filter: $passesFilter');
      }
      debugPrint('DEBUG: ... (${notams.length - 6} more NOTAMs) ...');
      for (int i = notams.length - 3; i < notams.length; i++) {
        final notam = notams[i];
        final isCurrentlyActive = notam.validFrom.isBefore(now) && notam.validTo.isAfter(now);
        final isFutureActive = notam.validFrom.isAfter(now) && notam.validFrom.isBefore(filterEndTime);
        final passesFilter = isCurrentlyActive || isFutureActive;
        
        debugPrint('DEBUG: NOTAM ${i + 1}/${notams.length}: ${notam.id} (${notam.icao})');
        debugPrint('DEBUG:   Valid from: ${notam.validFrom.toIso8601String()}');
        debugPrint('DEBUG:   Valid to: ${notam.validTo.toIso8601String()}');
        debugPrint('DEBUG:   Currently active: $isCurrentlyActive');
        debugPrint('DEBUG:   Future active: $isFutureActive');
        debugPrint('DEBUG:   Passes filter: $passesFilter');
      }
    }
    
    final filteredNotams = notams.where((notam) {
      // Show NOTAMs that are either:
      // 1. Currently active (started before now, ends after now)
      // 2. Will become active within the time window
      return (notam.validFrom.isBefore(now) && notam.validTo.isAfter(now)) || // Currently active
             (notam.validFrom.isAfter(now) && notam.validFrom.isBefore(filterEndTime)); // Future active
    }).toList();
    
    debugPrint('DEBUG: Filtered NOTAMs result: ${filteredNotams.length} NOTAMs pass the filter');
    return filteredNotams;
  }

  // Normalize airport codes to ensure consistency across tabs
  String _normalizeAirportCode(String icao) {
    // If it's a 3-letter US airport code, add 'K' prefix
    if (icao.length == 3 && icao == icao.toUpperCase()) {
      return 'K$icao';
    }
    return icao.toUpperCase();
  }

  Widget _buildNotams2Tab(BuildContext context, List<Notam> notams, FlightProvider flightProvider) {
    // Get unique airports from NOTAMs
    final airports = notams.map((notam) => _normalizeAirportCode(notam.icao)).toSet().toList();
    // Use selected airport
    final selectedAirport = flightProvider.selectedAirport ?? (airports.isNotEmpty ? airports.first : null);
    // Get filtered NOTAMs using caching to prevent unnecessary processing
    final filteredNotamsByTime = _getFilteredNotams(notams, flightProvider);
    final filteredNotams = selectedAirport != null
        ? filteredNotamsByTime.where((n) => _normalizeAirportCode(n.icao) == selectedAirport).toList().cast<Notam>()
        : <Notam>[];
    
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('DEBUG: 🔄 NOTAMs2 tab refresh triggered!');
        // Clear all caches for fresh data
        _clearCache();
        await flightProvider.refreshFlightData();
        debugPrint('DEBUG: 🔄 NOTAMs2 tab refresh completed!');
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Time filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  const Text(
                    'Show NOTAMs for next:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedTimeFilter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => _timeFilterOptions.map((filter) {
                      return PopupMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onSelected: (value) {
                      setState(() {
                        _selectedTimeFilter = value;
                        // Clear NOTAM cache when filter changes
                        _clearCache();
                      });
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: filteredNotams.isEmpty 
                          ? Colors.grey[200] 
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filteredNotams.isEmpty 
                              ? Icons.check_circle 
                              : Icons.warning,
                          size: 14,
                          color: filteredNotams.isEmpty 
                              ? Colors.grey[600] 
                              : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${filteredNotams.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: filteredNotams.isEmpty 
                                ? Colors.grey[600] 
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Grouped NOTAM list
            Expanded(
              child: NotamGroupedList(
                notams: filteredNotams,
                onNotamTap: (notam) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('NOTAM Details: ${notam.id}'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ICAO: ${notam.icao}'),
                            Text('Type: ${notam.type.name}'),
                            Text('Group: ${notam.group.name}'),
                            Text('Critical: ${notam.isCritical ? "Yes" : "No"}'),
                            const SizedBox(height: 8),
                            Text('Valid From: ${notam.validFrom.toUtc()}'),
                            Text('Valid To: ${notam.validTo.toUtc()}'),
                            const SizedBox(height: 8),
                            Text('Raw Text:'),
                            Text(notam.displayRawText, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('Decoded Text:'),
                            Text(notam.displayDecodedText, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                showGroupHeaders: true,
                initiallyExpanded: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 