import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/decoder_service.dart';
import '../models/decoded_weather_models.dart';
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
    Key? key,
    required this.taf,
    this.activePeriods,
  }) : super(key: key);

  @override
  State<RawTafCard> createState() => _RawTafCardState();
}

class _RawTafCardState extends State<RawTafCard> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrollable = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check if content is scrollable after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
    
    print('DEBUG: Raw TAF scroll check - maxScrollExtent: $maxScrollExtent, viewportDimension: $viewportDimension, contentHeight: $contentHeight, isScrollable: $isScrollable, current: $_isScrollable');
    
    if (isScrollable != _isScrollable) {
      print('DEBUG: Raw TAF scroll state changing from $_isScrollable to $isScrollable');
      setState(() {
        _isScrollable = isScrollable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: === RAW HIGHLIGHTING START ===');
    print('DEBUG: Raw highlighting - activePeriods: ${widget.activePeriods}');
    
    final originalRawText = widget.taf.rawText;
    final decoder = DecoderService();
    final formattedRawText = decoder.formatTafForDisplay(originalRawText);
    TextSpan textSpan;
    
    // Check scrollability after build when content changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollable();
    });
    
    if (widget.activePeriods != null) {
      print('DEBUG: Raw highlighting - Object ID: ${widget.activePeriods.hashCode}');
      
      // Use the same logic as decoded weather - get all active periods
      final baseline = widget.activePeriods!['baseline'] as DecodedForecastPeriod?;
      final concurrent = widget.activePeriods!['concurrent'] as List<DecodedForecastPeriod>;
      
      print('DEBUG: Raw highlighting - Baseline: ${baseline?.type}');
      print('DEBUG: Raw highlighting - Concurrent: ${concurrent.map((p) => p.type).toList()}');
      print('DEBUG: Raw highlighting - Concurrent length: ${concurrent.length}');
      
      // Simple highlighting based on period types
      textSpan = _buildSimpleHighlightedText(formattedRawText, baseline, concurrent);
    } else {
      // No active periods, show unformatted text
      textSpan = TextSpan(
        text: formattedRawText, 
        style: TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 12)
      );
    }
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                                    child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText.rich(
                    textSpan,
                    style: TextStyle(
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
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
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
          ],
        ),
      ),
    );
  }
  
  TextSpan _buildSimpleHighlightedText(String formattedText, DecodedForecastPeriod? baseline, List<DecodedForecastPeriod> concurrent) {
    print('DEBUG: Building simple highlighted text');
    print('DEBUG: Baseline: ${baseline?.type}');
    print('DEBUG: Concurrent: ${concurrent.map((p) => p.type).toList()}');
    
    // Simple approach: highlight lines that contain the active period types
    final lines = formattedText.split('\n');
    final children = <TextSpan>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      
      // Stop highlighting when RMK is encountered
      if (line.trim().startsWith('RMK')) {
        // Add RMK line without highlighting
        children.add(TextSpan(
          text: line + (isLastLine ? '' : '\n'),
          style: TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 12)
        ));
        continue;
      }
      
      // Check if this line should be highlighted
      Color? highlightColor;
      
      // Check baseline period
      if (baseline != null) {
        if (baseline.type == 'INITIAL' && i == 0) {
          // First line is INITIAL - it contains the TAF validity range
          highlightColor = WeatherColors.initial;
          print('DEBUG: Highlighting INITIAL line: "$line"');
        } else if (baseline.type == 'FM' && line.startsWith('FM')) {
          // Check if this is the specific FM period that's active
          if (_matchesPeriodTime(line, baseline)) {
            highlightColor = WeatherColors.fm;
            print('DEBUG: Highlighting specific FM line: "$line" (time: ${baseline.time})');
          }
        } else if (baseline.type == 'BECMG' && line.startsWith('BECMG')) {
          // Check if this is the specific BECMG period that's active
          // BECMG is transitional - it persists until the next FM period
          if (_matchesBecmgPeriod(line, baseline)) {
            // Use indigo during transition period
            final isInTransition = _isInBecmgTransition(baseline);
            highlightColor = isInTransition ? WeatherColors.becmg : WeatherColors.fm;
            print('DEBUG: Highlighting specific BECMG line: "$line" (time: ${baseline.time}) - ${isInTransition ? "TRANSITION" : "ACTIVE"}');
          }
        }
      }
      
      // Check concurrent periods
      for (final period in concurrent) {
        bool shouldHighlight = false;
        
        if (period.type.contains('TEMPO') && line.startsWith('TEMPO')) {
          // Check if this is the specific TEMPO period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            print('DEBUG: Highlighting specific TEMPO line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('INTER') && line.startsWith('INTER')) {
          // Check if this is the specific INTER period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            print('DEBUG: Highlighting specific INTER line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB30') && line.startsWith('PROB30')) {
          // Check if this is the specific PROB30 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            print('DEBUG: Highlighting specific PROB30 line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB40') && line.startsWith('PROB40')) {
          // Check if this is the specific PROB40 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = WeatherColors.getColorForProbCombination(period.type);
            shouldHighlight = true;
            print('DEBUG: Highlighting specific PROB40 line: "$line" (time: ${period.time})');
          }
        }
        
        if (shouldHighlight) break; // Use first match
      }
      
      // Add the line with or without highlighting
      children.add(TextSpan(
        text: line + (isLastLine ? '' : '\n'),
        style: TextStyle(
          color: highlightColor ?? Colors.black, 
          fontFamily: 'monospace', 
          fontSize: 12,
          // Only apply background highlighting for TEMPO, INTER, and PROB periods
          backgroundColor: _shouldApplyBackgroundHighlight(highlightColor, baseline, concurrent) ? highlightColor?.withOpacity(0.2) : null,
        )
      ));
    }
    
    return TextSpan(children: children);
  }
  
  bool _matchesPeriodTime(String line, DecodedForecastPeriod period) {
    if (period.time.isEmpty) return false;
    
    print('DEBUG: Checking if line "$line" matches period time "${period.time}"');
    
    // Convert period time format to TAF text format
    // Period time might be "2608-2611" but TAF text has "2608/2611"
    final periodTimeFormatted = period.time.replaceAll('-', '/');
    
    // Check if the line contains the formatted time
    final matches = line.contains(periodTimeFormatted);
    print('DEBUG: Period time formatted: "$periodTimeFormatted", matches: $matches');
    
    return matches;
  }
  
  bool _matchesBecmgPeriod(String line, DecodedForecastPeriod period) {
    if (period.time.isEmpty) return false;
    
    print('DEBUG: Checking if line "$line" matches BECMG period time "${period.time}"');
    
    // Convert period time format to TAF text format
    // Period time might be "2608-2611" but TAF text has "2608/2611"
    final periodTimeFormatted = period.time.replaceAll('-', '/');
    
    // Check if the line contains the formatted time
    final matches = line.contains(periodTimeFormatted);
    print('DEBUG: BECMG period time formatted: "$periodTimeFormatted", matches: $matches');
    
    return matches;
  }
  
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
    
    // For now, use current time - in a real implementation, this would use the slider time
    final currentTime = DateTime.now();
    
    return currentTime.isAfter(transitionStart) && currentTime.isBefore(transitionEnd);
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
          baseline.type == 'BECMG') {
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