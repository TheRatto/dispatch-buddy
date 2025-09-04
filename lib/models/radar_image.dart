/// Represents a single radar image from BOM
class RadarImage {
  final String siteId;
  final DateTime timestamp;
  final String url;
  final String range;
  final String? localPath;
  final bool isCached;
  final int? fileSizeBytes;
  final RadarLayers? layers; // For multi-layer radar composition

  const RadarImage({
    required this.siteId,
    required this.timestamp,
    required this.url,
    required this.range,
    this.localPath,
    this.isCached = false,
    this.fileSizeBytes,
    this.layers,
  });

  /// Get age of this radar image
  Duration get age => DateTime.now().toUtc().difference(timestamp);

  /// Check if image is recent (within last 30 minutes)
  bool get isRecent => age.inMinutes < 30;

  /// Check if image is current (within last 10 minutes)
  bool get isCurrent => age.inMinutes < 10;

  /// Get formatted timestamp for display (UTC)
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}Z';
  }

  /// Get formatted age for display
  String get formattedAge {
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  /// Create copy with updated properties
  RadarImage copyWith({
    String? siteId,
    DateTime? timestamp,
    String? url,
    String? range,
    String? localPath,
    bool? isCached,
    int? fileSizeBytes,
    RadarLayers? layers,
  }) {
    return RadarImage(
      siteId: siteId ?? this.siteId,
      timestamp: timestamp ?? this.timestamp,
      url: url ?? this.url,
      range: range ?? this.range,
      localPath: localPath ?? this.localPath,
      isCached: isCached ?? this.isCached,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      layers: layers ?? this.layers,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'siteId': siteId,
      'timestamp': timestamp.toIso8601String(),
      'url': url,
      'range': range,
      'localPath': localPath,
      'isCached': isCached,
      'fileSizeBytes': fileSizeBytes,
      'layers': layers?.toJson(),
    };
  }

  /// Create from JSON
  factory RadarImage.fromJson(Map<String, dynamic> json) {
    return RadarImage(
      siteId: json['siteId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      url: json['url'] as String,
      range: json['range'] as String,
      localPath: json['localPath'] as String?,
      isCached: json['isCached'] as bool? ?? false,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      layers: json['layers'] != null ? RadarLayers.fromJson(json['layers']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RadarImage &&
        other.siteId == siteId &&
        other.timestamp == timestamp &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(siteId, timestamp, range);

  @override
  String toString() => 'RadarImage(siteId: $siteId, timestamp: $timestamp, range: $range)';
}

/// Represents the multiple layers that compose a BOM radar image
class RadarLayers {
  final String backgroundUrl;     // IDR402.background.png
  final String? locationsUrl;     // IDR402.locations.png (optional - can be null to hide locations)
  final String rangeUrl;          // IDR402.range.png
  final String topographyUrl;     // IDR402.topography.png
  final String legendUrl;         // IDR.legend.0.png
  final String radarDataUrl;      // IDR402.T.202508300959.png

  const RadarLayers({
    required this.backgroundUrl,
    this.locationsUrl,             // Made optional
    required this.rangeUrl,
    required this.topographyUrl,
    required this.legendUrl,
    required this.radarDataUrl,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'backgroundUrl': backgroundUrl,
      'locationsUrl': locationsUrl, // Can be null
      'rangeUrl': rangeUrl,
      'topographyUrl': topographyUrl,
      'legendUrl': legendUrl,
      'radarDataUrl': radarDataUrl,
    };
  }

  /// Create from JSON
  factory RadarLayers.fromJson(Map<String, dynamic> json) {
    return RadarLayers(
      backgroundUrl: json['backgroundUrl'] as String,
      locationsUrl: json['locationsUrl'] as String?, // Handle nullable
      rangeUrl: json['rangeUrl'] as String,
      topographyUrl: json['topographyUrl'] as String,
      legendUrl: json['legendUrl'] as String,
      radarDataUrl: json['radarDataUrl'] as String,
    );
  }
}
