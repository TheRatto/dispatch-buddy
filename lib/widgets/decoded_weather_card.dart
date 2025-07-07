import 'package:flutter/material.dart';
import '../models/decoded_weather_models.dart';
import '../services/taf_state_manager.dart';
import '../constants/weather_colors.dart';

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
  final TafStateManager? tafStateManager;
  final String? airport;
  final double? sliderValue;
  final List<DecodedForecastPeriod>? allPeriods;

  const DecodedWeatherCard({
    super.key,
    required this.baseline,
    required this.completeWeather,
    required this.concurrentPeriods,
    this.tafStateManager,
    this.airport,
    this.sliderValue,
    this.allPeriods,
  });

  @override
  Widget build(BuildContext context) {
    // Return the card with period information for highlighting
    return _buildDecodedCard(baseline, completeWeather, concurrentPeriods);
  }

  Widget _buildEmptyDecodedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decoded TAF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
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

  Widget _buildDecodedCard(
    DecodedForecastPeriod baseline, 
    Map<String, String> completeWeather, 
    List<DecodedForecastPeriod> concurrentPeriods
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 290,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Decoded TAF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (concurrentPeriods.isNotEmpty) _buildConcurrentKeyWithBecmg(concurrentPeriods, baseline),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Wind/Visibility row (dynamic height)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGridItemWithConcurrent('Wind', completeWeather['Wind'], concurrentPeriods, 'Wind'),
                        const SizedBox(width: 16),
                        _buildGridItemWithConcurrent('Visibility', completeWeather['Visibility'], concurrentPeriods, 'Visibility'),
                      ],
                    ),
                    // Minimum spacing between sections
                    const SizedBox(height: 16),
                    // Weather/Cloud row (dynamic height)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGridItemWithConcurrent('Weather', completeWeather['Weather'], concurrentPeriods, 'Weather'),
                        const SizedBox(width: 16),
                        _buildGridItemWithConcurrent('Cloud', completeWeather['Cloud'], concurrentPeriods, 'Cloud'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConcurrentKey(List<DecodedForecastPeriod> concurrentPeriods) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: concurrentPeriods.map((period) {
        Color color = WeatherColors.getColorForProbCombination(period.type);
        String label = period.type;
        
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

  Widget _buildConcurrentKeyWithBecmg(List<DecodedForecastPeriod> concurrentPeriods, DecodedForecastPeriod? baseline) {
    final children = <Widget>[];
    
    // Add concurrent period keys
    for (final period in concurrentPeriods) {
      Color color = WeatherColors.getColorForProbCombination(period.type);
      String label = period.type;
      
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }
    
    // Add BECMG key if baseline is BECMG and we're in transition period
    if (baseline?.type == 'BECMG' && _isInBecmgTransition(baseline!)) {
      children.add(
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: Text(
            'BECMG',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: WeatherColors.becmg,
            ),
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// Check if we're currently in the BECMG transition period
  bool _isInBecmgTransition(DecodedForecastPeriod becmgPeriod) {
    if (becmgPeriod.type != 'BECMG' || becmgPeriod.startTime == null || becmgPeriod.endTime == null) {
      return false;
    }
    
    // Parse the transition time from the period time string
    final timeMatch = RegExp(r'(\d{2})(\d{2})/(\d{2})(\d{2})').firstMatch(becmgPeriod.time);
    if (timeMatch == null) return false;
    
    final fromDay = int.parse(timeMatch.group(1)!);
    final fromHour = int.parse(timeMatch.group(2)!);
    final toDay = int.parse(timeMatch.group(3)!);
    final toHour = int.parse(timeMatch.group(4)!);
    
    final transitionStart = DateTime(DateTime.now().year, DateTime.now().month, fromDay, fromHour, 0);
    final transitionEnd = DateTime(DateTime.now().year, DateTime.now().month, toDay, toHour, 0);
    
    // Use the slider time if available, otherwise use current time
    final currentTime = sliderValue != null && allPeriods != null 
        ? _getCurrentTimeFromSlider()
        : DateTime.now();
    
    final isInTransition = currentTime.isAfter(transitionStart) && currentTime.isBefore(transitionEnd);
    
    print('DEBUG: BECMG transition check for ${becmgPeriod.time}:');
    print('DEBUG:   Transition start: $transitionStart');
    print('DEBUG:   Transition end: $transitionEnd');
    print('DEBUG:   Current time: $currentTime');
    print('DEBUG:   Is in transition: $isInTransition');
    
    return isInTransition;
  }

  /// Get the current time based on slider value
  DateTime _getCurrentTimeFromSlider() {
    if (sliderValue == null || allPeriods == null || allPeriods!.isEmpty) {
      return DateTime.now();
    }
    
    // Find the timeline from the periods
    final timeline = <DateTime>[];
    for (final period in allPeriods!) {
      if (period.startTime != null) {
        timeline.add(period.startTime!);
      }
      if (period.endTime != null) {
        timeline.add(period.endTime!);
      }
    }
    
    if (timeline.isEmpty) {
      return DateTime.now();
    }
    
    // Sort and deduplicate timeline
    timeline.sort();
    final uniqueTimeline = timeline.toSet().toList()..sort();
    
    // Calculate current time based on slider position
    final index = (sliderValue! * (uniqueTimeline.length - 1)).round();
    return uniqueTimeline[index.clamp(0, uniqueTimeline.length - 1)];
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
          height: 94,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Wind', completeWeather['Wind'], concurrentPeriods, 'Wind'),
              const SizedBox(width: 16),
              _buildGridItemWithConcurrent('Visibility', completeWeather['Visibility'], concurrentPeriods, 'Visibility'),
            ],
          ),
        ),
        SizedBox(
          height: 94,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridItemWithConcurrent('Weather', completeWeather['Weather'], concurrentPeriods, 'Weather', isPhenomenaOrRemark: true),
              const SizedBox(width: 16),
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
    
    // Check if this value should be colored due to BECMG transition
    Color? valueColor;
    if (baseline.type == 'BECMG' && _isInBecmgTransition(baseline)) {
      // Check if this weather type is changing in the BECMG period
      if (baseline.changedElements.contains(weatherType)) {
        valueColor = WeatherColors.becmg;
      }
    }
    
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
            const SizedBox(height: 1),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor,
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