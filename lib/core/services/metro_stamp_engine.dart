import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metro line identifiers across Tashkent rapid transit.
enum MetroLine {
  chilanzar, // Red Line
  uzbekistan, // Blue Line
  yunusabad, // Green Line
}

/// Represents an iconic station on the Tashkent Metro network.
class MetroStation {
  final String id;
  final String name;
  final MetroLine line;
  final double latitude;
  final double longitude;
  final String district;
  final String stampMotif;
  final String stampColorHex;
  final int xpBonus;
  final bool isInterchange;

  const MetroStation({
    required this.id,
    required this.name,
    required this.line,
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.stampMotif,
    required this.stampColorHex,
    this.xpBonus = 25,
    this.isInterchange = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'line': line.name,
    'latitude': latitude,
    'longitude': longitude,
    'district': district,
    'stamp_motif': stampMotif,
    'stamp_color_hex': stampColorHex,
    'xp_bonus': xpBonus,
    'is_interchange': isInterchange,
  };

  factory MetroStation.fromJson(Map<String, dynamic> json) {
    MetroLine parsedLine;
    try {
      parsedLine = MetroLine.values.byName(json['line'] as String? ?? 'chilanzar');
    } catch (_) {
      parsedLine = MetroLine.chilanzar;
    }

    return MetroStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Station',
      line: parsedLine,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      district: json['district'] as String? ?? 'Central',
      stampMotif: json['stamp_motif'] as String? ?? 'Ceramic Medallion',
      stampColorHex: json['stamp_color_hex'] as String? ?? '#E53935',
      xpBonus: (json['xp_bonus'] as num?)?.toInt() ?? 25,
      isInterchange: json['is_interchange'] as bool? ?? false,
    );
  }
}

/// A claimed passport stamp for a metro station check-in.
class MetroStamp {
  final String stationId;
  final String stationName;
  final MetroLine line;
  final String stampMotif;
  final String stampColorHex;
  final DateTime claimedAt;
  final String? placeId;

  const MetroStamp({
    required this.stationId,
    required this.stationName,
    required this.line,
    required this.stampMotif,
    required this.stampColorHex,
    required this.claimedAt,
    this.placeId,
  });

  Map<String, dynamic> toJson() => {
    'station_id': stationId,
    'station_name': stationName,
    'line': line.name,
    'stamp_motif': stampMotif,
    'stamp_color_hex': stampColorHex,
    'claimed_at': claimedAt.toIso8601String(),
    if (placeId != null) 'place_id': placeId,
  };

  factory MetroStamp.fromJson(Map<String, dynamic> json) {
    MetroLine parsedLine;
    try {
      parsedLine = MetroLine.values.byName(json['line'] as String? ?? 'chilanzar');
    } catch (_) {
      parsedLine = MetroLine.chilanzar;
    }

    return MetroStamp(
      stationId: json['station_id'] as String? ?? '',
      stationName: json['station_name'] as String? ?? 'Station',
      line: parsedLine,
      stampMotif: json['stamp_motif'] as String? ?? 'Ceramic Medallion',
      stampColorHex: json['stamp_color_hex'] as String? ?? '#E53935',
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : DateTime.now(),
      placeId: json['place_id'] as String?,
    );
  }
}

/// Line completion progress meter and badge award.
class LineProgress {
  final MetroLine line;
  final int totalStations;
  final int claimedStations;
  final double completionPercentage;
  final bool isCompleted;
  final String badgeTitle;

  const LineProgress({
    required this.line,
    required this.totalStations,
    required this.claimedStations,
    required this.completionPercentage,
    required this.isCompleted,
    required this.badgeTitle,
  });
}

/// Core computational engine for metro station proximity, stamps, and line completion.
class MetroStampEngine {
  static const double proximityThresholdMeters = 600.0;

  static const List<MetroStation> canonicalStations = [
    // Chilanzar Line (Red)
    MetroStation(
      id: 'mustaqillik_maydoni',
      name: 'Mustaqillik Maydoni',
      line: MetroLine.chilanzar,
      latitude: 41.3158,
      longitude: 69.2689,
      district: 'Yunusabad',
      stampMotif: 'White Marble Sunburst',
      stampColorHex: '#E53935',
      isInterchange: false,
    ),
    MetroStation(
      id: 'amir_temur_xiyoboni',
      name: 'Amir Temur Xiyoboni',
      line: MetroLine.chilanzar,
      latitude: 41.3113,
      longitude: 69.2796,
      district: 'Mirabad',
      stampMotif: 'Bronze Dome Ornament',
      stampColorHex: '#E53935',
      isInterchange: true,
    ),
    MetroStation(
      id: 'paxtakor',
      name: 'Paxtakor',
      line: MetroLine.chilanzar,
      latitude: 41.3135,
      longitude: 69.2562,
      district: 'Shaykhontohur',
      stampMotif: 'Cotton Flower Ceramic',
      stampColorHex: '#E53935',
      isInterchange: true,
    ),
    MetroStation(
      id: 'novza',
      name: 'Novza',
      line: MetroLine.chilanzar,
      latitude: 41.2858,
      longitude: 69.2158,
      district: 'Chilanzar',
      stampMotif: 'Terracotta Geometric Star',
      stampColorHex: '#E53935',
      isInterchange: false,
    ),

    // Uzbekistan Line (Blue)
    MetroStation(
      id: 'kosmonavtlar',
      name: 'Kosmonavtlar',
      line: MetroLine.uzbekistan,
      latitude: 41.3094,
      longitude: 69.2678,
      district: 'Yakkasaray',
      stampMotif: 'Cosmos Blue Medallion',
      stampColorHex: '#1E88E5',
      isInterchange: false,
    ),
    MetroStation(
      id: 'alisher_navoiy',
      name: 'Alisher Navoiy',
      line: MetroLine.uzbekistan,
      latitude: 41.3142,
      longitude: 69.2558,
      district: 'Shaykhontohur',
      stampMotif: 'Turquoise Majolica Cupola',
      stampColorHex: '#1E88E5',
      isInterchange: true,
    ),
    MetroStation(
      id: 'chorsu',
      name: 'Chorsu',
      line: MetroLine.uzbekistan,
      latitude: 41.3271,
      longitude: 69.2365,
      district: 'Shaykhontohur',
      stampMotif: 'Turquoise Bazaar Dome',
      stampColorHex: '#1E88E5',
      isInterchange: false,
    ),
    MetroStation(
      id: 'oybek',
      name: 'Oybek',
      line: MetroLine.uzbekistan,
      latitude: 41.2988,
      longitude: 69.2785,
      district: 'Mirabad',
      stampMotif: 'Ceramic Poetry Seal',
      stampColorHex: '#1E88E5',
      isInterchange: true,
    ),

    // Yunusabad Line (Green)
    MetroStation(
      id: 'ming_urik',
      name: 'Ming O\'rik',
      line: MetroLine.yunusabad,
      latitude: 41.2991,
      longitude: 69.2790,
      district: 'Mirabad',
      stampMotif: 'Ancient Citadel Apricot',
      stampColorHex: '#43A047',
      isInterchange: true,
    ),
    MetroStation(
      id: 'bodomzor',
      name: 'Bodomzor',
      line: MetroLine.yunusabad,
      latitude: 41.3418,
      longitude: 69.2842,
      district: 'Yunusabad',
      stampMotif: 'Almond Blossom Glaze',
      stampColorHex: '#43A047',
      isInterchange: false,
    ),
    MetroStation(
      id: 'shahriston',
      name: 'Shahriston',
      line: MetroLine.yunusabad,
      latitude: 41.3551,
      longitude: 69.2885,
      district: 'Yunusabad',
      stampMotif: 'Northern Citadel Wall',
      stampColorHex: '#43A047',
      isInterchange: false,
    ),
    MetroStation(
      id: 'yunus_rajabiy',
      name: 'Yunus Rajabiy',
      line: MetroLine.yunusabad,
      latitude: 41.3117,
      longitude: 69.2801,
      district: 'Mirabad',
      stampMotif: 'Carved Sitora Columns',
      stampColorHex: '#43A047',
      isInterchange: true,
    ),
  ];

  /// Returns all stations on a given metro line.
  List<MetroStation> getStationsByLine(MetroLine line) {
    return canonicalStations.where((s) => s.line == line).toList();
  }

  /// Calculates line completion progress based on user's claimed stamps.
  LineProgress calculateLineProgress(MetroLine line, Set<String> claimedStationIds) {
    final lineStations = getStationsByLine(line);
    if (lineStations.isEmpty) {
      return LineProgress(
        line: line,
        totalStations: 0,
        claimedStations: 0,
        completionPercentage: 0.0,
        isCompleted: false,
        badgeTitle: '',
      );
    }

    int count = 0;
    for (final s in lineStations) {
      if (claimedStationIds.contains(s.id)) {
        count++;
      }
    }

    final percentage = (count / lineStations.length) * 100.0;
    final isCompleted = count == lineStations.length;

    return LineProgress(
      line: line,
      totalStations: lineStations.length,
      claimedStations: count,
      completionPercentage: double.parse(percentage.toStringAsFixed(1)),
      isCompleted: isCompleted,
      badgeTitle: _getLineBadgeTitle(line),
    );
  }

  /// Haversine distance in meters between two GPS coordinates.
  double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Finds the closest station within the proximity threshold (default 600m).
  MetroStation? findNearbyStation(
    double lat,
    double lon, {
    double maxDistanceMeters = proximityThresholdMeters,
  }) {
    MetroStation? closest;
    double minDistance = double.infinity;

    for (final station in canonicalStations) {
      final dist = calculateDistanceMeters(lat, lon, station.latitude, station.longitude);
      if (dist <= maxDistanceMeters && dist < minDistance) {
        minDistance = dist;
        closest = station;
      }
    }

    return closest;
  }

  /// Localized name for a Metro Line.
  String localizedLineName(MetroLine line, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (line) {
      case MetroLine.chilanzar:
        if (lang.startsWith('uz')) return 'Chilonzor yo\'li';
        if (lang.startsWith('ru')) return 'Чиланзарская линия';
        return 'Chilanzar Line';
      case MetroLine.uzbekistan:
        if (lang.startsWith('uz')) return 'O\'zbekiston yo\'li';
        if (lang.startsWith('ru')) return 'Узбекистанская линия';
        return 'Uzbekistan Line';
      case MetroLine.yunusabad:
        if (lang.startsWith('uz')) return 'Yunusobod yo\'li';
        if (lang.startsWith('ru')) return 'Юнусабадская линия';
        return 'Yunusabad Line';
    }
  }

  String _getLineBadgeTitle(MetroLine line) {
    switch (line) {
      case MetroLine.chilanzar:
        return 'Chilanzar Line Nomad';
      case MetroLine.uzbekistan:
        return 'Turquoise Line Wayfarer';
      case MetroLine.yunusabad:
        return 'Northern Line Pioneer';
    }
  }
}

final metroStampEngineProvider = Provider<MetroStampEngine>((ref) {
  return MetroStampEngine();
});
