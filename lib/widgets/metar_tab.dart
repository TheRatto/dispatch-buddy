import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import 'atis_card.dart' as atis_widget;
import 'metar_flip_card_widget.dart';

class MetarTab extends StatefulWidget {
  const MetarTab({
    super.key,
  });

  @override
  State<MetarTab> createState() => _MetarTabState();
}

class _MetarTabState extends State<MetarTab> {
  Timer? _ageUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Update age every minute for dynamic updates
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update age strings
        });
      }
    });
  }

  @override
  void dispose() {
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  Weather? _getAtisForAirport(BuildContext context, String? icao) {
    if (icao == null) return null;
    
    // Get all weather data from the flight provider
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final allWeather = flightProvider.currentFlight?.weather ?? [];
    
    // Find ATIS for the selected airport
    final atisList = allWeather.where((weather) => 
      weather.type == 'ATIS' && weather.icao == icao
    ).toList();
    
    // Return the latest ATIS (first in the list)
    return atisList.isNotEmpty ? atisList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Get all airports from the current flight
    final allAirports = flightProvider.currentFlight?.airports.map((a) => a.icao).toList() ?? [];
    
    // If an airport is selected, filter to just that airport. Otherwise, show all airports
    final airportsToShow = flightProvider.selectedAirport != null 
        ? [flightProvider.selectedAirport!]
        : allAirports;
    
    // Get METARs directly from the flight's weather data (like NOTAMs do)
    final flightWeather = flightProvider.currentFlight?.weather ?? [];
    final metarsToShow = <String, List<Weather>>{};
    
    debugPrint('DEBUG: Total weather items: ${flightWeather.length}');
    debugPrint('DEBUG: Weather types: ${flightWeather.map((w) => '${w.icao}(${w.type})').join(', ')}');
    
    for (final airport in airportsToShow) {
      final airportMetars = flightWeather
          .where((w) => w.type == 'METAR' && w.icao == airport)
          .toList();
      debugPrint('DEBUG: Found ${airportMetars.length} METARs for airport $airport');
      if (airportMetars.isNotEmpty) {
        metarsToShow[airport] = airportMetars;
        // Debug the first METAR
        final firstMetar = airportMetars.first;
        debugPrint('DEBUG: First METAR for $airport - rawText: "${firstMetar.rawText}"');
      }
    }
    
    debugPrint('DEBUG: Final metarsToShow: ${metarsToShow.keys.join(', ')}');
    
    // Check if we have any METARs to show after filtering
    if (metarsToShow.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 20, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No METARs Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  flightProvider.selectedAirport != null 
                      ? 'No METARs for ${flightProvider.selectedAirport}'
                      : 'No current weather observations',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    final selectedAirport = flightProvider.selectedAirport;

    // Determine if NAIPS is enabled but we have no NAIPS weather for this airport
    final allWeather = flightProvider.currentFlight?.weather ?? [];
    final hasAnyForAirport = allWeather.any((w) => w.icao == selectedAirport);
    final hasNaipsForAirport = allWeather.any((w) => w.icao == selectedAirport && w.source == 'naips');
    final showNaipsFallbackBanner = settings.naipsEnabled && hasAnyForAirport && !hasNaipsForAirport;

    return Column(
      children: [
          if (showNaipsFallbackBanner)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                border: Border.all(color: const Color(0xFFF59E0B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NAIPS data unavailable for this airport. Showing API data instead.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          // Single scrollable content area containing both ATIS and METAR
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200, // Ensure minimum height for scrolling
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                        // ATIS Card (first - more important for pilots)
                      Builder(
                        builder: (context) {
                          final atis = _getAtisForAirport(context, flightProvider.selectedAirport);
                          if (atis != null) {
                            return atis_widget.AtisCard(
                              key: ValueKey('atis_${flightProvider.selectedAirport ?? ''}'),
                              atis: atis,
                              icao: flightProvider.selectedAirport ?? '',
                            );
                          } else {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.radio,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "No ATIS available at ${flightProvider.selectedAirport}",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      
                      
                      // METAR Cards
                      ...metarsToShow.entries.map((entry) {
                        final metars = entry.value;
                        return Column(
                          children: [
                            // METAR Flip Cards for this airport
                            ...metars.map((metar) => MetarFlipCardWidget(
                              metar: metar,
                              icao: entry.key,
                            )).toList(),
                          ],
                        );
                      }).toList(),
                      
                      // No METARs message if none available
                      if (metarsToShow.isEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
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
                          ),
                        ),
                      
                      // Add bottom padding to prevent overflow and ensure pull-to-refresh works
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
} 