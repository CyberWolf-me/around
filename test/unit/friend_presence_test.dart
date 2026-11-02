import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/friend_presence_engine.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P16-04: FriendPresenceEngine & Neighborhood Rhythm Indicator', () {
    final referenceTime = DateTime(2026, 11, 3, 14, 0); // 14:00 (2:00 PM)

    final places = [
      const PlaceModel(
        id: 'place_breadly',
        name: 'Breadly Bakery',
        slug: 'breadly',
        category: 'Cafe',
        streetAddress: 'Mirabad st 12',
        district: 'Mirabad',
        latitude: 41.3000,
        longitude: 69.2600,
        heroImageUrl: 'https://images.unsplash.com/photo-breadly',
      ),
      const PlaceModel(
        id: 'place_ecopark',
        name: 'Ecopark Tashkent',
        slug: 'ecopark',
        category: 'Park',
        streetAddress: 'Yunusabad district',
        district: 'Yunusabad',
        latitude: 41.3200,
        longitude: 69.2800,
        heroImageUrl: 'https://images.unsplash.com/photo-ecopark',
      ),
    ];

    PostModel createSampleDrop({
      required String id,
      required String authorId,
      required String placeId,
      required DateTime createdAt,
    }) {
      return PostModel(
        id: id,
        authorId: authorId,
        authorName: 'User $authorId',
        authorUsername: 'user_$authorId',
        placeId: placeId,
        placeName: 'Sample Place',
        placeCategory: 'Cafe',
        placeAddress: 'Mirabad, Tashkent',
        note: 'Great vibes!',
        audience: PostAudience.friends,
        createdAt: createdAt,
      );
    }

    test('classifies drop within 30 minutes as justNow and online', () {
      final drops = [
        createSampleDrop(
          id: 'drop_1',
          authorId: 'friend_kamila',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(minutes: 15)),
        ),
      ];

      final status = FriendPresenceEngine.computeStatus(
        userId: 'friend_kamila',
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(status.recency, equals(FriendPresenceRecency.justNow));
      expect(status.isOnline, isTrue);
      expect(status.isRecent, isTrue);
      expect(status.district, equals('Mirabad'));

      // Check localization strings
      expect(
        status.getLocalizedLabel('en', referenceTime: referenceTime),
        equals('Active in Mirabad • Just now'),
      );
      expect(
        status.getLocalizedLabel('uz', referenceTime: referenceTime),
        equals('Mirobodda faol • Hozirgina'),
      );
      expect(
        status.getLocalizedLabel('ru', referenceTime: referenceTime),
        equals('Активен в Mirabad • Только что'),
      );
    });

    test('classifies drop within 4 hours as recentHours', () {
      final drops = [
        createSampleDrop(
          id: 'drop_2',
          authorId: 'friend_aziz',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 2)),
        ),
      ];

      final status = FriendPresenceEngine.computeStatus(
        userId: 'friend_aziz',
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(status.recency, equals(FriendPresenceRecency.recentHours));
      expect(status.isOnline, isFalse);
      expect(status.isRecent, isTrue);

      expect(
        status.getLocalizedLabel('en', referenceTime: referenceTime),
        equals('Active in Mirabad • 2h ago'),
      );
      expect(
        status.getLocalizedLabel('uz', referenceTime: referenceTime),
        equals('Mirobodda faol • 2 soat oldin'),
      );
      expect(
        status.getLocalizedLabel('ru', referenceTime: referenceTime),
        equals('Активен в Mirabad • 2 ч назад'),
      );
    });

    test('classifies drop within 12 hours as earlierToday', () {
      final drops = [
        createSampleDrop(
          id: 'drop_3',
          authorId: 'friend_diyor',
          placeId: 'place_ecopark',
          createdAt: referenceTime.subtract(const Duration(hours: 6)),
        ),
      ];

      final status = FriendPresenceEngine.computeStatus(
        userId: 'friend_diyor',
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(status.recency, equals(FriendPresenceRecency.earlierToday));
      expect(status.isOnline, isFalse);
      expect(status.isRecent, isTrue);
      expect(status.district, equals('Yunusabad'));

      expect(
        status.getLocalizedLabel('en', referenceTime: referenceTime),
        equals('Active in Yunusabad • Earlier today'),
      );
      expect(
        status.getLocalizedLabel('uz', referenceTime: referenceTime),
        equals('Yunusobodda faol • Bugun erta'),
      );
      expect(
        status.getLocalizedLabel('ru', referenceTime: referenceTime),
        equals('Активен в Yunusabad • Ранее сегодня'),
      );
    });

    test('classifies drop within 24 hours as yesterday', () {
      final drops = [
        createSampleDrop(
          id: 'drop_4',
          authorId: 'friend_malika',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 18)),
        ),
      ];

      final status = FriendPresenceEngine.computeStatus(
        userId: 'friend_malika',
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(status.recency, equals(FriendPresenceRecency.yesterday));
      expect(status.isRecent, isTrue);

      expect(
        status.getLocalizedLabel('en', referenceTime: referenceTime),
        equals('Active in Mirabad • Yesterday'),
      );
      expect(
        status.getLocalizedLabel('uz', referenceTime: referenceTime),
        equals('Mirobodda faol • Kecha'),
      );
    });

    test('classifies drop older than 24 hours or empty drops as inactive', () {
      final oldDrop = [
        createSampleDrop(
          id: 'drop_old',
          authorId: 'friend_jasur',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 36)),
        ),
      ];

      final statusOld = FriendPresenceEngine.computeStatus(
        userId: 'friend_jasur',
        drops: oldDrop,
        places: places,
        referenceTime: referenceTime,
      );

      expect(statusOld.recency, equals(FriendPresenceRecency.inactive));
      expect(statusOld.isOnline, isFalse);
      expect(statusOld.isRecent, isFalse);
      expect(statusOld.getLocalizedLabel('en'), equals('Resting'));
      expect(statusOld.getLocalizedLabel('uz'), equals('Dam olmoqda'));
      expect(statusOld.getLocalizedLabel('ru'), equals('Не в сети'));

      final statusEmpty = FriendPresenceEngine.computeStatus(
        userId: 'friend_nodir',
        drops: [],
        places: places,
        referenceTime: referenceTime,
      );
      expect(statusEmpty.recency, equals(FriendPresenceRecency.inactive));
    });

    test('selects latest drop when user has multiple drops', () {
      final drops = [
        createSampleDrop(
          id: 'drop_older',
          authorId: 'friend_multi',
          placeId: 'place_ecopark',
          createdAt: referenceTime.subtract(const Duration(hours: 5)),
        ),
        createSampleDrop(
          id: 'drop_newer',
          authorId: 'friend_multi',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(minutes: 10)),
        ),
      ];

      final status = FriendPresenceEngine.computeStatus(
        userId: 'friend_multi',
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(status.recency, equals(FriendPresenceRecency.justNow));
      expect(status.district, equals('Mirabad'));
    });

    test('aggregates neighborhood friend counts across 24h activity window', () {
      final drops = [
        // 2 friends in Mirabad
        createSampleDrop(
          id: 'd1',
          authorId: 'friend_1',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 1)),
        ),
        createSampleDrop(
          id: 'd2',
          authorId: 'friend_2',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 3)),
        ),
        // 1 friend in Yunusabad
        createSampleDrop(
          id: 'd3',
          authorId: 'friend_3',
          placeId: 'place_ecopark',
          createdAt: referenceTime.subtract(const Duration(hours: 2)),
        ),
        // 1 friend in Mirabad older than 24h -> should not count
        createSampleDrop(
          id: 'd4',
          authorId: 'friend_4',
          placeId: 'place_breadly',
          createdAt: referenceTime.subtract(const Duration(hours: 30)),
        ),
      ];

      final counts = FriendPresenceEngine.getNeighborhoodFriendCounts(
        friendIds: ['friend_1', 'friend_2', 'friend_3', 'friend_4'],
        drops: drops,
        places: places,
        referenceTime: referenceTime,
      );

      expect(counts['Mirabad'], equals(2));
      expect(counts['Yunusabad'], equals(1));
      expect(counts.containsKey('friend_4'), isFalse);
    });
  });
}
