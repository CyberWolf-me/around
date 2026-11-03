import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouteStop {
  final String placeId;
  final String name;
  final String district;
  final double latitude;
  final double longitude;
  final int recommendedOrder;
  final String atmosphereTag;
  final String nearestSubway;
  final int walkingMinutesFromPrevious;

  const RouteStop({
    required this.placeId,
    required this.name,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.recommendedOrder,
    required this.atmosphereTag,
    required this.nearestSubway,
    this.walkingMinutesFromPrevious = 0,
  });

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    'district': district,
    'latitude': latitude,
    'longitude': longitude,
    'recommended_order': recommendedOrder,
    'atmosphere_tag': atmosphereTag,
    'nearest_subway': nearestSubway,
    'walking_minutes_from_previous': walkingMinutesFromPrevious,
  };

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    placeId: json['place_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    district: json['district'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 41.31,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 69.28,
    recommendedOrder: (json['recommended_order'] as num?)?.toInt() ?? 1,
    atmosphereTag: json['atmosphere_tag'] as String? ?? '',
    nearestSubway: json['nearest_subway'] as String? ?? '',
    walkingMinutesFromPrevious: (json['walking_minutes_from_previous'] as num?)?.toInt() ?? 0,
  );
}

class CuratedRoute {
  final String id;
  final String title;
  final String subtitle;
  final String district;
  final String emoji;
  final List<RouteStop> stops;
  final int totalEstimatedMinutes;
  final int totalDistanceMeters;
  final int xpReward;
  final String startSubway;
  final String endSubway;

  const CuratedRoute({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.district,
    required this.emoji,
    required this.stops,
    required this.totalEstimatedMinutes,
    required this.totalDistanceMeters,
    this.xpReward = 150,
    required this.startSubway,
    required this.endSubway,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'district': district,
    'emoji': emoji,
    'stops': stops.map((s) => s.toJson()).toList(),
    'total_estimated_minutes': totalEstimatedMinutes,
    'total_distance_meters': totalDistanceMeters,
    'xp_reward': xpReward,
    'start_subway': startSubway,
    'end_subway': endSubway,
  };
}

class RouteProgressReport {
  final String routeId;
  final int totalStops;
  final int completedStops;
  final double completionFraction;
  final int completionPercentage;
  final bool isCompleted;
  final RouteStop? nextPendingStop;

  const RouteProgressReport({
    required this.routeId,
    required this.totalStops,
    required this.completedStops,
    required this.completionFraction,
    required this.completionPercentage,
    required this.isCompleted,
    this.nextPendingStop,
  });
}

class CuratedRouteEngine {
  static const List<CuratedRoute> defaultRoutes = [
    CuratedRoute(
      id: 'mirabad_coffee_crawl',
      title: 'Mirabad Specialty Coffee Crawl',
      subtitle: 'The golden triangle of Tashkent morning coffee and pastry craft',
      district: 'Mirabad',
      emoji: '☕',
      totalEstimatedMinutes: 12,
      totalDistanceMeters: 850,
      xpReward: 150,
      startSubway: 'Oybek',
      endSubway: 'Kosmonavtlar',
      stops: [
        RouteStop(
          placeId: 'place_breadly',
          name: 'Breadly Bakery & Café',
          district: 'Mirabad',
          latitude: 41.2985,
          longitude: 69.2741,
          recommendedOrder: 1,
          atmosphereTag: 'Morning Brew',
          nearestSubway: 'Oybek',
          walkingMinutesFromPrevious: 0,
        ),
        RouteStop(
          placeId: 'place_socials',
          name: 'Socials Coffee Hub',
          district: 'Mirabad',
          latitude: 41.3005,
          longitude: 69.2770,
          recommendedOrder: 2,
          atmosphereTag: 'Work Friendly',
          nearestSubway: 'Oybek',
          walkingMinutesFromPrevious: 5,
        ),
        RouteStop(
          placeId: 'place_ekler',
          name: 'Ekler Patisserie',
          district: 'Mirabad',
          latitude: 41.3030,
          longitude: 69.2792,
          recommendedOrder: 3,
          atmosphereTag: 'Sweet Bite',
          nearestSubway: 'Kosmonavtlar',
          walkingMinutesFromPrevious: 7,
        ),
      ],
    ),
    CuratedRoute(
      id: 'chorsu_heritage_trail',
      title: 'Old City Heritage & Bazaar Trail',
      subtitle: 'Sensory journey through clay tandoors, spice alleys, and steaming plov',
      district: 'Old City',
      emoji: '🍲',
      totalEstimatedMinutes: 16,
      totalDistanceMeters: 1100,
      xpReward: 150,
      startSubway: 'Chorsu',
      endSubway: 'Gafur Gulom',
      stops: [
        RouteStop(
          placeId: 'place_chorsu',
          name: 'Chorsu Bazaar Food Court',
          district: 'Old City',
          latitude: 41.3275,
          longitude: 69.2350,
          recommendedOrder: 1,
          atmosphereTag: 'Heritage Food',
          nearestSubway: 'Chorsu',
          walkingMinutesFromPrevious: 0,
        ),
        RouteStop(
          placeId: 'place_samarkand',
          name: 'Samarkand Darvoza Osh',
          district: 'Old City',
          latitude: 41.3220,
          longitude: 69.2310,
          recommendedOrder: 2,
          atmosphereTag: 'Master Plov',
          nearestSubway: 'Chorsu',
          walkingMinutesFromPrevious: 8,
        ),
      ],
    ),
    CuratedRoute(
      id: 'central_cultural_promenade',
      title: 'Central Tashkent Cultural Promenade',
      subtitle: 'Modern architectural walk between Broadway, teatime, and Uzbek hospitality',
      district: 'Central Tashkent',
      emoji: '🏛️',
      totalEstimatedMinutes: 14,
      totalDistanceMeters: 980,
      xpReward: 150,
      startSubway: 'Amir Temur Xiyoboni',
      endSubway: 'Mustaqillik Maydoni',
      stops: [
        RouteStop(
          placeId: 'place_tims',
          name: 'TIMS Coffee & Roastery',
          district: 'Central Tashkent',
          latitude: 41.3120,
          longitude: 69.2805,
          recommendedOrder: 1,
          atmosphereTag: 'Specialty Roast',
          nearestSubway: 'Amir Temur Xiyoboni',
          walkingMinutesFromPrevious: 0,
        ),
        RouteStop(
          placeId: 'place_afsona',
          name: 'Afsona Uzbek Contemporary',
          district: 'Central Tashkent',
          latitude: 41.3090,
          longitude: 69.2760,
          recommendedOrder: 2,
          atmosphereTag: 'Authentic Fusion',
          nearestSubway: 'Mustaqillik Maydoni',
          walkingMinutesFromPrevious: 6,
        ),
        RouteStop(
          placeId: 'place_dodo',
          name: 'Dodo Amir Temur',
          district: 'Central Tashkent',
          latitude: 41.3135,
          longitude: 69.2825,
          recommendedOrder: 3,
          atmosphereTag: 'Casual Hangout',
          nearestSubway: 'Amir Temur Xiyoboni',
          walkingMinutesFromPrevious: 8,
        ),
      ],
    ),
    CuratedRoute(
      id: 'tashkent_modernist_trail',
      title: 'Tashkent Soviet Modernist Architecture Trail',
      subtitle: 'Monumental 1966-1985 concrete sun-screens, shell structures, and iconic landmarks',
      district: 'Central Tashkent',
      emoji: '🏛️',
      totalEstimatedMinutes: 27,
      totalDistanceMeters: 3200,
      xpReward: 200,
      startSubway: 'Amir Temur Xiyoboni',
      endSubway: 'Shahriston',
      stops: [
        RouteStop(
          placeId: 'hotel-uzbekistan',
          name: 'Hotel Uzbekistan',
          district: 'Mirzo Ulugbek',
          latitude: 41.3130,
          longitude: 69.2810,
          recommendedOrder: 1,
          atmosphereTag: 'Brutalist Panjara',
          nearestSubway: 'Amir Temur Xiyoboni',
          walkingMinutesFromPrevious: 0,
        ),
        RouteStop(
          placeId: 'panorama-cinema',
          name: 'Panorama Cinema (Palace of Arts)',
          district: 'Shaykhontohur',
          latitude: 41.3195,
          longitude: 69.2485,
          recommendedOrder: 2,
          atmosphereTag: 'Shell Concrete',
          nearestSubway: 'Alisher Navoiy',
          walkingMinutesFromPrevious: 12,
        ),
        RouteStop(
          placeId: 'tashkent-tv-tower',
          name: 'Tashkent TV Tower',
          district: 'Yunusabad',
          latitude: 41.3458,
          longitude: 69.2845,
          recommendedOrder: 3,
          atmosphereTag: 'Panoramic Summit',
          nearestSubway: 'Shahriston',
          walkingMinutesFromPrevious: 15,
        ),
      ],
    ),
    CuratedRoute(
      id: 'chorsu_tandoor_and_tea_crawl',
      title: 'Old City Tandoor Bread & Chaykhana Crawl',
      subtitle: 'Sensory morning journey through clay tandoors, hot obi non, and shaded tea tapchans',
      district: 'Old City',
      emoji: '🫓',
      totalEstimatedMinutes: 15,
      totalDistanceMeters: 950,
      xpReward: 175,
      startSubway: 'Chorsu',
      endSubway: 'Chorsu',
      stops: [
        RouteStop(
          placeId: 'chorsu-kattabog-bakery',
          name: 'Chorsu Kattabog Tandoor Bakery',
          district: 'Shaykhontohur',
          latitude: 41.3283,
          longitude: 69.2394,
          recommendedOrder: 1,
          atmosphereTag: 'Fresh Tandoor Non',
          nearestSubway: 'Chorsu',
          walkingMinutesFromPrevious: 0,
        ),
        RouteStop(
          placeId: 'chorsu-chinor-chaykhana',
          name: 'Chorsu Chinor Chaykhana',
          district: 'Shaykhontohur',
          latitude: 41.3268,
          longitude: 69.2372,
          recommendedOrder: 2,
          atmosphereTag: 'Kok-Choy Ritual',
          nearestSubway: 'Chorsu',
          walkingMinutesFromPrevious: 4,
        ),
        RouteStop(
          placeId: 'chorsu',
          name: 'Chorsu Milliy Taomlar',
          district: 'Shaykhontohur',
          latitude: 41.3268,
          longitude: 69.2344,
          recommendedOrder: 3,
          atmosphereTag: 'Wedding Plov',
          nearestSubway: 'Chorsu',
          walkingMinutesFromPrevious: 5,
        ),
      ],
    ),
  ];

  static List<CuratedRoute> getAllRoutes() => defaultRoutes;

  static CuratedRoute? getRouteById(String id) {
    try {
      return defaultRoutes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<CuratedRoute> getRoutesForDistrict(String district) {
    return defaultRoutes
        .where((r) => r.district.toLowerCase() == district.trim().toLowerCase())
        .toList();
  }

  static RouteProgressReport computeProgress(
    CuratedRoute route,
    Set<String> visitedPlaceIds,
  ) {
    if (route.stops.isEmpty) {
      return RouteProgressReport(
        routeId: route.id,
        totalStops: 0,
        completedStops: 0,
        completionFraction: 0.0,
        completionPercentage: 0,
        isCompleted: false,
      );
    }

    int completed = 0;
    RouteStop? nextPending;

    for (final stop in route.stops) {
      if (visitedPlaceIds.contains(stop.placeId)) {
        completed += 1;
      } else {
        nextPending ??= stop;
      }
    }

    final fraction = completed / route.stops.length;
    final percent = (fraction * 100).round();
    final isDone = completed == route.stops.length;

    return RouteProgressReport(
      routeId: route.id,
      totalStops: route.stops.length,
      completedStops: completed,
      completionFraction: double.parse(fraction.toStringAsFixed(2)),
      completionPercentage: percent,
      isCompleted: isDone,
      nextPendingStop: nextPending,
    );
  }

  static int calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadiusMeters * c).round();
  }

  static int estimateWalkingMinutes(int distanceMeters) {
    // Average urban walking speed: 80 meters per minute (4.8 km/h)
    if (distanceMeters <= 0) return 0;
    final mins = (distanceMeters / 80.0).round();
    return math.max(1, mins);
  }

  static String getLocalizedTitle(CuratedRoute route, String lang) {
    if (lang == 'uz') {
      switch (route.id) {
        case 'mirabad_coffee_crawl':
          return 'Mirobod Qahva Sayri';
        case 'chorsu_heritage_trail':
          return 'Eski Shahar Merosi va Bozor Yo‘li';
        case 'central_cultural_promenade':
          return 'Markaziy Toshkent Madaniy Sayri';
      }
    } else if (lang == 'ru') {
      switch (route.id) {
        case 'mirabad_coffee_crawl':
          return 'Кофейный маршрут по Мирабаду';
        case 'chorsu_heritage_trail':
          return 'Исторический маршрут по Чорсу';
        case 'central_cultural_promenade':
          return 'Культурная прогулка по Центру';
      }
    }
    return route.title;
  }
}

final curatedRouteEngineProvider = Provider<CuratedRouteEngine>((ref) {
  return CuratedRouteEngine();
});

final allCuratedRoutesProvider = Provider<List<CuratedRoute>>((ref) {
  return CuratedRouteEngine.getAllRoutes();
});
