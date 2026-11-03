import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a sensory stop in an artisan tasting flight.
class TastingStop {
  final String id;
  final String placeId;
  final String venueName;
  final String district;
  final String itemTitle;
  final List<String> flavorNotes;
  final String originStory;
  final String? suggestedServingTemp;
  final double latitude;
  final double longitude;

  const TastingStop({
    required this.id,
    required this.placeId,
    required this.venueName,
    required this.district,
    required this.itemTitle,
    required this.flavorNotes,
    required this.originStory,
    this.suggestedServingTemp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': placeId,
    'venue_name': venueName,
    'district': district,
    'item_title': itemTitle,
    'flavor_notes': flavorNotes,
    'origin_story': originStory,
    if (suggestedServingTemp != null) 'suggested_serving_temp': suggestedServingTemp,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory TastingStop.fromJson(Map<String, dynamic> json) {
    final notes = (json['flavor_notes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return TastingStop(
      id: json['id'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      venueName: json['venue_name'] as String? ?? 'Artisan Venue',
      district: json['district'] as String? ?? 'Tashkent',
      itemTitle: json['item_title'] as String? ?? 'Tasting Specimen',
      flavorNotes: notes,
      originStory: json['origin_story'] as String? ?? '',
      suggestedServingTemp: json['suggested_serving_temp'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
    );
  }
}

/// A curated flight of artisan tasting experiences with a completion certificate.
class TastingFlight {
  final String id;
  final String slug;
  final String title;
  final String curatorTitle;
  final String description;
  final String category;
  final String flightIcon;
  final String accentColorHex;
  final int requiredStopsCount;
  final int xpReward;
  final List<TastingStop> stops;

  const TastingFlight({
    required this.id,
    required this.slug,
    required this.title,
    required this.curatorTitle,
    required this.description,
    required this.category,
    required this.flightIcon,
    required this.accentColorHex,
    required this.requiredStopsCount,
    this.xpReward = 50,
    required this.stops,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'curator_title': curatorTitle,
    'description': description,
    'category': category,
    'flight_icon': flightIcon,
    'accent_color_hex': accentColorHex,
    'required_stops_count': requiredStopsCount,
    'xp_reward': xpReward,
    'stops': stops.map((s) => s.toJson()).toList(),
  };

  factory TastingFlight.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    return TastingFlight(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Tasting Flight',
      curatorTitle: json['curator_title'] as String? ?? 'Artisan Flight',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Coffee',
      flightIcon: json['flight_icon'] as String? ?? 'cup.and.saucer',
      accentColorHex: json['accent_color_hex'] as String? ?? '#845EC2',
      requiredStopsCount: (json['required_stops_count'] as num?)?.toInt() ?? 3,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 50,
      stops: rawStops.map((s) => TastingStop.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

/// Logged user cupping and evaluation for a stop.
class TastingLog {
  final String stopId;
  final double rating; // 1.0 to 10.0
  final List<String> selectedFlavorNotes;
  final String? tastingNotes;
  final DateTime loggedAt;

  const TastingLog({
    required this.stopId,
    required this.rating,
    required this.selectedFlavorNotes,
    this.tastingNotes,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'stop_id': stopId,
    'rating': rating,
    'selected_flavor_notes': selectedFlavorNotes,
    if (tastingNotes != null) 'tasting_notes': tastingNotes,
    'logged_at': loggedAt.toIso8601String(),
  };

  factory TastingLog.fromJson(Map<String, dynamic> json) {
    final notes = (json['selected_flavor_notes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return TastingLog(
      stopId: json['stop_id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 8.0,
      selectedFlavorNotes: notes,
      tastingNotes: json['tasting_notes'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.tryParse(json['logged_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Evaluated user progress for a tasting flight.
class FlightProgress {
  final String flightId;
  final List<String> completedStopIds;
  final double averageCuppingScore;
  final List<String> allFlavorNotes;
  final bool isCompleted;
  final double completionPercentage;
  final int remainingStops;

  const FlightProgress({
    required this.flightId,
    required this.completedStopIds,
    required this.averageCuppingScore,
    required this.allFlavorNotes,
    required this.isCompleted,
    required this.completionPercentage,
    required this.remainingStops,
  });
}

/// Engine for evaluating tasting flights, cupping notes, and curator certificates.
class TastingFlightEngine {
  static const List<TastingFlight> defaultFlights = [
    TastingFlight(
      id: 'flight-specialty-coffee',
      slug: 'tashkent-specialty-coffee-flight',
      title: 'Tashkent Third-Wave Roastery Flight',
      curatorTitle: 'Specialty Coffee Cupping Certificate',
      description: 'Taste through single-origin Ethiopian naturals, anaerobic fermentations, and silky flat whites crafted by Tashkent micro-roasters.',
      category: 'Coffee',
      flightIcon: 'cup.and.saucer',
      accentColorHex: '#A259FF', // Violet
      requiredStopsCount: 3,
      xpReward: 50,
      stops: [
        TastingStop(
          id: 'stop-breadly-cupping',
          placeId: 'breadly-shevchenko-canonical',
          venueName: 'Breadly Bakery & Roastery',
          district: 'Mirabad',
          itemTitle: 'Ethiopia Sidama Natural Pour-Over',
          flavorNotes: ['Bergamot', 'Dried Peach', 'Wild Jasmine'],
          originStory: 'Slow-drip V60 extracted at 92°C highlighting high-altitude floral aromatics.',
          suggestedServingTemp: '92°C V60',
          latitude: 41.3005,
          longitude: 69.2731,
        ),
        TastingStop(
          id: 'stop-bb-anaerobic',
          placeId: 'bb-coffee-canonical',
          venueName: 'B&B Coffee House',
          district: 'Yakkasaray',
          itemTitle: 'Colombia Anaerobic Filter & Flat White',
          flavorNotes: ['Red Currant', 'Dark Cacao', 'Brown Sugar'],
          originStory: '72-hour extended maceration yielding deep winey sweetness and velvety crema.',
          suggestedServingTemp: 'Aeropress / 65°C Microfoam',
          latitude: 41.2912,
          longitude: 69.2554,
        ),
        TastingStop(
          id: 'stop-paul-bistro',
          placeId: 'paul-tashkent-canonical',
          venueName: 'Paul Bakery & Bistro',
          district: 'Mirabad',
          itemTitle: 'Guatemala Huehuetenango Cortado',
          flavorNotes: ['Roasted Hazelnut', 'Toffee', 'Orange Zest'],
          originStory: 'Classic medium roast balanced with steamed alpine whole milk.',
          suggestedServingTemp: 'Double Shot Cortado',
          latitude: 41.3112,
          longitude: 69.2810,
        ),
      ],
    ),
    TastingFlight(
      id: 'flight-chaykhana-tea',
      slug: 'tashkent-tea-master-trail',
      title: 'Silk Road Chaykhana & Saffron Tea Trail',
      curatorTitle: 'Chaykhana Sommelier Laurels',
      description: 'Experience timeless Uzbek tea hospitality in hand-painted Rishtan ceramic pialahs across Old City mahallas.',
      category: 'Tea',
      flightIcon: 'leaf',
      accentColorHex: '#00D2FC', // Cyan / Ceramic Blue
      requiredStopsCount: 2,
      xpReward: 50,
      stops: [
        TastingStop(
          id: 'stop-chorsu-chaykhana',
          placeId: 'chorsu-bazaar-canonical',
          venueName: 'Chorsu Chaykhana Pavilion',
          district: 'Shaykhontohur',
          itemTitle: 'Kok Choy No. 95 with Mountain Thyme',
          flavorNotes: ['Wild Thyme', 'Green Apple', 'Pine Needle'],
          originStory: 'Classic green tea steeped in clay teapots, poured thrice to "kaytar" marry the leaves.',
          suggestedServingTemp: 'Hot Clay Pialah',
          latitude: 41.3268,
          longitude: 69.2348,
        ),
        TastingStop(
          id: 'stop-blue-domes-tea',
          placeId: 'blue-domes-cafe-canonical',
          venueName: 'Golubye Kupola Chay Lounge',
          district: 'Yakkasaray',
          itemTitle: 'Bukhara Saffron & Cardamom Black Tea',
          flavorNotes: ['Zarafshan Saffron', 'Green Cardamom', 'Altai Honey'],
          originStory: 'Hand-picked saffron threads blooming in whole-leaf Ceylon tea with dried lemon.',
          suggestedServingTemp: 'Porcelain Samovar',
          latitude: 41.3090,
          longitude: 69.2678,
        ),
      ],
    ),
  ];

  /// Returns the catalog of tasting flights.
  List<TastingFlight> getAllFlights() => defaultFlights;

  /// Retrieves a specific flight by ID or slug.
  TastingFlight? getFlightById(String idOrSlug) {
    for (final f in defaultFlights) {
      if (f.id == idOrSlug || f.slug == idOrSlug) {
        return f;
      }
    }
    return null;
  }

  /// Calculates user progress across a flight based on logged tasting experiences.
  FlightProgress calculateProgress(
    TastingFlight flight,
    Map<String, TastingLog> userLogsByStopOrPlaceId,
  ) {
    final completedStops = <String>[];
    final allFlavorNotes = <String>{};
    double totalScore = 0.0;

    for (final stop in flight.stops) {
      final log = userLogsByStopOrPlaceId[stop.id] ??
          userLogsByStopOrPlaceId[stop.placeId];

      if (log != null) {
        completedStops.add(stop.id);
        totalScore += log.rating;
        allFlavorNotes.addAll(log.selectedFlavorNotes);
      }
    }

    final count = completedStops.length;
    final isCompleted = count >= flight.requiredStopsCount;
    final double percentage = flight.requiredStopsCount > 0
        ? (count / flight.requiredStopsCount).clamp(0.0, 1.0)
        : 1.0;

    final double avgScore = count > 0 ? (totalScore / count) : 0.0;
    final remaining = math.max(0, flight.requiredStopsCount - count);

    return FlightProgress(
      flightId: flight.id,
      completedStopIds: completedStops,
      averageCuppingScore: double.parse(avgScore.toStringAsFixed(1)),
      allFlavorNotes: allFlavorNotes.toList(),
      isCompleted: isCompleted,
      completionPercentage: percentage,
      remainingStops: remaining,
    );
  }

  /// Evaluates whether a flight cupping certificate is unlocked.
  bool isFlightCompleted(
    TastingFlight flight,
    Map<String, TastingLog> userLogsByStopOrPlaceId,
  ) {
    return calculateProgress(flight, userLogsByStopOrPlaceId).isCompleted;
  }

  /// Calculates total XP awarded from completed flights.
  int calculateTotalFlightXp(
    List<TastingFlight> flights,
    Map<String, TastingLog> userLogsByStopOrPlaceId,
  ) {
    int total = 0;
    for (final flight in flights) {
      if (isFlightCompleted(flight, userLogsByStopOrPlaceId)) {
        total += flight.xpReward;
      }
    }
    return total;
  }

  /// Formats user-friendly localized progress string.
  String formatFlightProgressLabel(
    FlightProgress progress,
    int requiredCount,
    String languageCode,
  ) {
    if (progress.isCompleted) {
      switch (languageCode) {
        case 'uz':
          return 'Tasting yakunlandi! Sertifikat ochildi (+50 XP)';
        case 'ru':
          return 'Дегустация завершена! Сертификат открыт (+50 XP)';
        case 'en':
        default:
          return 'Flight Completed! Cupping Certificate Unlocked (+50 XP)';
      }
    }

    final visitedCount = progress.completedStopIds.length;
    switch (languageCode) {
      case 'uz':
        return '$visitedCount/$requiredCount degustatsiya bajarildi';
      case 'ru':
        return 'Оценено $visitedCount из $requiredCount дегустаций';
      case 'en':
      default:
        return '$visitedCount of $requiredCount tastings logged';
    }
  }
}

/// Riverpod provider for TastingFlightEngine.
final tastingFlightEngineProvider = Provider<TastingFlightEngine>((ref) {
  return TastingFlightEngine();
});
