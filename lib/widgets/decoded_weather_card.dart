import 'package:flutter/material.dart';
import 'dart:async';
import '../models/decoded_weather_models.dart';
import '../services/taf_state_manager.dart';
import '../constants/weather_colors.dart';
import '../models/weather.dart';

/// Decoded Weather Card Widget
/// 
/// Displays decoded TAF weather information in a grid layout with:
/// - Wind, Visibility, Weather, Cloud sections
/// - Concurrent period highlighting (TEMPO/PROB)
/// - Color-coded concurrent weather display
/// - Exact styling preserved from original implementation
class DecodedWeatherCard extends StatefulWidget {
  final DecodedForecastPeriod baseline;
  final Map<String, String> completeWeather;
  final List<DecodedForecastPeriod> concurrentPeriods;
  final TafStateManager? tafStateManager;
  final String? airport;
  final double? sliderValue;
  final List<DecodedForecastPeriod>? allPeriods;
  final Weather? taf; // Add TAF for age calculation
  final List<DateTime>? timeline; // Add timeline parameter

  const DecodedWeatherCard({
    super.key,
    required this.baseline,
    required this.completeWeather,
    required this.concurrentPeriods,
    this.tafStateManager,
    this.airport,
    this.sliderValue,
    this.allPeriods,
    this.taf,
    this.timeline,
  });

  @override
  State<DecodedWeatherCard> createState() => _DecodedWeatherCardState();
}

class _DecodedWeatherCardState extends State<DecodedWeatherCard> {
  Timer? _ageUpdateTimer;
  String _ageText = '';

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: DecodedWeatherCard initState for ${widget.taf?.icao ?? 'no TAF'}');
    _updateAgeText();
    // Update age every minute
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAgeText();
    });
  }

  @override
  void dispose() {
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateAgeText() {
    if (!mounted || widget.taf == null) return;
    
    // Extract issue time from TAF raw text
    final issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z').firstMatch(widget.taf!.rawText);
    if (issueTimeMatch == null) {
      setState(() {
        _ageText = '';
      });
      return;
    }
    
    final day = int.parse(issueTimeMatch.group(1)!);
    final hour = int.parse(issueTimeMatch.group(2)!);
    final minute = int.parse(issueTimeMatch.group(3)!);
    
    // Create issue time with proper date handling
    final now = DateTime.now().toUtc();
    DateTime issueTime;
    
    // Try current day first
    issueTime = DateTime.utc(now.year, now.month, day, hour, minute);
    
    // If issue time is in the future, it must be from yesterday
    if (issueTime.isAfter(now)) {
      final yesterday = now.subtract(const Duration(days: 1));
      issueTime = DateTime.utc(yesterday.year, yesterday.month, day, hour, minute);
    }
    
    // Recalculate age with the correct date
    final finalAge = now.difference(issueTime);
    final hours = finalAge.inHours;
    final minutes = finalAge.inMinutes % 60;
    
    String ageText;
    if (hours > 0) {
      ageText = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} hrs old';
    } else {
      ageText = '${minutes.toString().padLeft(2, '0')} mins old';
    }
    
    // Debug logging
    debugPrint('DEBUG: DecodedWeatherCard age calculation for ${widget.taf!.icao}:');
    debugPrint('DEBUG:   Raw text: ${widget.taf!.rawText}');
    debugPrint('DEBUG:   Issue time: $issueTime');
    debugPrint('DEBUG:   Current time: $now');
    debugPrint('DEBUG:   Age: $finalAge');
    debugPrint('DEBUG:   Age text: $ageText');
    
    setState(() {
      _ageText = ageText;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: DecodedWeatherCard build for ${widget.taf?.icao ?? 'no TAF'}');
    // Return the card with period information for highlighting
    return _buildDecodedCard(widget.baseline, widget.completeWeather, widget.concurrentPeriods);
  }

  Widget _buildEmptyDecodedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with TAF age indicator in top left
            Row(
              children: [
                if (_ageText.isNotEmpty)
            Text(
                    _ageText,
              style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
              ),
            ),
                const Spacer(),
              ],
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
        maxHeight: 320, // Increased from 290 to allow more space for multiple lines
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
          child: Stack(
            children: [
              // Main scrollable content
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with TAF age indicator in top left
                    Row(
                      children: [
                        if (_ageText.isNotEmpty)
                        Text(
                            _ageText,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Time period indication
                    _buildTimePeriodIndicator(baseline),
                    const SizedBox(height: 12),
                    
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
                    
                    // Add bottom padding to prevent content from overlapping with fixed legend
                    if (concurrentPeriods.isNotEmpty) const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Fixed color legend at bottom (if there are concurrent periods)
              if (concurrentPeriods.isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: _buildConcurrentKeyWithBecmg(concurrentPeriods, baseline),
                ),
            ],
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
    final legendChildren = <Widget>[];
    
    // Add concurrent period keys
    for (final period in concurrentPeriods) {
      Color color = WeatherColors.getColorForProbCombination(period.type);
      String label = period.type;
      String periodInfo = _formatPeriodTime(period.time);
      
      legendChildren.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (periodInfo.isNotEmpty)
                Text(
                  periodInfo,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Add BECMG key if baseline is BECMG and we're in transition period
    if (baseline?.type == 'BECMG' && _isInBecmgTransition(baseline!)) {
      String becmgPeriodInfo = _formatPeriodTime(baseline.time);
      
      legendChildren.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: WeatherColors.becmg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: WeatherColors.becmg.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BECMG',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: WeatherColors.becmg,
                ),
              ),
              if (becmgPeriodInfo.isNotEmpty)
                Text(
                  becmgPeriodInfo,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                    color: WeatherColors.becmg.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Build concurrent period time indicators
    final timeIndicators = <Widget>[];
    for (final period in concurrentPeriods) {
      final timePeriodText = _formatTimePeriod(period);
      if (timePeriodText.isNotEmpty) {
        Color color = WeatherColors.getColorForProbCombination(period.type);
        
        timeIndicators.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16), // More pill-shaped
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '${period.type} $timePeriodText',
                style: TextStyle(
                  fontSize: 11, // Match the main time period indicator font size
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        );
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time period indicators only (legend badges removed as redundant)
        ...timeIndicators,
      ],
    );
  }

  /// Build time period indicator widget
  Widget _buildTimePeriodIndicator(DecodedForecastPeriod baseline) {
    final timePeriodText = _formatTimePeriod(baseline);
    
    if (timePeriodText.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16), // More pill-shaped
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          timePeriodText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  /// Format time period for display
  String _formatTimePeriod(DecodedForecastPeriod baseline) {
    if (baseline.startTime == null || baseline.endTime == null) {
      // Fallback to parsing from time string if startTime/endTime not available
      return _formatTimePeriodFromString(baseline.time, baseline.type);
    }
    
    // Format using DateTime objects
    final startTime = baseline.startTime!;
    final endTime = baseline.endTime!;
    
    final startDay = startTime.day.toString().padLeft(2, '0');
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endDay = endTime.day.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    
    return 'FROM $startDay ${startHour}${startMinute}Z TO $endDay ${endHour}${endMinute}Z';
  }

  /// Format time period from string (fallback method)
  String _formatTimePeriodFromString(String time, String type) {
    if (time.isEmpty) return '';
    
    // Handle different period formats
    // Examples: "FM1200", "TEMPO 1418", "INTER 2205/2208", "BECMG 2608/2611"
    
    String cleaned = time.replaceFirst(RegExp(r'^(FM|TEMPO|INTER|BECMG|PROB30|PROB40)\s*'), '').trim();
    
    if (cleaned.isEmpty) return '';
    
    // Handle time ranges (e.g., "2205/2208" -> "FROM 22 0500Z TO 22 0800Z")
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 2) {
        final start = parts[0];
        final end = parts[1];
        
        if (start.length >= 4 && end.length >= 4) {
          final startDay = start.substring(0, 2);
          final startTime = start.substring(2);
          final endDay = end.substring(0, 2);
          final endTime = end.substring(2);
          
          return 'FROM $startDay ${startTime}Z TO $endDay ${endTime}Z';
        }
      }
    }
    
    // Handle single times (e.g., "1200" -> "FROM 22 1200Z")
    if (cleaned.length == 4 && RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      final now = DateTime.now().toUtc();
      final day = now.day.toString().padLeft(2, '0');
      return 'FROM $day ${cleaned}Z';
    }
    
    return '';
  }

  /// Format period time for display in legend
  String _formatPeriodTime(String time) {
    if (time.isEmpty) return '';
    
    // Handle different period formats
    // Examples: "FM1200", "TEMPO 1418", "INTER 2205/2208", "BECMG 2608/2611"
    
    // Remove common prefixes and clean up
    String cleaned = time
        .replaceFirst(RegExp(r'^(FM|TEMPO|INTER|BECMG|PROB30|PROB40)\s*'), '')
        .trim();
    
    if (cleaned.isEmpty) return '';
    
    // Handle time ranges (e.g., "2205/2208" -> "05/08")
    if (cleaned.contains('/')) {
      final parts = cleaned.split('/');
      if (parts.length == 2) {
        final start = parts[0];
        final end = parts[1];
        
        // Extract day and time parts
        if (start.length >= 4 && end.length >= 4) {
          final startDay = start.substring(0, 2);
          final startTime = start.substring(2);
          final endDay = end.substring(0, 2);
          final endTime = end.substring(2);
          
          // If same day, show as "05/08"
          if (startDay == endDay) {
            return '$startTime/$endTime';
          } else {
            // Different days, show as "05/08"
            return '$startTime/$endTime';
          }
        }
      }
    }
    
    // Handle single times (e.g., "1200" -> "12:00")
    if (cleaned.length == 4 && RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      final hour = cleaned.substring(0, 2);
      final minute = cleaned.substring(2);
      return '$hour:$minute';
    }
    
    // Return cleaned version if we can't parse it
    return cleaned;
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
    final currentTime = widget.sliderValue != null && widget.allPeriods != null 
        ? _getCurrentTimeFromSlider()
        : DateTime.now();
    
    final isInTransition = currentTime.isAfter(transitionStart) && currentTime.isBefore(transitionEnd);
    
            debugPrint('DEBUG: BECMG transition check for ${becmgPeriod.time}:');
        debugPrint('DEBUG:   Transition start: $transitionStart');
        debugPrint('DEBUG:   Transition end: $transitionEnd');
        debugPrint('DEBUG:   Current time: $currentTime');
        debugPrint('DEBUG:   Is in transition: $isInTransition');
    
    return isInTransition;
  }

  /// Get the current time based on slider value
  DateTime _getCurrentTimeFromSlider() {
    if (widget.sliderValue == null) {
      return DateTime.now();
    }
    
    // Use the passed timeline if available, otherwise fall back to creating from periods
    List<DateTime> timeline;
    if (widget.timeline != null && widget.timeline!.isNotEmpty) {
      timeline = widget.timeline!;
    } else if (widget.allPeriods != null && widget.allPeriods!.isNotEmpty) {
      // Fallback: Find the timeline from the periods
      timeline = <DateTime>[];
      for (final period in widget.allPeriods!) {
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
      timeline = timeline.toSet().toList()..sort();
    } else {
      return DateTime.now();
    }
    
    // Calculate current time based on slider position
    final index = (widget.sliderValue! * (timeline.length - 1)).round();
    return timeline[index.clamp(0, timeline.length - 1)];
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
    if (widget.baseline.type == 'BECMG' && _isInBecmgTransition(widget.baseline)) {
      // Check if this weather type is changing in the BECMG period
      if (widget.baseline.changedElements.contains(weatherType)) {
        valueColor = WeatherColors.becmg;
      }
    }
    
    // Memoize concurrent period widgets to prevent unnecessary rebuilds
    final concurrentWidgets = relevantConcurrentPeriods.map((period) {
      final color = WeatherColors.getColorForProbCombination(period.type);
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
            fontSize: 12,
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