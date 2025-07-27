import 'package:flutter/material.dart';
import 'dart:async';
import '../models/weather.dart';
import 'grid_item.dart';

class MetarCompactDetails extends StatefulWidget {
  final Weather metar;

  const MetarCompactDetails({
    super.key,
    required this.metar,
  });

  @override
  State<MetarCompactDetails> createState() => _MetarCompactDetailsState();
}

class _MetarCompactDetailsState extends State<MetarCompactDetails> {
  Timer? _ageUpdateTimer;
  String _ageText = '';

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: MetarCompactDetails initState for ${widget.metar.icao}');
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
    if (!mounted) return;
    
    // Extract issue time from METAR raw text
    final issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z').firstMatch(widget.metar.rawText);
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
    
    // Try current month first
    issueTime = DateTime.utc(now.year, now.month, day, hour, minute);
    
    // If the calculated age is more than 24 hours, the METAR might be from the previous month
    final age = now.difference(issueTime);
    if (age.inHours > 24) {
      // Try previous month
      final previousMonth = now.month == 1 ? 12 : now.month - 1;
      final previousYear = now.month == 1 ? now.year - 1 : now.year;
      issueTime = DateTime.utc(previousYear, previousMonth, day, hour, minute);
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
    debugPrint('DEBUG: MetarCompactDetails age calculation for ${widget.metar.icao}:');
    debugPrint('DEBUG:   Raw text: ${widget.metar.rawText}');
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
    if (widget.metar.decodedWeather == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No decoded data available.'),
      );
    }

    final decoded = widget.metar.decodedWeather!;
    final isCavok = widget.metar.rawText.contains('CAVOK');
    
    String? temp, dewPoint;
    if (decoded.temperatureDescription.isNotEmpty && !decoded.temperatureDescription.contains('unavailable')) {
        var parts = decoded.temperatureDescription.split(',');
        temp = parts[0].replaceAll('Temperature ', '');
        if (parts.length > 1) {
            dewPoint = parts[1].replaceAll(' Dew point ', '');
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Age indicator in top left
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
        // Weather grid
        Row(
          children: [
            Expanded(
              child: GridItem(
                label: 'Wind',
                value: decoded.windDescription,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Visibility',
                value: decoded.visibilityDescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GridItem(
                label: 'Weather',
                value: decoded.conditionsDescription,
                isPhenomenaOrRemark: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Cloud',
                value: decoded.cloudDescription,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GridItem(
                label: 'Temp / Dew Point',
                value: decoded.temperatureDescription,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridItem(
                label: 'Remarks',
                value: decoded.remarks?.isNotEmpty == true ? decoded.remarks! : '-',
                isPhenomenaOrRemark: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 