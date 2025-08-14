import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/weather.dart';
import '../providers/flight_provider.dart';
import '../providers/settings_provider.dart';
import 'metar_compact_details.dart';
import 'atis_card.dart' as atis_widget;

class MetarTab extends StatefulWidget {
  const MetarTab({
    super.key,
  });

  @override
  State<MetarTab> createState() => _MetarTabState();
}

class _MetarTabState extends State<MetarTab> {
  Timer? _ageUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Update age every minute for dynamic updates
    _ageUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update age strings
        });
      }
    });
  }

  @override
  void dispose() {
    _ageUpdateTimer?.cancel();
    super.dispose();
  }

  // Normalize METAR raw text to avoid unexpected interior line breaks
  String _normalizeMetarRaw(String text) {
    final trimmed = text.trim();
    // If there is no newline, return as-is
    if (!trimmed.contains('\n')) return trimmed;
    // Common METAR lines break on QNH and RFxx segments; collapse lines into a single line
    final collapsed = trimmed.replaceAll(RegExp(r'\s*\n\s*'), ' ');
    // Also normalize multiple spaces
    return collapsed.replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  String _buildHeaderText(Weather metar) {
    debugPrint('DEBUG: _buildHeaderText called with metar.rawText: "${metar.rawText}"');
    debugPrint('DEBUG: metar.icao: ${metar.icao}');
    
    // Extract issue time from METAR raw text (handle both regular METARs and SPECI reports)
    // Try multiple regex patterns to handle different METAR formats
    RegExpMatch? issueTimeMatch;
    
    // Pattern 1: Standard METAR format with METAR prefix
    issueTimeMatch = RegExp(r'(?:METAR\s+|SPECI\s+)?\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
    if (issueTimeMatch != null) {
      debugPrint('DEBUG: Pattern 1 matched: Standard METAR format');
    } else {
      // Pattern 2: METAR without prefix, just ICAO followed by time
      issueTimeMatch = RegExp(r'^\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
      if (issueTimeMatch != null) {
        debugPrint('DEBUG: Pattern 2 matched: METAR without prefix');
      } else {
        // Pattern 3: Look for any 6-digit time pattern in the text (with or without Z)
        issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z?').firstMatch(metar.rawText);
        if (issueTimeMatch != null) {
          debugPrint('DEBUG: Pattern 3 matched: Generic time pattern');
        }
      }
    }
    
    debugPrint('DEBUG: issueTimeMatch: $issueTimeMatch');
    
    if (issueTimeMatch == null) {
      debugPrint('DEBUG: No match found, returning just ICAO: ${metar.icao}');
      return metar.icao;
    }
    
    // Group 1 = Day, Group 2 = Hour, Group 3 = Minute
    final hour = issueTimeMatch.group(2)!;
    final minute = issueTimeMatch.group(3)!;
    final issueTimeString = '$hour$minute' + 'Z';
    
    // Include "METAR" label as requested (e.g., "YBBN METAR 1100z")
    final headerText = '${metar.icao} METAR $issueTimeString';
    debugPrint('DEBUG: Returning header text: $headerText');
    return headerText;
  }

  String _formatMetarAge(Weather metar) {
    debugPrint('DEBUG: _formatMetarAge called with metar.rawText: "${metar.rawText}"');
    
    // Extract issue time from METAR raw text (handle both regular METARs and SPECI reports)
    // Try multiple regex patterns to handle different METAR formats
    RegExpMatch? issueTimeMatch;
    
    // Pattern 1: Standard METAR format with METAR prefix
    issueTimeMatch = RegExp(r'(?:METAR\s+|SPECI\s+)?\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
    if (issueTimeMatch != null) {
      debugPrint('DEBUG: Pattern 1 matched in _formatMetarAge: Standard METAR format');
    } else {
      // Pattern 2: METAR without prefix, just ICAO followed by time
      issueTimeMatch = RegExp(r'^\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
      if (issueTimeMatch != null) {
        debugPrint('DEBUG: Pattern 2 matched in _formatMetarAge: METAR without prefix');
      } else {
        // Pattern 3: Look for any 6-digit time pattern in the text (with or without Z)
        issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z?').firstMatch(metar.rawText);
        if (issueTimeMatch != null) {
          debugPrint('DEBUG: Pattern 3 matched in _formatMetarAge: Generic time pattern');
        }
      }
    }
    
    debugPrint('DEBUG: issueTimeMatch in _formatMetarAge: $issueTimeMatch');
    
    if (issueTimeMatch == null) {
      debugPrint('DEBUG: No match found in _formatMetarAge, returning empty string');
      return '';
    }
    
    // Group 1 = Day, Group 2 = Hour, Group 3 = Minute
    final day = int.parse(issueTimeMatch.group(1)!);
    final hour = int.parse(issueTimeMatch.group(2)!);
    final minute = int.parse(issueTimeMatch.group(3)!);
    
    debugPrint('DEBUG: Parsed day: $day, hour: $hour, minute: $minute');
    
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
    
    debugPrint('DEBUG: Calculated issueTime: $issueTime');
    
    // Calculate age
    final difference = now.difference(issueTime);
    debugPrint('DEBUG: Age difference: $difference');
    
    String result;
    if (difference.inMinutes < 1) {
      result = 'Just now';
    } else if (difference.inMinutes < 60) {
      result = '${difference.inMinutes} mins old';
    } else if (difference.inHours < 24) {
      // Match ATIS format: "11:37 hrs old" instead of "11 hours old"
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (minutes == 0) {
        result = '$hours hrs old';
      } else {
        result = '$hours:${minutes.toString().padLeft(2, '0')} hrs old';
      }
    } else {
      result = '${difference.inDays} days old';
    }
    
    debugPrint('DEBUG: Returning age string: $result');
    return result;
  }

  Color _getMetarAgeColor(Weather metar) {
    // Extract issue time from METAR raw text (handle both regular METARs and SPECI reports)
    // Try multiple regex patterns to handle different METAR formats
    RegExpMatch? issueTimeMatch;
    
    // Pattern 1: Standard METAR format with METAR prefix
    issueTimeMatch = RegExp(r'(?:METAR\s+|SPECI\s+)?\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
    if (issueTimeMatch == null) {
      // Pattern 2: METAR without prefix, just ICAO followed by time
      issueTimeMatch = RegExp(r'^\w{4}\s+(\d{2})(\d{2})(\d{2})Z').firstMatch(metar.rawText);
      if (issueTimeMatch == null) {
        // Pattern 3: Look for any 6-digit time pattern in the text (with or without Z)
        issueTimeMatch = RegExp(r'(\d{2})(\d{2})(\d{2})Z?').firstMatch(metar.rawText);
      }
    }
    
    if (issueTimeMatch == null) {
      return Colors.grey[600]!;
    }
    
    // Group 1 = Day, Group 2 = Hour, Group 3 = Minute
    final day = int.parse(issueTimeMatch.group(1)!);
    final hour = int.parse(issueTimeMatch.group(2)!);
    final minute = int.parse(issueTimeMatch.group(3)!);
    
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
    
    // Calculate age and return appropriate color
    final difference = now.difference(issueTime);
    
    if (difference.inMinutes <= 30) {
      return const Color(0xFF059669); // Green for fresh (up to 30 minutes)
    } else if (difference.inMinutes <= 60) {
      return const Color(0xFFD97706); // Orange for moderate (30-60 minutes)
    } else {
      return const Color(0xFFDC2626); // Red for old (over 60 minutes)
    }
  }

  Weather? _getAtisForAirport(BuildContext context, String? icao) {
    if (icao == null) return null;
    
    // Get all weather data from the flight provider
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final allWeather = flightProvider.currentFlight?.weather ?? [];
    
    // Find ATIS for the selected airport
    final atisList = allWeather.where((weather) => 
      weather.type == 'ATIS' && weather.icao == icao
    ).toList();
    
    // Return the latest ATIS (first in the list)
    return atisList.isNotEmpty ? atisList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final flightProvider = Provider.of<FlightProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Get all airports from the current flight
    final allAirports = flightProvider.currentFlight?.airports.map((a) => a.icao).toList() ?? [];
    
    // If an airport is selected, filter to just that airport. Otherwise, show all airports
    final airportsToShow = flightProvider.selectedAirport != null 
        ? [flightProvider.selectedAirport!]
        : allAirports;
    
    // Get METARs directly from the flight's weather data (like NOTAMs do)
    final flightWeather = flightProvider.currentFlight?.weather ?? [];
    final metarsToShow = <String, List<Weather>>{};
    
    debugPrint('DEBUG: Total weather items: ${flightWeather.length}');
    debugPrint('DEBUG: Weather types: ${flightWeather.map((w) => '${w.icao}(${w.type})').join(', ')}');
    
    for (final airport in airportsToShow) {
      final airportMetars = flightWeather
          .where((w) => w.type == 'METAR' && w.icao == airport)
          .toList();
      debugPrint('DEBUG: Found ${airportMetars.length} METARs for airport $airport');
      if (airportMetars.isNotEmpty) {
        metarsToShow[airport] = airportMetars;
        // Debug the first METAR
        final firstMetar = airportMetars.first;
        debugPrint('DEBUG: First METAR for $airport - rawText: "${firstMetar.rawText}"');
      }
    }
    
    debugPrint('DEBUG: Final metarsToShow: ${metarsToShow.keys.join(', ')}');
    
    // Check if we have any METARs to show after filtering
    if (metarsToShow.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 20, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No METARs Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  flightProvider.selectedAirport != null 
                      ? 'No METARs for ${flightProvider.selectedAirport}'
                      : 'No current weather observations',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    }

    final selectedAirport = flightProvider.selectedAirport;

    // Determine if NAIPS is enabled but we have no NAIPS weather for this airport
    final allWeather = flightProvider.currentFlight?.weather ?? [];
    final hasAnyForAirport = allWeather.any((w) => w.icao == selectedAirport);
    final hasNaipsForAirport = allWeather.any((w) => w.icao == selectedAirport && w.source == 'naips');
    final showNaipsFallbackBanner = settings.naipsEnabled && hasAnyForAirport && !hasNaipsForAirport;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          if (showNaipsFallbackBanner)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                border: Border.all(color: const Color(0xFFF59E0B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NAIPS data unavailable for this airport. Showing API data instead.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          // Single scrollable content area containing both ATIS and METAR
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 200, // Ensure minimum height for scrolling
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                        // ATIS Card (first - more important for pilots)
                      Builder(
                        builder: (context) {
                          final atis = _getAtisForAirport(context, flightProvider.selectedAirport);
                          if (atis != null) {
                            return atis_widget.AtisCard(
                              key: ValueKey('atis_${flightProvider.selectedAirport ?? ''}'),
                              atis: atis,
                              icao: flightProvider.selectedAirport ?? '',
                            );
                          } else {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.radio,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "No ATIS available at ${flightProvider.selectedAirport}",
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
                        },
                      ),
                      
                      // Divider between ATIS and METAR
                      Builder(
                        builder: (context) {
                          final atis = _getAtisForAirport(context, flightProvider.selectedAirport);
                          if (atis != null && metarsToShow.isNotEmpty) {
                            return Container(
                              height: 1,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(vertical: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      
                      // METAR Cards
                      ...metarsToShow.entries.map((entry) {
                        final metars = entry.value;
                        return Column(
                          children: [
                            // METAR Cards for this airport
                            ...metars.map((metar) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with METAR time - matching ATIS style exactly
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cloud, color: Color(0xFF3B82F6), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _buildHeaderText(metar),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Age indicator - matching ATIS spacing and color exactly
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                                    child: Text(
                                      _formatMetarAge(metar),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getMetarAgeColor(metar),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Decoded compact grid
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                                    child: MetarCompactDetails(metar: metar),
                                  ),
                                  const SizedBox(height: 12),
                                  // Separator
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                                    child: Row(
                                      children: const [
                                        Expanded(child: Divider(thickness: 1.2)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      _normalizeMetarRaw(metar.rawText),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        );
                      }).toList(),
                      
                      // No METARs message if none available
                      if (metarsToShow.isEmpty)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'No METARs Available',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No METARs for ${flightProvider.selectedAirport}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Add bottom padding to prevent overflow and ensure pull-to-refresh works
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 