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
import 'alternate_data_screen.dart';

class RawDataScreen extends StatefulWidget {
  const RawDataScreen({super.key});

  @override
  _RawDataScreenState createState() => _RawDataScreenState();
}

class _RawDataScreenState extends State<RawDataScreen> with TickerProviderStateMixin {
  // Tab controller for managing tabs
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Scaffold(
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
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            indicatorColor: const Color(0xFFF97316), // Accent Orange
            indicatorWeight: 3.0,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'NOTAMs'),
              Tab(text: 'METARs'),
              Tab(text: 'TAFs'),
            ],
          ),
        ),
        endDrawer: _buildEndDrawer(context),
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
                    controller: _tabController,
              children: [
                      // NOTAMs tab: grouped NOTAMs for selected airport
                      _buildNotams2Tab(context, flight.notams, flightProvider),
                RefreshIndicator(
                  onRefresh: () async {
                          _clearCache();
                    await flightProvider.refreshFlightData();
                  },
                  child: MetarTab(metarsByIcao: flightProvider.metarsByIcao),
                ),
                      // TAFs tab: timeline-based TAF display
                _buildTafs2Tab(context, flightProvider.tafsByIcao, flightProvider),
                    ],
                  ),
                ),
              ],
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

  Widget _buildEndDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Dispatch Buddy',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.not_interested),
            title: Text('NOTAMs'),
            subtitle: Text('Grouped with swipe actions'),
            onTap: () {
              debugPrint('DEBUG: NOTAMs menu item tapped');
              Navigator.of(context).pop(); // Close drawer
              // Navigate to NOTAMs tab
              final tabController = DefaultTabController.of(context);
              if (tabController != null && tabController.length > 0) {
                debugPrint('DEBUG: Animating to tab 0 (NOTAMs)');
                tabController.animateTo(0);
              } else {
                debugPrint('DEBUG: TabController is null or has no tabs');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.cloud),
            title: Text('METARs'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Navigate to METARs tab
              final tabController = DefaultTabController.of(context);
              if (tabController != null && tabController.length > 1) {
                tabController.animateTo(1);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('TAFs'),
            subtitle: Text('Timeline-based display'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Navigate to TAFs tab
              final tabController = DefaultTabController.of(context);
              if (tabController != null && tabController.length > 2) {
                tabController.animateTo(2);
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.alternate_email),
            title: Text('Alternate Data'),
            subtitle: Text('Legacy NOTAMs & TAFs'),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlternateDataScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 