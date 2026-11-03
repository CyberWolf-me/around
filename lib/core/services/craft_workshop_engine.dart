import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a specific hands-on artisan masterclass.
class WorkshopMasterclass {
  final String id;
  final String title;
  final int durationMinutes;
  final String skillLevel; // Beginner, Intermediate, Master
  final int maxParticipants;
  final int reservedParticipants;
  final int priceUzs;
  final int xpReward;
  final String timeSlot;

  const WorkshopMasterclass({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.skillLevel,
    required this.maxParticipants,
    required this.reservedParticipants,
    required this.priceUzs,
    required this.xpReward,
    required this.timeSlot,
  });

  bool get isFull => reservedParticipants >= maxParticipants;
  int get availableSeats => math.max(0, maxParticipants - reservedParticipants);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'duration_minutes': durationMinutes,
    'skill_level': skillLevel,
    'max_participants': maxParticipants,
    'reserved_participants': reservedParticipants,
    'price_uzs': priceUzs,
    'xp_reward': xpReward,
    'time_slot': timeSlot,
  };

  factory WorkshopMasterclass.fromJson(Map<String, dynamic> json) {
    return WorkshopMasterclass(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 90,
      skillLevel: json['skill_level'] as String? ?? 'Beginner',
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 8,
      reservedParticipants:
          (json['reserved_participants'] as num?)?.toInt() ?? 0,
      priceUzs: (json['price_uzs'] as num?)?.toInt() ?? 150000,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 40,
      timeSlot: json['time_slot'] as String? ?? '10:00 - 11:30',
    );
  }
}

/// Represents an authentic heritage artisan workshop or pottery studio in Tashkent.
class CraftStudio {
  final String id;
  final String title;
  final String district;
  final String craftDiscipline;
  final String masterArtisanName;
  final String masterHonorific;
  final String description;
  final String accentColorHex;
  final double latitude;
  final double longitude;
  final List<String> materials;
  final List<WorkshopMasterclass> masterclasses;

  const CraftStudio({
    required this.id,
    required this.title,
    required this.district,
    required this.craftDiscipline,
    required this.masterArtisanName,
    required this.masterHonorific,
    required this.description,
    required this.accentColorHex,
    required this.latitude,
    required this.longitude,
    required this.materials,
    required this.masterclasses,
  });

  String localizedTitle({String locale = 'en'}) {
    switch (locale) {
      case 'uz':
        if (id == 'studio-rishtan-ceramics') return 'Rishton Moviy Sir Kulolchilik Uyi';
        if (id == 'studio-chorsu-woodcarving') return 'Chorsu Yong\'oq Yog\'och O\'ymakorligi';
        if (id == 'studio-yakkasaray-silk') return 'Anhor So\'zana va Ipak To\'qish Ustaxonasi';
        if (id == 'studio-mirabad-copper') return 'Mirobod Mis Kandakorlik Ustaxonasi';
        return title;
      case 'ru':
        if (id == 'studio-rishtan-ceramics') return 'Гончарный Дом Риштанской Лазури';
        if (id == 'studio-chorsu-woodcarving') return 'Мастерская Резьбы по Ореху Чорсу';
        if (id == 'studio-yakkasaray-silk') return 'Студия Сюзане и Шелкоткачества Анхор';
        if (id == 'studio-mirabad-copper') return 'Мирабадская Медно-Чеканная Кузница';
        return title;
      default:
        return title;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'district': district,
    'craft_discipline': craftDiscipline,
    'master_artisan_name': masterArtisanName,
    'master_honorific': masterHonorific,
    'description': description,
    'accent_color_hex': accentColorHex,
    'latitude': latitude,
    'longitude': longitude,
    'materials': materials,
    'masterclasses': masterclasses.map((m) => m.toJson()).toList(),
  };

  factory CraftStudio.fromJson(Map<String, dynamic> json) {
    return CraftStudio(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      district: json['district'] as String? ?? 'Tashkent',
      craftDiscipline: json['craft_discipline'] as String? ?? 'Ceramics',
      masterArtisanName: json['master_artisan_name'] as String? ?? '',
      masterHonorific: json['master_honorific'] as String? ?? '',
      description: json['description'] as String? ?? '',
      accentColorHex: json['accent_color_hex'] as String? ?? '#2563EB',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.3110,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2405,
      materials: (json['materials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      masterclasses: (json['masterclasses'] as List<dynamic>?)
              ?.map((m) => WorkshopMasterclass.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Core domain engine for traditional Tashkent craft workshops and masterclass reservations.
class CraftWorkshopEngine {
  static const List<CraftStudio> defaultStudios = [
    CraftStudio(
      id: 'studio-rishtan-ceramics',
      title: 'Rishtan Blue Glaze Pottery House',
      district: 'Shaykhontohur',
      craftDiscipline: 'Ceramics',
      masterArtisanName: 'Usto Alisher Nazirov',
      masterHonorific: '7th Generation Rishtan Ceramicist',
      description: 'Spin traditional foot-powered kick wheels and paint natural mineral Ishkor glaze onto terracotta plates.',
      accentColorHex: '#2563EB', // Cobalt
      latitude: 41.3284,
      longitude: 69.2412,
      materials: ['Fergana Red Clay', 'Ishkor Herbal Ash Glaze', 'Cobalt Oxide Mineral'],
      masterclasses: [
        WorkshopMasterclass(
          id: 'class-kickwheel-pottery',
          title: 'Foot-Powered Kickwheel Pitcher Throwing',
          durationMinutes: 90,
          skillLevel: 'Beginner',
          maxParticipants: 6,
          reservedParticipants: 4,
          priceUzs: 180000,
          xpReward: 40,
          timeSlot: '11:00 - 12:30',
        ),
        WorkshopMasterclass(
          id: 'class-ishkor-glaze',
          title: 'Masterclass: Rishtan Turquoise Ishkor Glaze Painting',
          durationMinutes: 120,
          skillLevel: 'Intermediate',
          maxParticipants: 5,
          reservedParticipants: 5, // Full
          priceUzs: 220000,
          xpReward: 50,
          timeSlot: '15:00 - 17:00',
        ),
      ],
    ),
    CraftStudio(
      id: 'studio-chorsu-woodcarving',
      title: 'Chorsu Walnut Woodcarving Atelier',
      district: 'Old City Chorsu',
      craftDiscipline: 'Woodcarving',
      masterArtisanName: 'Usto Nematullo Khaydarov',
      masterHonorific: 'Master of Central Asian Floral Islimi',
      description: 'Hand-carve geometric Parda and vegetal Islimi patterns onto mountain walnut bookstands and tea tables.',
      accentColorHex: '#FF4800', // Orange
      latitude: 41.3275,
      longitude: 69.2370,
      materials: ['Fergana Wild Walnut', 'Natural Beeswax Polish', 'Hand-Forged Steel Chisels'],
      masterclasses: [
        WorkshopMasterclass(
          id: 'class-laukh-folding-stand',
          title: 'Carving a Seamless Single-Piece Laukh Bookstand',
          durationMinutes: 120,
          skillLevel: 'Intermediate',
          maxParticipants: 4,
          reservedParticipants: 2,
          priceUzs: 250000,
          xpReward: 45,
          timeSlot: '14:00 - 16:00',
        ),
      ],
    ),
    CraftStudio(
      id: 'studio-yakkasaray-silk',
      title: 'Ankhor Suzani & Silk Weaving Studio',
      district: 'Yakkasaray',
      craftDiscipline: 'Silk Weaving',
      masterArtisanName: 'Madina Kasimbaeva',
      masterHonorific: 'Traditional Ikat & Suzani Master',
      description: 'Learn century-old tambour chain stitches and natural dye preparation from pomegranate rind and madder root.',
      accentColorHex: '#A259FF', // Violet
      latitude: 41.2912,
      longitude: 69.2554,
      materials: ['Margilan Mulberry Silk', 'Pomegranate Peel Yellow', 'Madder Root Crimson'],
      masterclasses: [
        WorkshopMasterclass(
          id: 'class-suzani-embroidery',
          title: 'Tashkent Pomegranate Blossom Chain Stitching',
          durationMinutes: 90,
          skillLevel: 'Beginner',
          maxParticipants: 8,
          reservedParticipants: 3,
          priceUzs: 160000,
          xpReward: 40,
          timeSlot: '16:30 - 18:00',
        ),
      ],
    ),
    CraftStudio(
      id: 'studio-mirabad-copper',
      title: 'Mirabad Copper & Chasing Forge',
      district: 'Mirabad',
      craftDiscipline: 'Copper Embossing',
      masterArtisanName: 'Usto Farrukh Kandakor',
      masterHonorific: 'Central Asian Chasing Guildmaster',
      description: 'Chase traditional filigree relief onto tinned tea ewers and trays using copper punches and mallets.',
      accentColorHex: '#059669', // Emerald
      latitude: 41.3005,
      longitude: 69.2731,
      materials: ['Tinned Red Copper Sheets', 'Black Pitch Bedding', 'Tempered Punches'],
      masterclasses: [
        WorkshopMasterclass(
          id: 'class-copper-chasing',
          title: 'Embossing Traditional Rishtan Tea Plate Rim',
          durationMinutes: 90,
          skillLevel: 'Beginner',
          maxParticipants: 6,
          reservedParticipants: 5,
          priceUzs: 190000,
          xpReward: 40,
          timeSlot: '10:30 - 12:00',
        ),
      ],
    ),
  ];

  /// Returns all curated craft workshops.
  List<CraftStudio> getAllStudios() => defaultStudios;

  /// Retrieves studio by identifier.
  CraftStudio? getStudioById(String id) {
    for (final s in defaultStudios) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Filters studios by craft discipline (e.g. 'Ceramics', 'Woodcarving').
  List<CraftStudio> filterByDiscipline(String discipline) {
    if (discipline.isEmpty || discipline.toLowerCase() == 'all') {
      return defaultStudios;
    }
    return defaultStudios
        .where((s) => s.craftDiscipline.toLowerCase() == discipline.toLowerCase())
        .toList();
  }

  /// Calculates geodesic distance between studio and user coordinates in kilometers.
  double calculateDistanceKm(
    CraftStudio studio,
    double userLat,
    double userLon,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = (studio.latitude - userLat) * math.pi / 180.0;
    final dLon = (studio.longitude - userLon) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(userLat * math.pi / 180.0) *
            math.cos(studio.latitude * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(1));
  }

  /// Formats price in Uzbek Som nicely (e.g. "180 000 UZS").
  String formatPriceUzs(int priceUzs) {
    final str = priceUzs.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} UZS';
  }

  /// Formats reservation status message trilingually.
  String formatReservationStatus({
    required bool isReserved,
    required bool isFull,
    String locale = 'en',
  }) {
    if (isReserved) {
      switch (locale) {
        case 'uz':
          return 'Band qilingan (+40 XP)';
        case 'ru':
          return 'Забронировано (+40 XP)';
        default:
          return 'Reserved (+40 XP)';
      }
    }

    if (isFull) {
      switch (locale) {
        case 'uz':
          return 'Barcha joylar band';
        case 'ru':
          return 'Все места заняты';
        default:
          return 'Fully Booked';
      }
    }

    switch (locale) {
      case 'uz':
        return 'Joyni band qilish';
      case 'ru':
        return 'Забронировать место';
      default:
        return 'Reserve Seat';
    }
  }
}

/// Riverpod provider for CraftWorkshopEngine.
final craftWorkshopEngineProvider = Provider<CraftWorkshopEngine>((ref) {
  return CraftWorkshopEngine();
});
