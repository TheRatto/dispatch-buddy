import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import '../models/decoded_weather_models.dart';
import '../services/decoder_service.dart';
import 'taf_period_card.dart';
import 'taf_compact_details.dart';
import 'taf_empty_states.dart';


class TafTab extends StatelessWidget {
  const TafTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    
    // Get all airports from the current flight
    final allAirports = flightProvider.currentFlight?.airports.map((a) => a.icao).toList() ?? [];
    
    // If an airport is selected, filter to just that airport. Otherwise, show all airports
    final airportsToShow = flightProvider.selectedAirport != null 
        ? [flightProvider.selectedAirport!]
        : allAirports;
    
    // Get TAFs directly from the flight's weather data (like NOTAMs do)
    final flightWeather = flightProvider.currentFlight?.weather ?? [];
    final tafsToShow = <String, List<Weather>>{};
    
    for (final airport in airportsToShow) {
      final airportTafs = flightWeather
          .where((w) => w.type == 'TAF' && w.icao == airport)
          .toList();
      if (airportTafs.isNotEmpty) {
        tafsToShow[airport] = airportTafs;
      }
    }
    
    // Check if we have any TAFs to show after filtering
    if (tafsToShow.isEmpty) {
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
                  'No TAFs Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  flightProvider.selectedAirport != null 
                      ? 'No TAFs for ${flightProvider.selectedAirport}'
                      : 'No current weather forecasts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          
          // TAFs list
          Expanded(
            child: tafsToShow.isEmpty
                ? Center(
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
                          'No TAFs for ${flightProvider.selectedAirport}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tafsToShow.length,
      itemBuilder: (context, index) {
                      final airport = tafsToShow.keys.elementAt(index);
        final tafsForAirport = tafsToShow[airport]!;
        
        if (tafsForAirport.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(airport, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('No TAFs available for this airport.'),
            ),
          );
        }

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
                        airport,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tafsForAirport.length} TAF${tafsForAirport.length == 1 ? '' : 's'} available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show all TAFs for this airport
                    ...tafsForAirport.map((taf) {
                      final decodedTaf = taf.decodedWeather;
                      if (decodedTaf == null || decodedTaf.forecastPeriods == null || decodedTaf.forecastPeriods!.isEmpty) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('TAF ${taf.icao}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Could not decode TAF.'),
                          ),
                        );
                      }

                      // Find initial period
                      final initialPeriod = decodedTaf.forecastPeriods!.firstWhere(
                        (p) => p.type == 'INITIAL',
                        orElse: () => decodedTaf.forecastPeriods!.first,
                      );

                      // Create TimePeriod for display
                      final timePeriod = TimePeriod(
                        startTime: initialPeriod.startTime ?? DateTime.now(),
                        endTime: initialPeriod.endTime ?? DateTime.now().add(const Duration(hours: 1)),
                        baselinePeriod: initialPeriod,
                        concurrentPeriods: [],
                        rawTafSection: initialPeriod.rawSection ?? '',
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TAF header
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF3B82F6), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'TAF ${taf.icao}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // TAF compact details
                          TafCompactDetails(
                            baseline: timePeriod.baselinePeriod,
                            completeWeather: timePeriod.baselinePeriod.weather,
                            concurrentPeriods: timePeriod.concurrentPeriods,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Raw TAF text
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
                          
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
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
    );
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
} 