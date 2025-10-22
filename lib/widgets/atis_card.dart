import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather.dart';

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

  String _buildHeaderText(Weather atis) {
    final letterMatch = RegExp(r'ATIS\s+\w{4}\s+([A-Z])').firstMatch(atis.rawText);
    final timeMatch = RegExp(r'ATIS\s+\w{4}\s+[A-Z]\s*(\d{2})(\d{2})(\d{2})').firstMatch(atis.rawText);
    if (letterMatch != null && timeMatch != null) {
      final letter = letterMatch.group(1)!;
      final hh = timeMatch.group(2)!;
      final mm = timeMatch.group(3)!;
      return '${atis.icao} ATIS $letter ${hh}${mm}Z';
    }
    return '${atis.icao} ATIS';
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.radio, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildHeaderText(atis),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              _ageText,
              style: TextStyle(fontSize: 12, color: _ageColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              atis.rawText.trim(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}


