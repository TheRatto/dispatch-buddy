import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'grid_item.dart';

class MetarCompactDetails extends StatefulWidget {
  final Weather metar;

  const MetarCompactDetails({
    super.key,
    required this.metar,
  });

  @override
  State<MetarCompactDetails> createState() => _MetarCompactDetailsState();
}

class _MetarCompactDetailsState extends State<MetarCompactDetails> {
  @override
  Widget build(BuildContext context) {
    if (widget.metar.decodedWeather == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No decoded data available.'),
      );
    }

    final decoded = widget.metar.decodedWeather!;
    final isCavok = widget.metar.rawText.contains('CAVOK');
    
    String? temp, dewPoint;
    if (decoded.temperatureDescription.isNotEmpty && !decoded.temperatureDescription.contains('unavailable')) {
        var parts = decoded.temperatureDescription.split(',');
        temp = parts[0].replaceAll('Temperature ', '');
        if (parts.length > 1) {
            dewPoint = parts[1].replaceAll(' Dew point ', '');
        }
    }

    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Weather grid
        Row(
            children: [
            Expanded(
              child: GridItem(
                label: 'Wind',
                value: decoded.windDescription,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Visibility',
                value: decoded.visibilityDescription,
              ),
            ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
            children: [
            Expanded(
              child: GridItem(
                label: 'Weather',
                value: decoded.conditionsDescription,
                isPhenomenaOrRemark: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Cloud',
                value: decoded.cloudDescription,
              ),
            ),
            ],
          ),
        const SizedBox(height: 8),
            Row(
              children: [
            Expanded(
              child: GridItem(
                label: 'Temp / Dew Point',
                value: decoded.temperatureDescription,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Remarks',
                value: decoded.remarks?.isNotEmpty == true ? decoded.remarks! : '-',
                isPhenomenaOrRemark: true,
              ),
            ),
            ],
          ),
        ],
    );
  }
} 