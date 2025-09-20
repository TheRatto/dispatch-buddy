import '../services/airport_timezone_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class FirstLastLight {
  final String icao;
  final DateTime date;
  final String firstLight;
  final String lastLight;
  final DateTime timestamp;

  const FirstLastLight({
    required this.icao,
    required this.date,
    required this.firstLight,
    required this.lastLight,
    required this.timestamp,
  });

  /// Creates FirstLastLight from API response
  factory FirstLastLight.fromApiResponse({
    required String icao,
    required DateTime date,
    required Map<String, String> data,
  }) {
    return FirstLastLight(
      icao: icao.toUpperCase(),
      date: date,
      firstLight: data['firstLight'] ?? '',
      lastLight: data['lastLight'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'date': date.toIso8601String(),
      'firstLight': firstLight,
      'lastLight': lastLight,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates from JSON
  factory FirstLastLight.fromJson(Map<String, dynamic> json) {
    return FirstLastLight(
      icao: json['icao'] as String,
      date: DateTime.parse(json['date'] as String),
      firstLight: json['firstLight'] as String,
      lastLight: json['lastLight'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts UTC time to airport local time for display
  Future<String> getFirstLightLocal() async {
    try {
      final utcTime = _parseTime(firstLight);
      final airportTime = await _convertToAirportTime(utcTime);
      return '${airportTime.hour.toString().padLeft(2, '0')}${airportTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return firstLight;
    }
  }

  /// Converts UTC time to airport local time for display
  Future<String> getLastLightLocal() async {
    try {
      final utcTime = _parseTime(lastLight);
      final airportTime = await _convertToAirportTime(utcTime);
      return '${airportTime.hour.toString().padLeft(2, '0')}${airportTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return lastLight;
    }
  }

  /// Parses time string (HH:MM format) to DateTime
  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeStr');
    }
    
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    // Use UTC date to ensure consistent timezone handling
    // The date field should represent the date in UTC for the requested day
    final utcDate = date.isUtc ? date : DateTime.utc(date.year, date.month, date.day);
    
    return DateTime.utc(utcDate.year, utcDate.month, utcDate.day, hour, minute);
  }

  /// Converts UTC DateTime to airport local time
  Future<DateTime> _convertToAirportTime(DateTime utcTime) async {
    // Get airport timezone information
    final timezoneInfo = await AirportTimezoneService.getAirportTimezone(icao);
    
    if (timezoneInfo != null) {
      try {
        // Initialize timezone data if not already done
        tz.initializeTimeZones();
        
        // Get the airport's timezone
        final airportTz = tz.getLocation(timezoneInfo.timezone);
        
        // Convert UTC time to airport timezone
        final airportTzTime = tz.TZDateTime.from(utcTime, airportTz);
        
        return airportTzTime;
      } catch (e) {
        // If timezone conversion fails, fall back to device local time
        return utcTime.toLocal();
      }
    } else {
      // If no timezone info available, fall back to device local time
      return utcTime.toLocal();
    }
  }

  /// Gets the airport timezone offset string for display
  Future<String> getAirportTimezoneOffset() async {
    final timezoneInfo = await AirportTimezoneService.getAirportTimezone(icao);
    
    if (timezoneInfo != null) {
      try {
        // Initialize timezone data if not already done
        tz.initializeTimeZones();
        
        // Get the airport's timezone
        final airportTz = tz.getLocation(timezoneInfo.timezone);
        
        // Get current time in airport timezone
        final now = tz.TZDateTime.now(airportTz);
        final offset = now.timeZoneOffset;
        
        final hours = offset.inHours;
        final minutes = (offset.inMinutes % 60).abs();
        
        if (hours >= 0) {
          return '+${hours.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}z';
        } else {
          return '-${hours.abs().toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}z';
        }
      } catch (e) {
        // If timezone conversion fails, fall back to device timezone
        return getTimezoneOffset();
      }
    } else {
      // If no timezone info available, fall back to device timezone
      return getTimezoneOffset();
    }
  }

  /// Gets the device timezone offset string for display (fallback)
  String getTimezoneOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = (offset.inMinutes % 60).abs();
    
    if (hours >= 0) {
      return '+${hours.toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}z';
    } else {
      return '-${hours.abs().toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}z';
    }
  }

  @override
  String toString() {
    return 'FirstLastLight(icao: $icao, date: $date, firstLight: $firstLight, lastLight: $lastLight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirstLastLight &&
        other.icao == icao &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day;
  }

  @override
  int get hashCode {
    return icao.hashCode ^ date.year.hashCode ^ date.month.hashCode ^ date.day.hashCode;
  }
}
