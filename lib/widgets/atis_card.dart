import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/weather.dart';

class AtisCard extends StatefulWidget {
  final Weather? atis;
  final String icao;

  const AtisCard({
    super.key,
    required this.atis,
    required this.icao,
  });

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
    if (!mounted || widget.atis == null) return;
    
    // Extract ATIS issue time from raw text (e.g., "ATIS YPPH W 120529 +")
    final issueTimeMatch = RegExp(r'ATIS\s+\w+\s+[A-Z]\s+(\d{6})').firstMatch(widget.atis!.rawText);
    if (issueTimeMatch == null) {
      setState(() {
        _ageText = '';
        _ageColor = Colors.grey;
      });
      return;
    }
    
    final issueTimeStr = issueTimeMatch.group(1)!;
    final day = int.parse(issueTimeStr.substring(0, 2));
    final hour = int.parse(issueTimeStr.substring(2, 4));
    final minute = int.parse(issueTimeStr.substring(4, 6));
    
    // Create issue time with proper date handling
    final now = DateTime.now().toUtc();
    DateTime issueTime;
    
    // Try current month first
    issueTime = DateTime.utc(now.year, now.month, day, hour, minute);
    
    // If issue time is in the future, it must be from the previous month
    if (issueTime.isAfter(now)) {
      // Check if the day difference is large (more than 7 days), indicating it's from previous month
      if (day > now.day + 7) {
        // Previous month
        final previousMonth = now.month == 1 ? 12 : now.month - 1;
        final previousYear = now.month == 1 ? now.year - 1 : now.year;
        issueTime = DateTime.utc(previousYear, previousMonth, day, hour, minute);
      } else {
        // Previous day in current month
        final yesterday = now.subtract(const Duration(days: 1));
        issueTime = DateTime.utc(yesterday.year, yesterday.month, day, hour, minute);
      }
    }
    
    // Calculate age
    final difference = now.difference(issueTime);
    
    String ageText;
    if (difference.inMinutes < 1) {
      ageText = 'Just now';
    } else if (difference.inMinutes < 60) {
      ageText = '${difference.inMinutes} mins old';
    } else if (difference.inHours < 24) {
      // Match METAR format: "11:37 hrs old" instead of "11 hours old"
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        ageText = '$hours hrs old';
      } else {
        ageText = '$hours:${minutes.toString().padLeft(2, '0')} hrs old';
      }
    } else {
      ageText = '${difference.inDays} days old';
    }
    
    // Calculate color
    Color ageColor;
    if (difference.inMinutes <= 30) {
      ageColor = const Color(0xFF059669); // Green for fresh (up to 30 minutes)
    } else if (difference.inMinutes <= 60) {
      ageColor = const Color(0xFFD97706); // Orange for moderate (30-60 minutes)
    } else {
      ageColor = const Color(0xFFDC2626); // Red for old (over 60 minutes)
    }
    
    setState(() {
      _ageText = ageText;
      _ageColor = ageColor;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.atis == null) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.radio,
                color: Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                "No ATIS available at ${widget.icao}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with ATIS code - matching METAR style exactly
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.radio, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildHeaderText(widget.atis!),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 0),
          // Age indicator - matching METAR spacing exactly
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Text(
              _ageText,
              style: TextStyle(
                fontSize: 12,
                color: _ageColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 0),
          // Raw ATIS text - matching METAR style exactly
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Single SelectableText widget to fix text selection issues
                SelectableText(
                  _formatAtisText(widget.atis!.rawText),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                // NAIPS indication - matching TAF card styling exactly
                if (widget.atis!.source == 'naips')
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security,
                          size: 10,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'NAIPS',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build header text in format: "YBBN ATIS T" (matching METAR format)
  String _buildHeaderText(Weather atis) {
    // Extract ATIS code from raw text if not available in model
    String atisCode = atis.atisCode ?? '';
    debugPrint('DEBUG: AtisCard - atis.atisCode from model: "$atisCode"');
    
    if (atisCode.isEmpty) {
      // Try to extract from raw text: "ATIS YSSY I 100634" -> "I"
      final match = RegExp(r'ATIS\s+\w+\s+([A-Z])\s+\d{6}').firstMatch(atis.rawText);
      if (match != null) {
        atisCode = match.group(1) ?? '';
        debugPrint('DEBUG: AtisCard - Extracted ATIS code from raw text: "$atisCode"');
      } else {
        debugPrint('DEBUG: AtisCard - No regex match found in raw text: "${atis.rawText.substring(0, atis.rawText.length > 100 ? 100 : atis.rawText.length)}..."');
      }
    }
    
    final headerText = '${widget.icao} ATIS ${atisCode.isNotEmpty ? atisCode : '?'}';
    debugPrint('DEBUG: AtisCard - Final header text: "$headerText"');
    return headerText;
  }
  
  String _formatAtisText(String rawText) {
    final lines = rawText.split('\n');
    final formattedLines = <String>[];
    
    // First, clean up random line breaks by properly identifying sections and joining continuation lines
    final cleanedLines = <String>[];
    String currentSection = '';
    String currentContent = '';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Special handling for the first line that contains ATIS info
      if (i == 0 && line.startsWith('ATIS')) {
        // Check if the first line contains both ATIS identifier and first section
        if (line.contains(':')) {
          // Split the line: "ATIS YSSY I 100634 APCH: EXPECT..." -> separate lines
          final colonIndex = line.indexOf(':');
          final beforeColon = line.substring(0, colonIndex).trim();
          final afterColon = line.substring(colonIndex + 1).trim();
          
          // Find the last word before the colon - that's our section header
          final wordsBeforeColon = beforeColon.split(' ');
          final sectionHeader = wordsBeforeColon.last;
          final atisInfo = wordsBeforeColon.take(wordsBeforeColon.length - 1).join(' ');
          
          // First line: ATIS identifier
          cleanedLines.add(atisInfo);
          
          // Start collecting content for the first section
          currentSection = sectionHeader;
          currentContent = afterColon;
        } else {
          // First line: just ATIS identifier
          cleanedLines.add(line);
        }
        continue;
      }
      
      // Check if this line starts a new section (contains ':' and is a known section header)
      if (line.contains(':') && _isSectionHeader(line)) {
        // If we have accumulated content from previous section, add it
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          cleanedLines.add('$currentSection: $currentContent');
          currentContent = '';
        }
        // Start new section
        currentSection = line.substring(0, line.indexOf(':')).trim();
        currentContent = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('+')) {
        // Lines with "+" are standalone - add previous section if exists, then add this line
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          cleanedLines.add('$currentSection: $currentContent');
          currentSection = '';
          currentContent = '';
        }
        cleanedLines.add(line);
      } else if (line.startsWith('TMP:') || line.startsWith('QNH:')) {
        // Special case for TMP and QNH which are standalone
        if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
          cleanedLines.add('$currentSection: $currentContent');
          currentSection = '';
          currentContent = '';
        }
        cleanedLines.add(line);
      } else {
        // This is continuation content for current section
        if (currentContent.isNotEmpty) {
          currentContent += ' $line';
        } else {
          currentContent = line;
        }
      }
    }
    
    // Add the last section if it exists
    if (currentSection.isNotEmpty && currentContent.isNotEmpty) {
      cleanedLines.add('$currentSection: $currentContent');
    }
    
    // Now apply formatting to the cleaned lines
    for (int i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i].trim();
      if (line.isEmpty) continue;
      
      // Special handling for the first line that contains ATIS info
      if (i == 0 && line.startsWith('ATIS')) {
        // First line: ATIS identifier (e.g., "ATIS YSSY I 100634")
        formattedLines.add(line);
      } else if (_isSectionHeader(line)) {
        // Section headers with content - start on new line with proper indentation
        formattedLines.add('    $line');
      } else if (line.startsWith('+')) {
        // Lines with "+" get minimal indentation for highlighting
        formattedLines.add('  $line');
      } else if (line.startsWith('TMP:') || line.startsWith('QNH:')) {
        // TMP and QNH are standalone sections
        formattedLines.add('    $line');
      } else {
        // Continuation content lines get maximum indentation for clear hierarchy
        formattedLines.add('            $line');
      }
    }
    
    return formattedLines.join('\n');
  }
  
  bool _isSectionHeader(String line) {
    final sectionHeaders = [
      'APCH', 'RWY', 'SFC COND', 'OPR INFO', 'WIND', 'VIS', 'WX', 'CLD'
    ];
    
    for (final header in sectionHeaders) {
      if (line.startsWith('$header:')) {
        return true;
      }
    }
    return false;
  }
} 