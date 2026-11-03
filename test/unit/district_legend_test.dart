import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_legend_engine.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P15-04: DistrictLegendEngine Unit Tests', () {
    const breadly = PlaceModel(
      id: 'p_breadly',
      slug: 'breadly-bakery',
      name: 'Breadly Bakery & Café',
      category: 'Specialty Coffee',
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
      description: 'Artisan bakery.',
      heroImageUrl: 'assets/cafe.jpg',
      ratingAvg: 4.8,
      ratingCount: 300,
      tags: ['coffee'],
      photos: ['assets/cafe.jpg'],
    );

    const plovCenter = PlaceModel(
      id: 'p_plov',
      slug: 'central-plov-center',
      name: 'Central Asian Plov Centre',
      category: 'National Cuisine',
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
      description: 'Legendary plov.',
      heroImageUrl: 'assets/plov.jpg',
      ratingAvg: 4.9,
      ratingCount: 1500,
      tags: ['plov'],
      photos: ['assets/plov.jpg'],
    );

    final places = [breadly, plovCenter];
    final referenceTime = DateTime(2026, 11, 10, 12, 0);

    test('ignores users with fewer than 3 drops in a district', () {
      final drops = [
        PostModel(
          id: 'd1',
          authorId: 'u_aziza',
          authorName: 'Aziza',
          authorUsername: 'aziza_tashkent',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Drop 1',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 2)),
        ),
        PostModel(
          id: 'd2',
          authorId: 'u_aziza',
          authorName: 'Aziza',
          authorUsername: 'aziza_tashkent',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Drop 2',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 1)),
        ),
      ];

      final lb = DistrictLegendEngine.computeLeaderboard(
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(lb.districtLegends.isEmpty, isTrue);
      expect(lb.isUserLocalLegend('u_aziza'), isFalse);
    });

    test('awards Local Legend to user with >= 3 drops in 30 days', () {
      final drops = [
        PostModel(
          id: 'd1',
          authorId: 'u_kamila',
          authorName: 'Kamila',
          authorUsername: 'kamila_r',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Drop 1',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 15)),
        ),
        PostModel(
          id: 'd2',
          authorId: 'u_kamila',
          authorName: 'Kamila',
          authorUsername: 'kamila_r',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Drop 2',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 10)),
        ),
        PostModel(
          id: 'd3',
          authorId: 'u_kamila',
          authorName: 'Kamila',
          authorUsername: 'kamila_r',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Drop 3',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 1)),
        ),
        // Drop older than 30 days (ignored)
        PostModel(
          id: 'd_old',
          authorId: 'u_kamila',
          authorName: 'Kamila',
          authorUsername: 'kamila_r',
          placeId: 'p_breadly',
          placeName: 'Breadly',
          placeCategory: 'Coffee',
          placeAddress: 'Mirobod',
          note: 'Old',
          audience: PostAudience.public,
          createdAt: referenceTime.subtract(const Duration(days: 45)),
        ),
      ];

      final lb = DistrictLegendEngine.computeLeaderboard(
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(lb.totalQualifyingDrops, equals(3));
      expect(lb.isUserLocalLegend('u_kamila'), isTrue);
      expect(lb.isUserLocalLegend('u_kamila', 'Mirabad'), isTrue);
      expect(lb.isUserLocalLegend('u_kamila', 'Yunusabad'), isFalse);

      final mirabadLegend = lb.getLegendForDistrict('Mirabad');
      expect(mirabadLegend, isNotNull);
      expect(mirabadLegend!.userId, equals('u_kamila'));
      expect(mirabadLegend.dropCount, equals(3));
      expect(mirabadLegend.badgeTitleEn, equals('Mirabad Local Legend'));
      expect(mirabadLegend.getBadgeTitle('uz'), equals('Mirobod Afsonasi'));
      expect(mirabadLegend.getBadgeTitle('ru'), equals('Легенда района Mirabad'));
    });

    test('resolves ties by choosing the user with the most recent qualifying drop', () {
      final drops = [
        // Jasur: 3 drops, latest 3 days ago
        for (int i = 0; i < 3; i++)
          PostModel(
            id: 'j_$i',
            authorId: 'u_jasur',
            authorName: 'Jasur',
            authorUsername: 'jasur_dev',
            placeId: 'p_plov',
            placeName: 'Plov Center',
            placeCategory: 'Plov',
            placeAddress: 'Yunusabad',
            note: 'Plov time',
            audience: PostAudience.public,
            createdAt: referenceTime.subtract(Duration(days: 3 + i)),
          ),
        // Nodira: 3 drops, latest 1 day ago (should win tie!)
        for (int i = 0; i < 3; i++)
          PostModel(
            id: 'n_$i',
            authorId: 'u_nodira',
            authorName: 'Nodira',
            authorUsername: 'nodira_k',
            placeId: 'p_plov',
            placeName: 'Plov Center',
            placeCategory: 'Plov',
            placeAddress: 'Yunusabad',
            note: 'Plov is life',
            audience: PostAudience.public,
            createdAt: referenceTime.subtract(Duration(days: 1 + i)),
          ),
      ];

      final lb = DistrictLegendEngine.computeLeaderboard(
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      final yunusabadLegend = lb.getLegendForDistrict('Yunusabad');
      expect(yunusabadLegend, isNotNull);
      expect(yunusabadLegend!.userId, equals('u_nodira'));
      expect(yunusabadLegend.username, equals('nodira_k'));
    });

    test('allows a prolific curator to hold Local Legend crowns across multiple districts', () {
      final drops = [
        // Kamila: 3 drops in Mirabad
        for (int i = 0; i < 3; i++)
          PostModel(
            id: 'km_$i',
            authorId: 'u_kamila',
            authorName: 'Kamila',
            authorUsername: 'kamila_r',
            placeId: 'p_breadly',
            placeName: 'Breadly',
            placeCategory: 'Coffee',
            placeAddress: 'Mirobod',
            note: 'Bakery',
            audience: PostAudience.public,
            createdAt: referenceTime.subtract(Duration(days: i + 1)),
          ),
        // Kamila: 4 drops in Yunusabad
        for (int i = 0; i < 4; i++)
          PostModel(
            id: 'ky_$i',
            authorId: 'u_kamila',
            authorName: 'Kamila',
            authorUsername: 'kamila_r',
            placeId: 'p_plov',
            placeName: 'Plov Center',
            placeCategory: 'Plov',
            placeAddress: 'Yunusabad',
            note: 'Plov feast',
            audience: PostAudience.public,
            createdAt: referenceTime.subtract(Duration(days: i + 1)),
          ),
      ];

      final lb = DistrictLegendEngine.computeLeaderboard(
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      final kamilaLegends = lb.getLegendsForUser('u_kamila');
      expect(kamilaLegends.length, equals(2));
      expect(lb.isUserLocalLegend('u_kamila', 'Mirabad'), isTrue);
      expect(lb.isUserLocalLegend('u_kamila', 'Yunusabad'), isTrue);
    });
  });
}
