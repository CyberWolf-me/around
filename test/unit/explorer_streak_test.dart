import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/explorer_streak_engine.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P17-04: ExplorerStreakEngine & Weekly Discovery Streak Tests', () {
    // Reference: Wednesday, Nov 4, 2026 (Wednesday of that week)
    final refTime = DateTime(2026, 11, 4, 15, 30);
    final mondayThisWeek = ExplorerStreakEngine.getMondayOfWeek(refTime);

    PostModel createDrop({
      required String id,
      required String authorId,
      required DateTime createdAt,
    }) {
      return PostModel(
        id: id,
        authorId: authorId,
        authorName: 'Curator $authorId',
        authorUsername: 'curator_$authorId',
        placeId: 'place_breadly',
        placeName: 'Breadly Bakery',
        placeCategory: 'Cafe',
        placeAddress: 'Mirabad, Tashkent',
        note: 'Weekly explore',
        audience: PostAudience.friends,
        createdAt: createdAt,
      );
    }

    test('returns 0 streak for empty drop history', () {
      final status = ExplorerStreakEngine.computeStreak(
        userId: 'user_fresh',
        drops: [],
        referenceTime: refTime,
      );

      expect(status.currentStreakWeeks, equals(0));
      expect(status.longestStreakWeeks, equals(0));
      expect(status.isStreakActive, isFalse);
      expect(status.hasDroppedThisWeek, isFalse);
      expect(status.isAtRisk, isFalse);
      expect(status.totalQualifyingWeeks, equals(0));
      expect(status.badgeKey, equals('none'));
      expect(status.getLocalizedBadge('en'), equals('🧭 First Steps'));
    });

    test('calculates active streak when user dropped in current week', () {
      final drops = [
        // Drop in current week (Tuesday Nov 3)
        createDrop(
          id: 'd0',
          authorId: 'curator_1',
          createdAt: mondayThisWeek.add(const Duration(days: 1)),
        ),
        // Drop 1 week ago
        createDrop(
          id: 'd1',
          authorId: 'curator_1',
          createdAt: mondayThisWeek.subtract(const Duration(days: 3)),
        ),
        // Drop 2 weeks ago
        createDrop(
          id: 'd2',
          authorId: 'curator_1',
          createdAt: mondayThisWeek.subtract(const Duration(days: 10)),
        ),
      ];

      final status = ExplorerStreakEngine.computeStreak(
        userId: 'curator_1',
        drops: drops,
        referenceTime: refTime,
      );

      expect(status.currentStreakWeeks, equals(3));
      expect(status.longestStreakWeeks, equals(3));
      expect(status.hasDroppedThisWeek, isTrue);
      expect(status.isAtRisk, isFalse);
      expect(status.isStreakActive, isTrue);
      expect(status.badgeKey, equals('trailblazer'));
      expect(status.getLocalizedBadge('en'), equals('✨ 2-Week Trailblazer'));
      expect(status.getLocalizedBadge('uz'), equals('✨ 2-Haftalik Peshqadam'));
    });

    test('flags streak as at-risk when dropped last week but not yet this week', () {
      final drops = [
        // Drop 1 week ago
        createDrop(
          id: 'd1',
          authorId: 'curator_2',
          createdAt: mondayThisWeek.subtract(const Duration(days: 4)),
        ),
        // Drop 2 weeks ago
        createDrop(
          id: 'd2',
          authorId: 'curator_2',
          createdAt: mondayThisWeek.subtract(const Duration(days: 11)),
        ),
      ];

      final status = ExplorerStreakEngine.computeStreak(
        userId: 'curator_2',
        drops: drops,
        referenceTime: refTime,
      );

      expect(status.currentStreakWeeks, equals(2));
      expect(status.hasDroppedThisWeek, isFalse);
      expect(status.isAtRisk, isTrue);
      expect(status.isStreakActive, isTrue);
      expect(status.daysRemainingInWeek, equals(7 - refTime.weekday));

      // Retrospective prompt warning
      expect(status.getRetrospectivePrompt('en'), contains('Streak at risk!'));
      expect(status.getRetrospectivePrompt('uz'), contains('Seriyangiz xavf ostida!'));
    });

    test('resets current streak to 0 if last week was missed', () {
      final drops = [
        // Dropped 2 weeks ago, but missed 1 week ago
        createDrop(
          id: 'd_old',
          authorId: 'curator_gap',
          createdAt: mondayThisWeek.subtract(const Duration(days: 14)),
        ),
        createDrop(
          id: 'd_older',
          authorId: 'curator_gap',
          createdAt: mondayThisWeek.subtract(const Duration(days: 21)),
        ),
      ];

      final status = ExplorerStreakEngine.computeStreak(
        userId: 'curator_gap',
        drops: drops,
        referenceTime: refTime,
      );

      expect(status.currentStreakWeeks, equals(0));
      expect(status.longestStreakWeeks, equals(2));
      expect(status.hasDroppedThisWeek, isFalse);
      expect(status.isAtRisk, isFalse);
    });

    test('awards correct milestone badges across streak lengths', () {
      // 4 weeks streak
      final drops4 = List.generate(4, (i) {
        return createDrop(
          id: 'drop_$i',
          authorId: 'curator_4',
          createdAt: mondayThisWeek.subtract(Duration(days: 7 * i)),
        );
      });

      final status4 = ExplorerStreakEngine.computeStreak(
        userId: 'curator_4',
        drops: drops4,
        referenceTime: refTime,
      );

      expect(status4.currentStreakWeeks, equals(4));
      expect(status4.badgeKey, equals('explorer'));
      expect(status4.getLocalizedBadge('en'), equals('🔥 4-Week Explorer'));
      expect(status4.getLocalizedBadge('ru'), equals('🔥 Исследователь 4 недель'));
      expect(status4.getLocalizedBadge('uz'), equals('🔥 4-Haftalik Sayyoh'));

      // 8 weeks streak
      final drops8 = List.generate(8, (i) {
        return createDrop(
          id: 'drop_$i',
          authorId: 'curator_8',
          createdAt: mondayThisWeek.subtract(Duration(days: 7 * i)),
        );
      });

      final status8 = ExplorerStreakEngine.computeStreak(
        userId: 'curator_8',
        drops: drops8,
        referenceTime: refTime,
      );

      expect(status8.currentStreakWeeks, equals(8));
      expect(status8.badgeKey, equals('seasoned'));
      expect(status8.getLocalizedBadge('en'), equals('⚡ Seasoned Curator (8+ wks)'));

      // 12 weeks streak
      final drops12 = List.generate(12, (i) {
        return createDrop(
          id: 'drop_$i',
          authorId: 'curator_12',
          createdAt: mondayThisWeek.subtract(Duration(days: 7 * i)),
        );
      });

      final status12 = ExplorerStreakEngine.computeStreak(
        userId: 'curator_12',
        drops: drops12,
        referenceTime: refTime,
      );

      expect(status12.currentStreakWeeks, equals(12));
      expect(status12.badgeKey, equals('luminary'));
      expect(status12.getLocalizedBadge('en'), equals('👑 City Luminary (12+ wks)'));
      expect(status12.getLocalizedBadge('uz'), equals('👑 Shahar Afsonasi (12+ hafta)'));
    });
  });
}
