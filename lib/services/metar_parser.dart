import '../models/decoded_weather_models.dart';
import 'weather_parser.dart';

class MetarParser {
  // METAR Patterns
  static final _icaoPattern = RegExp(r'^([A-Z]{4})');
  static final _timestampPattern = RegExp(r'(\d{6})Z');
  static final _windPattern = RegExp(r'(\d{3}|VRB)(\d{2,3})G?(\d{2,3})?KT');
  static final _visibilityPattern = RegExp(r'(\d{4})|CAVOK');
  static final _visibilitySMPattern = RegExp(r'(\d{1,2})SM');
  static final _rvrPattern = RegExp(r'R(\d{2})/([PM]?\d{4})FT'); // RVR pattern
  static final _cloudPattern = RegExp(r'(FEW|SCT|BKN|OVC)(\d{3})');
  static final _cloudLayerPattern = RegExp(r'(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?');
  static final _cavokPattern = RegExp(r'\bCAVOK\b');
  static final _tempDewPattern = RegExp(r'(M?\d{2})/(M?\d{2})');
  static final _pressurePattern = RegExp(r'Q(\d{4})');
  static final _pressureInHgPattern = RegExp(r'A(\d{4})');
  
  // Weather codes for TAF/METAR parsing
  static const List<String> _weatherCodes = [
    'DZ', 'RA', 'SN', 'SG', 'IC', 'PL', 'GR', 'GS', 'UP', 'BR', 'FG', 'FU', 
    'VA', 'DU', 'SA', 'HZ', 'PY', 'PO', 'SQ', 'FC', 'SS', 'DS', 'TS', 'FZ', 
    'MI', 'BC', 'DR', 'BL', 'SH', 'VCSH', 'SHRA', 'VC', 'NSW'
  ];

  // Use the same weather pattern as WeatherParser
  static final _weatherPattern = RegExp(r'(?<!\w)([+-]?(?:TSRA|SHRA|TS|SH|FZ|MI|BC|DR|BL|DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS|VCTS|SHSN|SHGR|SHGS|SHPL|SHIC|SHUP|SHBR|SHFG|SHFU|SHVA|SHDU|SHSA|SHHZ|SHPY|SHPO|SHSQ|SHFC|SHSS|SHDS|SHVCTS|SHFZ|SHMI|SHBC|SHDR|SHBL))\b');
  
  static final _remarksPattern = RegExp(r'RMK(.+)');
  static final _peakWindPattern = RegExp(r'PK WND (\d{3})(\d{2})/(\d{2})'); // Peak wind pattern
  static final _windShiftPattern = RegExp(r'WSHFT (\d{4})'); // Wind shift pattern
  
  // Additional remarks patterns
  static final _variableVisibilityPattern = RegExp(r'VIS (\d+)/(\d+)V(\d+)'); // Variable visibility
  static final _rainBeginPattern = RegExp(r'RA(\d{2})'); // Rain began at XX past hour
  static final _ceilingVariablePattern = RegExp(r'CIG (\d{3})V(\d{3})'); // Ceiling variable
  static final _pressureTrendPattern = RegExp(r'(PRESFR|PRESRR|PRESFA|PRESRA)'); // Pressure trends
  static final _seaLevelPressurePattern = RegExp(r'SLP(\d{3})'); // Sea-level pressure
  static final _precipitationAmountPattern = RegExp(r'P(\d{4})'); // Precipitation amount
  static final _sixHourPrecipPattern = RegExp(r'6(\d{4})'); // 6-hour precipitation total
  static final _temperatureDewpointPattern = RegExp(r'T(\d{4})(\d{4})'); // Temp/dewpoint extremes
  static final _sixHourMaxTempPattern = RegExp(r'1(\d{3})'); // 6-hour max temp
  static final _sixHourMinTempPattern = RegExp(r'2(\d{3})'); // 6-hour min temp
  static final _automatedStationPattern = RegExp(r'(AO1|AO2)'); // Automated station type
  static final _cloudCoveragePattern = RegExp(r'([A-Z]{2})(\d)([A-Z]{2})(\d)'); // Cloud coverage like CU1SC5
  static final _densityAltitudePattern = RegExp(r'DENSITY ALT (\d+)FT'); // Density altitude

  DecodedWeather decodeMetar(String rawText) {
    final icao = _icaoPattern.firstMatch(rawText)?.group(1) ?? '';
    final timestamp = _parseTimestamp(rawText);
    
    // Parse wind
    final windMatch = _windPattern.firstMatch(rawText);
    String? windDirectionStr;
    int? windSpeed;
    int? windGust;
    if (windMatch != null) {
      windDirectionStr = windMatch.group(1);
      windSpeed = int.tryParse(windMatch.group(2) ?? '');
      windGust = windMatch.group(3) != null ? int.tryParse(windMatch.group(3)!) : null;
    }

    // The rest of the string after the wind group, or the whole string if no wind
    final textAfterWind = windMatch != null ? rawText.substring(windMatch.end) : rawText;
    
    // Parse visibility from the remaining string to avoid capturing time elements
    final visibilityMatch = _visibilityPattern.firstMatch(textAfterWind);
    final visibilitySM_match = _visibilitySMPattern.firstMatch(textAfterWind);

    int? visibility;
    String visibilityUnit = 'm';

    if (visibilitySM_match != null) {
      visibility = int.parse(visibilitySM_match.group(1)!);
      visibilityUnit = 'SM';
    } else if (visibilityMatch != null) {
      visibility = visibilityMatch.group(1) != null ? int.tryParse(visibilityMatch.group(1)!) : null;
    }
    
    // Parse RVR (Runway Visual Range)
    final rvrMatches = _rvrPattern.allMatches(rawText);
    String? rvr;
    if (rvrMatches.isNotEmpty) {
      rvr = rvrMatches.map((m) {
        final runway = m.group(1)!;
        final value = m.group(2)!;
        String prefix = '';
        if (value.startsWith('P')) {
          prefix = '> ';
        } else if (value.startsWith('M')) {
          prefix = '< ';
        }
        final distance = value.replaceAll(RegExp(r'^[PM]'), '');
        return 'R${runway}: ${prefix}${distance}ft';
      }).join(', ');
    }
    
    final isCavok = rawText.contains('CAVOK');
    final isNcd = rawText.contains('NCD');
    
    // Parse clouds
    final cloudMatches = _cloudPattern.allMatches(rawText);
    final cloudCover = cloudMatches.isNotEmpty ? cloudMatches.map((m) => '${m.group(1)}${m.group(2)}').join(' ') : null;
    
    // Parse temperature/dew point
    final tempMatch = _tempDewPattern.firstMatch(rawText);
    final temperature = tempMatch != null ? WeatherParser.parseTemp(tempMatch.group(1)!) : null;
    final dewPoint = tempMatch != null ? WeatherParser.parseTemp(tempMatch.group(2)!) : null;
    
    // Parse pressure
    final pressureMatch = _pressurePattern.firstMatch(rawText);
    final pressureInHgMatch = _pressureInHgPattern.firstMatch(rawText);
    int? qnh;
    String qnhUnit = 'hPa';

    if (pressureInHgMatch != null) {
      qnh = int.parse(pressureInHgMatch.group(1)!);
      qnhUnit = 'inHg';
    } else if (pressureMatch != null) {
      qnh = int.parse(pressureMatch.group(1)!);
    }
    
    // Parse weather conditions only if not CAVOK
    String? conditions;
    String? conditionsDescription;

    if (!isCavok) {
    final weatherMatches = _weatherPattern.allMatches(rawText);
      if (weatherMatches.isNotEmpty) {
        final rawCodes = weatherMatches.map((m) => m.group(1)!).toList();
        conditions = rawCodes.join(' ');
        conditionsDescription = rawCodes.map((code) => WeatherParser.describeConditions(code)).join(', ');
      }
    }
    
    // Parse remarks
    final remarksMatch = _remarksPattern.firstMatch(rawText);
    var remarks = remarksMatch?.group(1)?.trim();

    // Parse comprehensive remarks
    final parsedRemarks = <String>[];
    
    if (remarks != null) {
      // Peak winds
      final peakWindMatch = _peakWindPattern.firstMatch(remarks);
      if (peakWindMatch != null) {
        final direction = peakWindMatch.group(1)!;
        final speed = peakWindMatch.group(2)!;
        final time = peakWindMatch.group(3)!;
        parsedRemarks.add('Peak wind ${direction}° at ${speed}kt at ${time} past hour');
      }
      
      // Wind shifts
      final windShiftMatch = _windShiftPattern.firstMatch(remarks);
      if (windShiftMatch != null) {
        final time = windShiftMatch.group(1)!;
        parsedRemarks.add('Wind shift at ${time.substring(0, 2)}:${time.substring(2)}Z');
      }
      
      // Variable visibility
      final varVisMatch = _variableVisibilityPattern.firstMatch(remarks);
      if (varVisMatch != null) {
        final from = varVisMatch.group(1)!;
        final to = varVisMatch.group(2)!;
        final unit = varVisMatch.group(3)!;
        parsedRemarks.add('Variable visibility from $from to $to $unit');
      }
      
      // Rain begin
      final rainBeginMatch = _rainBeginPattern.firstMatch(remarks);
      if (rainBeginMatch != null) {
        final time = rainBeginMatch.group(1)!;
        parsedRemarks.add('Rain began at $time past hour');
      }
      
      // Ceiling variable
      final ceilingVarMatch = _ceilingVariablePattern.firstMatch(remarks);
      if (ceilingVarMatch != null) {
        final from = int.parse(ceilingVarMatch.group(1)!) * 100;
        final to = int.parse(ceilingVarMatch.group(2)!) * 100;
        parsedRemarks.add('Ceiling variable between ${from}ft and ${to}ft');
      }
      
      // Pressure trends
      final pressureTrendMatch = _pressureTrendPattern.firstMatch(remarks);
      if (pressureTrendMatch != null) {
        final trend = pressureTrendMatch.group(1)!;
        final trendDesc = {
          'PRESFR': 'Pressure falling rapidly',
          'PRESRR': 'Pressure rising rapidly',
          'PRESFA': 'Pressure falling slowly',
          'PRESRA': 'Pressure rising slowly',
        }[trend] ?? trend;
        parsedRemarks.add(trendDesc);
      }
      
      // Sea-level pressure
      final slpMatch = _seaLevelPressurePattern.firstMatch(remarks);
      if (slpMatch != null) {
        final slp = slpMatch.group(1)!;
        final pressure = (1000 + int.parse(slp) / 10).toStringAsFixed(1);
        parsedRemarks.add('Sea-level pressure: ${pressure}hPa');
      }
      
      // Precipitation amounts
      final precipMatch = _precipitationAmountPattern.firstMatch(remarks);
      if (precipMatch != null) {
        final amount = int.parse(precipMatch.group(1)!) / 100;
        parsedRemarks.add('${amount.toStringAsFixed(2)} inches of rain since last METAR');
      }
      
      // 6-hour precipitation
      final sixHourPrecipMatch = _sixHourPrecipPattern.firstMatch(remarks);
      if (sixHourPrecipMatch != null) {
        final amount = int.parse(sixHourPrecipMatch.group(1)!) / 100;
        parsedRemarks.add('6-hour precipitation total: ${amount.toStringAsFixed(2)} inches');
      }
      
      // Temperature/dewpoint extremes
      final tempDewMatch = _temperatureDewpointPattern.firstMatch(remarks);
      if (tempDewMatch != null) {
        final temp = WeatherParser.parseTempExtreme(tempDewMatch.group(1)!);
        final dew = WeatherParser.parseTempExtreme(tempDewMatch.group(2)!);
        parsedRemarks.add('Temperature extremes: ${temp}°C / ${dew}°C');
      }
      
      // 6-hour max temp
      final maxTempMatch = _sixHourMaxTempPattern.firstMatch(remarks);
      if (maxTempMatch != null) {
        final temp = WeatherParser.parseTempExtreme(maxTempMatch.group(1)!);
        parsedRemarks.add('6-hour maximum temperature: ${temp}°C');
      }
      
      // 6-hour min temp
      final minTempMatch = _sixHourMinTempPattern.firstMatch(remarks);
      if (minTempMatch != null) {
        final temp = WeatherParser.parseTempExtreme(minTempMatch.group(1)!);
        parsedRemarks.add('6-hour minimum temperature: ${temp}°C');
      }
      
      // Automated station type
      final autoStationMatch = _automatedStationPattern.firstMatch(remarks);
      if (autoStationMatch != null) {
        final type = autoStationMatch.group(1)!;
        final desc = type == 'AO1' ? 'Automated station without precipitation discriminator' : 'Automated station with precipitation discriminator';
        parsedRemarks.add(desc);
      }
      
      // Cloud coverage (e.g., CU1SC5)
      final cloudCoverageMatch = _cloudCoveragePattern.firstMatch(remarks);
      if (cloudCoverageMatch != null) {
        final cloud1 = cloudCoverageMatch.group(1)!;
        final oktas1 = cloudCoverageMatch.group(2)!;
        final cloud2 = cloudCoverageMatch.group(3)!;
        final oktas2 = cloudCoverageMatch.group(4)!;
        
        final cloud1Desc = WeatherParser.describeCloudType(cloud1);
        final cloud2Desc = WeatherParser.describeCloudType(cloud2);
        
        parsedRemarks.add('Cloud coverage: $oktas1 okta of $cloud1Desc, $oktas2 oktas of $cloud2Desc');
      }
      
      // Density altitude
      final densityAltMatch = _densityAltitudePattern.firstMatch(remarks);
      if (densityAltMatch != null) {
        final altitude = densityAltMatch.group(1)!;
        parsedRemarks.add('Density altitude: ${altitude}ft');
      }
    }

    if (rawText.contains('NOSIG')) {
      parsedRemarks.add('No significant change expected in the next 2 hours');
    }
    
    final finalRemarks = parsedRemarks.isNotEmpty ? parsedRemarks.join('\n') : null;
    
    return DecodedWeather(
      icao: icao,
      timestamp: timestamp,
      rawText: rawText,
      type: 'METAR',
      windDirection: windDirectionStr != null && windDirectionStr != 'VRB' ? int.tryParse(windDirectionStr) : null,
      windSpeed: windSpeed,
      visibility: visibility,
      cloudCover: cloudCover,
      temperature: temperature,
      dewPoint: dewPoint,
      qnh: qnh,
      conditions: conditions,
      remarks: finalRemarks,
      rvr: rvr,
      windDescription: WeatherParser.describeWind(windDirectionStr, windSpeed, windGust),
      visibilityDescription: WeatherParser.describeVisibility(visibility, isCavok, visibilityUnit),
      cloudDescription: WeatherParser.describeClouds(cloudCover, isCavok, isNcd),
      temperatureDescription: WeatherParser.describeTemperature(temperature, dewPoint),
      pressureDescription: WeatherParser.describePressure(qnh, qnhUnit),
      conditionsDescription: conditionsDescription ?? 'No significant weather',
      rvrDescription: WeatherParser.describeRvr(rvr),
      timeline: [],
    );
  }

  DateTime _parseTimestamp(String rawText) {
    final match = _timestampPattern.firstMatch(rawText);
    if (match != null) {
      final timeStr = match.group(1)!;
      final day = int.parse(timeStr.substring(0, 2));
      final hour = int.parse(timeStr.substring(2, 4));
      final minute = int.parse(timeStr.substring(4, 6));
      
      // Assume current month/year for now
      final now = DateTime.now();
      return DateTime(now.year, now.month, day, hour, minute);
    }
    return DateTime.now();
  }
} 