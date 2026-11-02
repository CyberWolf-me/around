import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/explorer_streak_engine.dart';
import 'package:around_app/core/services/sunday_retrospective_service.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P18-02: SundayRetrospectiveService Tests', () {
    // Sunday, Nov 8, 2026 at 19:30 (inside window)
    final sundayEvening = DateTime(2026, 11, 8, 19, 30);
    // Sunday at 14:00 (outside window)
    final sundayAfternoon = DateTime(2026, 11, 8, 14, 0);
    // Friday at 19:30 (outside window)
    final fridayEvening = DateTime(2026, 11, 6, 19, 30);

    final mondayThisWeek = ExplorerStreakEngine.getMondayOfWeek(sundayEvening);

    PostModel createDrop({
      required String id,
      required String authorId,
      required DateTime createdAt,
    }) {
      return PostModel(
        id: id,
        authorId: authorId,
        authorName: 'Author $authorId',
        authorUsername: 'author_$authorId',
        placeId: 'place_breadly',
        placeName: 'Breadly Bakery',
        placeCategory: 'Cafe',
        placeAddress: 'Mirabad, Tashkent',
        note: 'Review',
        audience: PostAudience.friends,
        createdAt: createdAt,
      );
    }

    test('isRetrospectiveWindow identifies Sunday 18:00-22:00 window accurately', () {
      expect(SundayRetrospectiveService.isRetrospectiveWindow(sundayEvening), isTrue);
      expect(SundayRetrospectiveService.isRetrospectiveWindow(sundayAfternoon), isFalse);
      expect(SundayRetrospectiveService.isRetrospectiveWindow(fridayEvening), isFalse);
    });

    test('generates at-risk alert when user had previous streak but zero drops this week', () {
      final userDrops = [
        // Drop last week (Tuesday Nov 3)
        createDrop(
          id: 'd_last_week',
          authorId: 'curator_1',
          createdAt: mondayThisWeek.subtract(const Duration(days: 4)),
        ),
      ];

      final card = SundayRetrospectiveService.generateDigest(
        userId: 'curator_1',
        userDrops: userDrops,
        friendIds: ['friend_a'],
        allDrops: userDrops,
        lang: 'en',
        referenceTime: sundayEvening,
      );

      expect(card.isAtRisk, isTrue);
      expect(card.dropsThisWeek, equals(0));
      expect(card.streakWeeks, equals(1));
      expect(card.title, contains('Streak At Risk!'));
      expect(card.ctaRoute, equals('/create-post'));
    });

    test('generates secured celebration card when user has drops in current week', () {
      final userDrops = [
        // Drop this Saturday
        createDrop(
          id: 'd_this_sat',
          authorId: 'curator_active',
          createdAt: sundayEvening.subtract(const Duration(days: 1)),
        ),
        // Drop last week
        createDrop(
          id: 'd_prev_week',
          authorId: 'curator_active',
          createdAt: mondayThisWeek.subtract(const Duration(days: 3)),
        ),
      ];

      final card = SundayRetrospectiveService.generateDigest(
        userId: 'curator_active',
        userDrops: userDrops,
        friendIds: ['friend_a'],
        allDrops: userDrops,
        lang: 'en',
        referenceTime: sundayEvening,
      );

      expect(card.isAtRisk, isFalse);
      expect(card.dropsThisWeek, equals(1));
      expect(card.streakWeeks, equals(2));
      expect(card.title, contains('Weekly Tashkent Retrospective'));
      expect(card.ctaRoute, equals('/profile'));
    });

    test('generates encouraging card for inactive curator with circle drops', () {
      final friendDrops = [
        createDrop(
          id: 'f1',
          authorId: 'friend_a',
          createdAt: sundayEvening.subtract(const Duration(days: 2)),
        ),
        createDrop(
          id: 'f2',
          authorId: 'friend_b',
          createdAt: sundayEvening.subtract(const Duration(days: 1)),
        ),
      ];

      final card = SundayRetrospectiveService.generateDigest(
        userId: 'curator_new',
        userDrops: [],
        friendIds: ['friend_a', 'friend_b'],
        allDrops: friendDrops,
        lang: 'en',
        referenceTime: sundayEvening,
      );

      expect(card.isAtRisk, isFalse);
      expect(card.dropsThisWeek, equals(0));
      expect(card.circleDropsThisWeek, equals(2));
      expect(card.ctaRoute, equals('/explore'));
    });

    test('produces accurate trilingual copy for at-risk and secured states', () {
      final userDrops = [
        createDrop(
          id: 'd_last_week',
          authorId: 'curator_trilingual',
          createdAt: mondayThisWeek.subtract(const Duration(days: 4)),
        ),
      ];

      final cardUz = SundayRetrospectiveService.generateDigest(
        userId: 'curator_trilingual',
        userDrops: userDrops,
        friendIds: [],
        allDrops: userDrops,
        lang: 'uz',
        referenceTime: sundayEvening,
      );
      expect(cardUz.title, contains('Seriyangiz Xavf Ostida!'));
      expect(cardUz.ctaText, equals('Joyni Belgilash'));

      final cardRu = SundayRetrospectiveService.generateDigest(
        userId: 'curator_trilingual',
        userDrops: userDrops,
        friendIds: [],
        allDrops: userDrops,
        lang: 'ru',
        referenceTime: sundayEvening,
      );
      expect(cardRu.title, contains('Серия под угрозой!'));
      expect(cardRu.ctaText, equals('Оставить дроп'));
    });
  });
}
