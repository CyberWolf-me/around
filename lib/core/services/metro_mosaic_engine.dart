import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Metro line taxonomy for Tashkent Subway.
enum MetroLine {
  chilanzar(
    id: 'chilanzar',
    nameUz: "Chilonzor yo'li",
    nameRu: 'Чиланзарская линия',
    nameEn: 'Chilanzar Line',
    colorHex: '#E53935',
    openingYear: 1977,
  ),
  uzbekistan(
    id: 'uzbekistan',
    nameUz: "O'zbekiston yo'li",
    nameRu: 'Узбекистанская линия',
    nameEn: 'Uzbekistan Line',
    colorHex: '#1E88E5',
    openingYear: 1984,
  ),
  yunusabad(
    id: 'yunusabad',
    nameUz: 'Yunusobod yo\'li',
    nameRu: 'Юнусабадская линия',
    nameEn: 'Yunusabad Line',
    colorHex: '#43A047',
    openingYear: 2001,
  ),
  circle(
    id: 'circle',
    nameUz: "Halqa yo'li",
    nameRu: 'Кольцевая линия',
    nameEn: 'Circle Line',
    colorHex: '#FBC02D',
    openingYear: 2020,
  );

  final String id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String colorHex;
  final int openingYear;

  const MetroLine({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.colorHex,
    required this.openingYear,
  });

  static MetroLine fromId(String id) {
    return MetroLine.values.firstWhere(
      (line) => line.id == id,
      orElse: () => MetroLine.uzbekistan,
    );
  }
}

/// Architectural Station Metadata Model.
class MetroStationModel {
  final String id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final MetroLine line;
  final int openingYear;
  final String architect;
  final String mosaicArtist;
  final String architecturalStyle;
  final String mosaicDescription;
  final String marblePillars;
  final String lightingStyle;
  final String audioGuideTrackUrl;
  final String audioGuideSnippetUz;
  final String audioGuideSnippetRu;
  final String audioGuideSnippetEn;
  final double latitude;
  final double longitude;
  final int stampPoints;

  const MetroStationModel({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.line,
    required this.openingYear,
    required this.architect,
    required this.mosaicArtist,
    required this.architecturalStyle,
    required this.mosaicDescription,
    required this.marblePillars,
    required this.lightingStyle,
    required this.audioGuideTrackUrl,
    required this.audioGuideSnippetUz,
    required this.audioGuideSnippetRu,
    required this.audioGuideSnippetEn,
    required this.latitude,
    required this.longitude,
    this.stampPoints = 30,
  });

  String localizedName(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
      default:
        return nameEn;
    }
  }

  String localizedAudioSnippet(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return audioGuideSnippetUz;
      case 'ru':
        return audioGuideSnippetRu;
      case 'en':
      default:
        return audioGuideSnippetEn;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_uz': nameUz,
        'name_ru': nameRu,
        'name_en': nameEn,
        'line': line.id,
        'opening_year': openingYear,
        'architect': architect,
        'mosaic_artist': mosaicArtist,
        'architectural_style': architecturalStyle,
        'mosaic_description': mosaicDescription,
        'marble_pillars': marblePillars,
        'lighting_style': lightingStyle,
        'audio_guide_track_url': audioGuideTrackUrl,
        'audio_guide_snippet_uz': audioGuideSnippetUz,
        'audio_guide_snippet_ru': audioGuideSnippetRu,
        'audio_guide_snippet_en': audioGuideSnippetEn,
        'latitude': latitude,
        'longitude': longitude,
        'stamp_points': stampPoints,
      };

  factory MetroStationModel.fromJson(Map<String, dynamic> json) {
    return MetroStationModel(
      id: json['id'] as String,
      nameUz: json['name_uz'] as String? ?? '',
      nameRu: json['name_ru'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      line: MetroLine.fromId(json['line'] as String? ?? 'uzbekistan'),
      openingYear: (json['opening_year'] as num?)?.toInt() ?? 1984,
      architect: json['architect'] as String? ?? '',
      mosaicArtist: json['mosaic_artist'] as String? ?? '',
      architecturalStyle: json['architectural_style'] as String? ?? '',
      mosaicDescription: json['mosaic_description'] as String? ?? '',
      marblePillars: json['marble_pillars'] as String? ?? '',
      lightingStyle: json['lighting_style'] as String? ?? '',
      audioGuideTrackUrl: json['audio_guide_track_url'] as String? ?? '',
      audioGuideSnippetUz: json['audio_guide_snippet_uz'] as String? ?? '',
      audioGuideSnippetRu: json['audio_guide_snippet_ru'] as String? ?? '',
      audioGuideSnippetEn: json['audio_guide_snippet_en'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      stampPoints: (json['stamp_points'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Digital Visit Stamp for Station Exploration.
class MetroVisitStamp {
  final String stationId;
  final DateTime visitedAt;
  final String? photoProofUrl;
  final String? notes;
  final int pointsEarned;

  const MetroVisitStamp({
    required this.stationId,
    required this.visitedAt,
    this.photoProofUrl,
    this.notes,
    this.pointsEarned = 30,
  });

  Map<String, dynamic> toJson() => {
        'station_id': stationId,
        'visited_at': visitedAt.toIso8601String(),
        'photo_proof_url': photoProofUrl,
        'notes': notes,
        'points_earned': pointsEarned,
      };

  factory MetroVisitStamp.fromJson(Map<String, dynamic> json) {
    return MetroVisitStamp(
      stationId: json['station_id'] as String,
      visitedAt: DateTime.tryParse(json['visited_at'] as String? ?? '') ?? DateTime.now(),
      photoProofUrl: json['photo_proof_url'] as String?,
      notes: json['notes'] as String?,
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Line Exploration Progress and Trophy Badge.
class LineExplorationBadge {
  final MetroLine line;
  final bool isUnlocked;
  final int stationsVisited;
  final int totalStations;
  final double completionPercent;
  final String badgeTitleUz;
  final String badgeTitleRu;
  final String badgeTitleEn;

  const LineExplorationBadge({
    required this.line,
    required this.isUnlocked,
    required this.stationsVisited,
    required this.totalStations,
    required this.completionPercent,
    required this.badgeTitleUz,
    required this.badgeTitleRu,
    required this.badgeTitleEn,
  });

  String localizedBadgeTitle(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return badgeTitleUz;
      case 'ru':
        return badgeTitleRu;
      case 'en':
      default:
        return badgeTitleEn;
    }
  }
}

/// Domain Service Engine for Metro Architecture & Ceramic Mosaics.
class MetroMosaicEngine {
  final List<MetroStationModel> stations;

  MetroMosaicEngine({List<MetroStationModel>? stations})
      : stations = stations ?? defaultStations;

  /// Curated canonical architectural masterpieces of Tashkent Metro.
  static final List<MetroStationModel> defaultStations = [
    const MetroStationModel(
      id: 'kosmonavtlar',
      nameUz: 'Kosmonavtlar',
      nameRu: 'Космонавтов',
      nameEn: 'Cosmonauts',
      line: MetroLine.uzbekistan,
      openingYear: 1984,
      architect: 'S. Sultonov',
      mosaicArtist: 'Arnold Gan',
      architecturalStyle: 'Cosmic Soviet Futurism & Ceramic Medallions',
      mosaicDescription:
          'Deep midnight-blue to black ceramic gradient walls echoing atmospheric entry, with ceramic medallions honoring Yuri Gagarin, Valentina Tereshkova, and astronomer Mirzo Ulugbek.',
      marblePillars: 'Deep blue-grey granite and ribbed cylindrical columns',
      lightingStyle: 'Illuminated floating glass orb chandeliers resembling the Milky Way galaxy',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/kosmonavtlar_en.mp3',
      audioGuideSnippetUz:
          'Kosmonavtlar bekati - koinotga sayohat hissini uyg\'otuvchi keramika ustalari Gan va Sultonov asari.',
      audioGuideSnippetRu:
          'Станция Космонавтов — погружение в открытый космос с медальонами Гагарина и Улугбека.',
      audioGuideSnippetEn:
          'Cosmonauts Station evokes a descent into deep cosmos with gradient cerulean tiles and astronomical medallions.',
      latitude: 41.3094,
      longitude: 69.2625,
      stampPoints: 30,
    ),
    const MetroStationModel(
      id: 'alisher_navoiy',
      nameUz: 'Alisher Navoiy',
      nameRu: 'Алишера Навои',
      nameEn: 'Alisher Navoi',
      line: MetroLine.uzbekistan,
      openingYear: 1984,
      architect: 'R. Fayzullayev',
      mosaicArtist: 'Chinghiz Akhmarov',
      architecturalStyle: 'Timurid Vaulted Blue Cupolas & Epic Poem Frescoes',
      mosaicDescription:
          'Intricate vaulted cupolas inspired by Samarkand madrasahs, featuring majolica blue medallions illustrating scenes from Navoi\'s legendary Khamsa epic.',
      marblePillars: 'White Kyzylkum marble arches and octagonal stalactite capitals',
      lightingStyle: 'Chiseled brass hanging mosque-style chandeliers casting lace shadows',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/alisher_navoiy_en.mp3',
      audioGuideSnippetUz:
          'Alisher Navoiy bekati Temuriylar me\'morchiligi va Xamsa dostonining eng nafis tasvirlariga ega.',
      audioGuideSnippetRu:
          'Станция Алишера Навои — шедевр восточной архитектуры с куполами и панно по мотивам Хамсы.',
      audioGuideSnippetEn:
          'Alisher Navoi Station presents vaulted turquoise cupolas depicting five legendary tales from the Khamsa epic.',
      latitude: 41.3197,
      longitude: 69.2558,
      stampPoints: 30,
    ),
    const MetroStationModel(
      id: 'pakhtakor',
      nameUz: 'Paxtakor',
      nameRu: 'Пахтакор',
      nameEn: 'Pakhtakor',
      line: MetroLine.chilanzar,
      openingYear: 1977,
      architect: 'A. Tabibov',
      mosaicArtist: 'V. Burmakin',
      architecturalStyle: 'Ceramic Cotton Blossom Majolica & Smalt Arabesques',
      mosaicDescription:
          'Dynamic flowing mosaics made of Tashkent smalt and glazed ceramics portraying blooming cotton bolls and solar swirls in jade, cobalt, and golden ochre.',
      marblePillars: 'Gazgan pink and white marble fluted columns',
      lightingStyle: 'Recessed geometric luminaire coffers embedded in the coffered ceiling',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/pakhtakor_en.mp3',
      audioGuideSnippetUz:
          'Paxtakor bekati 1977 yilda ochilgan bo\'lib, paxta gullari va quyosh nurlarining smalta mozaikasi bilan mashhur.',
      audioGuideSnippetRu:
          'Станция Пахтакор украшена яркой смальтовой мозаикой цветущего хлопчатника и солнца.',
      audioGuideSnippetEn:
          'Pakhtakor Station is celebrated for its radiant smalt mosaics weaving cotton blossoms and solar arabesques.',
      latitude: 41.3189,
      longitude: 69.2562,
      stampPoints: 30,
    ),
    const MetroStationModel(
      id: 'mustaqillik_maydoni',
      nameUz: 'Mustaqillik Maydoni',
      nameRu: 'Площадь Независимости',
      nameEn: 'Independence Square',
      line: MetroLine.chilanzar,
      openingYear: 1977,
      architect: 'L. Adamov',
      mosaicArtist: 'Uzbekistan National Studio',
      architecturalStyle: 'Neoclassical Ceremonial Marble & Crystal Chandeliers',
      mosaicDescription:
          'Polished Gazgan marble halls with geometric star marquetry floors and luminous alabaster cornices symbolizing independence and celebration.',
      marblePillars: 'Fluted white Gazgan marble pillars topped with gilded capital leaves',
      lightingStyle: 'Massive tiered crystal chandeliers evoking celebratory ceremonial palace halls',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/mustaqillik_en.mp3',
      audioGuideSnippetUz:
          'Mustaqillik Maydoni bekati o\'zining hashamatli marmar ustunlari va billur qandillari bilan ajralib turadi.',
      audioGuideSnippetRu:
          'Станция Мустакиллик Майдони — величественный белый мрамор и хрустальные дворцовые люстры.',
      audioGuideSnippetEn:
          'Independence Square Station features ceremonial white marble colonnades and tiered crystal chandeliers.',
      latitude: 41.3167,
      longitude: 69.2685,
      stampPoints: 30,
    ),
    const MetroStationModel(
      id: 'bodomzor',
      nameUz: 'Bodomzor',
      nameRu: 'Бадамзар',
      nameEn: 'Bodomzor',
      line: MetroLine.yunusabad,
      openingYear: 2001,
      architect: 'A. Adylov',
      mosaicArtist: 'Usto R. Tokhtayev',
      architecturalStyle: 'Modernist Ceramic Filigree & Almond Blossom Lanterns',
      mosaicDescription:
          'Geometric ceramic relief friezes reflecting almond trees (bodom), paired with undulating ceiling plasterwork and stylized branch motifs.',
      marblePillars: 'Curved light Nurata marble benches and circular central pedestals',
      lightingStyle: 'Pod-like sculptural almond-shaped frosted acrylic luminaires',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/bodomzor_en.mp3',
      audioGuideSnippetUz:
          'Bodomzor bekati bodom gullari shaklidagi zamonaviy yoritgichlari va nafis keramikasi bilan ajralib turadi.',
      audioGuideSnippetRu:
          'Станция Бодомзор известна оригинальными светильниками в форме миндаля и бирюзовым декором.',
      audioGuideSnippetEn:
          'Bodomzor Station features sculptural almond-shaped light pods and delicate ceramic relief patterns.',
      latitude: 41.3417,
      longitude: 69.2842,
      stampPoints: 30,
    ),
    const MetroStationModel(
      id: 'beruniy',
      nameUz: 'Beruniy',
      nameRu: 'Беруни',
      nameEn: 'Beruniy',
      line: MetroLine.uzbekistan,
      openingYear: 1991,
      architect: 'S. Sultonov',
      mosaicArtist: 'A. Rakhmatullaev',
      architecturalStyle: 'High Geometric Domes & Astrolabe Reliefs',
      mosaicDescription:
          'Massive spherical tiled cupolas echoing Abu Rayhan al-Biruni\'s spherical trigonometry, adorned with bronze astrolabe emblems and astronomical constellations.',
      marblePillars: 'Polished grey marble arches with interlocking Islamic geometric friezes',
      lightingStyle: 'Concentric ring luminaires representing planetary orbits',
      audioGuideTrackUrl: 'https://cdn.around.uz/audio/metro/beruniy_en.mp3',
      audioGuideSnippetUz:
          'Beruniy bekati buyuk allomaning falakiyot va matematika kashfiyotlariga bag\'ishlangan gumbazlarga ega.',
      audioGuideSnippetRu:
          'Станция Беруни — планетарные своды и астролябии в честь великого средневекового энциклопедиста.',
      audioGuideSnippetEn:
          'Beruniy Station honors the polymath Al-Biruni with astronomical domes and planetary orbit chandeliers.',
      latitude: 41.3444,
      longitude: 69.2065,
      stampPoints: 30,
    ),
  ];

  /// Returns all stations on a particular metro line.
  List<MetroStationModel> getStationsByLine(MetroLine line) {
    return stations.where((s) => s.line == line).toList();
  }

  /// Locates station by unique identifier.
  MetroStationModel? findStationById(String id) {
    try {
      return stations.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Calculates geodesic distance using Haversine formula in kilometers.
  double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Proximity check for station stamp check-in (within maxDistanceMeters, default 500m).
  bool isNearStation(
    double userLat,
    double userLon,
    MetroStationModel station, {
    double maxDistanceMeters = 500,
  }) {
    final distKm = calculateDistanceKm(userLat, userLon, station.latitude, station.longitude);
    return (distKm * 1000.0) <= maxDistanceMeters;
  }

  /// Calculates exploration progress for a specific Metro line.
  LineExplorationBadge calculateLineExploration(
    MetroLine line,
    List<String> visitedStationIds,
  ) {
    final lineStations = getStationsByLine(line);
    final total = lineStations.length;
    if (total == 0) {
      return LineExplorationBadge(
        line: line,
        isUnlocked: false,
        stationsVisited: 0,
        totalStations: 0,
        completionPercent: 0.0,
        badgeTitleUz: '${line.nameUz} kashfiyotchisi',
        badgeTitleRu: 'Исследователь (${line.nameRu})',
        badgeTitleEn: '${line.nameEn} Explorer',
      );
    }

    final visitedCount = lineStations
        .where((s) => visitedStationIds.contains(s.id))
        .length;
    final percent = (visitedCount / total) * 100.0;
    final isUnlocked = visitedCount == total;

    return LineExplorationBadge(
      line: line,
      isUnlocked: isUnlocked,
      stationsVisited: visitedCount,
      totalStations: total,
      completionPercent: percent,
      badgeTitleUz: '${line.nameUz} Ustasi',
      badgeTitleRu: 'Мастер (${line.nameRu})',
      badgeTitleEn: '${line.nameEn} Master Explorer',
    );
  }

  /// Overall exploration telemetry across all Tashkent stations.
  Map<String, dynamic> calculateOverallExploration(List<String> visitedStationIds) {
    final total = stations.length;
    final visitedCount = stations.where((s) => visitedStationIds.contains(s.id)).length;
    final percent = total > 0 ? (visitedCount / total) * 100.0 : 0.0;
    final totalXp = stations
        .where((s) => visitedStationIds.contains(s.id))
        .fold<int>(0, (sum, s) => sum + s.stampPoints);

    return {
      'total_stations': total,
      'visited_count': visitedCount,
      'completion_percentage': percent,
      'total_xp_earned': totalXp,
      'all_lines_unlocked': visitedCount == total,
    };
  }

  /// Creates a validated visit stamp.
  MetroVisitStamp collectStamp({
    required String stationId,
    String? notes,
    String? photoProofUrl,
  }) {
    final station = findStationById(stationId);
    final points = station?.stampPoints ?? 30;

    return MetroVisitStamp(
      stationId: stationId,
      visitedAt: DateTime.now(),
      photoProofUrl: photoProofUrl,
      notes: notes,
      pointsEarned: points,
    );
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

/// Riverpod Provider for MetroMosaicEngine.
final metroMosaicEngineProvider = Provider<MetroMosaicEngine>((ref) {
  return MetroMosaicEngine();
});
