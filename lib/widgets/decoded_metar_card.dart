import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import 'metar_compact_details.dart';

class DecodedMetarCard extends StatelessWidget {
  final Weather metar;
  final String icao;

  const DecodedMetarCard({
    super.key,
    required this.metar,
    required this.icao,
  });

  String _buildHeaderText(Weather metar, BuildContext context) {
    final timeStr = metar.timestamp.toString().substring(11, 16);
    final localTimeText = _getLocalTimeText(metar, context);
    return '${metar.icao} METAR ${timeStr}Z$localTimeText';
  }

  String? _getLocalTimeText(Weather metar, BuildContext context) {
    final utcTime = metar.timestamp;
    
    // Get timezone from FlightProvider
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    if (flightProvider.airportTimezones.containsKey(metar.icao)) {
      try {
        final timezoneString = flightProvider.airportTimezones[metar.icao];
        final location = tz.getLocation(timezoneString!);
        
        // Create a TZDateTime in the target timezone to get the offset
        final tempTZDateTime = tz.TZDateTime.from(utcTime, location);
        final offset = tempTZDateTime.timeZoneOffset;
        
        // Manually calculate local time by adding the offset
        final localTime = utcTime.add(offset);
        
        // Format the local time manually
        final formattedTime = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
        
        return ' / $formattedTime';
      } catch (e) {
        debugPrint('DEBUG: DecodedMetarCard - Timezone conversion failed: $e');
        return null;
      }
    }
    return null;
  }

  String _formatMetarAge(Weather metar) {
    final now = DateTime.now();
    final metarTime = metar.timestamp;
    final difference = now.difference(metarTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins old';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs old';
    } else {
      return '${difference.inDays} days old';
    }
  }

  Color _getMetarAgeColor(Weather metar) {
    final now = DateTime.now();
    final metarTime = metar.timestamp;
    final difference = now.difference(metarTime);
    
    if (difference.inMinutes < 30) {
      return Colors.green;
    } else if (difference.inMinutes < 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: DecodedMetarCard build for $icao');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with METAR time - matching ATIS style exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              _buildHeaderText(metar, context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 0.5),
          // Age indicator - matching ATIS spacing and color exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              _formatMetarAge(metar),
              style: TextStyle(
                fontSize: 14,
                color: _getMetarAgeColor(metar),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Decoded compact grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: MetarCompactDetails(metar: metar),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
