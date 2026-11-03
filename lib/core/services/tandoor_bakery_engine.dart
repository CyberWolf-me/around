import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Traditional Uzbek bread varieties baked in clay tandoor ovens.
enum BreadVariety {
  obiNon(
    id: 'obi_non',
    nameEn: 'Obi Non (Classic Sourdough)',
    nameUz: 'Obi non (Klassik tandir noni)',
    nameRu: 'Оби нон (Классический тандырный)',
    defaultPriceUzs: 4000,
    optimalOvenTempCelsius: 280,
    description: 'The golden daily staple leavened with hop sourdough, crisp rim, and nigella seed garnish.',
  ),
  patir(
    id: 'patir',
    nameEn: 'Patir Non (Flaky Butter Crust)',
    nameUz: 'Patir non (Qatlama sariyog\'li)',
    nameRu: 'Патыр нон (Слоеный праздничный)',
    defaultPriceUzs: 8000,
    optimalOvenTempCelsius: 300,
    description: 'Decadent festive bread enriched with pure butter, cream, and mutton tallow with a flaky crumb.',
  ),
  shirmoy(
    id: 'shirmoy',
    nameEn: 'Shirmoy Non (Anise & Chickpea)',
    nameUz: 'Shirmoy non (No\'xat va arpabodiyon)',
    nameRu: 'Ширмой нон (Анисово-нутовый)',
    defaultPriceUzs: 12000,
    optimalOvenTempCelsius: 260,
    description: 'Medicinal and ceremonial bread leavened with chickpea broth and sweet aniseed.',
  ),
  jizzali(
    id: 'jizzali',
    nameEn: 'Jizzali Non (Crispy Cracklings)',
    nameUz: 'Jizzali non (Jizza va piyozli)',
    nameRu: 'Жиззали нон (Со шкварками и луком)',
    defaultPriceUzs: 10000,
    optimalOvenTempCelsius: 290,
    description: 'Hearty winter savory bread studded with fried mutton cracklings and sweet braised onion.',
  );

  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final int defaultPriceUzs;
  final int optimalOvenTempCelsius;
  final String description;

  const BreadVariety({
    required this.id,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.defaultPriceUzs,
    required this.optimalOvenTempCelsius,
    required this.description,
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

  static BreadVariety fromId(String id) {
    return BreadVariety.values.firstWhere(
      (b) => b.id == id,
      orElse: () => BreadVariety.obiNon,
    );
  }
}

/// Geometric pin patterns used in the wooden chekich bread center stamp.
enum ChekichPattern {
  sunburst(
    id: 'sunburst',
    nameEn: 'Solar Sunburst (Quyosh)',
    nameUz: 'Quyosh nurlari',
    nameRu: 'Солнечные лучи',
    description: 'Radiant concentric steel pin spokes reflecting Central Asian sun symbolism.',
  ),
  rosette(
    id: 'rosette',
    nameEn: 'Eight-Petal Rosette (Gul)',
    nameUz: 'Sakkiz yaproqli gul',
    nameRu: 'Восьмилепестковая розетка',
    description: 'Floral rosette geometry preventing center bubble swelling during rapid tandoor rise.',
  ),
  octagon(
    id: 'octagon',
    nameEn: 'Timurid Octagram (Yulduz)',
    nameUz: 'Temuriy yulduzi',
    nameRu: 'Тимуридская звезда',
    description: 'Sacred architectural star constellation pressed into the center of holiday patirs.',
  );

  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final String description;

  const ChekichPattern({
    required this.id,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.description,
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

  static ChekichPattern fromId(String id) {
    return ChekichPattern.values.firstWhere(
      (p) => p.id == id,
      orElse: () => ChekichPattern.sunburst,
    );
  }
}

/// Model representing a Neighborhood Clay Tandoor Bakery.
class TandoorBakeryVenue {
  final String id;
  final String name;
  final String district;
  final String headBaker;
  final String tandoorClayOrigin;
  final int dailyBatchesCount;
  final int currentBatchHotLoaves;
  final int nextBatchMinutes;
  final double latitude;
  final double longitude;
  final List<BreadVariety> signatureBreads;
  final ChekichPattern favoriteChekich;

  const TandoorBakeryVenue({
    required this.id,
    required this.name,
    required this.district,
    required this.headBaker,
    required this.tandoorClayOrigin,
    required this.dailyBatchesCount,
    required this.currentBatchHotLoaves,
    required this.nextBatchMinutes,
    required this.latitude,
    required this.longitude,
    required this.signatureBreads,
    required this.favoriteChekich,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'district': district,
        'head_baker': headBaker,
        'tandoor_clay_origin': tandoorClayOrigin,
        'daily_batches_count': dailyBatchesCount,
        'current_batch_hot_loaves': currentBatchHotLoaves,
        'next_batch_minutes': nextBatchMinutes,
        'latitude': latitude,
        'longitude': longitude,
        'signature_breads': signatureBreads.map((b) => b.id).toList(),
        'favorite_chekich': favoriteChekich.id,
      };

  factory TandoorBakeryVenue.fromJson(Map<String, dynamic> json) {
    final breadsRaw = json['signature_breads'] as List<dynamic>? ?? [];
    return TandoorBakeryVenue(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      headBaker: json['head_baker'] as String? ?? '',
      tandoorClayOrigin: json['tandoor_clay_origin'] as String? ?? '',
      dailyBatchesCount: (json['daily_batches_count'] as num?)?.toInt() ?? 12,
      currentBatchHotLoaves: (json['current_batch_hot_loaves'] as num?)?.toInt() ?? 24,
      nextBatchMinutes: (json['next_batch_minutes'] as num?)?.toInt() ?? 8,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      signatureBreads: breadsRaw
          .map((b) => BreadVariety.fromId(b.toString()))
          .toList(),
      favoriteChekich: ChekichPattern.fromId(
        json['favorite_chekich'] as String? ?? 'sunburst',
      ),
    );
  }
}

/// Reservation record for reserving piping hot tandoor loaves.
class BreadBatchReservation {
  final String bakeryId;
  final BreadVariety variety;
  final int loavesCount;
  final DateTime reservedAt;
  final int xpEarned;
  final String status;

  const BreadBatchReservation({
    required this.bakeryId,
    required this.variety,
    required this.loavesCount,
    required this.reservedAt,
    this.xpEarned = 30,
    this.status = 'confirmed',
  });
}

/// Pure Dart Domain Service Engine for Tandoor Bakeries & Bread Guild.
class TandoorBakeryEngine {
  final List<TandoorBakeryVenue> bakeries;

  TandoorBakeryEngine({List<TandoorBakeryVenue>? bakeries})
      : bakeries = bakeries ?? defaultBakeries;

  static final List<TandoorBakeryVenue> defaultBakeries = [
    const TandoorBakeryVenue(
      id: 'bakery-chorsu-kattabog',
      name: 'Chorsu Kattabog Tandoor Bakery',
      district: 'Old City Shaykhontohur',
      headBaker: 'Novvoyboshi Usto Shuhrat',
      tandoorClayOrigin: 'Rishtan Ochre Refractory Clay',
      dailyBatchesCount: 16,
      currentBatchHotLoaves: 32,
      nextBatchMinutes: 6,
      latitude: 41.3262,
      longitude: 69.2395,
      signatureBreads: [
        BreadVariety.obiNon,
        BreadVariety.patir,
      ],
      favoriteChekich: ChekichPattern.sunburst,
    ),
    const TandoorBakeryVenue(
      id: 'bakery-chigatoy-shirmoy',
      name: 'Chigatoy Mahalla Shirmoy Guild',
      district: 'Almazar',
      headBaker: 'Usto Otabek Novvoy',
      tandoorClayOrigin: 'Bukhara Silt & Straw Adobe Clay',
      dailyBatchesCount: 10,
      currentBatchHotLoaves: 18,
      nextBatchMinutes: 12,
      latitude: 41.3385,
      longitude: 69.2241,
      signatureBreads: [
        BreadVariety.shirmoy,
        BreadVariety.obiNon,
      ],
      favoriteChekich: ChekichPattern.rosette,
    ),
    const TandoorBakeryVenue(
      id: 'bakery-keles-jizzali',
      name: 'Keles Traditional Winter Tandoor',
      district: 'Olmazor North',
      headBaker: 'Usto Bahrom Novvoy',
      tandoorClayOrigin: 'Gazgan Red Fireclay Tandoor',
      dailyBatchesCount: 14,
      currentBatchHotLoaves: 28,
      nextBatchMinutes: 4,
      latitude: 41.3521,
      longitude: 69.2132,
      signatureBreads: [
        BreadVariety.jizzali,
        BreadVariety.patir,
      ],
      favoriteChekich: ChekichPattern.octagon,
    ),
  ];

  /// Locates bakery by unique ID.
  TandoorBakeryVenue? findBakeryById(String id) {
    try {
      return bakeries.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filters bakeries that bake a specific variety of bread.
  List<TandoorBakeryVenue> filterBakeriesByVariety(BreadVariety variety) {
    return bakeries.where((b) => b.signatureBreads.contains(variety)).toList();
  }

  /// Evaluates bread freshness tier based on minutes elapsed since batch removal.
  String calculateFreshnessGrade(int minutesSinceBake, String langCode) {
    if (minutesSinceBake <= 15) {
      switch (langCode.toLowerCase()) {
        case 'uz':
          return 'Tandirdan uzilgan (Qaynoq)';
        case 'ru':
          return 'С пылу с жару (Горячий)';
        case 'en':
        default:
          return 'Piping Hot (Fresh from Tandoor)';
      }
    } else if (minutesSinceBake <= 45) {
      switch (langCode.toLowerCase()) {
        case 'uz':
          return 'Iliq va xushbo\'y';
        case 'ru':
          return 'Теплый и ароматный';
        case 'en':
        default:
          return 'Warm & Fragrant';
      }
    } else {
      switch (langCode.toLowerCase()) {
        case 'uz':
          return 'Yangi tandir noni';
        case 'ru':
          return 'Свежий хлеб';
        case 'en':
        default:
          return 'Fresh Daily Loaf';
      }
    }
  }

  /// Checks if hot loaves are currently available.
  bool isBatchReady(TandoorBakeryVenue bakery) {
    return bakery.currentBatchHotLoaves > 0;
  }

  /// Reserves hot loaves and awards +30 Explorer XP.
  BreadBatchReservation reserveLoaves(
    String bakeryId,
    BreadVariety variety,
    int loavesCount,
  ) {
    return BreadBatchReservation(
      bakeryId: bakeryId,
      variety: variety,
      loavesCount: loavesCount,
      reservedAt: DateTime.now(),
      xpEarned: 30,
      status: 'confirmed',
    );
  }
}

/// Riverpod Provider for TandoorBakeryEngine.
final tandoorBakeryEngineProvider = Provider<TandoorBakeryEngine>((ref) {
  return TandoorBakeryEngine();
});
