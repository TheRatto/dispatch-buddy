import 'package:flutter/material.dart';

class FlightPlanFormCard extends StatelessWidget {
  final TextEditingController routeController;
  final TextEditingController flightLevelController;
  final DateTime selectedDateTime;
  final bool isZuluTime;
  final VoidCallback onTimeFormatChanged;
  final VoidCallback onDateTimeTap;
  final String Function(String?)? routeValidator;
  final String Function(String?)? flightLevelValidator;

  const FlightPlanFormCard({
    super.key,
    required this.routeController,
    required this.flightLevelController,
    required this.selectedDateTime,
    required this.isZuluTime,
    required this.onTimeFormatChanged,
    required this.onDateTimeTap,
    this.routeValidator,
    this.flightLevelValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flight Plan Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: routeController,
              decoration: const InputDecoration(
                labelText: 'Route',
                hintText: 'e.g., YPPH YSSY',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.route),
              ),
              validator: routeValidator ?? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a route';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Local/Zulu Time Toggle
            Row(
              children: [
                const Text(
                  'Time Format:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton('Local', !isZuluTime, () {
                        onTimeFormatChanged();
                      }),
                      _buildToggleButton('Zulu', isZuluTime, () {
                        onTimeFormatChanged();
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ETD Date/Time Picker
            InkWell(
              onTap: onDateTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ETD',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(selectedDateTime),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isZuluTime) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Local: ${_formatLocalTime(selectedDateTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text(
                              'Zulu: ${_formatZuluTime(selectedDateTime)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: flightLevelController,
              decoration: const InputDecoration(
                labelText: 'Flight Level',
                hintText: 'e.g., FL350',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flight),
              ),
              validator: flightLevelValidator ?? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter flight level';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    if (isZuluTime) {
      return _formatZuluTime(dateTime);
    } else {
      return _formatLocalTime(dateTime);
    }
  }

  String _formatLocalTime(DateTime dateTime) {
    final date = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time (Local)';
  }

  String _formatZuluTime(DateTime dateTime) {
    // Convert to UTC (Zulu time)
    final utcTime = dateTime.toUtc();
    final date = '${utcTime.day.toString().padLeft(2, '0')}/${utcTime.month.toString().padLeft(2, '0')}/${utcTime.year}';
    final time = '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')}';
    return '$date at ${time}Z';
  }
} 