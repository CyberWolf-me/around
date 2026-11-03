import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a specific architectural landmark stop in a quest.
class QuestStop {
  final String id;
  final String placeId;
  final String name;
  final String district;
  final String architecturalStyle;
  final int? yearBuilt;
  final String architecturalFact;
  final double latitude;
  final double longitude;
  final String? photoUrl;

  const QuestStop({
    required this.id,
    required this.placeId,
    required this.name,
    required this.district,
    required this.architecturalStyle,
    this.yearBuilt,
    required this.architecturalFact,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': placeId,
    'name': name,
    'district': district,
    'architectural_style': architecturalStyle,
    if (yearBuilt != null) 'year_built': yearBuilt,
    'architectural_fact': architecturalFact,
    'latitude': latitude,
    'longitude': longitude,
    if (photoUrl != null) 'photo_url': photoUrl,
  };

  factory QuestStop.fromJson(Map<String, dynamic> json) {
    return QuestStop(
      id: json['id'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Landmark',
      district: json['district'] as String? ?? 'Tashkent',
      architecturalStyle: json['architectural_style'] as String? ?? 'Modernism',
      yearBuilt: (json['year_built'] as num?)?.toInt(),
      architecturalFact: json['architectural_fact'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

/// Represents an architectural discovery quest with an unlockable badge.
class ArchitecturalQuest {
  final String id;
  final String slug;
  final String title;
  final String badgeName;
  final String description;
  final String category;
  final String badgeIcon;
  final String badgeAccentColorHex;
  final int requiredStopsCount;
  final int xpReward;
  final List<QuestStop> stops;
  final String? curatorQuote;

  const ArchitecturalQuest({
    required this.id,
    required this.slug,
    required this.title,
    required this.badgeName,
    required this.description,
    required this.category,
    required this.badgeIcon,
    required this.badgeAccentColorHex,
    required this.requiredStopsCount,
    this.xpReward = 50,
    required this.stops,
    this.curatorQuote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'badge_name': badgeName,
    'description': description,
    'category': category,
    'badge_icon': badgeIcon,
    'badge_accent_color_hex': badgeAccentColorHex,
    'required_stops_count': requiredStopsCount,
    'xp_reward': xpReward,
    'stops': stops.map((s) => s.toJson()).toList(),
    if (curatorQuote != null) 'curator_quote': curatorQuote,
  };

  factory ArchitecturalQuest.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    return ArchitecturalQuest(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Architectural Quest',
      badgeName: json['badge_name'] as String? ?? 'Badge',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Architecture',
      badgeIcon: json['badge_icon'] as String? ?? 'heritage',
      badgeAccentColorHex: json['badge_accent_color_hex'] as String? ?? '#D97706',
      requiredStopsCount: (json['required_stops_count'] as num?)?.toInt() ?? 3,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
      stops: rawStops.map((s) => QuestStop.fromJson(s as Map<String, dynamic>)).toList(),
      curatorQuote: json['curator_quote'] as String?,
    );
  }
}

/// Evaluated user progress for an architectural quest.
class QuestProgress {
  final String questId;
  final List<String> visitedStopIds;
  final DateTime? unlockedAt;
  final bool isCompleted;
  final double completionPercentage;
  final int remainingStops;

  const QuestProgress({
    required this.questId,
    required this.visitedStopIds,
    this.unlockedAt,
    required this.isCompleted,
    required this.completionPercentage,
    required this.remainingStops,
  });

  Map<String, dynamic> toJson() => {
    'quest_id': questId,
    'visited_stop_ids': visitedStopIds,
    if (unlockedAt != null) 'unlocked_at': unlockedAt!.toIso8601String(),
    'is_completed': isCompleted,
    'completion_percentage': completionPercentage,
    'remaining_stops': remainingStops,
  };

  factory QuestProgress.fromJson(Map<String, dynamic> json) {
    final visited = (json['visited_stop_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return QuestProgress(
      questId: json['quest_id'] as String? ?? '',
      visitedStopIds: visited,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      remainingStops: (json['remaining_stops'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Core engine for architectural discovery quests, badge unlocks, and XP rewards.
class ArchitecturalBadgeEngine {
  /// Default catalog of curated Tashkent architectural quests.
  static const List<ArchitecturalQuest> defaultQuests = [
    ArchitecturalQuest(
      id: 'quest-soviet-modernism',
      slug: 'tashkent-modernism',
      title: 'Soviet Modernism & Brise-Soleil Trail',
      badgeName: 'Modernist Connoisseur',
      description: 'Explore the bold concrete facades, geometric solar sun-screens, and dramatic cantilevered canopies of 1960s-1980s Tashkent.',
      category: 'Modernism',
      badgeIcon: 'building.columns',
      badgeAccentColorHex: '#D97706', // Amber / Ochre
      requiredStopsCount: 3,
      xpReward: 50,
      curatorQuote: 'The post-1966 earthquake reconstruction transformed Tashkent into an open-air laboratory of experimental solar architecture.',
      stops: [
        QuestStop(
          id: 'stop-hotel-uzbekistan',
          placeId: 'hotel-uzbekistan-canonical',
          name: 'Hotel Uzbekistan',
          district: 'Mirabad',
          architecturalStyle: 'Soviet Modernism / Brise-Soleil',
          yearBuilt: 1974,
          architecturalFact: 'Features an iconic sweeping curved facade wrapped in a decorative concrete brise-soleil lattice inspired by traditional Uzbek panjara.',
          latitude: 41.3115,
          longitude: 69.2796,
        ),
        QuestStop(
          id: 'stop-tashkent-circus',
          placeId: 'tashkent-circus-canonical',
          name: 'Tashkent State Circus',
          district: 'Shaykhontohur',
          architecturalStyle: 'Futuristic Modernism / Sky Blue Dome',
          yearBuilt: 1976,
          architecturalFact: 'Known as the "Flying Saucer", its sky-blue faceted dome spans 76 meters without central support pillars.',
          latitude: 41.3262,
          longitude: 69.2389,
        ),
        QuestStop(
          id: 'stop-blue-domes',
          placeId: 'blue-domes-cafe-canonical',
          name: 'Golubye Kupola (Blue Domes)',
          district: 'Yakkasaray',
          architecturalStyle: 'Modernist Pavilions / Ceramic Vaults',
          yearBuilt: 1970,
          architecturalFact: 'Designed by Vil Muratov, combining airy open terraces under hemispherical ceramic-tiled domes nestled in park greenery.',
          latitude: 41.3090,
          longitude: 69.2678,
        ),
      ],
    ),
    ArchitecturalQuest(
      id: 'quest-silk-road-heritage',
      slug: 'silk-road-heritage',
      title: 'Silk Road Majolica & Minaret Route',
      badgeName: 'Silk Road Custodian',
      description: 'Journey through centuries of turquoise glazed majolica, intricate wood-carved columns, and grand madrasah courtyards in Old City.',
      category: 'Heritage',
      badgeIcon: 'sparkles',
      badgeAccentColorHex: '#2563EB', // Cobalt Blue
      requiredStopsCount: 3,
      xpReward: 50,
      curatorQuote: 'Old Tashkent preserves the centuries-old spatial rhythm of the mahalla surrounding towering spiritual landmarks.',
      stops: [
        QuestStop(
          id: 'stop-hazrati-imam',
          placeId: 'hazrati-imam-canonical',
          name: 'Hazrati Imam Complex (Hast Imam)',
          district: 'Almazar',
          architecturalStyle: 'Timurid Revival & Majolica Tilework',
          yearBuilt: 2007,
          architecturalFact: 'Home to the 7th-century Uthman Quran; features carved sandalwood columns and 50-meter minarets adorned with lapis-blue calligraphy.',
          latitude: 41.3385,
          longitude: 69.2412,
        ),
        QuestStop(
          id: 'stop-kukeldash-madrasah',
          placeId: 'kukeldash-canonical',
          name: 'Kukeldash Madrasah',
          district: 'Shaykhontohur',
          architecturalStyle: '16th Century Central Asian Islamic',
          yearBuilt: 1570,
          architecturalFact: 'Built during the Shaybanid dynasty with burnt yellow brick, high entrance peshtaq portal, and an inner sunlit courtyard.',
          latitude: 41.3217,
          longitude: 69.2361,
        ),
        QuestStop(
          id: 'stop-chorsu-dome',
          placeId: 'chorsu-bazaar-canonical',
          name: 'Chorsu Bazaar Central Dome',
          district: 'Shaykhontohur',
          architecturalStyle: 'Structural Expressionism / Modern Dome',
          yearBuilt: 1980,
          architecturalFact: 'Combines medieval trade dome acoustics with precast concrete ribs crowned by turquoise and white geometric ceramic tilework.',
          latitude: 41.3268,
          longitude: 69.2348,
        ),
      ],
    ),
    ArchitecturalQuest(
      id: 'quest-contemporary-courtyards',
      slug: 'contemporary-courtyards',
      title: 'Contemporary Cafe & Spatial Design Quest',
      badgeName: 'Urban Aesthetic Pioneer',
      description: 'Discover the new generation of Tashkent cafe spaces blending tactile travertine, raw linen, exposed brick, and verdant glass courtyards.',
      category: 'Contemporary',
      badgeIcon: 'cup.and.saucer',
      badgeAccentColorHex: '#059669', // Emerald
      requiredStopsCount: 2,
      xpReward: 50,
      curatorQuote: 'Tashkent specialty coffee venues have evolved into modern neighborhood living rooms with thoughtful spatial design.',
      stops: [
        QuestStop(
          id: 'stop-breadly-bakery',
          placeId: 'breadly-shevchenko-canonical',
          name: 'Breadly Bakery & Cafe',
          district: 'Mirabad',
          architecturalStyle: 'Warm Minimalist / Shevchenko Lane',
          yearBuilt: 2021,
          architecturalFact: 'Clean Scandinavian lines framed by high sunlit glass arches and tactile textured plaster along historic Shevchenko Street.',
          latitude: 41.3005,
          longitude: 69.2731,
        ),
        QuestStop(
          id: 'stop-bb-coffee',
          placeId: 'bb-coffee-canonical',
          name: 'B&B Coffee House',
          district: 'Yakkasaray',
          architecturalStyle: 'Industrial Warmth / Brick Loft',
          yearBuilt: 2018,
          architecturalFact: 'Repurposed brick masonry with exposed steel beams, custom leather seating, and sheltered courtyard flora.',
          latitude: 41.2912,
          longitude: 69.2554,
        ),
      ],
    ),
  ];

  /// Returns the catalog of architectural quests.
  List<ArchitecturalQuest> getAllQuests() => defaultQuests;

  /// Retrieves a specific quest by ID or slug.
  ArchitecturalQuest? getQuestById(String idOrSlug) {
    for (final q in defaultQuests) {
      if (q.id == idOrSlug || q.slug == idOrSlug) {
        return q;
      }
    }
    return null;
  }

  /// Calculates user progress across a quest based on visited place/stop IDs.
  QuestProgress calculateProgress(
    ArchitecturalQuest quest,
    Set<String> visitedPlaceOrStopIds,
  ) {
    final visitedMatched = <String>[];

    for (final stop in quest.stops) {
      if (visitedPlaceOrStopIds.contains(stop.id) ||
          visitedPlaceOrStopIds.contains(stop.placeId)) {
        visitedMatched.add(stop.id);
      }
    }

    final isCompleted = visitedMatched.length >= quest.requiredStopsCount;
    final double percentage = quest.requiredStopsCount > 0
        ? (visitedMatched.length / quest.requiredStopsCount).clamp(0.0, 1.0)
        : 1.0;

    final remaining = math.max(0, quest.requiredStopsCount - visitedMatched.length);

    return QuestProgress(
      questId: quest.id,
      visitedStopIds: visitedMatched,
      unlockedAt: isCompleted ? DateTime.now() : null,
      isCompleted: isCompleted,
      completionPercentage: percentage,
      remainingStops: remaining,
    );
  }

  /// Evaluates whether a quest badge is unlocked.
  bool isBadgeUnlocked(
    ArchitecturalQuest quest,
    Set<String> visitedPlaceOrStopIds,
  ) {
    return calculateProgress(quest, visitedPlaceOrStopIds).isCompleted;
  }

  /// Calculates total XP awarded from completed architectural quests.
  int calculateTotalXp(
    List<ArchitecturalQuest> quests,
    Set<String> visitedPlaceOrStopIds,
  ) {
    int total = 0;
    for (final quest in quests) {
      if (isBadgeUnlocked(quest, visitedPlaceOrStopIds)) {
        total += quest.xpReward;
      }
    }
    return total;
  }

  /// Checks if a user's location is within radius of a quest stop (default 80 meters).
  bool isNearStop({
    required double userLat,
    required double userLng,
    required QuestStop stop,
    double radiusMeters = 80.0,
  }) {
    final distance = computeDistanceMeters(
      userLat,
      userLng,
      stop.latitude,
      stop.longitude,
    );
    return distance <= radiusMeters;
  }

  /// Formats user-friendly localized progress string.
  String formatProgressLabel(QuestProgress progress, int requiredCount, String languageCode) {
    if (progress.isCompleted) {
      switch (languageCode) {
        case 'uz':
          return 'Bajarildi! Nishon ochildi (+50 XP)';
        case 'ru':
          return 'Завершено! Бейдж открыт (+50 XP)';
        case 'en':
        default:
          return 'Completed! Badge Unlocked (+50 XP)';
      }
    }

    final visitedCount = progress.visitedStopIds.length;
    switch (languageCode) {
      case 'uz':
        return '$visitedCount/$requiredCount to‘xtash joyi tashrif buyurildi';
      case 'ru':
        return 'Посещено $visitedCount из $requiredCount локаций';
      case 'en':
      default:
        return '$visitedCount of $requiredCount locations visited';
    }
  }

  /// Computes distance in meters between two coordinates using Haversine formula.
  static double computeDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}

/// Riverpod provider for ArchitecturalBadgeEngine.
final architecturalBadgeEngineProvider = Provider<ArchitecturalBadgeEngine>((ref) {
  return ArchitecturalBadgeEngine();
});
