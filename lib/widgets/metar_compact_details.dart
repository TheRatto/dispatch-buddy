import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'grid_item.dart';

class MetarCompactDetails extends StatelessWidget {
  final Weather metar;

  const MetarCompactDetails({
    Key? key,
    required this.metar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (metar.decodedWeather == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No decoded data available.'),
      );
    }

    final decoded = metar.decodedWeather!;
    final isCavok = metar.rawText.contains('CAVOK');
    
    String? temp, dewPoint;
    if (decoded.temperatureDescription.isNotEmpty && !decoded.temperatureDescription.contains('unavailable')) {
        var parts = decoded.temperatureDescription.split(',');
        temp = parts[0].replaceAll('Temperature ', '');
        if (parts.length > 1) {
            dewPoint = parts[1].replaceAll(' Dew point ', '');
        }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItem(label: 'Wind', value: decoded.windDescription.replaceFirst('Wind ', '')),
              SizedBox(width: 16),
              GridItem(label: 'Visibility', value: isCavok ? 'CAVOK' : decoded.visibilityDescription.replaceFirst('Visibility ', '')),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItem(label: 'Weather', value: decoded.conditionsDescription, isPhenomenaOrRemark: true),
              SizedBox(width: 16),
              GridItem(label: 'Cloud', value: decoded.cloudDescription),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItem(label: 'Temp / Dew Point', value: '$temp / $dewPoint'),
              SizedBox(width: 16),
              GridItem(label: 'QNH', value: decoded.pressureDescription.replaceFirst('QNH ', '')),
            ],
          ),
          if (decoded.rvrDescription.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridItem(label: 'RVR', value: decoded.rvrDescription.replaceFirst('Runway Visual Range: ', '')),
                SizedBox(width: 16),
                Expanded(child: SizedBox()), // Placeholder for alignment
              ],
            ),
           Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItem(label: 'Remarks', value: decoded.remarks, isPhenomenaOrRemark: true),
            ],
          ),
        ],
      ),
    );
  }
} 