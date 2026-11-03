import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Heat intensity levels for a neighborhood cluster.
enum ClusterIntensity {
  serene, // 1-2 drops
  lively, // 3-5 drops
  buzzing, // 6-10 drops
  peak, // 11+ drops
}

/// An individual spatial drop point before aggregation.
class SpatialDropPoint {
  final String id;
  final double latitude;
  final double longitude;
  final String placeName;
  final String district;
  final DateTime createdAt;

  const SpatialDropPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.district,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'place_name': placeName,
    'district': district,
    'created_at': createdAt.toIso8601String(),
  };

  factory SpatialDropPoint.fromJson(Map<String, dynamic> json) {
    return SpatialDropPoint(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      placeName: json['place_name'] as String? ?? 'Spot',
      district: json['district'] as String? ?? 'Mirabad',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// A privacy-safe spatial cluster of community activity.
class NeighborhoodCluster {
  final String id;
  final double centroidLat;
  final double centroidLng;
  final String district;
  final ClusterIntensity intensity;
  final int dropsCount;
  final List<String> venueNames;
  final String primaryVenueName;
  final double radiusMeters;

  const NeighborhoodCluster({
    required this.id,
    required this.centroidLat,
    required this.centroidLng,
    required this.district,
    required this.intensity,
    required this.dropsCount,
    required this.venueNames,
    required this.primaryVenueName,
    this.radiusMeters = 350.0,
  });

  String get intensityEmoji {
    switch (intensity) {
      case ClusterIntensity.serene:
        return '🍃';
      case ClusterIntensity.lively:
        return '✨';
      case ClusterIntensity.buzzing:
        return '🔥';
      case ClusterIntensity.peak:
        return '⚡';
    }
  }

  String localizedIntensityLabel({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (intensity) {
      case ClusterIntensity.serene:
        if (lang.startsWith('uz')) return 'Sokin Hudud';
        if (lang.startsWith('ru')) return 'Спокойный уголок';
        return 'Serene Spot';
      case ClusterIntensity.lively:
        if (lang.startsWith('uz')) return 'Jonli Muhit';
        if (lang.startsWith('ru')) return 'Оживленное место';
        return 'Lively Spot';
      case ClusterIntensity.buzzing:
        if (lang.startsWith('uz')) return 'Qaynoq Nuqta';
        if (lang.startsWith('ru')) return 'Бурлящая точка';
        return 'Buzzing Hotspot';
      case ClusterIntensity.peak:
        if (lang.startsWith('uz')) return 'Eng Ommabop Markaz';
        if (lang.startsWith('ru')) return 'Пик активности';
        return 'Peak Activity Center';
    }
  }

  String localizedSummary({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    if (lang.startsWith('uz')) {
      return '$primaryVenueName va yaqinida $dropsCount ta drop';
    } else if (lang.startsWith('ru')) {
      return '$dropsCount дроп(ов) в районе $primaryVenueName и рядом';
    }
    return '$dropsCount drops across $primaryVenueName & nearby';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'centroid_lat': centroidLat,
    'centroid_lng': centroidLng,
    'district': district,
    'intensity': intensity.name,
    'drops_count': dropsCount,
    'venue_names': venueNames,
    'primary_venue_name': primaryVenueName,
    'radius_meters': radiusMeters,
  };

  factory NeighborhoodCluster.fromJson(Map<String, dynamic> json) {
    ClusterIntensity parsedIntensity;
    final rawIntensity = json['intensity'] as String? ?? 'serene';
    try {
      parsedIntensity = ClusterIntensity.values.byName(rawIntensity);
    } catch (_) {
      parsedIntensity = ClusterIntensity.serene;
    }

    final rawVenues = json['venue_names'] as List? ?? [];
    final venues = rawVenues.map((v) => v.toString()).toList();

    return NeighborhoodCluster(
      id: json['id'] as String? ?? '',
      centroidLat: (json['centroid_lat'] as num?)?.toDouble() ?? 41.311081,
      centroidLng: (json['centroid_lng'] as num?)?.toDouble() ?? 69.240562,
      district: json['district'] as String? ?? 'Mirabad',
      intensity: parsedIntensity,
      dropsCount: json['drops_count'] as int? ?? 1,
      venueNames: venues,
      primaryVenueName: json['primary_venue_name'] as String? ?? (venues.isNotEmpty ? venues[0] : 'Local spot'),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 350.0,
    );
  }
}

/// Computes privacy-safe spatial clustering and heat intensity for Tashkent neighborhood drops.
class NeighborhoodClusterEngine {
  // Grid cell dimensions representing approx 350 meters in Tashkent
  static const double _gridStepLat = 0.00315;
  static const double _gridStepLng = 0.00421;

  /// Aggregates individual spatial drops into neighborhood clusters.
  List<NeighborhoodCluster> clusterDrops(List<SpatialDropPoint> drops) {
    if (drops.isEmpty) return const [];

    final Map<String, List<SpatialDropPoint>> cells = {};

    for (final drop in drops) {
      final cellX = (drop.latitude / _gridStepLat).round();
      final cellY = (drop.longitude / _gridStepLng).round();
      final cellKey = '${drop.district}_${cellX}_$cellY';

      cells.putIfAbsent(cellKey, () => []).add(drop);
    }

    final clusters = <NeighborhoodCluster>[];

    for (final entry in cells.entries) {
      final cellDrops = entry.value;
      if (cellDrops.isEmpty) continue;

      double sumLat = 0.0;
      double sumLng = 0.0;
      final venueSet = <String>{};

      for (final d in cellDrops) {
        sumLat += d.latitude;
        sumLng += d.longitude;
        if (d.placeName.trim().isNotEmpty) {
          venueSet.add(d.placeName.trim());
        }
      }

      // Obfuscate centroid to 4 decimal places (~11m precision) to preserve dual-layer privacy
      final rawLat = sumLat / cellDrops.length;
      final rawLng = sumLng / cellDrops.length;
      final centroidLat = double.parse(rawLat.toStringAsFixed(4));
      final centroidLng = double.parse(rawLng.toStringAsFixed(4));

      final count = cellDrops.length;
      final intensity = calculateIntensity(count);
      final venueList = venueSet.toList();
      final primaryVenue = venueList.isNotEmpty ? venueList[0] : 'Local Spot';

      clusters.add(NeighborhoodCluster(
        id: 'cluster_${entry.key}',
        centroidLat: centroidLat,
        centroidLng: centroidLng,
        district: cellDrops[0].district,
        intensity: intensity,
        dropsCount: count,
        venueNames: venueList,
        primaryVenueName: primaryVenue,
      ));
    }

    // Sort descending by drops count (hottest clusters first)
    clusters.sort((a, b) => b.dropsCount.compareTo(a.dropsCount));
    return clusters;
  }

  /// Calculates intensity tier according to activity density.
  ClusterIntensity calculateIntensity(int dropsCount) {
    if (dropsCount >= 11) return ClusterIntensity.peak;
    if (dropsCount >= 6) return ClusterIntensity.buzzing;
    if (dropsCount >= 3) return ClusterIntensity.lively;
    return ClusterIntensity.serene;
  }
}

final neighborhoodClusterEngineProvider = Provider<NeighborhoodClusterEngine>((ref) {
  return NeighborhoodClusterEngine();
});
