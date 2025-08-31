/// Represents an Australian Bureau of Meteorology radar site
class RadarSite {
  final String id;
  final String name;
  final String location;
  final String state;
  final double latitude;
  final double longitude;
  final List<String> availableRanges;
  final bool isActive;
  final String? description;

  const RadarSite({
    required this.id,
    required this.name,
    required this.location,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.availableRanges,
    this.isActive = true,
    this.description,
  });

  /// Get display name for UI
  String get displayName => '$name ($location)';

  /// Check if this radar site supports the given range
  bool supportsRange(String range) => availableRanges.contains(range);

  /// Get state abbreviation for UI
  String get stateCode => state;



  /// Get default range (prefer 256km, fallback to first available)
  String get defaultRange {
    if (availableRanges.contains('256km')) return '256km';
    return availableRanges.isNotEmpty ? availableRanges.first : '256km';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'availableRanges': availableRanges,
      'isActive': isActive,
      'description': description,
    };
  }

  /// Create from JSON
  factory RadarSite.fromJson(Map<String, dynamic> json) {
    return RadarSite(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      state: json['state'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      availableRanges: List<String>.from(json['availableRanges'] as List),
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RadarSite && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RadarSite(id: $id, name: $name, location: $location)';
}
