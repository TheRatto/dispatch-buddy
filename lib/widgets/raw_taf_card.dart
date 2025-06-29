import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/decoder_service.dart';
import '../models/decoded_weather_models.dart';

/// Raw TAF Card Widget
/// 
/// Displays raw TAF text with period highlighting:
/// - Formatted TAF text display
/// - Period-based highlighting (baseline and concurrent)
/// - Scrollable text with monospace font
/// - Exact styling preserved from original implementation
class RawTafCard extends StatelessWidget {
  final Weather taf;
  final Map<String, dynamic>? activePeriods;

  const RawTafCard({
    Key? key,
    required this.taf,
    this.activePeriods,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('DEBUG: === RAW HIGHLIGHTING START ===');
    print('DEBUG: Raw highlighting - activePeriods: $activePeriods');
    
    final originalRawText = taf.rawText;
    final decoder = DecoderService();
    final formattedRawText = decoder.formatTafForDisplay(originalRawText);
    TextSpan textSpan;
    
    if (activePeriods != null) {
      print('DEBUG: Raw highlighting - Object ID: ${activePeriods.hashCode}');
      
      // Use the same logic as decoded weather - get all active periods
      final baseline = activePeriods!['baseline'] as DecodedForecastPeriod?;
      final concurrent = activePeriods!['concurrent'] as List<DecodedForecastPeriod>;
      
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raw TAF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
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
          highlightColor = Color(0xFFF97316); // Orange
          print('DEBUG: Highlighting INITIAL line: "$line"');
        } else if (baseline.type == 'FM' && line.startsWith('FM')) {
          // Check if this is the specific FM period that's active
          if (_matchesPeriodTime(line, baseline)) {
            highlightColor = Color(0xFFF97316); // Orange
            print('DEBUG: Highlighting specific FM line: "$line" (time: ${baseline.time})');
          }
        } else if (baseline.type == 'BECMG' && line.startsWith('BECMG')) {
          // Check if this is the specific BECMG period that's active
          // BECMG is transitional - it persists until the next FM period
          if (_matchesBecmgPeriod(line, baseline)) {
            highlightColor = Color(0xFFF97316); // Orange
            print('DEBUG: Highlighting specific BECMG line: "$line" (time: ${baseline.time})');
          }
        }
      }
      
      // Check concurrent periods
      for (final period in concurrent) {
        bool shouldHighlight = false;
        
        if (period.type.contains('TEMPO') && line.startsWith('TEMPO')) {
          // Check if this is the specific TEMPO period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = Colors.orange;
            shouldHighlight = true;
            print('DEBUG: Highlighting specific TEMPO line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('INTER') && line.startsWith('INTER')) {
          // Check if this is the specific INTER period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = Colors.purple;
            shouldHighlight = true;
            print('DEBUG: Highlighting specific INTER line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB30') && line.startsWith('PROB30')) {
          // Check if this is the specific PROB30 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = Colors.orange;
            shouldHighlight = true;
            print('DEBUG: Highlighting specific PROB30 line: "$line" (time: ${period.time})');
          }
        } else if (period.type.contains('PROB40') && line.startsWith('PROB40')) {
          // Check if this is the specific PROB40 period that's active
          if (_matchesPeriodTime(line, period)) {
            highlightColor = Colors.orange;
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
          backgroundColor: highlightColor != null ? highlightColor.withOpacity(0.2) : null,
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
} 