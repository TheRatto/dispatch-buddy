/// Briefing Model
/// 
/// Represents a saved briefing with all associated data including
/// airports, NOTAMs, weather, and user metadata.
class Briefing {
  final String id;
  final String? name;
  final List<String> airports;
  final Map<String, dynamic> notams;
  final Map<String, dynamic> weather;
  final DateTime timestamp;
  final bool isFlagged;
  final String? userNotes;

  const Briefing({
    required this.id,
    this.name,
    required this.airports,
    required this.notams,
    required this.weather,
    required this.timestamp,
    this.isFlagged = false,
    this.userNotes,
  });

  /// Create a new briefing with current timestamp
  factory Briefing.create({
    String? name,
    required List<String> airports,
    required Map<String, dynamic> notams,
    required Map<String, dynamic> weather,
    bool isFlagged = false,
    String? userNotes,
  }) {
    final now = DateTime.now();
    final id = 'briefing_${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return Briefing(
      id: id,
      name: name,
      airports: airports,
      notams: notams,
      weather: weather,
      timestamp: now,
      isFlagged: isFlagged,
      userNotes: userNotes,
    );
  }

  /// Create a copy of this briefing with updated fields
  Briefing copyWith({
    String? id,
    String? name,
    List<String>? airports,
    Map<String, dynamic>? notams,
    Map<String, dynamic>? weather,
    DateTime? timestamp,
    bool? isFlagged,
    String? userNotes,
  }) {
    return Briefing(
      id: id ?? this.id,
      name: name, // Allow explicit null values
      airports: airports ?? this.airports,
      notams: notams ?? this.notams,
      weather: weather ?? this.weather,
      timestamp: timestamp ?? this.timestamp,
      isFlagged: isFlagged ?? this.isFlagged,
      userNotes: userNotes, // Allow explicit null values
    );
  }

  /// Convert briefing to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'airports': airports,
      'notams': notams,
      'weather': weather,
      'timestamp': timestamp.toIso8601String(),
      'isFlagged': isFlagged,
      'userNotes': userNotes,
    };
  }

  /// Create briefing from JSON
  factory Briefing.fromJson(Map<String, dynamic> json) {
    return Briefing(
      id: json['id'] as String,
      name: json['name'] as String?,
      airports: List<String>.from(json['airports'] as List),
      notams: Map<String, dynamic>.from(json['notams'] as Map),
      weather: Map<String, dynamic>.from(json['weather'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFlagged: json['isFlagged'] as bool? ?? false,
      userNotes: json['userNotes'] as String?,
    );
  }

  /// Get display name for the briefing
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    // Generate name from airports if no custom name
    if (airports.isNotEmpty) {
      return airports.take(3).join(' ');
    }
    return 'Briefing ${id.split('_').last}';
  }

  /// Get primary airports (first 3)
  List<String> get primaryAirports {
    return airports.take(3).toList();
  }

  /// Get alternate airports (after first 3)
  List<String> get alternateAirports {
    return airports.skip(3).toList();
  }

  /// Get total number of NOTAMs across all airports
  int get totalNotams {
    int count = 0;
    for (final airportNotams in notams.values) {
      if (airportNotams is List) {
        count += airportNotams.length;
      }
    }
    return count;
  }

  /// Get age of briefing data in hours
  int get ageInHours {
    final now = DateTime.now();
    return now.difference(timestamp).inHours;
  }

  /// Check if briefing data is fresh (< 12 hours)
  bool get isFresh => ageInHours < 12;

  /// Check if briefing data is stale (12-24 hours)
  bool get isStale => ageInHours >= 12 && ageInHours < 24;

  /// Check if briefing data is expired (> 24 hours)
  bool get isExpired => ageInHours >= 24;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Briefing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Briefing(id: $id, name: $name, airports: $airports, timestamp: $timestamp, isFlagged: $isFlagged)';
  }
} 