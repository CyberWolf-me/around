import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The 4 traditional stages of Uzbek mulberry silk paper craft.
enum PaperCraftStage {
  soaking(
    stepNumber: 1,
    nameEn: 'Mulberry Bark Soaking & Peeling',
    nameUz: 'Tut po\'stlog\'ini ivitish va archish',
    nameRu: 'Вымачивание и окорка шелковицы',
    durationHours: 12,
    description: 'Fresh mulberry branches soaked in mountain stream water to separate the fibrous inner phloem.',
  ),
  pulping(
    stepNumber: 2,
    nameEn: 'Watermill Wooden Mashing',
    nameUz: 'Objuvozda yog\'och tuyg\'ich bilan ezish',
    nameRu: 'Толчение древесины в водяных ступах',
    durationHours: 8,
    description: 'Wooden pestles powered by watermills crush fibers into a creamy, pliable cellulose mash.',
  ),
  sievePressing(
    stepNumber: 3,
    nameEn: 'Silk Sieve Framing & Sun Dewatering',
    nameUz: 'Ipak qoliplash va quyoshda quritish',
    nameRu: 'Отлив на шелковые сетки и сушка',
    durationHours: 24,
    description: 'Suspended fibers scooped into fine silk-gauze deckles, screw-pressed and dried against wooden boards.',
  ),
  burnishing(
    stepNumber: 4,
    nameEn: 'Agate Stone Mirror Burnishing',
    nameUz: 'Aqiq tosh bilan ko\'zgu sayqallash',
    nameRu: 'Лощение натуральным агатом',
    durationHours: 1,
    description: 'Sheets burnished manually with polished agate stone until lustrous and impervious to ink bleed.',
  );

  final int stepNumber;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final int durationHours;
  final String description;

  const PaperCraftStage({
    required this.stepNumber,
    required this.nameEn,
    required this.nameUz,
    required this.nameRu,
    required this.durationHours,
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
}

/// Calligraphy script styles practiced in Tashkent manuscript ateliers.
enum CalligraphyScript {
  nastaliq(
    id: 'nastaliq',
    nameEn: 'Nasta\'liq (Lyrical Manuscript)',
    nameUz: 'Nasta\'liq (Kelin xati)',
    nameRu: 'Насталик (Поэтический)',
    description: 'The bride of Islamic scripts: fluid, diagonal harmony used for classical Uzbek divans.',
  ),
  thuluth(
    id: 'thuluth',
    nameEn: 'Thuluth (Monumental Title)',
    nameUz: 'Suls (Ulug\'vor me\'moriy xat)',
    nameRu: 'Сулюс (Монументальный)',
    description: 'Grand cursive script with dramatic curves gracing madrasah portals and sacred titles.',
  ),
  kufic(
    id: 'kufic',
    nameEn: 'Kufic (Geometric Archaic)',
    nameUz: 'Kufiy (Geometrik qadimiy)',
    nameRu: 'Куфический (Геометрический)',
    description: 'Archaic angular script with interlocking geometric finials from early Islamic Samanid era.',
  ),
  diwani(
    id: 'diwani',
    nameEn: 'Diwani (Chancery Flourish)',
    nameUz: 'Devoniy (Sultoniylar saroy xati)',
    nameRu: 'Дивани (Канцелярский)',
    description: 'Intricately woven calligraphic flourishes originally reserved for royal firmans and decrees.',
  );

  final String id;
  final String nameEn;
  final String nameUz;
  final String nameRu;
  final String description;

  const CalligraphyScript({
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

  static CalligraphyScript fromId(String id) {
    return CalligraphyScript.values.firstWhere(
      (s) => s.id == id,
      orElse: () => CalligraphyScript.nastaliq,
    );
  }
}

/// Model representing a Tashkent Mulberry Silk Paper & Calligraphy Atelier.
class SilkPaperAtelier {
  final String id;
  final String name;
  final String district;
  final String masterName;
  final String centuryTradition;
  final String mulberryVariety;
  final String burnishStoneType;
  final double latitude;
  final double longitude;
  final List<CalligraphyScript> supportedScripts;
  final int workshopPriceUzs;
  final int availableMasterclasses;
  final int maxCapacity;

  const SilkPaperAtelier({
    required this.id,
    required this.name,
    required this.district,
    required this.masterName,
    required this.centuryTradition,
    required this.mulberryVariety,
    required this.burnishStoneType,
    required this.latitude,
    required this.longitude,
    required this.supportedScripts,
    required this.workshopPriceUzs,
    required this.availableMasterclasses,
    required this.maxCapacity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'district': district,
        'master_name': masterName,
        'century_tradition': centuryTradition,
        'mulberry_variety': mulberryVariety,
        'burnish_stone_type': burnishStoneType,
        'latitude': latitude,
        'longitude': longitude,
        'supported_scripts': supportedScripts.map((s) => s.id).toList(),
        'workshop_price_uzs': workshopPriceUzs,
        'available_masterclasses': availableMasterclasses,
        'max_capacity': maxCapacity,
      };

  factory SilkPaperAtelier.fromJson(Map<String, dynamic> json) {
    final scriptsRaw = json['supported_scripts'] as List<dynamic>? ?? [];
    return SilkPaperAtelier(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      masterName: json['master_name'] as String? ?? '',
      centuryTradition: json['century_tradition'] as String? ?? '',
      mulberryVariety: json['mulberry_variety'] as String? ?? '',
      burnishStoneType: json['burnish_stone_type'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      supportedScripts: scriptsRaw
          .map((s) => CalligraphyScript.fromId(s.toString()))
          .toList(),
      workshopPriceUzs: (json['workshop_price_uzs'] as num?)?.toInt() ?? 150000,
      availableMasterclasses: (json['available_masterclasses'] as num?)?.toInt() ?? 3,
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 8,
    );
  }
}

/// Reservation details for a hands-on paper crafting masterclass.
class PaperWorkshopReservation {
  final String atelierId;
  final CalligraphyScript script;
  final DateTime bookedAt;
  final int xpEarned;
  final String status;

  const PaperWorkshopReservation({
    required this.atelierId,
    required this.script,
    required this.bookedAt,
    this.xpEarned = 35,
    this.status = 'confirmed',
  });
}

/// Pure Dart Domain Service Engine for Silk Paper & Calligraphy Ateliers.
class SilkPaperCalligraphyEngine {
  final List<SilkPaperAtelier> ateliers;

  SilkPaperCalligraphyEngine({List<SilkPaperAtelier>? ateliers})
      : ateliers = ateliers ?? defaultAteliers;

  static final List<SilkPaperAtelier> defaultAteliers = [
    const SilkPaperAtelier(
      id: 'atelier-chorsu-mulberry',
      name: 'Chorsu Silk Paper & Manuscript Guild',
      district: 'Old City Shaykhontohur',
      masterName: 'Usto Mirzo Bobo Qog\'ozchi',
      centuryTradition: '10th Century Samarkand-Tashkent Silk Paper Legacy',
      mulberryVariety: 'White Mulberry (Morus Alba) Inner Phloem',
      burnishStoneType: 'Kyzylkum Red Agate Stone (Aqiq)',
      latitude: 41.3275,
      longitude: 69.2389,
      supportedScripts: [
        CalligraphyScript.nastaliq,
        CalligraphyScript.thuluth,
        CalligraphyScript.kufic,
      ],
      workshopPriceUzs: 150000,
      availableMasterclasses: 4,
      maxCapacity: 8,
    ),
    const SilkPaperAtelier(
      id: 'atelier-hast-imam-calligraphy',
      name: 'Hast Imam Holy Scripture & Vellum Atelier',
      district: 'Almazar',
      masterName: 'Usto Abdulaziz Mansur Calligrapher',
      centuryTradition: 'Imperial Quranic Illumination & Gold Leaf Scribing',
      mulberryVariety: 'Black Mulberry (Morus Nigra) High-Cellulose Bark',
      burnishStoneType: 'Mountain Chalcedony & Horn Burnisher',
      latitude: 41.3364,
      longitude: 69.2415,
      supportedScripts: [
        CalligraphyScript.thuluth,
        CalligraphyScript.kufic,
        CalligraphyScript.diwani,
      ],
      workshopPriceUzs: 180000,
      availableMasterclasses: 2,
      maxCapacity: 6,
    ),
    const SilkPaperAtelier(
      id: 'atelier-navoiy-literature',
      name: 'Navoiy Literary Manuscript & Diwani Atelier',
      district: 'Mirabad',
      masterName: 'Usto Dilshodbek Khattot',
      centuryTradition: 'Timurid Renaissance Divan & Nastaliq Miniature Scrolls',
      mulberryVariety: 'Wild Pskem River Mulberry Fibers',
      burnishStoneType: 'Polished Riverbed Jasper & Sea Shell',
      latitude: 41.3052,
      longitude: 69.2741,
      supportedScripts: [
        CalligraphyScript.nastaliq,
        CalligraphyScript.diwani,
      ],
      workshopPriceUzs: 140000,
      availableMasterclasses: 5,
      maxCapacity: 10,
    ),
  ];

  /// Locates atelier by identifier.
  SilkPaperAtelier? findAtelierById(String id) {
    try {
      return ateliers.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filters ateliers that instruct a specific calligraphy script.
  List<SilkPaperAtelier> filterAteliersByScript(CalligraphyScript script) {
    return ateliers.where((a) => a.supportedScripts.contains(script)).toList();
  }

  /// Checks if masterclass seats are open.
  bool isMasterclassAvailable(SilkPaperAtelier atelier) {
    return atelier.availableMasterclasses > 0;
  }

  /// Calculates paper smoothness score based on agate stroke passes.
  /// 0-10 passes: rough; 20 passes: smooth; 30+ passes: glass-like (100%).
  double calculateBurnishSmoothness(int strokePasses) {
    if (strokePasses <= 0) return 0.0;
    if (strokePasses >= 30) return 100.0;
    return (strokePasses / 30.0) * 100.0;
  }

  /// Calculates total crafting duration across all 4 stages.
  int estimateTotalCraftingHours() {
    return PaperCraftStage.values.fold<int>(
      0,
      (sum, stage) => sum + stage.durationHours,
    );
  }

  /// Reserves a masterclass seat and awards +35 Explorer XP.
  PaperWorkshopReservation reserveMasterclass(
    String atelierId,
    CalligraphyScript script,
  ) {
    return PaperWorkshopReservation(
      atelierId: atelierId,
      script: script,
      bookedAt: DateTime.now(),
      xpEarned: 35,
      status: 'confirmed',
    );
  }
}

/// Riverpod Provider for SilkPaperCalligraphyEngine.
final silkPaperCalligraphyEngineProvider =
    Provider<SilkPaperCalligraphyEngine>((ref) {
  return SilkPaperCalligraphyEngine();
});
