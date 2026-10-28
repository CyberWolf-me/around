class PlaceModel {
  final String id;
  final String slug;
  final String name;
  final String category;
  final String streetAddress;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final int walkTimeMinutes;
  final String priceTier;
  final String hours;
  final String statusLine;
  final String description;
  final String heroImageUrl;
  final double ratingAvg;
  final int ratingCount;
  final List<String> tags;
  final List<String> photos;

  const PlaceModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    required this.streetAddress,
    this.district = 'Barlow Hill',
    this.city = 'Tashkent',
    required this.latitude,
    required this.longitude,
    this.distanceMeters = 300,
    this.walkTimeMinutes = 4,
    this.priceTier = '€€',
    this.hours = '8:00 AM – 10:00 PM',
    this.statusLine = 'Open today',
    this.description = '',
    required this.heroImageUrl,
    this.ratingAvg = 4.5,
    this.ratingCount = 120,
    this.tags = const [],
    this.photos = const [],
  });

  String get shortCategory => category.split('·').first.trim();

  String get walkDistanceLabel => '$walkTimeMinutes min walk';

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? 'venue',
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Café',
      streetAddress: json['street_address'] as String? ?? '',
      district: json['district'] as String? ?? 'Barlow Hill',
      city: json['city'] as String? ?? 'Tashkent',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.2995,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2401,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 350.0,
      walkTimeMinutes: json['walk_time_minutes'] as int? ?? 4,
      priceTier: json['price_tier'] as String? ?? '€€',
      hours: json['hours'] as String? ?? '8am – 10pm',
      statusLine: json['status_line'] as String? ?? 'Open today',
      description: json['description'] as String? ?? '',
      heroImageUrl: json['hero_image_url'] as String? ?? 'assets/kettle-hero.jpg',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.5,
      ratingCount: json['rating_count'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
