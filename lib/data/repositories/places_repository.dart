import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_logger.dart';
import '../models/place_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository();
});

class RecommendedPlaceResult {
  final PlaceModel place;
  final double relevanceScore;
  final int friendsRecommendCount;
  final String explanation;

  const RecommendedPlaceResult({
    required this.place,
    required this.relevanceScore,
    required this.friendsRecommendCount,
    required this.explanation,
  });
}

class PlacesRepository {
  static const Map<String, String> _legacyAliases = {
    'kettle': 'breadly',
    'fern': 'bnb',
    'sable': 'steam',
    'castellan': 'steam',
    'volta': 'kitobxon',
    'marigold': 'ecorn',
    'noodle': 'chorsu',
    'longtable': 'bnb',
    'quiet': 'tims',
  };

  static final List<PlaceModel> _canonicalPlaces = [
    const PlaceModel(
      id: 'breadly',
      canonicalUuid: '11111111-1111-4111-8111-111111111101',
      slug: 'breadly-bakery-cafe',
      name: 'Breadly Bakery & Café',
      category: 'Bakery · Specialty Café',
      streetAddress: '24 Taras Shevchenko Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.2996,
      longitude: 69.2748,
      distanceMeters: 320,
      walkTimeMinutes: 4,
      priceTier: r'$$',
      hours: '8:00 AM – 10:00 PM',
      statusLine: 'Open today · Fresh bake at 8am',
      description: 'Sun-drenched courtyard bakery in Mirabad. Artisan sourdough baked fresh daily, lavender matcha, delicate pastries, and Tashkent’s best brunch veranda.',
      heroImageUrl: 'assets/bakery-counter.jpg',
      ratingAvg: 4.8,
      ratingCount: 342,
      tags: ['artisan sourdough', 'courtyard', 'specialty coffee', 'quiet mornings'],
      photos: ['assets/bakery-counter.jpg', 'assets/cafe-light.jpg', 'assets/pastries.jpg'],
    ),
    const PlaceModel(
      id: 'bnb',
      canonicalUuid: '11111111-1111-4111-8111-111111111102',
      slug: 'bnb-coffee-house',
      name: 'B&B Coffee House',
      category: 'Study Café · Roastery',
      streetAddress: '24 Shota Rustaveli Street',
      district: 'Yakkasaray',
      city: 'Tashkent',
      latitude: 41.2918,
      longitude: 69.2619,
      distanceMeters: 550,
      walkTimeMinutes: 7,
      priceTier: r'$',
      hours: '8:00 AM – 11:00 PM',
      statusLine: 'Closes 11pm · Fast Wi-Fi',
      description: 'The definitive Tashkent student and remote-work haven. Sockets at every wooden booth, single-origin pour-overs, Basque cheesecake, and focused vibe.',
      heroImageUrl: 'assets/study-desk.jpg',
      ratingAvg: 4.6,
      ratingCount: 512,
      tags: ['power outlets', 'study-friendly', 'chemex', 'long stays'],
      photos: ['assets/study-table.jpg', 'assets/cafe-light.jpg', 'assets/study-desk.jpg'],
    ),
    const PlaceModel(
      id: 'ecorn',
      canonicalUuid: '11111111-1111-4111-8111-111111111103',
      slug: 'ecorn-patisserie',
      name: 'Ecorn Patisserie',
      category: 'French Patisserie · Bistro',
      streetAddress: '32 Amir Timur Avenue',
      district: 'Yunusabad',
      city: 'Tashkent',
      latitude: 41.3175,
      longitude: 69.2825,
      distanceMeters: 700,
      walkTimeMinutes: 9,
      priceTier: r'$$$',
      hours: '9:00 AM – 10:00 PM',
      statusLine: 'Closes 10pm · Terrace open',
      description: 'Refined Parisian viennoiserie overlooking Amir Timur Avenue. Flaky pistachio pain au chocolat, raspberry mille-feuille, and quiet second-floor terrace.',
      heroImageUrl: 'assets/patisserie.jpg',
      ratingAvg: 4.7,
      ratingCount: 228,
      tags: ['pistachio eclair', 'terrace', 'date spot', 'french press'],
      photos: ['assets/patisserie.jpg', 'assets/pastries.jpg', 'assets/storefront.jpg'],
    ),
    const PlaceModel(
      id: 'tims',
      canonicalUuid: '11111111-1111-4111-8111-111111111104',
      slug: 'tims-coffee-roastery',
      name: 'Tim’s Coffee & Roastery',
      category: 'Specialty Roastery · Espresso Bar',
      streetAddress: '40 Taras Shevchenko Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.2975,
      longitude: 69.2778,
      distanceMeters: 450,
      walkTimeMinutes: 6,
      priceTier: r'$$',
      hours: '8:00 AM – 11:00 PM',
      statusLine: 'Open today · Roasting Tuesdays',
      description: 'Tashkent’s third-wave pioneer. Micro-roasted Ethiopian and Colombian beans, calibrated espresso flights, communal wooden benches, and tech founders crowd.',
      heroImageUrl: 'assets/cafe-light.jpg',
      ratingAvg: 4.9,
      ratingCount: 419,
      tags: ['single origin', 'v60 pour-over', 'tech crowd', 'roastery'],
      photos: ['assets/cafe-light.jpg', 'assets/records-crates.jpg', 'assets/cafe-bw.jpg'],
    ),
    const PlaceModel(
      id: 'chorsu',
      canonicalUuid: '11111111-1111-4111-8111-111111111105',
      slug: 'chorsu-national-food',
      name: 'Chorsu Milliy Taomlar',
      category: 'Uzbek Cuisine · Open Kitchen',
      streetAddress: 'Beruni Avenue, Chorsu Old City',
      district: 'Shaykhontohur',
      city: 'Tashkent',
      latitude: 41.3268,
      longitude: 69.2344,
      distanceMeters: 1200,
      walkTimeMinutes: 16,
      priceTier: r'$',
      hours: '10:00 AM – 9:00 PM',
      statusLine: 'Wedding Plov ready at 11am',
      description: 'The monumental culinary soul of Old Tashkent. Giant steaming bronze kazans of saffron-scented Wedding Osh plov, crisp tandir somsa, and lemon tea under azure domes.',
      heroImageUrl: 'assets/street.jpg',
      ratingAvg: 4.9,
      ratingCount: 880,
      tags: ['wedding plov', 'tandir somsa', 'kazan cooking', 'authentic', 'ramen'],
      photos: ['assets/street.jpg', 'assets/ramen-bowl.jpg', 'assets/storefront.jpg'],
    ),
    const PlaceModel(
      id: 'centralpark',
      canonicalUuid: '11111111-1111-4111-8111-111111111106',
      slug: 'central-park-tashkent',
      name: 'Central Park (Mirzo Ulugbek)',
      category: 'Park · Green Promenade',
      streetAddress: '21 Movaraunnahr Street',
      district: 'Mirzo Ulugbek',
      city: 'Tashkent',
      latitude: 41.3142,
      longitude: 69.2931,
      distanceMeters: 850,
      walkTimeMinutes: 11,
      priceTier: 'Free',
      hours: '6:00 AM – 11:00 PM',
      statusLine: 'Open · Sunset promenade',
      description: 'Centuries-old shaded sycamores, swans paddling along the lake, rollerblading paths, and evening matcha kiosks. Tashkent’s premier outdoor community space.',
      heroImageUrl: 'assets/window-girl.jpg',
      ratingAvg: 4.7,
      ratingCount: 654,
      tags: ['shaded walks', 'evening strolls', 'lake', 'matcha kiosk'],
      photos: ['assets/window-girl.jpg', 'assets/cafe-bw.jpg', 'assets/street.jpg'],
    ),
    const PlaceModel(
      id: 'steam',
      canonicalUuid: '11111111-1111-4111-8111-111111111107',
      slug: 'steam-bar-lounge',
      name: 'Steam Bar & Lounge',
      category: 'Cocktail Lounge · Wine Bar · Vinyl Records',
      streetAddress: '29 Nukus Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.2942,
      longitude: 69.2694,
      distanceMeters: 620,
      walkTimeMinutes: 8,
      priceTier: r'$$$',
      hours: '6:00 PM – 2:00 AM',
      statusLine: 'Opens 6pm · DJ from 9pm',
      description: 'Industrial steampunk aesthetics, curated craft cocktails infused with local pomegranate and mountain herbs, and resident DJs playing analog vinyl sets.',
      heroImageUrl: 'assets/wine-wide.jpg',
      ratingAvg: 4.6,
      ratingCount: 310,
      tags: ['craft cocktails', 'vinyl DJ', 'late night', 'date spot', 'records', 'wine bar'],
      photos: ['assets/wine-wide.jpg', 'assets/wine-tall.jpg', 'assets/records.jpg'],
    ),
    const PlaceModel(
      id: 'kitobxon',
      canonicalUuid: '11111111-1111-4111-8111-111111111108',
      slug: 'kitobxon-book-cafe',
      name: 'Kitobxon Book Café',
      category: 'Bookshop · Literary Café',
      streetAddress: '11 Alisher Navoi Avenue',
      district: 'Yunusabad',
      city: 'Tashkent',
      latitude: 41.3182,
      longitude: 69.2558,
      distanceMeters: 450,
      walkTimeMinutes: 6,
      priceTier: r'$',
      hours: '9:00 AM – 9:00 PM',
      statusLine: 'Open today · Quiet reading zone',
      description: 'Three-room independent bookstore café near Navoi Theatre. Floor-to-ceiling shelves of Uzbek and world classics, plush armchairs, and slow Aeropress coffee.',
      heroImageUrl: 'assets/bookshop.jpg',
      ratingAvg: 4.8,
      ratingCount: 195,
      tags: ['bookstore', 'bookshop', 'quiet nooks', 'aeropress', 'reading'],
      photos: ['assets/bookshop.jpg', 'assets/bookshop-tall.jpg', 'assets/storefront.jpg'],
    ),
    const PlaceModel(
      id: 'broadway',
      canonicalUuid: '11111111-1111-4111-8111-111111111109',
      slug: 'broadway-sayilgoh',
      name: 'Broadway (Sayilgoh Street)',
      category: 'Pedestrian Promenade · Arts',
      streetAddress: 'Sayilgoh Street, Amir Timur Square',
      district: 'Yunusabad',
      city: 'Tashkent',
      latitude: 41.3129,
      longitude: 69.2772,
      distanceMeters: 380,
      walkTimeMinutes: 5,
      priceTier: r'$',
      hours: 'Open 24 hours',
      statusLine: 'Lively atmosphere tonight',
      description: 'Tashkent’s legendary pedestrian avenue connecting Mustaqillik Square and Amir Timur Square. Portrait painters, antique vendors, street performers, and ice cream stands.',
      heroImageUrl: 'assets/storefront.jpg',
      ratingAvg: 4.5,
      ratingCount: 780,
      tags: ['street artists', 'souvenirs', 'night stroll', 'bustling'],
      photos: ['assets/storefront.jpg', 'assets/street.jpg', 'assets/ramen-bowl.jpg'],
    ),
    const PlaceModel(
      id: 'sette',
      canonicalUuid: '11111111-1111-4111-8111-111111111110',
      slug: 'sette-restaurant-terrace',
      name: 'Sette Restaurant & Terrace',
      category: 'Italian Cuisine · Rooftop Terrace',
      streetAddress: '1 Navoi Avenue (Hyatt Regency)',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3168,
      longitude: 69.2785,
      distanceMeters: 720,
      walkTimeMinutes: 9,
      priceTier: r'$$$$',
      hours: '12:00 PM – 11:30 PM',
      statusLine: 'Open today · Sunset rooftop seating',
      description: 'Panoramic 7th-floor rooftop views over Amir Timur Square. Wood-fired Neapolitan pizza, handmade tagliolini with truffles, and an extensive European wine collection.',
      heroImageUrl: 'assets/wine-wide.jpg',
      ratingAvg: 4.8,
      ratingCount: 340,
      tags: ['rooftop', 'panoramic view', 'sunset', 'wine bar', 'wood-fired pizza', 'dinner', 'terrace'],
      photos: ['assets/wine-wide.jpg', 'assets/wine-tall.jpg', 'assets/storefront.jpg'],
    ),
    const PlaceModel(
      id: 'socials',
      canonicalUuid: '11111111-1111-4111-8111-111111111111',
      slug: 'socials-cafe-bar',
      name: 'Socials Café & Bar',
      category: 'All-Day Brunch · Specialty Coffee',
      streetAddress: '34 Taras Shevchenko Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3005,
      longitude: 69.2742,
      distanceMeters: 510,
      walkTimeMinutes: 7,
      priceTier: r'$$',
      hours: '8:00 AM – 11:00 PM',
      statusLine: 'Open · All-day sourdough toast',
      description: 'High-energy neighborhood hub on Shevchenko. Fluffy ricotta hotcakes, smashed avocado toast on artisan sourdough, and expertly pulled flat whites.',
      heroImageUrl: 'assets/cafe-light.jpg',
      ratingAvg: 4.7,
      ratingCount: 280,
      tags: ['brunch', 'ricotta hotcakes', 'specialty coffee', 'shevchenko', 'terrace', 'coffee', 'breakfast'],
      photos: ['assets/cafe-light.jpg', 'assets/window-girl.jpg', 'assets/cafe-bw.jpg'],
    ),
    const PlaceModel(
      id: 'afsona',
      canonicalUuid: '11111111-1111-4111-8111-111111111112',
      slug: 'afsona-contemporary-uzbek',
      name: 'Afsona Contemporary Uzbek',
      category: 'Modern Uzbek Cuisine · Wine Bar',
      streetAddress: '30 Taras Shevchenko Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3021,
      longitude: 69.2760,
      distanceMeters: 480,
      walkTimeMinutes: 6,
      priceTier: r'$$$',
      hours: '12:00 PM – 11:00 PM',
      statusLine: 'Open · Contemporary dining',
      description: 'Refined contemporary interpretation of traditional Uzbek gastronomy. Slow-braised lamb shank with quince, vegetarian pumpkin manti, and regional Samarkand wines.',
      heroImageUrl: 'assets/ramen-bowl.jpg',
      ratingAvg: 4.8,
      ratingCount: 410,
      tags: ['modern uzbek', 'shevchenko', 'lamb shank', 'wine bar', 'date spot', 'dinner'],
      photos: ['assets/ramen-bowl.jpg', 'assets/street.jpg', 'assets/wine-tall.jpg'],
    ),
    const PlaceModel(
      id: 'caravan',
      canonicalUuid: '11111111-1111-4111-8111-111111111113',
      slug: 'caravan-art-restaurant',
      name: 'Caravan Art Café & Restaurant',
      category: 'Traditional Uzbek · Art Courtyard',
      streetAddress: '22 Abdulla Qahhor Street',
      district: 'Yakkasaray',
      city: 'Tashkent',
      latitude: 41.2910,
      longitude: 69.2625,
      distanceMeters: 920,
      walkTimeMinutes: 12,
      priceTier: r'$$$',
      hours: '11:00 AM – 11:00 PM',
      statusLine: 'Open · Courtyard fountain active',
      description: 'Tashkent’s first art restaurant set within a traditional Uzbek residential courtyard. Handwoven Suzani tapestries, antique ceramics, and slow-cooked tandoor dishes.',
      heroImageUrl: 'assets/storefront.jpg',
      ratingAvg: 4.7,
      ratingCount: 520,
      tags: ['art cafe', 'courtyard', 'traditional', 'dutar music', 'suzani', 'dinner'],
      photos: ['assets/storefront.jpg', 'assets/street.jpg', 'assets/records-crates.jpg'],
    ),
    const PlaceModel(
      id: 'teplo',
      canonicalUuid: '11111111-1111-4111-8111-111111111114',
      slug: 'teplo-bakery-kitchen',
      name: 'Teplo Bakery & Kitchen',
      category: 'Artisan Bakery · Breakfast',
      streetAddress: '42 Sadyk Azimov Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3082,
      longitude: 69.2845,
      distanceMeters: 650,
      walkTimeMinutes: 8,
      priceTier: r'$$',
      hours: '8:00 AM – 10:00 PM',
      statusLine: 'Fresh baguettes and brioche ready',
      description: 'Cozy neighborhood bakery famous for crusty baguettes, almond croissants, shakshuka, and specialty coffee. Warm Scandi-Uzbek oak interior.',
      heroImageUrl: 'assets/breadly.jpg',
      ratingAvg: 4.8,
      ratingCount: 295,
      tags: ['bakery', 'croissants', 'shakshuka', 'breakfast', 'coffee', 'specialty coffee'],
      photos: ['assets/breadly.jpg', 'assets/cafe-light.jpg', 'assets/window-girl.jpg'],
    ),
  ];

  static String resolveCanonicalId(String id) {
    return _legacyAliases[id] ?? id;
  }

  /// Calculates Haversine great-circle distance in meters between two WGS84 coordinates.
  static double calculateDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  List<PlaceModel> getAllPlaces() {
    final custom = StorageService.getCustomPlaces();
    return [..._canonicalPlaces, ...custom];
  }

  Future<void> addCustomPlace(PlaceModel place) async {
    final existingCustom = StorageService.getCustomPlaces();
    final updated = [...existingCustom, place];
    await StorageService.persistCustomPlaces(updated);

    if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
      try {
        await SupabaseService.client.from('places').insert({
          'slug': place.slug,
          'name': place.name,
          'category': place.category,
          'street_address': place.streetAddress,
          'district': place.district,
          'city': place.city,
          'location': 'POINT(${place.longitude} ${place.latitude})',
          'price_tier': place.priceTier,
          'hours': place.hours,
          'status_line': place.statusLine,
          'description': place.description,
          'hero_image_url': place.heroImageUrl,
          'tags': place.tags,
          'created_by': SupabaseService.currentUser?.id,
        });
      } catch (e) {
        AppLogger.warn('PlacesRepository', 'Supabase custom place sync error', e);
      }
    }
  }

  /// Fetches nearby places with support for keyset cursor pagination (`P8-01`).
  /// Deterministic tie-breaking on `id` prevents duplicate venues across pages.
  Future<List<PlaceModel>> getNearbyPlaces({
    double lat = 41.3111,
    double lng = 69.2797,
    String category = 'All',
    String searchQuery = '',
    int limit = 20,
    double? cursorDistance,
    String? cursorId,
  }) async {
    if (SupabaseService.isInitialized) {
      try {
        final Map<String, dynamic> params = {
          'user_lat': lat,
          'user_lng': lng,
          'radius_meters': 5000,
          'filter_category': category,
          'search_query': searchQuery,
          'limit_count': limit,
        };
        if (cursorDistance != null) {
          params['p_cursor_distance'] = cursorDistance;
          if (cursorId != null && cursorId.contains('-')) {
            params['p_cursor_id'] = cursorId;
          }
        }

        final res = await SupabaseService.client.rpc(
          'get_nearby_places',
          params: params,
        );
        if (res is List) {
          return res.map((e) => PlaceModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      } catch (err) {
        AppLogger.warn('PlacesRepository', 'RPC fallback to local spatial calculation', err);
      }
    }

    final all = getAllPlaces();
    final filtered = all.where((p) {
      final matchesCat = category == 'All' ||
          p.category.toLowerCase().contains(category.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(category.toLowerCase()));
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.streetAddress.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.district.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesCat && matchesSearch;
    }).toList();

    // Deterministic distance + ID tie-breaking for local pagination
    filtered.sort((a, b) {
      final comp = a.distanceMeters.compareTo(b.distanceMeters);
      if (comp != 0) return comp;
      return a.id.compareTo(b.id);
    });

    Iterable<PlaceModel> paged = filtered;
    if (cursorDistance != null) {
      paged = paged.where((p) {
        if (p.distanceMeters > cursorDistance) return true;
        if (p.distanceMeters == cursorDistance && cursorId != null) {
          return p.id.compareTo(cursorId) > 0;
        }
        return false;
      });
    }

    return paged.take(limit).toList();
  }

  /// Explainable, privacy-preserving recommendation engine (Phase 6 — Discovery Domain).
  /// Scores venues by accepted friends' recommendations, saved-place category affinity,
  /// and community rating without exposing private visit timelines.
  List<RecommendedPlaceResult> getRecommendedPlaces({
    required Set<String> acceptedFriendPlaceIds,
    required Set<String> savedPlaceIds,
    required Map<String, String> savedStatuses,
  }) {
    final all = getAllPlaces();
    final savedCategories = <String>{};
    for (final id in savedPlaceIds) {
      final p = getPlaceById(id);
      if (p != null) {
        savedCategories.add(p.category.split(' · ').first.toLowerCase());
      }
    }

    final results = <RecommendedPlaceResult>[];
    for (final p in all) {
      // Exclude places the user has already marked as 'been'
      if (savedStatuses[p.id] == 'been') continue;

      final friendMatch = acceptedFriendPlaceIds.contains(p.id) ? 1 : 0;
      final primaryCat = p.category.split(' · ').first.toLowerCase();
      final catAffinity = savedCategories.contains(primaryCat) ? 1.5 : 0.0;

      // Time-of-day contextual affinity (Sprint 4.1)
      final currentHour = DateTime.now().hour;
      final isMorning = currentHour >= 7 && currentHour < 12;
      final isEvening = currentHour >= 18 && currentHour < 24;

      double timeContextBoost = 0.0;
      String? timeReason;

      if (isMorning && p.tags.any((t) => ['coffee', 'bakery', 'breakfast', 'v60', 'matcha'].contains(t.toLowerCase()))) {
        timeContextBoost = 1.5;
        timeReason = 'Perfect morning coffee & bakes in ${p.district}';
      } else if (isEvening && p.tags.any((t) => ['dinner', 'cocktails', 'wine bar', 'craft cocktails', 'vinyl', 'late night', 'rooftop'].contains(t.toLowerCase()))) {
        timeContextBoost = 1.5;
        timeReason = 'Great evening dinner & cocktail vibe in ${p.district}';
      }

      final score = (friendMatch * 3.0) + catAffinity + timeContextBoost + (p.ratingAvg * 0.5);

      final String reason;
      if (friendMatch > 0) {
        reason = 'Recommended by your accepted friends in ${p.district}';
      } else if (timeReason != null) {
        reason = timeReason;
      } else if (catAffinity > 0) {
        reason = 'Matches your saved ${p.category.split(' · ').first} spots';
      } else {
        reason = 'Top-rated in ${p.district} (${p.ratingAvg}★)';
      }

      results.add(RecommendedPlaceResult(
        place: p,
        relevanceScore: double.parse(score.toStringAsFixed(2)),
        friendsRecommendCount: friendMatch,
        explanation: reason,
      ));
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  PlaceModel? getPlaceById(String id) {
    final resolved = resolveCanonicalId(id);
    final all = getAllPlaces();
    for (final p in all) {
      if (p.id == resolved || p.id == id || p.slug == id || p.canonicalUuid == id) {
        return p;
      }
    }
    return null;
  }
}
