import 'package:flutter/foundation.dart';

/// Handles parsing of weather elements from METAR and TAF segments
class WeatherParser {
  // Weather parsing regex patterns
  static final _windPattern = RegExp(r'(\d{3}|VRB)(\d{2,3})G?(\d{2,3})?KT');
  static final _tafVisibilityPattern = RegExp(r'\b(\d{4}|CAVOK)\b');
  static final _tafVisibilitySMPattern = RegExp(r'\b(P?\d+SM)\b');
  static final _cloudLayerPattern = RegExp(r'\b(FEW|SCT|BKN|OVC)(\d{3})(TCU|CB)?\b');
  static final _skcPattern = RegExp(r'\bSKC\b');
  static final _weatherPattern = RegExp(r'(?<!\w)([+-]?(?:TSRA|SHRA|TS|SH|FZ|MI|BC|DR|BL|DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS|VCTS|VCSH|SHSN|SHGR|SHGS|SHPL|SHIC|SHUP|SHBR|SHFG|SHFU|SHVA|SHDU|SHSA|SHHZ|SHPY|SHPO|SHSQ|SHFC|SHSS|SHDS|SHVCTS|SHFZ|SHMI|SHBC|SHDR|SHBL))\b');
  static final _cavokPattern = RegExp(r'\bCAVOK\b');

  /// Parse all weather elements from a TAF/METAR segment
  static Map<String, String> parseWeatherFromSegment(String segment) {
    final weather = <String, String>{};
    final isCavok = _cavokPattern.hasMatch(segment);
    
    // Check if this is EGLL segment
    final isEgll = segment.contains('EGLL');
    if (isEgll) {
      print('DEBUG: 🎯 EGLL segment parsing: "$segment"');
    }
    
    // Check if this is a TEMPO/INTER/PROB segment
    final isConcurrent = segment.contains('TEMPO') || segment.contains('INTER') || segment.contains('PROB');
    if (isConcurrent) {
      print('DEBUG: 🎯 Concurrent segment parsing: "$segment"');
    }
    
    print('DEBUG: Parsing segment: $segment');
    print('DEBUG: CAVOK detected: $isCavok');
    
    // Test for -RA specifically
    if (segment.contains('-RA')) {
      print('DEBUG: 🚨 FOUND -RA in segment!');
      print('DEBUG: Segment contains -RA: ${segment.contains('-RA')}');
      print('DEBUG: Weather pattern test: ${_weatherPattern.hasMatch(segment)}');
      final raMatch = _weatherPattern.firstMatch(segment);
      if (raMatch != null) {
        print('DEBUG: -RA match found: ${raMatch.group(1)}');
      } else {
        print('DEBUG: No -RA match found!');
      }
    }

    // Parse wind
    final windMatch = _windPattern.firstMatch(segment);
    if (windMatch != null) {
      final dir = windMatch.group(1);
      final spd = int.tryParse(windMatch.group(2) ?? '');
      final gust = windMatch.group(3) != null ? int.tryParse(windMatch.group(3)!) : null;
      if (spd != null) {
        weather['Wind'] = _describeWind(dir, spd, gust).replaceFirst('Wind ', '');
        if (isEgll) {
          print('DEBUG: EGLL wind parsed: ${weather['Wind']}');
        }
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL wind not found in segment!');
    }

    // Parse visibility - search in the segment after wind
    final searchSegment = windMatch != null ? segment.substring(windMatch.end) : segment;
    print('DEBUG: 🔍 Searching for visibility in: "$searchSegment"');
    
    // Remove time patterns like "2806/2809" before searching for visibility
    // This prevents BECMG times and other time ranges from being parsed as visibility
    String visibilitySearchText = searchSegment.replaceAll(RegExp(r'\d{4}/\d{4}'), '');
    print('DEBUG: 🔍 After removing time patterns: "$visibilitySearchText"');
    
    final visibilityMatch = _tafVisibilityPattern.firstMatch(visibilitySearchText);
    final visibilitySMMatch = _tafVisibilitySMPattern.firstMatch(visibilitySearchText);
    
    print('DEBUG: 🔍 Visibility match: ${visibilityMatch?.group(0)}');
    print('DEBUG: 🔍 Visibility SM match: ${visibilitySMMatch?.group(0)}');
    
    if (visibilityMatch != null) {
      final visibility = visibilityMatch.group(1);
      print('DEBUG: 🔍 Parsed visibility: $visibility');
      if (visibility == 'CAVOK') {
        weather['Visibility'] = 'CAVOK';
      } else if (visibility != null) {
        final visMeters = int.tryParse(visibility);
        if (visMeters != null) {
          if (visMeters >= 9999) {
            weather['Visibility'] = '>10km';
          } else {
            weather['Visibility'] = '${visMeters}m';
          }
        }
      }
      if (isEgll) {
        print('DEBUG: EGLL visibility parsed: ${weather['Visibility']}');
      }
    } else if (visibilitySMMatch != null) {
      final visibility = visibilitySMMatch.group(1);
      if (visibility != null) {
        // Format visibility for display
        if (visibility.startsWith('P')) {
          // P6SM -> >6 statute miles
          final number = visibility.substring(1).replaceAll('SM', '');
          weather['Visibility'] = '>$number statute miles';
        } else {
          // 6SM -> 6 statute miles
          final number = visibility.replaceAll('SM', '');
          weather['Visibility'] = '$number statute miles';
        }
      }
      if (isEgll) {
        print('DEBUG: EGLL visibility (SM) parsed: ${weather['Visibility']}');
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL visibility not found in segment!');
    }

    // Parse clouds
    final cloudMatches = _cloudLayerPattern.allMatches(segment);
    if (cloudMatches.isNotEmpty) {
      final cloudDescriptions = <String>[];
      for (final match in cloudMatches) {
        final type = match.group(1);
        final height = match.group(2);
        final special = match.group(3);
        if (type != null && height != null) {
          final heightFt = int.parse(height) * 100;
          String description = '$type at ${heightFt}ft';
          if (special != null) {
            if (special == 'CB') {
              description += ' Cumulonimbus';
            } else if (special == 'TCU') {
              description += ' Towering Cumulus';
            } else {
              description += ' $special';
            }
          }
          cloudDescriptions.add(description);
        }
      }
      weather['Cloud'] = cloudDescriptions.join('\n');
      if (isEgll) {
        print('DEBUG: EGLL cloud parsed: ${weather['Cloud']}');
      }
    } else if (_skcPattern.hasMatch(segment)) {
      weather['Cloud'] = 'Sky Clear';
      if (isEgll) {
        print('DEBUG: EGLL cloud parsed: Sky Clear (SKC detected)');
      }
    } else if (segment.contains('NSC')) {
      weather['Cloud'] = 'No Significant Cloud';
      if (isEgll) {
        print('DEBUG: EGLL cloud parsed: No Significant Cloud (NSC detected)');
      }
    } else if (isEgll) {
      print('DEBUG: 🚨 EGLL cloud not found in segment!');
    }

    // Parse weather phenomena - exclude cloud information from search
    final searchForWeather = segment.replaceAll(RegExp(r'\b(FEW|SCT|BKN|OVC)\d{3}\b'), '');
    if (isEgll) {
      print('DEBUG: EGLL searching for weather in: "$searchForWeather"');
    }
    print('DEBUG: 🔍 Searching for weather in: "$searchForWeather"');
    final weatherMatches = _weatherPattern.allMatches(searchForWeather);
    print('DEBUG: Weather pattern matches found: ${weatherMatches.length}');
    for (final match in weatherMatches) {
      print('DEBUG: Weather match: "${match.group(1)}"');
    }
    if (weatherMatches.isNotEmpty) {
      final weatherDescriptions = <String>[];
      for (final match in weatherMatches) {
        final code = match.group(1) ?? '';
        final description = describeConditions(code);
        weatherDescriptions.add(description);
        print('DEBUG: Weather code: "$code" -> "$description"');
      }
      weather['Weather'] = weatherDescriptions.join(', ');
    } else if (segment.contains('NSW')) {
      weather['Weather'] = 'No Significant Weather';
      print('DEBUG: Found explicit NSW');
    } else {
      // Try to parse full text weather descriptions (NAIPS format)
      final fullTextWeather = _parseFullTextWeather(segment);
      if (fullTextWeather != null) {
        weather['Weather'] = fullTextWeather;
        print('DEBUG: Found full text weather: "$fullTextWeather"');
      } else {
        weather['Weather'] = '-';
        print('DEBUG: No weather phenomena found, setting to "-"');
      }
    }

    // Set CAVOK visibility if detected (this overrides any other visibility)
    if (isCavok) {
      weather['Visibility'] = 'CAVOK';
      weather['Cloud'] = 'CAVOK';
      weather['Weather'] = 'CAVOK';
      print('DEBUG: Set CAVOK visibility, cloud, and weather');
    }

    if (isEgll) {
      print('DEBUG: EGLL final weather: $weather');
    }
    print('DEBUG: Final weather for segment: $weather');
    return weather;
  }

  /// Parse wind from a TAF/METAR segment
  static String? parseWind(String segment) {
    final windMatch = _windPattern.firstMatch(segment);
    if (windMatch != null) {
      final dir = windMatch.group(1);
      final spd = int.tryParse(windMatch.group(2) ?? '');
      final gust = windMatch.group(3) != null ? int.tryParse(windMatch.group(3)!) : null;
      if (spd != null) {
        return _describeWind(dir, spd, gust).replaceFirst('Wind ', '');
      }
    }
    return null;
  }

  /// Parse visibility from a TAF/METAR segment
  static String? parseVisibility(String segment) {
    final visibilityMatch = _tafVisibilityPattern.firstMatch(segment);
    final visibilitySMMatch = _tafVisibilitySMPattern.firstMatch(segment);
    
    if (visibilityMatch != null) {
      final visibility = visibilityMatch.group(1);
      if (visibility == 'CAVOK') {
        return 'CAVOK';
      } else if (visibility != null) {
        final visMeters = int.tryParse(visibility);
        if (visMeters != null) {
          if (visMeters >= 9999) {
            return '>10km';
          } else {
            return '${visMeters}m';
          }
        }
      }
    } else if (visibilitySMMatch != null) {
      final visibility = visibilitySMMatch.group(1);
      if (visibility != null) {
        // Format visibility for display
        if (visibility.startsWith('P')) {
          // P6SM -> >6 statute miles
          final number = visibility.substring(1).replaceAll('SM', '');
          return '>$number statute miles';
        } else {
          // 6SM -> 6 statute miles
          final number = visibility.replaceAll('SM', '');
          return '$number statute miles';
        }
      }
    }
    return null;
  }

  /// Parse cloud from a TAF/METAR segment
  static String? parseCloud(String segment) {
    final cloudMatches = _cloudLayerPattern.allMatches(segment);
    if (cloudMatches.isNotEmpty) {
      final cloudDescriptions = <String>[];
      for (final match in cloudMatches) {
        final type = match.group(1);
        final height = match.group(2);
        final special = match.group(3);
        if (type != null && height != null) {
          final heightFt = int.parse(height) * 100;
          String description = '$type at ${heightFt}ft';
          if (special != null) {
            if (special == 'CB') {
              description += ' Cumulonimbus';
            } else if (special == 'TCU') {
              description += ' Towering Cumulus';
            } else {
              description += ' $special';
            }
          }
          cloudDescriptions.add(description);
        }
      }
      return cloudDescriptions.join('\n');
    }
    if (_skcPattern.hasMatch(segment)) {
      return 'Sky Clear';
    }
    return null;
  }

  /// Parse weather codes from a TAF/METAR segment
  static String? parseWeather(String segment) {
    final searchForWeather = segment.replaceAll(RegExp(r'\b(FEW|SCT|BKN|OVC)\d{3}\b'), '');
    final weatherMatches = _weatherPattern.allMatches(searchForWeather);
    
    if (weatherMatches.isNotEmpty) {
      final weatherDescriptions = <String>[];
      for (final match in weatherMatches) {
        final code = match.group(1) ?? '';
        final description = describeConditions(code);
        weatherDescriptions.add(description);
      }
      return weatherDescriptions.join(', ');
    } else if (segment.contains('NSW')) {
      return 'No Significant Weather';
    }
    
    // Try to parse full text weather descriptions (NAIPS format)
    final fullTextWeather = _parseFullTextWeather(segment);
    if (fullTextWeather != null) {
      debugPrint('DEBUG: 🌧️ Full text weather parsed: "$fullTextWeather" from segment: "$segment"');
      return fullTextWeather;
    }
    
    return null;
  }

  /// Parse full text weather descriptions (NAIPS format)
  static String? _parseFullTextWeather(String segment) {
    debugPrint('DEBUG: 🔍 _parseFullTextWeather called with segment: "$segment"');
    
    // Look for common full text weather patterns
    if (segment.contains('SHOWERS OF LIGHT RAIN')) {
      debugPrint('DEBUG: 🎯 Found SHOWERS OF LIGHT RAIN');
      return 'Light Showers of Rain';
    } else if (segment.contains('SHOWERS OF MODERATE RAIN')) {
      debugPrint('DEBUG: 🎯 Found SHOWERS OF MODERATE RAIN');
      return 'Moderate Showers of Rain';
    } else if (segment.contains('SHOWERS OF HEAVY RAIN')) {
      debugPrint('DEBUG: 🎯 Found SHOWERS OF HEAVY RAIN');
      return 'Heavy Showers of Rain';
    } else if (segment.contains('LIGHT RAIN')) {
      debugPrint('DEBUG: 🎯 Found LIGHT RAIN');
      return 'Light Rain';
    } else if (segment.contains('MODERATE RAIN')) {
      debugPrint('DEBUG: 🎯 Found MODERATE RAIN');
      return 'Moderate Rain';
    } else if (segment.contains('HEAVY RAIN')) {
      debugPrint('DEBUG: 🎯 Found HEAVY RAIN');
      return 'Heavy Rain';
    } else if (segment.contains('LIGHT DRIZZLE')) {
      debugPrint('DEBUG: 🎯 Found LIGHT DRIZZLE');
      return 'Light Drizzle';
    } else if (segment.contains('MODERATE DRIZZLE')) {
      debugPrint('DEBUG: 🎯 Found MODERATE DRIZZLE');
      return 'Moderate Drizzle';
    } else if (segment.contains('HEAVY DRIZZLE')) {
      debugPrint('DEBUG: 🎯 Found HEAVY DRIZZLE');
      return 'Heavy Drizzle';
    } else if (segment.contains('LIGHT SNOW')) {
      debugPrint('DEBUG: 🎯 Found LIGHT SNOW');
      return 'Light Snow';
    } else if (segment.contains('MODERATE SNOW')) {
      debugPrint('DEBUG: 🎯 Found MODERATE SNOW');
      return 'Moderate Snow';
    } else if (segment.contains('HEAVY SNOW')) {
      debugPrint('DEBUG: 🎯 Found HEAVY SNOW');
      return 'Heavy Snow';
    } else if (segment.contains('LIGHT FOG')) {
      debugPrint('DEBUG: 🎯 Found LIGHT FOG');
      return 'Light Fog';
    } else if (segment.contains('MODERATE FOG')) {
      debugPrint('DEBUG: 🎯 Found MODERATE FOG');
      return 'Moderate Fog';
    } else if (segment.contains('HEAVY FOG')) {
      debugPrint('DEBUG: 🎯 Found HEAVY FOG');
      return 'Heavy Fog';
    } else if (segment.contains('LIGHT MIST')) {
      debugPrint('DEBUG: 🎯 Found LIGHT MIST');
      return 'Light Mist';
    } else if (segment.contains('MODERATE MIST')) {
      debugPrint('DEBUG: 🎯 Found MODERATE MIST');
      return 'Moderate Mist';
    } else if (segment.contains('HEAVY MIST')) {
      debugPrint('DEBUG: 🎯 Found HEAVY MIST');
      return 'Heavy Mist';
    }
    
    debugPrint('DEBUG: 🔍 No full text weather patterns found');
    return null;
  }

  /// Describe wind conditions in human-readable format
  static String _describeWind(String? directionStr, int? speed, int? gustSpeed) {
    if (speed == null) return 'Wind unknown';
    
    String description = 'Wind ';
    
    if (directionStr == 'VRB') {
      description += 'Variable';
    } else if (directionStr != null) {
      // Preserve the original 3-digit format with leading zeros
      description += '$directionStr°';
    } else {
      description += 'unknown direction';
    }
    
    description += ' at ${speed}kt';
    
    if (gustSpeed != null && gustSpeed > speed) {
      description += '\nMax gust ${gustSpeed}kt';
    }
    
    return description;
  }

  /// Describe weather conditions in human-readable format
  static String describeConditions(String? conditionCode) {
    print('DEBUG: 🎯 describeConditions called with: "$conditionCode"');
    if (conditionCode == null || conditionCode.isEmpty) return 'Unknown';
    
    String intensity = '';
    String code = conditionCode;
    
    // Check for intensity prefix
    if (code.startsWith('+')) {
      intensity = 'Heavy ';
      code = code.substring(1);
      print('DEBUG: Found "+" prefix, intensity: "$intensity", code: "$code"');
    } else if (code.startsWith('-')) {
      intensity = 'Light ';
      code = code.substring(1);
      print('DEBUG: Found "-" prefix, intensity: "$intensity", code: "$code"');
    } else {
      print('DEBUG: No intensity prefix, code: "$code"');
    }
    
    String description = '';
    
    // Weather phenomena descriptions
    switch (code) {
      case 'DZ': description = 'Drizzle'; break;
      case 'RA': description = 'Rain'; break;
      case 'SN': description = 'Snow'; break;
      case 'SG': description = 'Snow Grains'; break;
      case 'IC': description = 'Ice Crystals'; break;
      case 'PL': description = 'Ice Pellets'; break;
      case 'GR': description = 'Hail'; break;
      case 'GS': description = 'Small Hail'; break;
      case 'UP': description = 'Unknown Precipitation'; break;
      case 'BR': description = 'Mist'; break;
      case 'FG': description = 'Fog'; break;
      case 'FU': description = 'Smoke'; break;
      case 'VA': description = 'Volcanic Ash'; break;
      case 'DU': description = 'Dust'; break;
      case 'SA': description = 'Sand'; break;
      case 'HZ': description = 'Haze'; break;
      case 'PY': description = 'Spray'; break;
      case 'PO': description = 'Dust/Sand Whirls'; break;
      case 'SQ': description = 'Squalls'; break;
      case 'FC': description = 'Funnel Cloud'; break;
      case 'SS': description = 'Sandstorm'; break;
      case 'DS': description = 'Duststorm'; break;
      case 'TS': description = 'Thunderstorm'; break;
      case 'VCTS': description = 'Vicinity Thunderstorms'; break;
      case 'VCSH': description = 'Vicinity Showers'; break;
      case 'SH': description = 'Showers'; break;
      case 'FZ': description = 'Freezing'; break;
      case 'MI': description = 'Shallow'; break;
      case 'BC': description = 'Patches'; break;
      case 'DR': description = 'Low Drifting'; break;
      case 'BL': description = 'Blowing'; break;
      case 'TSRA': description = 'Thunderstorms and Rain'; break;
      case 'SHRA': description = 'Showers of Rain'; break;
      case 'SHSN': description = 'Showers of Snow'; break;
      case 'SHGR': description = 'Showers of Hail'; break;
      case 'SHGS': description = 'Showers of Small Hail'; break;
      case 'SHPL': description = 'Showers of Ice Pellets'; break;
      case 'SHIC': description = 'Showers of Ice Crystals'; break;
      case 'SHUP': description = 'Showers of Unknown Precipitation'; break;
      case 'SHBR': description = 'Showers of Mist'; break;
      case 'SHFG': description = 'Showers of Fog'; break;
      case 'SHFU': description = 'Showers of Smoke'; break;
      case 'SHVA': description = 'Showers of Volcanic Ash'; break;
      case 'SHDU': description = 'Showers of Dust'; break;
      case 'SHSA': description = 'Showers of Sand'; break;
      case 'SHHZ': description = 'Showers of Haze'; break;
      case 'SHPY': description = 'Showers of Spray'; break;
      case 'SHPO': description = 'Showers of Dust/Sand Whirls'; break;
      case 'SHSQ': description = 'Showers of Squalls'; break;
      case 'SHFC': description = 'Showers of Funnel Cloud'; break;
      case 'SHSS': description = 'Showers of Sandstorm'; break;
      case 'SHDS': description = 'Showers of Duststorm'; break;
      case 'SHVCTS': description = 'Showers of Vicinity Thunderstorms'; break;
      case 'SHFZ': description = 'Showers of Freezing'; break;
      case 'SHMI': description = 'Showers of Shallow'; break;
      case 'SHBC': description = 'Showers of Patches'; break;
      case 'SHDR': description = 'Showers of Low Drifting'; break;
      case 'SHBL': description = 'Showers of Blowing'; break;
      default: description = 'Unknown weather'; break;
    }
    
    final finalDescription = intensity + description;
    print('DEBUG: Final weather description: "$finalDescription" (intensity: "$intensity", description: "$description")');
    return finalDescription;
  }

  // Additional methods needed by DecoderService
  static String describeWind(String? directionStr, int? speed, int? gustSpeed) {
    if (speed == null || directionStr == null) return 'Wind data unavailable';

    // Handle calm wind case
    final dirInt = int.tryParse(directionStr);
    if (dirInt == 0 && speed == 0 && gustSpeed == null) return 'Wind Calm';

    String directionDisplay;
    if (directionStr == 'VRB') {
        directionDisplay = 'Variable';
    } else {
        directionDisplay = '${directionStr.padLeft(3, '0')}°';
    }

    String baseWind = 'Wind $directionDisplay at ${speed}kt';
    if (gustSpeed != null) {
      baseWind += '\nMax gust ${gustSpeed}kt';
    }
    return baseWind;
  }

  static String describeVisibility(int? visibility, bool isCavok, String unit, {bool isGreaterThan = false}) {
    if (isCavok) return 'CAVOK - Ceiling and Visibility OK';
    if (visibility == null) return 'Visibility data unavailable';
    
    String prefix = isGreaterThan ? '>' : '';
    if (unit == 'SM') return 'Visibility $prefix${visibility}SM';
    if (visibility == 9999) return '>10km';
    return 'Visibility $prefix${visibility}m';
  }

  static String describeClouds(String? cloudCover, bool isCavok, bool isNcd) {
    if (isNcd) return 'No cloud detected';
    if (isCavok) return 'CAVOK';
    if (cloudCover == null || cloudCover.isEmpty) return '-';
    
    final clouds = cloudCover.split(' ').map((cloud) {
      final type = cloud.substring(0, 3);
      final height = int.parse(cloud.substring(3)) * 100;
      
      final typeNames = {
        'FEW': 'Few',
        'SCT': 'Scattered',
        'BKN': 'Broken',
        'OVC': 'Overcast'
      };
      
      return '${typeNames[type]} at ${height}ft';
    }).join('\n');
    
    return clouds;
  }

  static String describeTemperature(double? temp, double? dewPoint) {
    if (temp == null) return 'Temperature data unavailable';
    final tempDesc = 'Temperature ${temp.round()}°C';
    if (dewPoint != null) {
      return '$tempDesc, Dew point ${dewPoint.round()}°C';
    }
    return tempDesc;
  }

  static String describePressure(int? qnh, String unit) {
    if (qnh == null) return 'Pressure data unavailable';
    if (unit == 'inHg') return '${qnh/100} inHg';
    return 'QNH ${qnh}hPa';
  }

  static String describeRvr(String? rvr) {
    if (rvr == null || rvr.isEmpty) return '';
    return 'Runway Visual Range: $rvr';
  }

  static double? parseTemp(String tempStr) {
    if (tempStr.startsWith('M')) {
      return double.parse(tempStr.substring(1)) * -1;
    }
    return double.tryParse(tempStr);
  }

  static String parseTempExtreme(String tempStr) {
    // Temperature extremes in remarks are encoded as 4 digits
    // First digit: 0 = positive, 1 = negative
    // Last 3 digits: temperature in tenths of degrees
    final isNegative = tempStr.startsWith('1');
    final tempValue = int.parse(tempStr.substring(1));
    final temp = tempValue / 10.0;
    return isNegative ? '-${temp.toStringAsFixed(1)}' : temp.toStringAsFixed(1);
  }

  static String describeCloudType(String cloudType) {
    final typeNames = {
      'CU': 'Cumulus',
      'CB': 'Cumulonimbus',
      'CI': 'Cirrus',
      'CS': 'Cirrostratus',
      'AS': 'Altostratus',
      'SC': 'Stratocumulus',
      'ST': 'Stratus',
      'SN': 'Snow',
      'SS': 'Snow',
    };
    
    return typeNames[cloudType] ?? cloudType;
  }
} 