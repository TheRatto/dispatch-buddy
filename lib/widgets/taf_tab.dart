import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import 'taf_compact_details.dart';
import 'taf_period_card.dart';
import 'taf_airport_selector.dart';

class TafTab extends StatelessWidget {
  final Map<String, List<Weather>> tafsByIcao;

  const TafTab({
    super.key,
    required this.tafsByIcao,
  });

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    
    // Get unique airports from TAFs
    final airports = tafsByIcao.keys.toList();
    
    // Initialize selected airport if not set
    if (flightProvider.selectedAirport == null || !airports.contains(flightProvider.selectedAirport)) {
      if (airports.isNotEmpty) {
        flightProvider.setSelectedAirport(airports.first);
      }
    }
    
    // Filter TAFs by selected airport
    final filteredTafs = flightProvider.selectedAirport != null 
        ? tafsByIcao[flightProvider.selectedAirport!] ?? []
        : [];
    
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          
          // TAFs list
          Expanded(
            child: filteredTafs.isEmpty
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
                    itemCount: filteredTafs.length,
      itemBuilder: (context, index) {
                      final taf = filteredTafs[index];
        final decodedTaf = taf.decodedWeather;
        
        if (decodedTaf == null || decodedTaf.forecastPeriods == null || decodedTaf.forecastPeriods!.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(taf.icao, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Could not decode TAF.'),
            ),
          );
        }

        final initialPeriod = decodedTaf.forecastPeriods!.firstWhere((p) => p.type == 'INITIAL');
        
        // Create TimePeriod objects for the old tab display
        final timePeriods = <TimePeriod>[
          ...decodedTaf.forecastPeriods!.map((period) => TimePeriod(
          startTime: period.startTime ?? DateTime.now(),
            endTime: period.endTime ?? DateTime.now().add(const Duration(hours: 1)),
          baselinePeriod: period,
          concurrentPeriods: [],
          rawTafSection: period.rawSection ?? '',
          )),
        ];
        
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
                        taf.icao,
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
                TafCompactDetails(
                  baseline: initialTimePeriodObj.baselinePeriod,
                  completeWeather: initialTimePeriodObj.baselinePeriod.weather,
                  concurrentPeriods: initialTimePeriodObj.concurrentPeriods,
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
                      return TafPeriodCard(
                        period: timePeriod,
                        timePeriodStrings: timePeriodStrings,
                        allPeriods: timePeriods,
                      );
                    }).toList(),
                    
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