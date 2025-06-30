import 'package:flutter/material.dart';
import '../models/decoded_weather_models.dart';
import '../constants/weather_colors.dart';

class GridItemWithConcurrent extends StatelessWidget {
  final String label;
  final String? value;
  final List<DecodedForecastPeriod> concurrentPeriods;
  final String weatherType;
  final bool isPhenomenaOrRemark;

  const GridItemWithConcurrent({
    Key? key,
    required this.label,
    this.value,
    required this.concurrentPeriods,
    required this.weatherType,
    this.isPhenomenaOrRemark = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String displayValue = value ?? '-';
    if (isPhenomenaOrRemark) {
      if (value == null || value!.isEmpty || value == 'No significant weather') {
        displayValue = '-';
      }
    } else {
      if (value == null || value!.isEmpty || value!.contains('unavailable') || value!.contains('No cloud information')) {
        displayValue = '-'; // Show - instead of N/A to match weather heading
      }
    }
    
    // Find concurrent periods that have changes for this weather type
    final relevantConcurrentPeriods = concurrentPeriods.where((period) => 
      period.changedElements.contains(weatherType)
    ).toList();
    
    // Memoize concurrent period widgets to prevent unnecessary rebuilds
    final concurrentWidgets = relevantConcurrentPeriods.map((period) {
      final color = WeatherColors.getColorForProbCombination(period.type);
      final label = period.type; // Use the full period type instead of just 'TEMPO' or 'INTER'
      final concurrentValue = period.weather[weatherType];
      
      if (concurrentValue == null || concurrentValue.isEmpty || 
          (isPhenomenaOrRemark && (concurrentValue == 'No significant weather'))) {
        return const SizedBox.shrink();
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          concurrentValue,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      );
    }).toList();
    
    return Expanded(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add TEMPO/INTER lines if they have changes for this weather type
            ...concurrentWidgets,
          ],
        ),
      ),
    );
  }
} 