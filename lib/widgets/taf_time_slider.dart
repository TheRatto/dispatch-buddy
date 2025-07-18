import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  const TafTimeSlider({
    super.key,
    required this.timeline,
    required this.sliderValue,
    required this.onChanged,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              value: sliderValue,
              min: 0.0,
              max: 1.0,
              divisions: timeline.length > 1 ? (timeline.length - 1) : 1,
              onChanged: onChanged,
              activeColor: const Color(0xFF14B8A6),
            ),
            // Show current time instead of all labels
            Text(
              '${DateFormat('dd HH:mm').format(timeline[(sliderValue * (timeline.length - 1)).round()])} Z',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
} 