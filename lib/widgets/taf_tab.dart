import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/decoded_weather_models.dart';
import 'taf_compact_details.dart';
import 'taf_period_card.dart';

class TafTab extends StatelessWidget {
  final Map<String, List<Weather>> tafsByIcao;

  const TafTab({
    Key? key,
    required this.tafsByIcao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    return ListView.builder(
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
                        endTime: period.endTime ?? DateTime.now().add(Duration(hours: 1)),
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