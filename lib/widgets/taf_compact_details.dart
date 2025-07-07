import 'package:flutter/material.dart';
import '../models/decoded_weather_models.dart';
import 'grid_item_with_concurrent.dart';

class TafCompactDetails extends StatelessWidget {
  final DecodedForecastPeriod baseline;
  final Map<String, String> completeWeather;
  final List<DecodedForecastPeriod> concurrentPeriods;

  const TafCompactDetails({
    super.key,
    required this.baseline,
    required this.completeWeather,
    required this.concurrentPeriods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Baseline weather with integrated TEMPO/INTER
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItemWithConcurrent(
                label: 'Wind',
                value: completeWeather['Wind'],
                concurrentPeriods: concurrentPeriods,
                weatherType: 'Wind',
              ),
              const SizedBox(width: 16),
              GridItemWithConcurrent(
                label: 'Visibility',
                value: completeWeather['Visibility'],
                concurrentPeriods: concurrentPeriods,
                weatherType: 'Visibility',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridItemWithConcurrent(
                label: 'Weather',
                value: completeWeather['Weather'],
                concurrentPeriods: concurrentPeriods,
                weatherType: 'Weather',
                isPhenomenaOrRemark: true,
              ),
              const SizedBox(width: 16),
              GridItemWithConcurrent(
                label: 'Cloud',
                value: completeWeather['Cloud'],
                concurrentPeriods: concurrentPeriods,
                weatherType: 'Cloud',
              ),
            ],
          ),
        ),
      ],
    );
  }
} 