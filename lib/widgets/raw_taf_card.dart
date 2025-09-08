import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/decoded_weather_models.dart';
import '../models/weather.dart';
import '../services/decoder_service.dart';
import '../constants/weather_colors.dart';


/// Raw TAF Card Widget
/// 
/// Displays raw TAF text with period highlighting:
/// - Formatted TAF text display
/// - Period-based highlighting (baseline and concurrent)
/// - Scrollable text with monospace font
/// - Scroll indicator when content overflows
/// - Exact styling preserved from original implementation
class RawTafCard extends StatefulWidget {
  final Weather taf;
  final Map<String, dynamic>? activePeriods;

  const RawTafCard({
    super.key,
    required this.taf,
    this.activePeriods,
  });

  @override
  State<RawTafCard> createState() => _RawTafCardState();
}

class _RawTafCardState extends State<RawTafCard> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollable = false;
  Timer? _ageUpdateTimer;
  String _ageText = '';

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: RawTafCard initState for ${widget.taf.icao}');
    _scrollController.addListener(_onScroll);
    _updateAgeText();
    // Update age every minute
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateAgeText();
    });
    // Check if content is scrollable after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateAgeText() {
    if (!mounted) return;
    
    // Extract issue time from TAF raw text
    final issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z').firstMatch(widget.taf.rawText);
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
    debugPrint('DEBUG: RawTafCard age calculation for ${widget.taf.icao}:');
    debugPrint('DEBUG:   Raw text: ${widget.taf.rawText}');
    debugPrint('DEBUG:   Issue time: $issueTime');
    debugPrint('DEBUG:   Current time: $now');
    debugPrint('DEBUG:   Age: $finalAge');
    debugPrint('DEBUG:   Age text: $ageText');
    
    setState(() {
      _ageText = ageText;
    });
  }

  void _onScroll() {
    // Keep track of scroll position if needed
  }

  void _checkIfScrollable() {
    if (!_scrollController.hasClients) return;
    
    final position = _scrollController.position;
    final maxScrollExtent = position.maxScrollExtent;
    final viewportDimension = position.viewportDimension;
    final contentHeight = position.maxScrollExtent + viewportDimension;
    
    // Content is scrollable if maxScrollExtent > 0 OR if content height > viewport height
    final isScrollable = maxScrollExtent > 0 || contentHeight > viewportDimension;
    
    debugPrint('DEBUG: Raw TAF scroll check - maxScrollExtent: $maxScrollExtent, viewportDimension: $viewportDimension, contentHeight: $contentHeight, isScrollable: $isScrollable, current: $_isScrollable');
    
    if (_isScrollable != isScrollable) {
      debugPrint('DEBUG: Raw TAF scroll state changing from $_isScrollable to $isScrollable');
      setState(() {
        _isScrollable = isScrollable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: RawTafCard build for ${widget.taf.icao}');
    debugPrint('DEBUG: === RAW HIGHLIGHTING START ===');
    debugPrint('DEBUG: Raw highlighting - activePeriods: ${widget.activePeriods}');
    
    final originalRawText = widget.taf.rawText;
    final decoder = DecoderService();
    final formattedRawText = decoder.formatTafForDisplay(originalRawText);
    TextSpan textSpan;
    
    // Check scrollability after build when content changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
    
    if (widget.activePeriods != null) {
      debugPrint('DEBUG: Raw highlighting - Object ID: ${widget.activePeriods.hashCode}');
      
      // Use the same logic as decoded weather - get all active periods
      final baseline = widget.activePeriods!['baseline'] as DecodedForecastPeriod?;
      final concurrent = widget.activePeriods!['concurrent'] as List<DecodedForecastPeriod>;
      
      debugPrint('DEBUG: Raw highlighting - Baseline: ${baseline?.type}');
      debugPrint('DEBUG: Raw highlighting - Concurrent: ${concurrent.map((p) => p.type).toList()}');
      debugPrint('DEBUG: Raw highlighting - Concurrent length: ${concurrent.length}');
      
      // Simple highlighting based on period types
      textSpan = _buildSimpleHighlightedText(formattedRawText, baseline, concurrent);
    } else {
      // No active periods, show unformatted text
      textSpan = TextSpan(
        text: formattedRawText, 
        style: const TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 12)
      );
    }
    
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
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: SelectableText.rich(
                        textSpan,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  // Scroll indicator - only appears when content is scrollable
                  if (_isScrollable)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white,
                              size: 12,
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
            // Source indicator at the bottom
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  widget.taf.source == 'naips' ? Icons.security : Icons.cloud_sync,
                  size: 10,
                  color: widget.taf.source == 'naips' ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 2),
                Text(
                  // Ensure NAIPS label when source says naips
                  widget.taf.source == 'naips' ? 'NAIPS' : 'aviationweather.gov',
                  style: TextStyle(
                    fontSize: 8,
                    color: widget.taf.source == 'naips' ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  
  TextSpan _buildSimpleHighlightedText(String formattedText, DecodedForecastPeriod? baseline, List<DecodedForecastPeriod> concurrent) {
    debugPrint('DEBUG: Building simple highlighted text');
    debugPrint('DEBUG: Baseline: ${baseline?.type}');
    debugPrint('DEBUG: Concurrent: ${concurrent.map((p) => p.type).toList()}');
    
    // Simple approach: highlight lines that contain the active period types
    final lines = formattedText.split('\n');
    final children = <TextSpan>[];
    
    // Track if we're currently in a highlighted period to handle continuation lines
    bool inHighlightedPeriod = false;
    Color? currentHighlightColor;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      
      // Stop highlighting when RMK is encountered
      if (line.trim().startsWith('RMK')) {
        // Add RMK line without highlighting
        children.add(TextSpan(
          text: line + (isLastLine ? '' : '\n'),
          style: const TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 12)
        ));
        inHighlightedPeriod = false;
        currentHighlightColor = null;
        continue;
      }
      
      // Check if this line should be highlighted
      Color? highlightColor;
      
      // Check baseline period
      if (baseline != null) {
        if (baseline.type == 'INITIAL' && i == 0) {
          // First line is INITIAL - it contains the TAF validity range
          highlightColor = WeatherColors.initial;
          debugPrint('DEBUG: Highlighting INITIAL line: "$line"');
        } else if (baseline.type == 'FM' && line.startsWith('FM')) {
          // Check if this is the specific FM period that's active
          if (_matchesPeriodTime(line, baseline)) {
            highlightColor = WeatherColors.fm;
            debugPrint('DEBUG: Highlighting specific FM line: "$line" (time: ${baseline.time})');
          }
        } else if (baseline.type == 'POST_BECMG' && line.startsWith('BECMG')) {
          // Highlight the BECMG line that matches the POST_BECMG time window
          // Try multiple matching strategies
          bool matched = false;
          
          // Strategy 1: Direct replacement
          final postBecmgTime = baseline.time.replaceFirst('POST_BECMG ', 'BECMG ');
          debugPrint('DEBUG: POST_BECMG matching - baseline time: "${baseline.time}", postBecmgTime: "$postBecmgTime", line: "$line"');
          
          if (line.contains(postBecmgTime)) {
            matched = true;
            debugPrint('DEBUG: POST_BECMG matched with strategy 1');
          }
          
          // Strategy 2: Extract time from POST_BECMG and match BECMG line
          if (!matched) {
            final timeMatch = RegExp(r'POST_BECMG (\d{2}\d{2}/\d{2}\d{2})').firstMatch(baseline.time);
            if (timeMatch != null) {
              final timeString = timeMatch.group(1)!;
              if (line.contains('BECMG $timeString')) {
                matched = true;
                debugPrint('DEBUG: POST_BECMG matched with strategy 2 - time: $timeString');
              }
            }
          }
          
          // Strategy 3: Extract time from BECMG line and match POST_BECMG
          if (!matched) {
            final becmgTimeMatch = RegExp(r'BECMG (\d{2}\d{2}/\d{2}\d{2})').firstMatch(line);
            if (becmgTimeMatch != null) {
              final becmgTime = becmgTimeMatch.group(1)!;
              if (baseline.time.contains(becmgTime)) {
                matched = true;
                debugPrint('DEBUG: POST_BECMG matched with strategy 3 - BECMG time: $becmgTime');
              }
            }
          }
          
          if (matched) {
            highlightColor = WeatherColors.fm; // Use FM color for established conditions
            debugPrint('DEBUG: Highlighting BECMG line as POST_BECMG (now baseline): "$line" (time: ${baseline.time})');
          } else {
            debugPrint('DEBUG: POST_BECMG line NOT matched: "$line" does not match "${baseline.time}"');
          }
        }
      }
      
      // Check concurrent periods
      for (final period in concurrent) {
        bool shouldHighlight = false;
        
        if (period.type == 'BECMG' && line.startsWith('BECMG')) {
          // BECMG as concurrent (during transition) - highlight in purple
          if (_matchesBecmgPeriod(line, period)) {
            highlightColor = WeatherColors.becmg; // Purple for transition
            shouldHighlight = true;
            debugPrint('DEBUG: Highlighting BECMG transition line: "$line" (time: ${period.time}) - TRANSITION');
          }
        } else if (period.type.contains('TEMPO') && line.startsWith('TEMPO')) {
          // Check if this is the specific TEMPO period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            debugPrint('DEBUG: Highlighting specific TEMPO line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('INTER') && line.startsWith('INTER')) {
          // Check if this is the specific INTER period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            debugPrint('DEBUG: Highlighting specific INTER line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB30') && line.startsWith('PROB30')) {
          // Check if this is the specific PROB30 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            debugPrint('DEBUG: Highlighting specific PROB30 line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB40') && line.startsWith('PROB40')) {
          // Check if this is the specific PROB40 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            debugPrint('DEBUG: Highlighting specific PROB40 line: "$line" (time: ${period.time})');
          }
        }
        
        if (shouldHighlight) break; // Use first match
      }
      
      // Check if this line is a continuation of a highlighted period
      if (highlightColor == null && inHighlightedPeriod && currentHighlightColor != null) {
        // This line doesn't start a new period but we're in a highlighted period
        // Check if it's a continuation line (not empty and not starting with a period indicator)
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty && !trimmedLine.startsWith(RegExp(r'^(FM|TEMPO|BECMG|PROB30|PROB40|INTER|RMK|TAF3)'))) {
          highlightColor = currentHighlightColor;
          debugPrint('DEBUG: Highlighting continuation line: "$line"');
        }
      }
      
      // Update highlighting state
      if (highlightColor != null) {
        inHighlightedPeriod = true;
        currentHighlightColor = highlightColor;
      } else if (line.trim().startsWith(RegExp(r'^(FM|TEMPO|BECMG|PROB30|PROB40|INTER|RMK|TAF3)'))) {
        // This line starts a new period, reset highlighting state
        inHighlightedPeriod = false;
        currentHighlightColor = null;
      }
      
      // Add the line with or without highlighting
      children.add(TextSpan(
        text: line + (isLastLine ? '' : '\n'),
        style: TextStyle(
          color: highlightColor ?? Colors.black, 
          fontFamily: 'monospace', 
          fontSize: 12,
          // Only apply background highlighting for TEMPO, INTER, and PROB periods
          backgroundColor: _shouldApplyBackgroundHighlight(highlightColor, baseline, concurrent) ? highlightColor?.withValues(alpha: 0.2) : null,
        )
      ));
    }
    
    return TextSpan(children: children);
  }
  
  bool _matchesPeriodTime(String line, DecodedForecastPeriod period) {
    if (period.time.isEmpty) return false;
    
    debugPrint('DEBUG: Checking if line "$line" matches period time "${period.time}"');
    
    // Convert period time format to TAF text format
    // Period time might be "2608-2611" but TAF text has "2608/2611"
    final periodTimeFormatted = period.time.replaceAll('-', '/');
    
    // Check if the line contains the formatted time
    final matches = line.contains(periodTimeFormatted);
    debugPrint('DEBUG: Period time formatted: "$periodTimeFormatted", matches: $matches');
    
    return matches;
  }
  
  bool _matchesBecmgPeriod(String line, DecodedForecastPeriod period) {
    if (period.time.isEmpty) return false;
    
    debugPrint('DEBUG: Checking if line "$line" matches BECMG period time "${period.time}"');
    
    // Convert period time format to TAF text format
    // Period time might be "2608-2611" but TAF text has "2608/2611"
    final periodTimeFormatted = period.time.replaceAll('-', '/');
    
    // Check if the line contains the formatted time
    final matches = line.contains(periodTimeFormatted);
    debugPrint('DEBUG: BECMG period time formatted: "$periodTimeFormatted", matches: $matches');
    
    return matches;
  }
  


  bool _shouldApplyBackgroundHighlight(Color? highlightColor, DecodedForecastPeriod? baseline, List<DecodedForecastPeriod> concurrent) {
    if (highlightColor == null) return false;
    
    // Check if the highlight color is for TEMPO, INTER, or PROB periods (these get background highlighting)
    if (highlightColor == Colors.orange ||
        highlightColor == Colors.purple) {
      return true;
    }
    
    // Check if the highlight color is for baseline periods (these get text color only, no background)
    if (baseline != null) {
      if (baseline.type == 'INITIAL' ||
          baseline.type == 'FM' ||
          baseline.type == 'BECMG' ||
          baseline.type == 'POST_BECMG') {
        return false; // No background highlighting for these
      }
    }
    
    // Check if any concurrent period is for TEMPO, INTER, or PROB (these get background highlighting)
    for (final period in concurrent) {
      if (period.type.contains('TEMPO') ||
          period.type.contains('INTER') ||
          period.type.contains('PROB')) {
        return true;
      }
    }
    
    return false;
  }
} 