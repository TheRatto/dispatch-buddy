import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/weather.dart';
import '../providers/flight_provider.dart';

class AtisCard extends StatefulWidget {
  final Weather? atis;
  final String icao;

  const AtisCard({super.key, required this.atis, required this.icao});

  @override
  State<AtisCard> createState() => _AtisCardState();
}

class _AtisCardState extends State<AtisCard> {
  Timer? _ageUpdateTimer;
  String _ageText = '';
  Color _ageColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _updateAgeText();
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateAgeText());
  }

  @override
  void didUpdateWidget(covariant AtisCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icao != widget.icao || oldWidget.atis?.rawText != widget.atis?.rawText) {
      _updateAgeText();
    }
  }

  @override
  void dispose() {
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateAgeText() {
    final atis = widget.atis;
    if (!mounted || atis == null) return;

    final timeMatch = RegExp(r'ATIS\s+\w{4}\s+[A-Z]\s*(\d{6})').firstMatch(atis.rawText);
    if (timeMatch == null) {
      setState(() {
        _ageText = '';
        _ageColor = Colors.grey;
      });
      return;
    }

    final digits = timeMatch.group(1)!;
    final day = int.parse(digits.substring(0, 2));
    final hour = int.parse(digits.substring(2, 4));
    final minute = int.parse(digits.substring(4, 6));

    final now = DateTime.now().toUtc();
    DateTime issueTime = DateTime.utc(now.year, now.month, day, hour, minute);
    if (issueTime.isAfter(now)) {
      if (day > now.day + 7) {
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        issueTime = DateTime.utc(prevYear, prevMonth, day, hour, minute);
      } else {
        final y = now.subtract(const Duration(days: 1));
        issueTime = DateTime.utc(y.year, y.month, day, hour, minute);
      }
    }

    final diff = now.difference(issueTime);
    String text;
    if (diff.inMinutes < 1) {
      text = 'Just now';
    } else if (diff.inMinutes < 60) {
      text = '${diff.inMinutes} mins old';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      text = m == 0 ? '$h hrs old' : '$h:${m.toString().padLeft(2, '0')} hrs old';
    } else {
      text = '${diff.inDays} days old';
    }

    final color = diff.inMinutes <= 30
        ? const Color(0xFF059669)
        : (diff.inMinutes <= 60 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    setState(() {
      _ageText = text;
      _ageColor = color;
    });
  }

  String _buildHeaderText(Weather atis, String? localTimeText) {
    final timeMatch = RegExp(r'ATIS\s+\w{4}\s+[A-Z]\s*(\d{2})(\d{2})(\d{2})').firstMatch(atis.rawText);
    if (timeMatch != null) {
      final hh = timeMatch.group(2)!;
      final mm = timeMatch.group(3)!;
      return '${atis.icao} ATIS ${hh}${mm}Z$localTimeText';
    }
    return '${atis.icao} ATIS';
  }

  String? _getLocalTimeText(Weather atis) {
    final timeMatch = RegExp(r'ATIS\s+\w{4}\s+[A-Z]\s*(\d{2})(\d{2})(\d{2})').firstMatch(atis.rawText);
    if (timeMatch == null) return null;
    
    final day = int.parse(timeMatch.group(1)!);
    final hour = int.parse(timeMatch.group(2)!);
    final minute = int.parse(timeMatch.group(3)!);
    
    final now = DateTime.now().toUtc();
    final utcTime = DateTime.utc(now.year, now.month, day, hour, minute);
    
    // Get timezone from FlightProvider
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    if (flightProvider.airportTimezones.containsKey(atis.icao)) {
      try {
        final timezoneString = flightProvider.airportTimezones[atis.icao];
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
        debugPrint('DEBUG: AtisCard - Timezone conversion failed: $e');
        return null;
      }
    }
    return null;
  }

  String _formatAtisText(String rawText) {
    // Split the raw text into lines
    final lines = rawText.trim().split('\n');
    if (lines.isEmpty) return rawText;
    
    final formattedLines = <String>[];
    
    // Process each line
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // First line should be the header (ATIS ICAO LETTER DDHHMM...)
      if (i == 0) {
        // Check if this is a proper ATIS header
        final headerMatch = RegExp(r'^ATIS\s+\w{4}\s+[A-Z]\s+(\d{6})').firstMatch(line);
        if (headerMatch != null) {
          // This is a proper ATIS header - add it and then add a new line (not blank)
          formattedLines.add(line);
          // Don't add blank line - just continue to next line
          continue;
        }
      }
      
      // For all other lines, add consistent indentation
      // Remove any existing inconsistent indentation and add standard 2-space indent
      final cleanLine = line.replaceFirst(RegExp(r'^\s*'), '');
      formattedLines.add('  $cleanLine'); // 2-space indentation
    }
    
    // Post-process to connect fragmented sentences
    return _connectFragmentedLines(formattedLines.join('\n'));
  }

  String _connectFragmentedLines(String text) {
    final lines = text.split('\n');
    final connectedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final currentLine = lines[i];
      
      // Skip empty lines
      if (currentLine.trim().isEmpty) {
        connectedLines.add(currentLine);
        continue;
      }
      
      // Check if this line should be connected to the next line
      if (i < lines.length - 1) {
        final nextLine = lines[i + 1];
        
        // Don't connect if next line is empty
        if (nextLine.trim().isEmpty) {
          connectedLines.add(currentLine);
          continue;
        }
        
        // Check for common fragmentation patterns
        final shouldConnect = _shouldConnectLines(currentLine, nextLine);
        
        if (shouldConnect) {
          // Connect the lines with a space
          final connectedLine = '$currentLine ${nextLine.trim()}';
          connectedLines.add(connectedLine);
          i++; // Skip the next line since we've connected it
        } else {
          connectedLines.add(currentLine);
        }
      } else {
        connectedLines.add(currentLine);
      }
    }
    
    return connectedLines.join('\n');
  }

  bool _shouldConnectLines(String currentLine, String nextLine) {
    final currentTrimmed = currentLine.trim();
    final nextTrimmed = nextLine.trim();
    
    // Don't connect if next line starts with certain prefixes that should be separate
    final separatePrefixes = ['RWY:', 'WIND:', 'WND:', 'VIS:', 'WX:', 'CLD:', 'TMP:', 'QNH:', 'SIGWX:', '+'];
    for (final prefix in separatePrefixes) {
      if (nextTrimmed.startsWith(prefix)) {
        return false;
      }
    }
    
    // Connect if current line ends with common continuation words
    final continuationWords = ['AND', 'IN', 'ON', 'FOR', 'TO', 'OF', 'AT', 'FROM', 'WITH'];
    for (final word in continuationWords) {
      if (currentTrimmed.endsWith(word)) {
        return true;
      }
    }
    
    // Connect if current line ends with punctuation that suggests continuation
    if (currentTrimmed.endsWith(',') || currentTrimmed.endsWith(':')) {
      return true;
    }
    
    // Connect if next line is very short (likely a continuation)
    if (nextTrimmed.length < 20 && !nextTrimmed.contains(':')) {
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final atis = widget.atis;
    if (atis == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              _buildHeaderText(atis, _getLocalTimeText(atis)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              _ageText,
              style: TextStyle(fontSize: 14, color: _ageColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _formatAtisText(atis.rawText),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}


