import 'package:flutter/material.dart';
import '../models/decoded_weather_models.dart';
import '../services/decoder_service.dart';

/// Decoded Weather Card Widget
/// 
/// Displays decoded TAF weather information in a grid layout with:
/// - Wind, Visibility, Weather, Cloud sections
/// - Concurrent period highlighting (TEMPO/PROB)
/// - Color-coded concurrent weather display
/// - Exact styling preserved from original implementation
class DecodedWeatherCard extends StatelessWidget {
  final DecodedForecastPeriod baseline;
  final Map<String, String> completeWeather;
  final List<DecodedForecastPeriod> concurrentPeriods;

  const DecodedWeatherCard({
    Key? key,
    required this.baseline,
    required this.completeWeather,
    required this.concurrentPeriods,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Return the card with period information for highlighting
    return _buildDecodedCardWithHighlightingInfo(baseline, completeWeather, concurrentPeriods);
  }

  Widget _buildEmptyDecodedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decoded TAF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  'No decoded data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecodedCardWithHighlightingInfo(
    DecodedForecastPeriod baseline, 
    Map<String, String> completeWeather, 
    List<DecodedForecastPeriod> concurrentPeriods
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Decoded TAF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (concurrentPeriods.isNotEmpty) _buildConcurrentKey(concurrentPeriods),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: _buildTafCompactDetails(baseline, completeWeather, concurrentPeriods),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcurrentKey(List<DecodedForecastPeriod> concurrentPeriods) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: concurrentPeriods.map((period) {
        Color color;
        String label;
        
        if (period.type.contains('TEMPO')) {
          color = Colors.orange;
          label = period.type; // Use the full period type instead of hardcoded 'TEMPO'
        } else if (period.type.contains('INTER')) {
          color = Colors.purple;
          label = period.type; // Use the full period type instead of hardcoded 'INTER'
        } else if (period.type.contains('PROB30')) {
          color = Colors.orange;
          label = period.type; // Use the full period type instead of hardcoded 'PROB30'
        } else if (period.type.contains('PROB40')) {
          color = Colors.orange;
          label = period.type; // Use the full period type instead of hardcoded 'PROB40'
        } else {
          color = Colors.purple;
          label = period.type;
        }
        
        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTafCompactDetails(
    DecodedForecastPeriod baseline, 
    Map<String, String> completeWeather, 
    List<DecodedForecastPeriod> concurrentPeriods
  ) {
    return Column(
      children: [
        // Baseline weather with integrated TEMPO/INTER
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Wind', completeWeather['Wind'], concurrentPeriods, 'Wind'),
              SizedBox(width: 16),
              _buildGridItemWithConcurrent('Visibility', completeWeather['Visibility'], concurrentPeriods, 'Visibility'),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Weather', completeWeather['Weather'], concurrentPeriods, 'Weather', isPhenomenaOrRemark: true),
              SizedBox(width: 16),
              _buildGridItemWithConcurrent('Cloud', completeWeather['Cloud'], concurrentPeriods, 'Cloud'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItemWithConcurrent(
    String label, 
    String? value, 
    List<DecodedForecastPeriod> concurrentPeriods, 
    String weatherType, 
    {bool isPhenomenaOrRemark = false}
  ) {
    String displayValue = value ?? '-';
    if (isPhenomenaOrRemark) {
      if (value == null || value.isEmpty || value == 'No significant weather') {
        displayValue = '-';
      }
    } else {
      if (value == null || value.isEmpty || value.contains('unavailable') || value.contains('No cloud information')) {
        displayValue = '-'; // Show - instead of N/A to match weather heading
      }
    }
    
    // Find concurrent periods that have changes for this weather type
    final relevantConcurrentPeriods = concurrentPeriods.where((period) => 
      period.changedElements.contains(weatherType)
    ).toList();
    
    // Memoize concurrent period widgets to prevent unnecessary rebuilds
    final concurrentWidgets = relevantConcurrentPeriods.map((period) {
      final color = period.type.contains('TEMPO') ? Colors.orange : Colors.purple;
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
                fontSize: 12,
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