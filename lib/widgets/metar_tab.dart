import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import 'metar_compact_details.dart';
import 'taf_airport_selector.dart';

class MetarTab extends StatelessWidget {
  final Map<String, List<Weather>> metarsByIcao;

  const MetarTab({
    super.key,
    required this.metarsByIcao,
  });

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          
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
        final decoded = metar.decodedWeather;
        
        return Card(
                        margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                              const SizedBox(height: 8),
                MetarCompactDetails(metar: metar),
              ],
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
    );
  }
} 