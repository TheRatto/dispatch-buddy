import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'metar_compact_details.dart';

class MetarTab extends StatelessWidget {
  final Map<String, List<Weather>> metarsByIcao;

  const MetarTab({
    Key? key,
    required this.metarsByIcao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: icaos.length,
      itemBuilder: (context, index) {
        final icao = icaos[index];
        final metar = metarsByIcao[icao]!.first;
        final decoded = metar.decodedWeather;
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                SizedBox(height: 8),
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
    );
  }
} 