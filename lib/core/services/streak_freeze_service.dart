import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/services/storage_service.dart';
import 'analytics_service.dart';
import 'app_logger.dart';
import 'explorer_streak_engine.dart';

/// Status of an explorer's Streak Freeze shield inventory and protection (`P21-02`).
class StreakFreezeStatus {
  final int availableShields;
  final int maxShields;
  final int dropsThisWeek;
  final int dropsNeededForNextShield;
  final bool hasEarnedShieldThisWeek;
  final List<DateTime> frozenWeeks;

  const StreakFreezeStatus({
    required this.availableShields,
    this.maxShields = 2,
    required this.dropsThisWeek,
    required this.dropsNeededForNextShield,
    required this.hasEarnedShieldThisWeek,
    required this.frozenWeeks,
  });

  bool get hasShieldAvailable => availableShields > 0;
}

/// Explorer Streak Freeze Shield & Grace Period Engine (`P21-02`).
/// Provides Duolingo/Strava-style retention shields for active Tashkent curators:
/// logging >=3 drops in a calendar week banks a freeze shield (capped at 2),
/// automatically protecting explorer streaks against missed weekly deadlines.
class StreakFreezeService {
  static const String _kShieldsCountKey = 'around_streak_freeze_shields_count';
  static const String _kFrozenWeeksKey = 'around_streak_frozen_weeks_history';
  static const int maxShieldsCapacity = 2;
  static const int dropsThresholdForShield = 3;

  /// Retrieves currently banked shields count.
  static int getAvailableShields() {
    final count = StorageService.getInt(_kShieldsCountKey);
    return count.clamp(0, maxShieldsCapacity);
  }

  /// Sets banked shields count safely within capacity limits [0..maxShieldsCapacity].
  static Future<void> setAvailableShields(int count) async {
    final clamped = count.clamp(0, maxShieldsCapacity);
    await StorageService.setInt(_kShieldsCountKey, clamped);
  }

  /// Retrieves history of weeks where freeze shield was consumed to preserve streak.
  static List<DateTime> getFrozenWeeks() {
    final raw = StorageService.getString(_kFrozenWeeksKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DateTime.tryParse(e.toString()))
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      AppLogger.warn('StreakFreezeService', 'Failed to decode frozen weeks history', e);
      return [];
    }
  }

  /// Records a frozen week timestamp and stores history.
  static Future<void> recordFrozenWeek(DateTime weekStart) async {
    final current = getFrozenWeeks();
    final normalized = DateTime(weekStart.year, weekStart.month, weekStart.day);
    if (!current.any((d) => d.year == normalized.year && d.month == normalized.month && d.day == normalized.day)) {
      final updated = [...current, normalized];
      await StorageService.setString(
        _kFrozenWeeksKey,
        jsonEncode(updated.map((d) => d.toIso8601String()).toList()),
      );
    }
  }

  /// Evaluates curator's drop activity for the current week, banks freeze shields
  /// if eligible, and returns comprehensive shield status.
  static Future<StreakFreezeStatus> evaluateShieldStatus({
    required String userId,
    required List<PostModel> drops,
    DateTime? referenceTime,
    AnalyticsService? analytics,
  }) async {
    final now = referenceTime ?? DateTime.now();
    final currentMonday = ExplorerStreakEngine.getMondayOfWeek(now);

    // Filter user drops in the current calendar week
    final weekDrops = drops.where((d) {
      return d.authorId == userId &&
          ExplorerStreakEngine.getMondayOfWeek(d.createdAt) == currentMonday;
    }).length;

    int availableShields = getAvailableShields();
    final frozenWeeks = getFrozenWeeks();

    final hasEarnedShieldThisWeek = weekDrops >= dropsThresholdForShield;
    final dropsNeeded = math.max(0, dropsThresholdForShield - weekDrops);

    // Auto-bank shield if earned and below capacity
    if (hasEarnedShieldThisWeek && availableShields < maxShieldsCapacity) {
      availableShields = math.min(maxShieldsCapacity, availableShields + 1);
      await setAvailableShields(availableShields);
      AppLogger.info('StreakFreezeService', 'Banked streak freeze shield for curator $userId (Total: $availableShields)');

      analytics?.trackCustom('streak_freeze_shield_earned', {
        'user_id': userId,
        'week_start': currentMonday.toIso8601String(),
        'available_shields': availableShields,
      });
    }

    return StreakFreezeStatus(
      availableShields: availableShields,
      dropsThisWeek: weekDrops,
      dropsNeededForNextShield: dropsNeeded,
      hasEarnedShieldThisWeek: hasEarnedShieldThisWeek,
      frozenWeeks: frozenWeeks,
    );
  }

  /// Automatically applies a streak freeze shield to protect an at-risk streak
  /// when a weekly rollover occurs with zero drops.
  static Future<bool> applyFreezeShieldIfEligible({
    required String userId,
    required ExplorerStreakStatus streakStatus,
    DateTime? referenceTime,
    AnalyticsService? analytics,
  }) async {
    if (!streakStatus.isAtRisk) {
      return false; // Streak is either secured or already 0
    }

    final available = getAvailableShields();
    if (available <= 0) {
      AppLogger.info('StreakFreezeService', 'No freeze shields available to protect at-risk streak for $userId');
      return false;
    }

    final now = referenceTime ?? DateTime.now();
    final currentMonday = ExplorerStreakEngine.getMondayOfWeek(now);

    // Consume 1 shield
    final newCount = available - 1;
    await setAvailableShields(newCount);
    await recordFrozenWeek(currentMonday);

    AppLogger.info(
      'StreakFreezeService',
      'Applied Streak Freeze Shield! Preserved ${streakStatus.currentStreakWeeks}-week streak for curator $userId. Remaining shields: $newCount',
    );

    analytics?.trackCustom('streak_freeze_shield_consumed', {
      'user_id': userId,
      'preserved_streak_weeks': streakStatus.currentStreakWeeks,
      'week_start': currentMonday.toIso8601String(),
      'remaining_shields': newCount,
    });

    return true;
  }
}

/// Provider exposing StreakFreezeService evaluation status.
final streakFreezeStatusProvider = FutureProvider<StreakFreezeStatus>((ref) async {
  return StreakFreezeService.evaluateShieldStatus(
    userId: 'current_user',
    drops: const [],
  );
});
