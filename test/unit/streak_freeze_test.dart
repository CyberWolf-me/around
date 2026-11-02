import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/streak_freeze_service.dart';
import 'package:around_app/core/services/explorer_streak_engine.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await StorageService.init();
    await StreakFreezeService.setAvailableShields(0);
  });

  PostModel createDrop({
    required String id,
    required String userId,
    required DateTime createdAt,
  }) {
    return PostModel(
      id: id,
      authorId: userId,
      authorName: 'Test Curator',
      authorUsername: 'curator_test',
      placeId: 'place_breadly',
      placeName: 'Breadly Bakery',
      placeCategory: 'Café',
      placeAddress: 'Mirabad, Tashkent',
      audience: PostAudience.friends,
      createdAt: createdAt,
      note: 'Great morning espresso and sourdough!',
    );
  }

  group('P21-02: StreakFreezeService Unit Tests', () {
    test('initializes with zero available shields and clamp bounds', () async {
      expect(StreakFreezeService.getAvailableShields(), equals(0));

      await StreakFreezeService.setAvailableShields(5); // should clamp to 2
      expect(StreakFreezeService.getAvailableShields(), equals(2));

      await StreakFreezeService.setAvailableShields(-1); // should clamp to 0
      expect(StreakFreezeService.getAvailableShields(), equals(0));
    });

    test('banks shield when user drops reach weekly threshold of 3', () async {
      final now = DateTime(2026, 11, 4, 12, 0); // Wednesday
      final drops = [
        createDrop(id: 'd1', userId: 'user_1', createdAt: DateTime(2026, 11, 2, 10, 0)), // Monday
        createDrop(id: 'd2', userId: 'user_1', createdAt: DateTime(2026, 11, 3, 14, 0)), // Tuesday
        createDrop(id: 'd3', userId: 'user_1', createdAt: DateTime(2026, 11, 4, 9, 0)),  // Wednesday
      ];

      final status = await StreakFreezeService.evaluateShieldStatus(
        userId: 'user_1',
        drops: drops,
        referenceTime: now,
      );

      expect(status.hasEarnedShieldThisWeek, isTrue);
      expect(status.dropsThisWeek, equals(3));
      expect(status.dropsNeededForNextShield, equals(0));
      expect(status.availableShields, equals(1));
      expect(StreakFreezeService.getAvailableShields(), equals(1));
    });

    test('does not bank shield when user drops are below threshold', () async {
      final now = DateTime(2026, 11, 4, 12, 0);
      final drops = [
        createDrop(id: 'd1', userId: 'user_1', createdAt: DateTime(2026, 11, 2, 10, 0)),
      ];

      final status = await StreakFreezeService.evaluateShieldStatus(
        userId: 'user_1',
        drops: drops,
        referenceTime: now,
      );

      expect(status.hasEarnedShieldThisWeek, isFalse);
      expect(status.dropsThisWeek, equals(1));
      expect(status.dropsNeededForNextShield, equals(2));
      expect(status.availableShields, equals(0));
    });

    test('caps available shields at max capacity of 2', () async {
      await StreakFreezeService.setAvailableShields(2);

      final now = DateTime(2026, 11, 4, 12, 0);
      final drops = [
        createDrop(id: 'd1', userId: 'user_1', createdAt: DateTime(2026, 11, 2, 10, 0)),
        createDrop(id: 'd2', userId: 'user_1', createdAt: DateTime(2026, 11, 3, 14, 0)),
        createDrop(id: 'd3', userId: 'user_1', createdAt: DateTime(2026, 11, 4, 9, 0)),
      ];

      final status = await StreakFreezeService.evaluateShieldStatus(
        userId: 'user_1',
        drops: drops,
        referenceTime: now,
      );

      expect(status.availableShields, equals(2));
      expect(StreakFreezeService.getAvailableShields(), equals(2));
    });

    test('applies shield automatically when streak is at risk and decrements count', () async {
      await StreakFreezeService.setAvailableShields(1);

      final atRiskStatus = ExplorerStreakStatus(
        currentStreakWeeks: 4,
        longestStreakWeeks: 4,
        hasDroppedThisWeek: false,
        isAtRisk: true,
        daysRemainingInWeek: 0,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 4,
      );

      final applied = await StreakFreezeService.applyFreezeShieldIfEligible(
        userId: 'user_1',
        streakStatus: atRiskStatus,
        referenceTime: DateTime(2026, 11, 8, 21, 0), // Sunday night
      );

      expect(applied, isTrue);
      expect(StreakFreezeService.getAvailableShields(), equals(0));

      final frozenHistory = StreakFreezeService.getFrozenWeeks();
      expect(frozenHistory.length, equals(1));
    });

    test('does not apply shield when streak is not at risk', () async {
      await StreakFreezeService.setAvailableShields(1);

      final securedStatus = ExplorerStreakStatus(
        currentStreakWeeks: 4,
        longestStreakWeeks: 4,
        hasDroppedThisWeek: true,
        isAtRisk: false,
        daysRemainingInWeek: 3,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 4,
      );

      final applied = await StreakFreezeService.applyFreezeShieldIfEligible(
        userId: 'user_1',
        streakStatus: securedStatus,
      );

      expect(applied, isFalse);
      expect(StreakFreezeService.getAvailableShields(), equals(1));
    });

    test('fails to apply shield when inventory is empty', () async {
      await StreakFreezeService.setAvailableShields(0);

      final atRiskStatus = ExplorerStreakStatus(
        currentStreakWeeks: 4,
        longestStreakWeeks: 4,
        hasDroppedThisWeek: false,
        isAtRisk: true,
        daysRemainingInWeek: 0,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 4,
      );

      final applied = await StreakFreezeService.applyFreezeShieldIfEligible(
        userId: 'user_1',
        streakStatus: atRiskStatus,
      );

      expect(applied, isFalse);
      expect(StreakFreezeService.getAvailableShields(), equals(0));
    });
  });
}
