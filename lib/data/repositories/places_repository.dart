import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/place_model.dart';
import '../services/supabase_service.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return PlacesRepository();
});

class PlacesRepository {
  // Pre-seeded canonical venues (Tashkent / Barlow Hill area)
  static final List<PlaceModel> _seedPlaces = [
    const PlaceModel(
      id: 'kettle',
      slug: 'kettle-and-loaf',
      name: 'Kettle & Loaf',
      category: 'Bakery · Café',
      streetAddress: '14 Ledger Street',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.2995,
      longitude: 69.2401,
      distanceMeters: 320,
      walkTimeMinutes: 4,
      priceTier: '€',
      hours: '7:00 AM – 4:00 PM',
      statusLine: 'Opens tomorrow 7am',
      description: 'Bread out of the oven at 7, gone by 11. The back room is the quiet one.',
      heroImageUrl: 'assets/kettle-hero.jpg',
      ratingAvg: 4.7,
      ratingCount: 184,
      tags: ['quiet mornings', 'good cortado', 'work-friendly', 'solo seats'],
      photos: ['assets/bakery-counter.jpg', 'assets/cafe-light.jpg', 'assets/pastries.jpg'],
    ),
    const PlaceModel(
      id: 'fern',
      slug: 'the-fern-room',
      name: 'The Fern Room',
      category: 'Study café',
      streetAddress: '2 Ostrander Avenue',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.3020,
      longitude: 69.2430,
      distanceMeters: 550,
      walkTimeMinutes: 7,
      priceTier: '€€',
      hours: '8:00 AM – 6:00 PM',
      statusLine: 'Closes in 2 hours',
      description: 'Twenty sockets, twelve tables, one rule: headphones on.',
      heroImageUrl: 'assets/study-desk.jpg',
      ratingAvg: 4.5,
      ratingCount: 96,
      tags: ['outlets', 'big tables', 'silent-ish', 'long stays'],
      photos: ['assets/study-table.jpg', 'assets/cafe-light.jpg', 'assets/window-girl.jpg'],
    ),
    const PlaceModel(
      id: 'sable',
      slug: 'sable-records',
      name: 'Sable Records',
      category: 'Record shop',
      streetAddress: '63 Kestrel Lane',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.2970,
      longitude: 69.2480,
      distanceMeters: 700,
      walkTimeMinutes: 9,
      priceTier: '€€',
      hours: '11:00 AM – 7:00 PM',
      statusLine: 'Closes in 5 hours',
      description: 'Two thousand records and a chair nobody uses. Ask Dilan for the shellac.',
      heroImageUrl: 'assets/records.jpg',
      ratingAvg: 4.8,
      ratingCount: 62,
      tags: ['crate digging', 'second-hand', 'staff picks', 'no rush'],
      photos: ['assets/records-crates.jpg', 'assets/storefront.jpg', 'assets/street.jpg'],
    ),
    const PlaceModel(
      id: 'castellan',
      slug: 'castellan-wine',
      name: 'Castellan',
      category: 'Wine bar',
      streetAddress: '8 Prine Row',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.3050,
      longitude: 69.2370,
      distanceMeters: 850,
      walkTimeMinutes: 11,
      priceTier: '€€€',
      hours: '5:00 PM – 1:00 AM',
      statusLine: 'Opens 5pm',
      description: 'No menu. Tell them what you liked last time and they pour it.',
      heroImageUrl: 'assets/wine-tall.jpg',
      ratingAvg: 4.6,
      ratingCount: 210,
      tags: ['date night', 'natural wine', 'small plates', 'standing room'],
      photos: ['assets/wine-wide.jpg', 'assets/wine-tall.jpg', 'assets/street.jpg'],
    ),
    const PlaceModel(
      id: 'volta',
      slug: 'volta-books',
      name: 'Volta Books',
      category: 'Bookshop',
      streetAddress: '21 Fenwick Walk',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.2950,
      longitude: 69.2410,
      distanceMeters: 450,
      walkTimeMinutes: 6,
      priceTier: '€',
      hours: '10:00 AM – 8:00 PM',
      statusLine: 'Closes in 6 hours',
      description: 'Three floors, one staircase built for one person at a time.',
      heroImageUrl: 'assets/bookshop.jpg',
      ratingAvg: 4.9,
      ratingCount: 143,
      tags: ['browsing', 'staff picks', '€4 shelf', 'tiny staircase'],
      photos: ['assets/bookshop-tall.jpg', 'assets/bookshop.jpg', 'assets/storefront.jpg'],
    ),
    const PlaceModel(
      id: 'noodle',
      slug: 'noodle-union',
      name: 'Noodle Union',
      category: 'Ramen',
      streetAddress: '40 Halloway Street',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.2980,
      longitude: 69.2450,
      distanceMeters: 250,
      walkTimeMinutes: 3,
      priceTier: '€€',
      hours: '12:00 PM – 10:00 PM',
      statusLine: 'Closes in 4 hours',
      description: 'Twelve stools. Eat, pay, leave. Nobody has ever lingered here.',
      heroImageUrl: 'assets/ramen-bowl.jpg',
      ratingAvg: 4.4,
      ratingCount: 308,
      tags: ['counter seats', 'fast', 'spicy miso', 'cash only'],
      photos: ['assets/ramen.jpg', 'assets/ramen-bowl.jpg', 'assets/street.jpg'],
    ),
    const PlaceModel(
      id: 'marigold',
      slug: 'marigold-patisserie',
      name: 'Marigold Patisserie',
      category: 'Patisserie',
      streetAddress: '5 Duarte Court',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.3030,
      longitude: 69.2500,
      distanceMeters: 620,
      walkTimeMinutes: 8,
      priceTier: '€€',
      hours: '8:00 AM – 3:00 PM',
      statusLine: 'Opens tomorrow 8am',
      description: 'Two trays, one oven, a queue that starts at 8:40.',
      heroImageUrl: 'assets/patisserie.jpg',
      ratingAvg: 4.6,
      ratingCount: 77,
      tags: ['kouign-amann', 'sells out early', 'standing only', 'cash + card'],
      photos: ['assets/pastries.jpg', 'assets/patisserie.jpg', 'assets/bakery-counter.jpg'],
    ),
    const PlaceModel(
      id: 'longtable',
      slug: 'the-long-table',
      name: 'The Long Table',
      category: 'Work space',
      streetAddress: '11 Marrow Lane',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.2930,
      longitude: 69.2380,
      distanceMeters: 920,
      walkTimeMinutes: 12,
      priceTier: '€€',
      hours: '9:00 AM – 9:00 PM',
      statusLine: 'Closes in 7 hours',
      description: 'One 14-metre table. Day pass costs a coffee and a pastry.',
      heroImageUrl: 'assets/study-table.jpg',
      ratingAvg: 4.3,
      ratingCount: 58,
      tags: ['outlets', 'day pass', 'printers', 'quiet zone'],
      photos: ['assets/study-desk.jpg', 'assets/study-table.jpg', 'assets/cafe-light.jpg'],
    ),
    const PlaceModel(
      id: 'quiet',
      slug: 'quiet-hours',
      name: 'Quiet Hours',
      category: 'Late café',
      streetAddress: '27 Ledger Street',
      district: 'Barlow Hill',
      city: 'Tashkent',
      latitude: 41.3005,
      longitude: 69.2390,
      distanceMeters: 400,
      walkTimeMinutes: 5,
      priceTier: '€',
      hours: '6:00 PM – 2:00 AM',
      statusLine: 'Opens 6pm',
      description: 'Candles after nine. The espresso machine turns off at ten.',
      heroImageUrl: 'assets/cafe-bw.jpg',
      ratingAvg: 4.5,
      ratingCount: 131,
      tags: ['late night', 'no music', 'reading', 'cheap'],
      photos: ['assets/window-girl.jpg', 'assets/cafe-bw.jpg', 'assets/storefront.jpg'],
    ),
  ];

  Future<List<PlaceModel>> getNearbyPlaces({
    double lat = 41.2995,
    double lng = 69.2401,
    String category = 'All',
    String searchQuery = '',
  }) async {
    // If Supabase is connected, invoke PostGIS function get_nearby_places
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client.rpc(
          'get_nearby_places',
          params: {
            'user_lat': lat,
            'user_lng': lng,
            'radius_meters': 3000,
            'filter_category': category,
          },
        );
        return (res as List).map((e) => PlaceModel.fromJson(e)).toList();
      } catch (err) {
        // Fallback to local
      }
    }

    // Local in-memory filter
    return _seedPlaces.where((p) {
      final matchesCat = category == 'All' ||
          p.category.toLowerCase().contains(category.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(category.toLowerCase()));
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.streetAddress.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchesCat && matchesSearch;
    }).toList();
  }

  PlaceModel? getPlaceById(String id) {
    try {
      return _seedPlaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
