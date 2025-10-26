import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../providers/flight_provider.dart';
import 'package:provider/provider.dart';

/// TAF Time Slider Widget
/// 
/// Displays a timeline slider for TAF navigation:
/// - Slider with timeline divisions
/// - Current time display in 24-hour format
/// - Empty state handling
/// - Exact styling preserved from original implementation
class TafTimeSlider extends StatelessWidget {
  final List<DateTime> timeline;
  final double sliderValue;
  final ValueChanged<double> onChanged;
  final String? airportIcao; // Add airport parameter for timezone lookup

  const TafTimeSlider({
    super.key,
    required this.timeline,
    required this.sliderValue,
    required this.onChanged,
    this.airportIcao, // Optional airport ICAO for local time display
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return _buildEmptyTimeSlider();
    }
    
    return _buildTimeSliderFromTimeline(timeline, sliderValue, onChanged);
  }

  Widget _buildEmptyTimeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Slider',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  'No forecast periods available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSliderFromTimeline(List<DateTime> timeline, double sliderValue, ValueChanged<double> onChanged) {
    final currentTime = timeline[(sliderValue * (timeline.length - 1)).round()];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time display above slider
            _buildTimeDisplay(currentTime),
            const SizedBox(height: 6),
            // Slider
            Slider(
              value: sliderValue,
              min: 0.0,
              max: 1.0,
              divisions: timeline.length > 1 ? (timeline.length - 1) : 1,
              onChanged: onChanged,
              activeColor: const Color(0xFF14B8A6),
            ),
          ],
        ),
      ),
    );
  }

  /// Build time display with UTC and local time
  Widget _buildTimeDisplay(DateTime utcTime) {
    return Consumer<FlightProvider>(
      builder: (context, flightProvider, child) {
        String localTimeText = '';
        
        debugPrint('DEBUG: TafTimeSlider - _buildTimeDisplay called for $airportIcao');
        debugPrint('DEBUG: TafTimeSlider - Available timezones: ${flightProvider.airportTimezones.keys.toList()}');
        debugPrint('DEBUG: TafTimeSlider - Has timezone for $airportIcao: ${flightProvider.airportTimezones.containsKey(airportIcao)}');
        
        // Get pre-fetched timezone data from FlightProvider
        if (airportIcao != null && flightProvider.airportTimezones.containsKey(airportIcao)) {
          try {
            final timezoneString = flightProvider.airportTimezones[airportIcao!];
            final location = tz.getLocation(timezoneString!);
            
            // Create a TZDateTime in the target timezone to get the offset
            final tempTZDateTime = tz.TZDateTime.from(utcTime, location);
            final offset = tempTZDateTime.timeZoneOffset;
            
            // Manually calculate local time by adding the offset
            final localTime = utcTime.add(offset);
            
            // Debug the conversion process
            debugPrint('DEBUG: TafTimeSlider - Airport: $airportIcao, Timezone: $timezoneString');
            debugPrint('DEBUG: TafTimeSlider - Input UTC: ${utcTime.toIso8601String()}');
            debugPrint('DEBUG: TafTimeSlider - Timezone Offset: $offset');
            debugPrint('DEBUG: TafTimeSlider - Converted Local: ${localTime.toIso8601String()}');
            debugPrint('DEBUG: TafTimeSlider - Local Hour: ${localTime.hour}');
            debugPrint('DEBUG: TafTimeSlider - UTC Hour: ${utcTime.hour}');
            
            // Format the local time manually
            final formattedTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
            
            debugPrint('DEBUG: TafTimeSlider - Manual format result: $formattedTime');
            
            // Use the manual formatting
            localTimeText = ' / $formattedTime';
            
            debugPrint('DEBUG: TafTimeSlider - UTC: ${DateFormat('dd HH:mm').format(utcTime)}Z, Local: $formattedTime');
          } catch (e) {
            // If timezone conversion fails, just show UTC
            debugPrint('DEBUG: TafTimeSlider - Timezone conversion failed: $e');
            localTimeText = '';
          }
        } else {
          debugPrint('DEBUG: TafTimeSlider - No pre-fetched timezone data for $airportIcao');
        }
        
        return Text(
          '${DateFormat('dd HH:mm').format(utcTime)}Z$localTimeText',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        );
      },
    );
  }
} 