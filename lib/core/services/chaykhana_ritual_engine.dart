import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an authentic Uzbek tea blend infused in ceramic teapots.
class TeaBlend {
  final String id;
  final String name;
  final String teaType; // Green, Black, Herbal, Saffron
  final String description;
  final List<String> botanicalIngredients;
  final int waterTempCelsius;
  final int steepTimeSeconds;
  final String flavorProfile;

  const TeaBlend({
    required this.id,
    required this.name,
    required this.teaType,
    required this.description,
    required this.botanicalIngredients,
    required this.waterTempCelsius,
    required this.steepTimeSeconds,
    required this.flavorProfile,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tea_type': teaType,
    'description': description,
    'botanical_ingredients': botanicalIngredients,
    'water_temp_celsius': waterTempCelsius,
    'steep_time_seconds': steepTimeSeconds,
    'flavor_profile': flavorProfile,
  };

  factory TeaBlend.fromJson(Map<String, dynamic> json) {
    return TeaBlend(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Kok Choy',
      teaType: json['tea_type'] as String? ?? 'Green',
      description: json['description'] as String? ?? '',
      botanicalIngredients: (json['botanical_ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      waterTempCelsius: (json['water_temp_celsius'] as num?)?.toInt() ?? 85,
      steepTimeSeconds: (json['steep_time_seconds'] as num?)?.toInt() ?? 180,
      flavorProfile: json['flavor_profile'] as String? ?? 'Floral & Crisp',
    );
  }
}

/// Represents one step of the traditional 3-pour Kaytarish tea aeration ritual.
class KaytarishStep {
  final int stepNumber; // 1, 2, 3
  final String nameUz; // Loy, Moy, Choy
  final String titleEn;
  final String titleUz;
  final String titleRu;
  final String descriptionEn;
  final int oxygenationPercent;

  const KaytarishStep({
    required this.stepNumber,
    required this.nameUz,
    required this.titleEn,
    required this.titleUz,
    required this.titleRu,
    required this.descriptionEn,
    required this.oxygenationPercent,
  });

  String localizedTitle({String locale = 'en'}) {
    switch (locale) {
      case 'uz':
        return titleUz;
      case 'ru':
        return titleRu;
      default:
        return titleEn;
    }
  }
}

/// Represents a traditional Tashkent neighborhood chaykhana with open-air tapchans.
class ChaykhanaVenue {
  final String id;
  final String name;
  final String district;
  final String chaykhanaUstoName;
  final String accentColorHex;
  final String samovarType;
  final int availableTapchans;
  final int totalTapchans;
  final List<TeaBlend> signatureBlends;
  final double latitude;
  final double longitude;

  const ChaykhanaVenue({
    required this.id,
    required this.name,
    required this.district,
    required this.chaykhanaUstoName,
    required this.accentColorHex,
    required this.samovarType,
    required this.availableTapchans,
    required this.totalTapchans,
    required this.signatureBlends,
    required this.latitude,
    required this.longitude,
  });

  String localizedName({String locale = 'en'}) {
    switch (locale) {
      case 'uz':
        if (id == 'chaykhana-chorsu-chinor') return 'Chorsu Chinor Choyxonasi';
        if (id == 'chaykhana-hast-imam') return 'Hazrati Imom Zafaron Choyxonasi';
        if (id == 'chaykhana-ankhor-terrace') return 'Anhor Sohil Bo\'yi Choyxonasi';
        return name;
      case 'ru':
        if (id == 'chaykhana-chorsu-chinor') return 'Чайхана Чорсу Чинор';
        if (id == 'chaykhana-hast-imam') return 'Шафрановая Чайхана Хазрати Имам';
        if (id == 'chaykhana-ankhor-terrace') return 'Набережная Чайхана Анхор';
        return name;
      default:
        return name;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'district': district,
    'chaykhana_usto_name': chaykhanaUstoName,
    'accent_color_hex': accentColorHex,
    'samovar_type': samovarType,
    'available_tapchans': availableTapchans,
    'total_tapchans': totalTapchans,
    'signature_blends': signatureBlends.map((b) => b.toJson()).toList(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory ChaykhanaVenue.fromJson(Map<String, dynamic> json) {
    return ChaykhanaVenue(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? 'Tashkent',
      chaykhanaUstoName: json['chaykhana_usto_name'] as String? ?? '',
      accentColorHex: json['accent_color_hex'] as String? ?? '#059669',
      samovarType: json['samovar_type'] as String? ?? 'Samovar',
      availableTapchans: (json['available_tapchans'] as num?)?.toInt() ?? 4,
      totalTapchans: (json['total_tapchans'] as num?)?.toInt() ?? 12,
      signatureBlends: (json['signature_blends'] as List<dynamic>?)
              ?.map((b) => TeaBlend.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.3284,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2412,
    );
  }
}

/// Core domain engine for Tashkent chaykhana culture, tea blends, and the 3-step Kaytarish aeration ritual.
class ChaykhanaRitualEngine {
  static const List<KaytarishStep> canonicalSteps = [
    KaytarishStep(
      stepNumber: 1,
      nameUz: 'Loy',
      titleEn: '1st Pour: Loy (Mud) — Waking the Leaves',
      titleUz: '1-qaytarish: Loy — Choy bargini uyg\'otish',
      titleRu: '1-й налив: Лой (Ил) — Пробуждение чайного листа',
      descriptionEn: 'First pour into the pialah draws out raw tannins and dust; return immediately to the porcelain pot.',
      oxygenationPercent: 33,
    ),
    KaytarishStep(
      stepNumber: 2,
      nameUz: 'Moy',
      titleEn: '2nd Pour: Moy (Oil) — Releasing Essential Aromas',
      titleUz: '2-qaytarish: Moy — Efir moylari va hidini chiqarish',
      titleRu: '2-й налив: Мой (Масло) — Раскрытие эфирных ароматов',
      descriptionEn: 'Second pour dissolves natural botanical oils into shimmering surface sheen; return to pot for deep infusion.',
      oxygenationPercent: 66,
    ),
    KaytarishStep(
      stepNumber: 3,
      nameUz: 'Choy',
      titleEn: '3rd Pour: Choy (Tea) — Pristine Nectar of Hospitality',
      titleUz: '3-qaytarish: Choy — Mukammal tillarang choy',
      titleRu: '3-й налив: Чой (Чай) — Золотистый нектар гостеприимства',
      descriptionEn: 'Third pour achieves silky amber clarity. Serve half-filled in Rishtan pialah with right hand over heart.',
      oxygenationPercent: 100,
    ),
  ];

  static const List<ChaykhanaVenue> defaultVenues = [
    ChaykhanaVenue(
      id: 'chaykhana-chorsu-chinor',
      name: 'Chorsu Chinor Chaykhana',
      district: 'Shaykhontohur',
      chaykhanaUstoName: 'Usto Bobomurod Choychi',
      accentColorHex: '#059669', // Emerald
      samovarType: 'Charcoal Tinned Brass Samovar (1924)',
      availableTapchans: 4,
      totalTapchans: 12,
      latitude: 41.3284,
      longitude: 69.2412,
      signatureBlends: [
        TeaBlend(
          id: 'blend-tashkent-kok-choy',
          name: 'Old City Kok-Choy No. 95',
          teaType: 'Green',
          description: 'High-fire Chinese gunpowder green leaf aerated over centuries-old plane tree shade.',
          botanicalIngredients: ['Spring Green Leaf', 'Dried Mountain Thyme', 'Wild Mint'],
          waterTempCelsius: 85,
          steepTimeSeconds: 180,
          flavorProfile: 'Crisp, grassy sweetness with gentle astringency',
        ),
      ],
    ),
    ChaykhanaVenue(
      id: 'chaykhana-hast-imam',
      name: 'Hast Imam Saffron & Mint Chaykhana',
      district: 'Almazar',
      chaykhanaUstoName: 'Usto Ilkhom Choypaz',
      accentColorHex: '#FFD666', // Saffron
      samovarType: 'Firewood Hammered Copper Samovar',
      availableTapchans: 6,
      totalTapchans: 16,
      latitude: 41.3360,
      longitude: 69.2390,
      signatureBlends: [
        TeaBlend(
          id: 'blend-zafaron-saffron',
          name: 'Poytaxt Royal Saffron Amber',
          teaType: 'Saffron',
          description: 'Bukhara saffron threads steeped with wild mountain oregano and golden honey.',
          botanicalIngredients: ['Red Saffron Stigmas', 'Dried Quince Blossoms', 'Ceylon Black Tip'],
          waterTempCelsius: 92,
          steepTimeSeconds: 240,
          flavorProfile: 'Velvety honey, floral saffron aromatics, and toasted spice',
        ),
      ],
    ),
    ChaykhanaVenue(
      id: 'chaykhana-ankhor-terrace',
      name: 'Ankhor Embankment Riverbed Chaykhana',
      district: 'Yakkasaray',
      chaykhanaUstoName: 'Otabek Mirzo',
      accentColorHex: '#00D2FC', // Water Blue
      samovarType: 'Tsarist Imperial Brass Samovar (1898)',
      availableTapchans: 2,
      totalTapchans: 8,
      latitude: 41.2912,
      longitude: 69.2554,
      signatureBlends: [
        TeaBlend(
          id: 'blend-pomegranate-hibiscus',
          name: 'Canal Willow Pomegranate Infusion',
          teaType: 'Herbal',
          description: 'Ruby red infusion of sun-dried Kuva pomegranate peel, hibiscus petals, and clove.',
          botanicalIngredients: ['Pomegranate Peel', 'Hibiscus Calyces', 'Cardamom Pods'],
          waterTempCelsius: 95,
          steepTimeSeconds: 300,
          flavorProfile: 'Tart ruby fruit, sweet clove warmth, and citrus perfume',
        ),
      ],
    ),
  ];

  /// Returns all available Tashkent chaykhanas.
  List<ChaykhanaVenue> getAllVenues() => defaultVenues;

  /// Retrieves a specific chaykhana by identifier.
  ChaykhanaVenue? getVenueById(String id) {
    for (final v in defaultVenues) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Returns canonical 3-step Kaytarish aeration flow.
  List<KaytarishStep> getKaytarishSteps() => canonicalSteps;

  /// Formats traditional Uzbek tea proverb trilingually.
  String formatKaytarishProverb({String locale = 'en'}) {
    switch (locale) {
      case 'uz':
        return 'Birinchi loy, ikkinchi moy, uchinchi choy';
      case 'ru':
        return 'Первая — глина, вторая — масло, третья — чай';
      default:
        return 'First is mud, second is oil, third is tea';
    }
  }

  /// Formats tapchan table reservation status trilingually.
  String formatTapchanStatus(int available, int total, {String locale = 'en'}) {
    if (available <= 0) {
      switch (locale) {
        case 'uz':
          return 'Barcha tapchanlar band';
        case 'ru':
          return 'Все тапчаны заняты';
        default:
          return 'All Tapchans Full';
      }
    }
    switch (locale) {
      case 'uz':
        return '$available ta tapchan bo\'sh (jami $total)';
      case 'ru':
        return '$available тапчанов свободно (из $total)';
      default:
        return '$available tapchans free (of $total)';
    }
  }
}

/// Riverpod provider for ChaykhanaRitualEngine.
final chaykhanaRitualEngineProvider = Provider<ChaykhanaRitualEngine>((ref) {
  return ChaykhanaRitualEngine();
});
