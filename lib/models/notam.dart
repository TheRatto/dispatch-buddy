enum NotamType { runway, navaid, taxiway, lighting, procedure, other }

class Notam {
  final String id;
  final String icao;
  final NotamType type;
  final DateTime validFrom;
  final DateTime validTo;
  final String rawText;
  final String decodedText;
  final String affectedSystem;
  final bool isCritical;

  Notam({
    required this.id,
    required this.icao,
    required this.type,
    required this.validFrom,
    required this.validTo,
    required this.rawText,
    required this.decodedText,
    required this.affectedSystem,
    required this.isCritical,
  });

  factory Notam.fromJson(Map<String, dynamic> json) {
    return Notam(
      id: json['id'],
      icao: json['icao'],
      type: NotamType.values.firstWhere((e) => e.toString() == 'NotamType.${json['type']}'),
      validFrom: DateTime.parse(json['validFrom']),
      validTo: DateTime.parse(json['validTo']),
      rawText: json['rawText'],
      decodedText: json['decodedText'],
      affectedSystem: json['affectedSystem'],
      isCritical: json['isCritical'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icao': icao,
      'type': type.toString().split('.').last,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'rawText': rawText,
      'decodedText': decodedText,
      'affectedSystem': affectedSystem,
      'isCritical': isCritical,
    };
  }
} 