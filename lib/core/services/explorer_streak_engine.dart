import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';

/// Weekly Explorer Streak status and milestone awards (`P17-04`).
class ExplorerStreakStatus {
  final int currentStreakWeeks;
  final int longestStreakWeeks;
  final bool hasDroppedThisWeek;
  final bool isAtRisk;
  final int daysRemainingInWeek;
  final DateTime currentWeekStart;
  final int totalQualifyingWeeks;

  const ExplorerStreakStatus({
    required this.currentStreakWeeks,
    required this.longestStreakWeeks,
    required this.hasDroppedThisWeek,
    required this.isAtRisk,
    required this.daysRemainingInWeek,
    required this.currentWeekStart,
    required this.totalQualifyingWeeks,
  });

  bool get isStreakActive => currentStreakWeeks > 0;

  /// Streak milestone badge identifier.
  String get badgeKey {
    if (currentStreakWeeks >= 12) return 'luminary';
    if (currentStreakWeeks >= 8) return 'seasoned';
    if (currentStreakWeeks >= 4) return 'explorer';
    if (currentStreakWeeks >= 2) return 'trailblazer';
    if (currentStreakWeeks == 1) return 'emerging';
    return 'none';
  }

  /// Localized milestone badge title across Uzbek, Russian, and English.
  String getLocalizedBadge(String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        if (currentStreakWeeks >= 12) return '👑 Shahar Afsonasi (12+ hafta)';
        if (currentStreakWeeks >= 8) return '⚡ Tajribali Kurator (8+ hafta)';
        if (currentStreakWeeks >= 4) return '🔥 4-Haftalik Sayyoh';
        if (currentStreakWeeks >= 2) return '✨ 2-Haftalik Peshqadam';
        if (currentStreakWeeks == 1) return '🌱 Yangi Sayyoh (1 hafta)';
        return '🧭 Ilk Qadamlar';

      case 'ru':
        if (currentStreakWeeks >= 12) return '👑 Городской Люминарий (12+ нед)';
        if (currentStreakWeeks >= 8) return '⚡ Опытный Куратор (8+ нед)';
        if (currentStreakWeeks >= 4) return '🔥 Исследователь 4 недель';
        if (currentStreakWeeks >= 2) return '✨ Первопроходец 2 недель';
        if (currentStreakWeeks == 1) return '🌱 Начинающий Куратор (1 нед)';
        return '🧭 Первые шаги';

      case 'en':
      default:
        if (currentStreakWeeks >= 12) return '👑 City Luminary (12+ wks)';
        if (currentStreakWeeks >= 8) return '⚡ Seasoned Curator (8+ wks)';
        if (currentStreakWeeks >= 4) return '🔥 4-Week Explorer';
        if (currentStreakWeeks >= 2) return '✨ 2-Week Trailblazer';
        if (currentStreakWeeks == 1) return '🌱 Emerging Explorer (1 wk)';
        return '🧭 First Steps';
    }
  }

  /// Weekly retrospective notification and call-to-action prompt.
  String getRetrospectivePrompt(String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'uz':
        if (hasDroppedThisWeek) {
          return '🎉 Bu haftalik kashfiyot seriyasi saqlandi! Toshkent boʻylab ajoyib joylarni kashf etdingiz.';
        }
        if (isAtRisk) {
          return '⚠️ Seriyangiz xavf ostida! Yakshanbagacha biror joyni belgilang va $currentStreakWeeks haftalik seriyangizni saqlang.';
        }
        return '🧭 Bu hafta yangi qahvaxona yoki joyni kashf qiling va seriyangizni boshlang!';

      case 'ru':
        if (hasDroppedThisWeek) {
          return '🎉 Серия открытий на этой неделе закреплена! Вы исследовали Ташкент.';
        }
        if (isAtRisk) {
          return '⚠️ Ваша серия под угрозой! Оставьте дроп до конца воскресенья, чтобы сохранить $currentStreakWeeks нед.';
        }
        return '🧭 Откройте новое место в Ташкенте на этой неделе и начните серию!';

      case 'en':
      default:
        if (hasDroppedThisWeek) {
          return '🎉 Weekly discovery streak secured! You explored Tashkent this week.';
        }
        if (isAtRisk) {
          return '⚠️ Streak at risk! Log a spot before Sunday ends to preserve your $currentStreakWeeks-week streak.';
        }
        return '🧭 Discover a new spot in Tashkent this week to start your streak!';
    }
  }
}

/// Strava-Style Weekly Discovery Streak Engine (`P17-04`).
/// Tracks consecutive weeks where a curator dropped or reviewed a Tashkent spot.
class ExplorerStreakEngine {
  /// Computes the start of the calendar week (Monday 00:00:00).
  static DateTime getMondayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  /// Computes weekly streak status for a given user from their drop history.
  static ExplorerStreakStatus computeStreak({
    required String userId,
    required List<PostModel> drops,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final currentMonday = getMondayOfWeek(now);

    // Days remaining in the current week (Sunday ends at midnight)
    final daysRemaining = 7 - now.weekday;

    // Filter drops authored by this user
    final userDrops = drops.where((d) => d.authorId == userId).toList();
    if (userDrops.isEmpty) {
      return ExplorerStreakStatus(
        currentStreakWeeks: 0,
        longestStreakWeeks: 0,
        hasDroppedThisWeek: false,
        isAtRisk: false,
        daysRemainingInWeek: daysRemaining,
        currentWeekStart: currentMonday,
        totalQualifyingWeeks: 0,
      );
    }

    // Map each drop to its Monday date key
    final activeWeekMondays = <DateTime>{};
    for (final drop in userDrops) {
      activeWeekMondays.add(getMondayOfWeek(drop.createdAt));
    }

    final hasDroppedThisWeek = activeWeekMondays.contains(currentMonday);

    // Determine current streak
    int currentStreak = 0;
    bool isAtRisk = false;

    if (hasDroppedThisWeek) {
      currentStreak = 1;
      var checkMonday = currentMonday.subtract(const Duration(days: 7));
      while (activeWeekMondays.contains(checkMonday)) {
        currentStreak++;
        checkMonday = checkMonday.subtract(const Duration(days: 7));
      }
    } else {
      // Check if user had a streak ending last week
      final lastWeekMonday = currentMonday.subtract(const Duration(days: 7));
      if (activeWeekMondays.contains(lastWeekMonday)) {
        isAtRisk = true;
        currentStreak = 1;
        var checkMonday = lastWeekMonday.subtract(const Duration(days: 7));
        while (activeWeekMondays.contains(checkMonday)) {
          currentStreak++;
          checkMonday = checkMonday.subtract(const Duration(days: 7));
        }
      } else {
        currentStreak = 0;
      }
    }

    // Determine longest historical streak
    final sortedWeeks = activeWeekMondays.toList()..sort();
    int longestStreak = 0;
    int rollingStreak = 0;
    DateTime? previousMonday;

    for (final monday in sortedWeeks) {
      if (previousMonday == null) {
        rollingStreak = 1;
      } else {
        final diffDays = monday.difference(previousMonday).inDays;
        if (diffDays == 7) {
          rollingStreak++;
        } else {
          rollingStreak = 1;
        }
      }
      if (rollingStreak > longestStreak) {
        longestStreak = rollingStreak;
      }
      previousMonday = monday;
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return ExplorerStreakStatus(
      currentStreakWeeks: currentStreak,
      longestStreakWeeks: longestStreak,
      hasDroppedThisWeek: hasDroppedThisWeek,
      isAtRisk: isAtRisk,
      daysRemainingInWeek: daysRemaining,
      currentWeekStart: currentMonday,
      totalQualifyingWeeks: activeWeekMondays.length,
    );
  }
}

/// Global Riverpod provider for explorer streak engine.
final explorerStreakEngineProvider =
    Provider<ExplorerStreakEngine>((ref) => ExplorerStreakEngine());
