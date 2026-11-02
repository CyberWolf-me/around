import 'dart:math' as math;

/// Tashkent Metro Line identifiers.
enum SubwayLine {
  chilonzor,
  ozbekiston,
  yunusobod,
  halqa,
}

extension SubwayLineExtension on SubwayLine {
  String get nameUz {
    switch (this) {
      case SubwayLine.chilonzor:
        return 'Chilonzor yo‘li';
      case SubwayLine.ozbekiston:
        return 'O‘zbekiston yo‘li';
      case SubwayLine.yunusobod:
        return 'Yunusobod yo‘li';
      case SubwayLine.halqa:
        return 'Halqa (Do‘stlik-Qo‘yliq) yo‘li';
    }
  }

  String get nameRu {
    switch (this) {
      case SubwayLine.chilonzor:
        return 'Чиланзарская линия';
      case SubwayLine.ozbekiston:
        return 'Узбекистанская линия';
      case SubwayLine.yunusobod:
        return 'Юнусабадская линия';
      case SubwayLine.halqa:
        return 'Кольцевая линия';
    }
  }

  String get nameEn {
    switch (this) {
      case SubwayLine.chilonzor:
        return 'Chilonzor Line';
      case SubwayLine.ozbekiston:
        return 'Ozbekiston Line';
      case SubwayLine.yunusobod:
        return 'Yunusobod Line';
      case SubwayLine.halqa:
        return 'Circle Line';
    }
  }

  /// Hex color int (0xAARRGGBB) for line badge indicators.
  int get colorHex {
    switch (this) {
      case SubwayLine.chilonzor:
        return 0xFFE53935; // Red
      case SubwayLine.ozbekiston:
        return 0xFF1E88E5; // Blue
      case SubwayLine.yunusobod:
        return 0xFF43A047; // Green
      case SubwayLine.halqa:
        return 0xFFFB8C00; // Orange / Gold
    }
  }
}

/// Metadata representation of a Tashkent Metro station.
class SubwayStation {
  final String id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final SubwayLine line;
  final double latitude;
  final double longitude;
  final String? transferStationId;

  const SubwayStation({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.transferStationId,
  });

  String localizedName(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }
}

/// Proximity match with geodesic distance and estimated walking time.
class SubwayProximityMatch {
  final SubwayStation station;
  final int distanceMeters;
  final int walkingMinutes;

  const SubwayProximityMatch({
    required this.station,
    required this.distanceMeters,
    required this.walkingMinutes,
  });

  /// Formatted transit badge for card footers and headers.
  String getFormattedBadge({String lang = 'en'}) {
    final stName = station.localizedName(lang);
    switch (lang.toLowerCase()) {
      case 'uz':
        return '🚇 $stName • $distanceMeters m ($walkingMinutes daqiqa piyoda)';
      case 'ru':
        return '🚇 $stName • $distanceMeters м ($walkingMinutes мин пешком)';
      case 'en':
      default:
        return '🚇 $stName • ${distanceMeters}m ($walkingMinutes min walk)';
    }
  }
}

/// Tashkent Subway Proximity & Transit Landmark Beacon Engine (`P22-01`).
/// Computes geodesic distance and walking time between venues and Tashkent metro stations.
class SubwayProximityEngine {
  /// Canonical registry of Tashkent metro stations across all active lines.
  static const List<SubwayStation> stations = [
    // --- Chilonzor Line (Red) ---
    SubwayStation(
      id: 'buyuk_ipak_yoli',
      nameUz: 'Buyuk Ipak Yo‘li',
      nameRu: 'Буюк Ипак Йули',
      nameEn: 'Buyuk Ipak Yoli',
      line: SubwayLine.chilonzor,
      latitude: 41.3267,
      longitude: 69.3275,
    ),
    SubwayStation(
      id: 'pushkin',
      nameUz: 'Pushkin',
      nameRu: 'Пушкин',
      nameEn: 'Pushkin',
      line: SubwayLine.chilonzor,
      latitude: 41.3228,
      longitude: 69.3090,
    ),
    SubwayStation(
      id: 'hamid_olimjon',
      nameUz: 'Hamid Olimjon',
      nameRu: 'Хамид Олимджан',
      nameEn: 'Hamid Olimjon',
      line: SubwayLine.chilonzor,
      latitude: 41.3195,
      longitude: 69.2933,
    ),
    SubwayStation(
      id: 'amir_temur_xiyoboni',
      nameUz: 'Amir Temur Xiyoboni',
      nameRu: 'Сквер Амира Темура',
      nameEn: 'Amir Temur Square',
      line: SubwayLine.chilonzor,
      latitude: 41.3130,
      longitude: 69.2798,
      transferStationId: 'yunus_rajabiy',
    ),
    SubwayStation(
      id: 'mustaqillik_maydoni',
      nameUz: 'Mustaqillik Maydoni',
      nameRu: 'Площадь Независимости',
      nameEn: 'Mustaqillik Square',
      line: SubwayLine.chilonzor,
      latitude: 41.3150,
      longitude: 69.2680,
    ),
    SubwayStation(
      id: 'paxtakor',
      nameUz: 'Paxtakor',
      nameRu: 'Пахтакор',
      nameEn: 'Pakhtakor',
      line: SubwayLine.chilonzor,
      latitude: 41.3138,
      longitude: 69.2555,
      transferStationId: 'alisher_navoiy',
    ),
    SubwayStation(
      id: 'xalqlar_dostligi',
      nameUz: 'Xalqlar Do‘stligi',
      nameRu: 'Дружба Народов',
      nameEn: 'People Friendship',
      line: SubwayLine.chilonzor,
      latitude: 41.3106,
      longitude: 69.2439,
    ),
    SubwayStation(
      id: 'milliy_bog',
      nameUz: 'Milliy Bog‘',
      nameRu: 'Национальный Парк',
      nameEn: 'National Park',
      line: SubwayLine.chilonzor,
      latitude: 41.3039,
      longitude: 69.2372,
    ),
    SubwayStation(
      id: 'novza',
      nameUz: 'Novza',
      nameRu: 'Новза',
      nameEn: 'Novza',
      line: SubwayLine.chilonzor,
      latitude: 41.2942,
      longitude: 69.2272,
    ),
    SubwayStation(
      id: 'mirzo_ulugbek',
      nameUz: 'Mirzo Ulug‘bek',
      nameRu: 'Мирзо Улугбек',
      nameEn: 'Mirzo Ulugbek',
      line: SubwayLine.chilonzor,
      latitude: 41.2847,
      longitude: 69.2150,
    ),
    SubwayStation(
      id: 'chilonzor',
      nameUz: 'Chilonzor',
      nameRu: 'Чиланзар',
      nameEn: 'Chilonzor',
      line: SubwayLine.chilonzor,
      latitude: 41.2747,
      longitude: 69.2045,
    ),

    // --- O‘zbekiston Line (Blue) ---
    SubwayStation(
      id: 'beruniy',
      nameUz: 'Beruniy',
      nameRu: 'Беруни',
      nameEn: 'Beruniy',
      line: SubwayLine.ozbekiston,
      latitude: 41.3444,
      longitude: 69.2069,
    ),
    SubwayStation(
      id: 'tinchlik',
      nameUz: 'Tinchlik',
      nameRu: 'Тинчлик',
      nameEn: 'Tinchlik',
      line: SubwayLine.ozbekiston,
      latitude: 41.3347,
      longitude: 69.2192,
    ),
    SubwayStation(
      id: 'chorsu',
      nameUz: 'Chorsu',
      nameRu: 'Чорсу',
      nameEn: 'Chorsu',
      line: SubwayLine.ozbekiston,
      latitude: 41.3267,
      longitude: 69.2375,
    ),
    SubwayStation(
      id: 'gafur_gulom',
      nameUz: 'G‘afur G‘ulom',
      nameRu: 'Гафура Гуляма',
      nameEn: 'Gafur Gulom',
      line: SubwayLine.ozbekiston,
      latitude: 41.3250,
      longitude: 69.2472,
    ),
    SubwayStation(
      id: 'alisher_navoiy',
      nameUz: 'Alisher Navoiy',
      nameRu: 'Алишера Навои',
      nameEn: 'Alisher Navoi',
      line: SubwayLine.ozbekiston,
      latitude: 41.3142,
      longitude: 69.2550,
      transferStationId: 'paxtakor',
    ),
    SubwayStation(
      id: 'ozbekiston',
      nameUz: 'O‘zbekiston',
      nameRu: 'Узбекистанская',
      nameEn: 'Ozbekiston',
      line: SubwayLine.ozbekiston,
      latitude: 41.3094,
      longitude: 69.2611,
    ),
    SubwayStation(
      id: 'kosmonavtlar',
      nameUz: 'Kosmonavtlar',
      nameRu: 'Космонавтов',
      nameEn: 'Kosmonavtlar',
      line: SubwayLine.ozbekiston,
      latitude: 41.3039,
      longitude: 69.2678,
    ),
    SubwayStation(
      id: 'oybek',
      nameUz: 'Oybek',
      nameRu: 'Ойбек',
      nameEn: 'Oybek',
      line: SubwayLine.ozbekiston,
      latitude: 41.2986,
      longitude: 69.2789,
      transferStationId: 'ming_orik',
    ),
    SubwayStation(
      id: 'toshkent',
      nameUz: 'Toshkent',
      nameRu: 'Ташкент',
      nameEn: 'Tashkent',
      line: SubwayLine.ozbekiston,
      latitude: 41.2917,
      longitude: 69.2844,
    ),
    SubwayStation(
      id: 'mashinasozlar',
      nameUz: 'Mashinasozlar',
      nameRu: 'Машиностроителей',
      nameEn: 'Mashinasozlar',
      line: SubwayLine.ozbekiston,
      latitude: 41.2978,
      longitude: 69.3083,
    ),
    SubwayStation(
      id: 'dostlik',
      nameUz: 'Do‘stlik',
      nameRu: 'Дустлик',
      nameEn: 'Dostlik',
      line: SubwayLine.ozbekiston,
      latitude: 41.2950,
      longitude: 69.3242,
      transferStationId: 'dostlik_2',
    ),

    // --- Yunusobod Line (Green) ---
    SubwayStation(
      id: 'ming_orik',
      nameUz: 'Ming O‘rik',
      nameRu: 'Минг Урик',
      nameEn: 'Ming Orik',
      line: SubwayLine.yunusobod,
      latitude: 41.2994,
      longitude: 69.2797,
      transferStationId: 'oybek',
    ),
    SubwayStation(
      id: 'yunus_rajabiy',
      nameUz: 'Yunus Rajabiy',
      nameRu: 'Юнуса Раджаби',
      nameEn: 'Yunus Rajabiy',
      line: SubwayLine.yunusobod,
      latitude: 41.3131,
      longitude: 69.2803,
      transferStationId: 'amir_temur_xiyoboni',
    ),
    SubwayStation(
      id: 'abdulla_qodiriy',
      nameUz: 'Abdulla Qodiriy',
      nameRu: 'Абдуллы Кадыри',
      nameEn: 'Abdulla Qodiriy',
      line: SubwayLine.yunusobod,
      latitude: 41.3217,
      longitude: 69.2806,
    ),
    SubwayStation(
      id: 'minor',
      nameUz: 'Minor',
      nameRu: 'Минор',
      nameEn: 'Minor',
      line: SubwayLine.yunusobod,
      latitude: 41.3294,
      longitude: 69.2831,
    ),
    SubwayStation(
      id: 'bodomzor',
      nameUz: 'Bodomzor',
      nameRu: 'Бадамзар',
      nameEn: 'Bodomzor',
      line: SubwayLine.yunusobod,
      latitude: 41.3389,
      longitude: 69.2847,
    ),
    SubwayStation(
      id: 'shahriston',
      nameUz: 'Shahriston',
      nameRu: 'Шахристан',
      nameEn: 'Shahriston',
      line: SubwayLine.yunusobod,
      latitude: 41.3536,
      longitude: 69.2872,
    ),
    SubwayStation(
      id: 'turkiston',
      nameUz: 'Turkiston',
      nameRu: 'Туркистон',
      nameEn: 'Turkiston',
      line: SubwayLine.yunusobod,
      latitude: 41.3686,
      longitude: 69.2889,
    ),
  ];

  /// Finds the closest subway station to the specified geographical coordinates.
  static SubwayProximityMatch findClosestStation(double lat, double lng) {
    SubwayStation closest = stations.first;
    double minDistance = double.infinity;

    for (final station in stations) {
      final dist = calculateDistanceMeters(lat, lng, station.latitude, station.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closest = station;
      }
    }

    final distMeters = minDistance.round();
    final walkingMinutes = calculateWalkingMinutes(minDistance);

    return SubwayProximityMatch(
      station: closest,
      distanceMeters: distMeters,
      walkingMinutes: walkingMinutes,
    );
  }

  /// Finds all stations within a given radius in meters, sorted by proximity.
  static List<SubwayProximityMatch> findStationsWithinRadius(
    double lat,
    double lng, {
    double maxRadiusMeters = 1500,
  }) {
    final matches = <SubwayProximityMatch>[];

    for (final station in stations) {
      final dist = calculateDistanceMeters(lat, lng, station.latitude, station.longitude);
      if (dist <= maxRadiusMeters) {
        matches.add(SubwayProximityMatch(
          station: station,
          distanceMeters: dist.round(),
          walkingMinutes: calculateWalkingMinutes(dist),
        ));
      }
    }

    matches.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return matches;
  }

  /// Calculates geodesic distance between two coordinates in meters (Haversine formula).
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Estimates walking time in minutes based on ~4.8 km/h (~80 m/min).
  static int calculateWalkingMinutes(double distanceMeters) {
    if (distanceMeters <= 50) return 1;
    return (distanceMeters / 80.0).ceil();
  }

  /// Retrieves station by id.
  static SubwayStation? getStationById(String id) {
    try {
      return stations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves all stations belonging to a specific line.
  static List<SubwayStation> getStationsForLine(SubwayLine line) {
    return stations.where((s) => s.line == line).toList();
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
