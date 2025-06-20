class Weather {
  final String icao;
  final DateTime timestamp;
  final String rawText;
  final String decodedText;
  final int windDirection;
  final int windSpeed;
  final int visibility;
  final String cloudCover;
  final double temperature;
  final double dewPoint;
  final int qnh;
  final String conditions;

  Weather({
    required this.icao,
    required this.timestamp,
    required this.rawText,
    required this.decodedText,
    required this.windDirection,
    required this.windSpeed,
    required this.visibility,
    required this.cloudCover,
    required this.temperature,
    required this.dewPoint,
    required this.qnh,
    required this.conditions,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      icao: json['icao'],
      timestamp: DateTime.parse(json['timestamp']),
      rawText: json['rawText'],
      decodedText: json['decodedText'],
      windDirection: json['windDirection'],
      windSpeed: json['windSpeed'],
      visibility: json['visibility'],
      cloudCover: json['cloudCover'],
      temperature: json['temperature'],
      dewPoint: json['dewPoint'],
      qnh: json['qnh'],
      conditions: json['conditions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icao': icao,
      'timestamp': timestamp.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'windDirection': windDirection,
      'windSpeed': windSpeed,
      'visibility': visibility,
      'cloudCover': cloudCover,
      'temperature': temperature,
      'dewPoint': dewPoint,
      'qnh': qnh,
      'conditions': conditions,
    };
  }
} 