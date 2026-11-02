import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/atmosphere_service.dart';
import 'package:around_app/core/services/weekly_digest_engine.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  group('P14-04: WeeklyDigestEngine Unit Tests', () {
    const breadly = PlaceModel(
      id: 'place_breadly',
      slug: 'breadly-bakery',
      name: 'Breadly Bakery & Café',
      category: 'Specialty Coffee · Bakery',
      streetAddress: '24 Mirobod Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3002,
      longitude: 69.2715,
      distanceMeters: 250,
      walkTimeMinutes: 3,
      priceTier: r'$$',
      hours: '8:00 AM – 11:00 PM',
      statusLine: 'Open now · Artisan croissants',
      description: 'Cozy café.',
      heroImageUrl: 'assets/cafe-bw.jpg',
      ratingAvg: 4.8,
      ratingCount: 320,
      tags: ['coffee', 'croissant'],
      photos: ['assets/cafe-bw.jpg'],
    );

    const canti = PlaceModel(
      id: 'place_canti',
      slug: 'canti-wine-bar',
      name: 'Canti Wine Bar',
      category: 'Wine Bar · Bistro',
      streetAddress: '15 Shakhrisabz Street',
      district: 'Central Tashkent',
      city: 'Tashkent',
      latitude: 41.3111,
      longitude: 69.2797,
      distanceMeters: 500,
      walkTimeMinutes: 7,
      priceTier: r'$$$',
      hours: '5:00 PM – 1:00 AM',
      statusLine: 'Open now · Natural wines',
      description: 'Intimate wine bistro.',
      heroImageUrl: 'assets/canti.jpg',
      ratingAvg: 4.7,
      ratingCount: 190,
      tags: ['wine', 'tapas'],
      photos: ['assets/canti.jpg'],
    );

    final places = [breadly, canti];

    final fixedNow = DateTime(2026, 11, 6, 18, 30); // Friday 18:30

    test('isWeekendWindow identifies Friday evening, Saturday, and Sunday', () {
      final friMorning = DateTime(2026, 11, 6, 11, 0); // Friday 11:00
      final friEvening = DateTime(2026, 11, 6, 18, 0); // Friday 18:00
      final satNoon = DateTime(2026, 11, 7, 12, 0); // Saturday 12:00
      final sunNight = DateTime(2026, 11, 8, 22, 0); // Sunday 22:00
      final wedAfternoon = DateTime(2026, 11, 4, 15, 0); // Wednesday 15:00

      expect(WeeklyDigestEngine.isWeekendWindow(friMorning), isFalse);
      expect(WeeklyDigestEngine.isWeekendWindow(friEvening), isTrue);
      expect(WeeklyDigestEngine.isWeekendWindow(satNoon), isTrue);
      expect(WeeklyDigestEngine.isWeekendWindow(sunNight), isTrue);
      expect(WeeklyDigestEngine.isWeekendWindow(wedAfternoon), isFalse);
    });

    test('generateWeeklyDigest aggregates past 7 days and filters out older drops', () {
      final drops = [
        // Within past 7 days (breadly in Mirabad)
        PostModel(
          id: 'drop_1',
          authorId: 'u1',
          authorName: 'User 1',
          authorUsername: 'u1',
          placeId: 'place_breadly',
          placeName: 'Breadly Bakery & Café',
          placeCategory: 'Coffee',
          placeAddress: '24 Mirobod Street',
          note: 'Great coffee!',
          audience: PostAudience.friends,
          createdAt: fixedNow.subtract(const Duration(days: 2, hours: 10)), // 08:30 (morningBrew)
        ),
        PostModel(
          id: 'drop_2',
          authorId: 'u2',
          authorName: 'User 2',
          authorUsername: 'u2',
          placeId: 'place_breadly',
          placeName: 'Breadly Bakery & Café',
          placeCategory: 'Coffee',
          placeAddress: '24 Mirobod Street',
          note: 'Croissant perfection',
          audience: PostAudience.friends,
          createdAt: fixedNow.subtract(const Duration(days: 1, hours: 9)), // 09:30 (morningBrew)
        ),
        // Within past 7 days (canti in Central Tashkent)
        PostModel(
          id: 'drop_3',
          authorId: 'u3',
          authorName: 'User 3',
          authorUsername: 'u3',
          placeId: 'place_canti',
          placeName: 'Canti Wine Bar',
          placeCategory: 'Wine Bar',
          placeAddress: '15 Shakhrisabz Street',
          note: 'Nice atmosphere',
          audience: PostAudience.friends,
          createdAt: fixedNow.subtract(const Duration(hours: 1)), // 17:30 (goldenHour)
        ),
        // Older than 7 days (must be ignored)
        PostModel(
          id: 'drop_old',
          authorId: 'u4',
          authorName: 'User 4',
          authorUsername: 'u4',
          placeId: 'place_canti',
          placeName: 'Canti Wine Bar',
          placeCategory: 'Wine Bar',
          placeAddress: '15 Shakhrisabz Street',
          note: 'Old drop',
          audience: PostAudience.friends,
          createdAt: fixedNow.subtract(const Duration(days: 10)),
        ),
      ];

      final digest = WeeklyDigestEngine.generateWeeklyDigest(
        drops: drops,
        places: places,
        referenceTime: fixedNow,
      );

      expect(digest.totalWeeklyDrops, equals(3));
      expect(digest.topDistrict, equals('Mirabad'));
      expect(digest.topDistrictDropCount, equals(2));
      expect(digest.trendingVenue?.id, equals('place_breadly'));
      expect(digest.trendingVenueDropCount, equals(2));
      expect(digest.dominantAtmosphere, equals(AtmosphereMode.morningBrew));

      // Friday evening prompt assertions
      expect(digest.promptEn, contains('Friday night in Tashkent: Mirabad is buzzing'));
      expect(digest.promptRu, contains('Пятничный вечер в Ташкенте: район Mirabad'));
      expect(digest.promptUz, contains('Toshkentda juma oqshomi: Mirabad tumanida'));

      // Localized prompt accessor
      expect(digest.getPrompt('uz'), equals(digest.promptUz));
      expect(digest.getPrompt('ru'), equals(digest.promptRu));
      expect(digest.getPrompt('en'), equals(digest.promptEn));
    });

    test('generateWeeklyDigest synthesizes Saturday morning prompt', () {
      final saturdayMorning = DateTime(2026, 11, 7, 9, 30); // Saturday 09:30
      final drops = [
        PostModel(
          id: 'drop_1',
          authorId: 'u1',
          authorName: 'User 1',
          authorUsername: 'u1',
          placeId: 'place_breadly',
          placeName: 'Breadly Bakery & Café',
          placeCategory: 'Coffee',
          placeAddress: '24 Mirobod Street',
          note: 'Great spot!',
          audience: PostAudience.friends,
          createdAt: saturdayMorning.subtract(const Duration(days: 1)),
        ),
      ];

      final digest = WeeklyDigestEngine.generateWeeklyDigest(
        drops: drops,
        places: places,
        referenceTime: saturdayMorning,
      );

      expect(digest.promptEn, contains('Saturday rhythm: Mirabad croissants'));
      expect(digest.promptRu, contains('Субботний ритм: утренний кофе'));
      expect(digest.promptUz, contains('Shanba tongi maromi: issiq qahva'));
    });

    test('generateWeeklyDigest falls back to districtDensities when drops are empty', () {
      const densities = [
        DistrictDensityModel(
          district: 'Yunusabad',
          dropCount: 14,
          activeVenuesCount: 5,
          centroidLat: 41.3654,
          centroidLng: 69.2888,
          relativeDensity: 0.8,
        ),
        DistrictDensityModel(
          district: 'Mirabad',
          dropCount: 8,
          activeVenuesCount: 3,
          centroidLat: 41.3002,
          centroidLng: 69.2715,
          relativeDensity: 0.5,
        ),
      ];

      final wednesdayNoon = DateTime(2026, 11, 4, 12, 0); // Wednesday 12:00
      final digest = WeeklyDigestEngine.generateWeeklyDigest(
        drops: [],
        places: places,
        districtDensities: densities,
        referenceTime: wednesdayNoon,
      );

      expect(digest.totalWeeklyDrops, equals(0));
      expect(digest.topDistrict, equals('Yunusabad'));
      expect(digest.topDistrictDropCount, equals(14));
      expect(digest.promptEn, contains('Weekly Rhythm: 0 drops'));
    });

    test('generateWeekendInviteMessage generates trilingual coordination copy', () {
      final digest = WeeklyDigest(
        totalWeeklyDrops: 18,
        topDistrict: 'Mirabad',
        topDistrictDropCount: 12,
        trendingVenue: breadly,
        trendingVenueDropCount: 7,
        dominantAtmosphere: AtmosphereMode.morningBrew,
        generatedAt: fixedNow,
        promptUz: 'UZ prompt',
        promptRu: 'RU prompt',
        promptEn: 'EN prompt',
      );

      final uzMsg = digest.generateWeekendInviteMessage('uz');
      final ruMsg = digest.generateWeekendInviteMessage('ru');
      final enMsg = digest.generateWeekendInviteMessage('en');

      expect(uzMsg, contains("Ushbu haftada Mirabad juda jonli bo'ldi (12 ta tavsiya)"));
      expect(uzMsg, contains('Breadly Bakery & Café'));
      expect(uzMsg, contains('https://around.tashkent.app'));

      expect(ruMsg, contains('На этой неделе в районе Mirabad было оживленно (12 дропов)'));
      expect(ruMsg, contains('Breadly Bakery & Café'));

      expect(enMsg, contains('Mirabad was buzzing with 12 drops this week'));
      expect(enMsg, contains('Breadly Bakery & Café'));
    });
  });
}
