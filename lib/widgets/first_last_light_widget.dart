import 'package:flutter/material.dart';
import '../models/first_last_light.dart';

class FirstLastLightWidget extends StatelessWidget {
  final FirstLastLight? firstLastLight;
  final bool isLoading;

  const FirstLastLightWidget({
    Key? key,
    this.firstLastLight,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            if (firstLastLight != null) ...[
              FutureBuilder<String>(
                future: firstLastLight!.getFirstLightLocal(),
                builder: (context, snapshot) {
                  final localTime = snapshot.data ?? firstLastLight!.firstLight;
                  return _buildLightRow(
                    context,
                    'First light',
                    localTime,
                    firstLastLight!.firstLight,
                    Icons.wb_sunny,
                  );
                },
              ),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: firstLastLight!.getLastLightLocal(),
                builder: (context, snapshot) {
                  final localTime = snapshot.data ?? firstLastLight!.lastLight;
                  return _buildLightRow(
                    context,
                    'Last light',
                    localTime,
                    firstLastLight!.lastLight,
                    Icons.nightlight_round,
                  );
                },
              ),
            ] else if (isLoading) ...[
              _buildLoadingRow(context, 'First light', Icons.wb_sunny),
              const SizedBox(height: 8),
              _buildLoadingRow(context, 'Last light', Icons.nightlight_round),
            ] else ...[
              Text(
                'First/last light data not available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLightRow(
    BuildContext context,
    String label,
    String localTime,
    String utcTime,
    IconData icon,
  ) {
    // Format local time to include colon (e.g., 1431 -> 14:31)
    final formattedLocalTime = _formatTimeWithColon(localTime);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: icon == Icons.wb_sunny ? Colors.orange[600] : Colors.indigo[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formattedLocalTime,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${utcTime}z)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatTimeWithColon(String time) {
    // Convert time like "1431" to "14:31"
    if (time.length == 4) {
      return '${time.substring(0, 2)}:${time.substring(2, 4)}';
    }
    return time;
  }

  Widget _buildLoadingRow(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: icon == Icons.wb_sunny ? Colors.orange[600] : Colors.indigo[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 30,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
