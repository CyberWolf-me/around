import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/taste_archetype_engine.dart';
import 'package:around_app/data/models/place_model.dart';

void main() {
  group('P15-02: TasteArchetypeEngine Unit Tests', () {
    const coffee1 = PlaceModel(
      id: 'p_coffee_1',
      slug: 'breadly-bakery',
      name: 'Breadly Bakery & Café',
      category: 'Specialty Coffee · Bakery',
      streetAddress: '24 Mirobod',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3002,
      longitude: 69.2715,
      distanceMeters: 200,
      walkTimeMinutes: 3,
      priceTier: r'$$',
      hours: '8:00 AM - 11:00 PM',
      statusLine: 'Open now',
      description: 'Artisan espresso and pastries.',
      heroImageUrl: 'assets/cafe.jpg',
      ratingAvg: 4.8,
      ratingCount: 300,
      tags: ['coffee', 'croissant'],
      photos: ['assets/cafe.jpg'],
    );

    const coffee2 = PlaceModel(
      id: 'p_coffee_2',
      slug: 'b1-coffee',
      name: 'B1 Specialty Coffee',
      category: 'Third-Wave Coffee Roasters',
      streetAddress: '10 Taras Shevchenko',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3050,
      longitude: 69.2750,
      distanceMeters: 300,
      walkTimeMinutes: 4,
      priceTier: r'$$',
      hours: '8:00 AM - 10:00 PM',
      statusLine: 'Open now',
      description: 'Single origin pour overs.',
      heroImageUrl: 'assets/b1.jpg',
      ratingAvg: 4.9,
      ratingCount: 180,
      tags: ['coffee', 'pourover'],
      photos: ['assets/b1.jpg'],
    );

    const national1 = PlaceModel(
      id: 'p_national_1',
      slug: 'central-plov-center',
      name: 'Central Asian Plov Centre',
      category: 'National Cuisine · Plov',
      streetAddress: '1 Guard Street',
      district: 'Yunusabad',
      city: 'Tashkent',
      latitude: 41.3654,
      longitude: 69.2888,
      distanceMeters: 1200,
      walkTimeMinutes: 15,
      priceTier: r'$',
      hours: '10:00 AM - 4:00 PM',
      statusLine: 'Open now',
      description: 'Giant kazan wedding plov.',
      heroImageUrl: 'assets/plov.jpg',
      ratingAvg: 4.9,
      ratingCount: 1500,
      tags: ['plov', 'osh', 'national'],
      photos: ['assets/plov.jpg'],
    );

    const bar1 = PlaceModel(
      id: 'p_bar_1',
      slug: 'canti-wine-bar',
      name: 'Canti Wine Bar',
      category: 'Wine Bar · Bistro',
      streetAddress: '15 Shakhrisabz',
      district: 'Central Tashkent',
      city: 'Tashkent',
      latitude: 41.3111,
      longitude: 69.2797,
      distanceMeters: 500,
      walkTimeMinutes: 7,
      priceTier: r'$$$',
      hours: '5:00 PM - 1:00 AM',
      statusLine: 'Open now',
      description: 'Natural wine selections.',
      heroImageUrl: 'assets/canti.jpg',
      ratingAvg: 4.7,
      ratingCount: 190,
      tags: ['wine', 'tapas'],
      photos: ['assets/canti.jpg'],
    );

    const art1 = PlaceModel(
      id: 'p_art_1',
      slug: 'ilkhom-theatre',
      name: 'Ilkhom Theatre & Gallery',
      category: 'Arts & Culture · Independent Theatre',
      streetAddress: '5 Pakhtakor',
      district: 'Shaykhontohur',
      city: 'Tashkent',
      latitude: 41.3200,
      longitude: 69.2500,
      distanceMeters: 800,
      walkTimeMinutes: 10,
      priceTier: r'$$',
      hours: '11:00 AM - 9:00 PM',
      statusLine: 'Open now',
      description: 'Avant-garde gallery and performances.',
      heroImageUrl: 'assets/ilkhom.jpg',
      ratingAvg: 4.9,
      ratingCount: 420,
      tags: ['art', 'gallery', 'theater'],
      photos: ['assets/ilkhom.jpg'],
    );

    test('analyze handles empty places gracefully with Curious Newcomer archetype', () {
      final profile = TasteArchetypeEngine.analyze([]);

      expect(profile.archetypeTitleEn, equals('Curious Newcomer'));
      expect(profile.archetypeIcon, equals('✨'));
      expect(profile.diversityScore, equals(0.0));
      expect(profile.totalVenuesAnalyzed, equals(0));
      expect(profile.getArchetypeTitle('uz'), equals('Yangi Sayyoh'));
      expect(profile.getArchetypeTitle('ru'), equals('Новый Исследователь'));
    });

    test('analyze identifies Specialty Connoisseur when coffee dominates', () {
      final profile = TasteArchetypeEngine.analyze([coffee1, coffee2]);

      expect(profile.archetypeTitleEn, equals('Specialty Connoisseur'));
      expect(profile.archetypeIcon, equals('☕'));
      expect(profile.dimensionWeights[TasteDimension.specialtyCoffee], equals(1.0));
      expect(profile.getArchetypeTitle('uz'), equals('Qahva Bilagdoni'));
    });

    test('analyze identifies Old City Gourmet when national cuisine dominates', () {
      final profile = TasteArchetypeEngine.analyze([national1]);

      expect(profile.archetypeTitleEn, equals('Old City Gourmet'));
      expect(profile.archetypeIcon, equals('🍲'));
      expect(profile.dimensionWeights[TasteDimension.nationalDining], equals(1.0));
      expect(profile.getArchetypeTitle('ru'), equals('Гурман Старого Города'));
    });

    test('analyze identifies All-Around Tashkent Explorer when diverse categories are explored', () {
      final profile = TasteArchetypeEngine.analyze([coffee1, national1, bar1, art1]);

      expect(profile.totalVenuesAnalyzed, equals(4));
      expect(profile.diversityScore, equals(0.8)); // 4 out of 5 dimensions
      expect(profile.archetypeTitleEn, equals('All-Around Tashkent Explorer'));
      expect(profile.archetypeIcon, equals('🧭'));
      expect(profile.getArchetypeTitle('uz'), equals('Toshkent Sayyohi'));
    });
  });
}
