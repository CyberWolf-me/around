import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/place_model.dart';
import '../../data/models/post_model.dart';
import 'explorer_streak_engine.dart';

/// Retrospective digest card generated for Sunday evening reflection (`P18-02`).
class SundayRetrospectiveCard {
  final String title;
  final String message;
  final String ctaText;
  final String ctaRoute;
  final bool isAtRisk;
  final int dropsThisWeek;
  final int streakWeeks;
  final int circleDropsThisWeek;
  final String? topDistrict;

  const SundayRetrospectiveCard({
    required this.title,
    required this.message,
    required this.ctaText,
    required this.ctaRoute,
    required this.isAtRisk,
    required this.dropsThisWeek,
    required this.streakWeeks,
    required this.circleDropsThisWeek,
    this.topDistrict,
  });
}

/// Sunday Evening Social Digest & Retrospective Trigger Engine (`P18-02`).
/// Detects Sunday evening reflection window (18:00 - 22:00 Tashkent time)
/// and produces targeted weekly summaries and streak preservation alerts.
class SundayRetrospectiveService {
  /// Sunday evening retrospective trigger window: 18:00 to 22:00.
  static const int startHour = 18;
  static const int endHour = 22;

  /// Whether current moment is inside the Sunday evening retrospective window.
  static bool isRetrospectiveWindow([DateTime? time]) {
    final now = time ?? DateTime.now();
    return now.weekday == DateTime.sunday &&
        now.hour >= startHour &&
        now.hour < endHour;
  }

  /// Generates personalized Sunday evening digest card.
  static SundayRetrospectiveCard generateDigest({
    required String userId,
    required List<PostModel> userDrops,
    required List<String> friendIds,
    required List<PostModel> allDrops,
    List<PlaceModel> places = const [],
    String lang = 'en',
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? DateTime.now();
    final currentMonday = ExplorerStreakEngine.getMondayOfWeek(now);

    final streakStatus = ExplorerStreakEngine.computeStreak(
      userId: userId,
      drops: userDrops,
      referenceTime: now,
    );

    // Calculate drops by user in current calendar week
    final dropsThisWeek = userDrops.where((d) {
      return ExplorerStreakEngine.getMondayOfWeek(d.createdAt) == currentMonday;
    }).length;

    // Calculate drops by friends in current calendar week
    final circleDropsThisWeek = allDrops.where((d) {
      return friendIds.contains(d.authorId) &&
          ExplorerStreakEngine.getMondayOfWeek(d.createdAt) == currentMonday;
    }).length;

    // Identify user's most visited district this week if any
    String? topDistrict;
    if (dropsThisWeek > 0) {
      final weekDrops = userDrops.where((d) {
        return ExplorerStreakEngine.getMondayOfWeek(d.createdAt) == currentMonday;
      }).toList();

      final districtCounts = <String, int>{};
      for (final d in weekDrops) {
        final dist = _extractDistrict(d, places);
        districtCounts[dist] = (districtCounts[dist] ?? 0) + 1;
      }
      if (districtCounts.isNotEmpty) {
        topDistrict = districtCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
    }

    final langCode = lang.toLowerCase().trim();

    // Case 1: Streak at risk (user had a streak last week, but hasn't dropped this week)
    if (streakStatus.isAtRisk) {
      return _buildAtRiskCard(
        streakWeeks: streakStatus.currentStreakWeeks,
        circleDrops: circleDropsThisWeek,
        lang: langCode,
      );
    }

    // Case 2: User successfully dropped this week (streak secured)
    if (dropsThisWeek > 0) {
      return _buildSecuredCard(
        dropsCount: dropsThisWeek,
        streakWeeks: streakStatus.currentStreakWeeks,
        circleDrops: circleDropsThisWeek,
        topDistrict: topDistrict,
        lang: langCode,
      );
    }

    // Case 3: Inactive curator (encouragement to start fresh)
    return _buildInactiveCard(
      circleDrops: circleDropsThisWeek,
      lang: langCode,
    );
  }

  static SundayRetrospectiveCard _buildAtRiskCard({
    required int streakWeeks,
    required int circleDrops,
    required String lang,
  }) {
    switch (lang) {
      case 'uz':
        return SundayRetrospectiveCard(
          title: '⚠️ Yakshanba Oqshomi: Seriyangiz Xavf Ostida!',
          message:
              'Hafta tugashiga oz qoldi! $streakWeeks haftalik kashfiyot seriyangizni saqlab qolish uchun bugun 1 ta joyni belgilang.',
          ctaText: 'Joyni Belgilash',
          ctaRoute: '/create-post',
          isAtRisk: true,
          dropsThisWeek: 0,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
        );
      case 'ru':
        return SundayRetrospectiveCard(
          title: '⚠️ Воскресный вечер: Серия под угрозой!',
          message:
              'До конца недели осталось несколько часов! Оставьте дроп, чтобы сохранить серию в $streakWeeks нед.',
          ctaText: 'Оставить дроп',
          ctaRoute: '/create-post',
          isAtRisk: true,
          dropsThisWeek: 0,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
        );
      case 'en':
      default:
        return SundayRetrospectiveCard(
          title: '⚠️ Sunday Evening: Streak At Risk!',
          message:
              'Only hours remain in the week! Drop a spot tonight to protect your $streakWeeks-week streak.',
          ctaText: 'Drop Spot Now',
          ctaRoute: '/create-post',
          isAtRisk: true,
          dropsThisWeek: 0,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
        );
    }
  }

  static SundayRetrospectiveCard _buildSecuredCard({
    required int dropsCount,
    required int streakWeeks,
    required int circleDrops,
    String? topDistrict,
    required String lang,
  }) {
    switch (lang) {
      case 'uz':
        return SundayRetrospectiveCard(
          title: '🎉 Haftalik Toshkent Sarhisobi',
          message:
              'Ajoyib natija! Bu hafta $dropsCount ta joy kashf qildingiz va $streakWeeks haftalik seriyani mustahkamladingiz.',
          ctaText: 'Pasportni Koʻrish',
          ctaRoute: '/profile',
          isAtRisk: false,
          dropsThisWeek: dropsCount,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
          topDistrict: topDistrict,
        );
      case 'ru':
        return SundayRetrospectiveCard(
          title: '🎉 Итоги недели в Ташкенте',
          message:
              'Отличная работа! Вы открыли $dropsCount мест на этой неделе, закрепив серию в $streakWeeks нед.',
          ctaText: 'Посмотреть паспорт',
          ctaRoute: '/profile',
          isAtRisk: false,
          dropsThisWeek: dropsCount,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
          topDistrict: topDistrict,
        );
      case 'en':
      default:
        return SundayRetrospectiveCard(
          title: '🎉 Weekly Tashkent Retrospective',
          message:
              'Great exploration! You reviewed $dropsCount spots this week, securing your $streakWeeks-week streak.',
          ctaText: 'View Taste Passport',
          ctaRoute: '/profile',
          isAtRisk: false,
          dropsThisWeek: dropsCount,
          streakWeeks: streakWeeks,
          circleDropsThisWeek: circleDrops,
          topDistrict: topDistrict,
        );
    }
  }

  static SundayRetrospectiveCard _buildInactiveCard({
    required int circleDrops,
    required String lang,
  }) {
    switch (lang) {
      case 'uz':
        return SundayRetrospectiveCard(
          title: '🧭 Yangi Hafta — Yangi Rejalar',
          message:
              'Doʻstlaringiz bu hafta $circleDrops ta joyni belgilashdi. Kelasi hafta oʻz kashfiyot seriyangizni boshlang!',
          ctaText: 'Xaritani Ochish',
          ctaRoute: '/explore',
          isAtRisk: false,
          dropsThisWeek: 0,
          streakWeeks: 0,
          circleDropsThisWeek: circleDrops,
        );
      case 'ru':
        return SundayRetrospectiveCard(
          title: '🧭 Новая неделя — новые места',
          message:
              'Ваши друзья оставили $circleDrops дропов на этой неделе. Начните свою серию открытий!',
          ctaText: 'Открыть карту',
          ctaRoute: '/explore',
          isAtRisk: false,
          dropsThisWeek: 0,
          streakWeeks: 0,
          circleDropsThisWeek: circleDrops,
        );
      case 'en':
      default:
        return SundayRetrospectiveCard(
          title: '🧭 New Week Ahead',
          message:
              'Your circle logged $circleDrops drops this week. Discover a new spot and begin your streak!',
          ctaText: 'Explore Map',
          ctaRoute: '/explore',
          isAtRisk: false,
          dropsThisWeek: 0,
          streakWeeks: 0,
          circleDropsThisWeek: circleDrops,
        );
    }
  }

  static String _extractDistrict(PostModel drop, List<PlaceModel> places) {
    for (final p in places) {
      if (p.id == drop.placeId || p.slug == drop.placeId) {
        return p.district;
      }
    }
    final addr = drop.placeAddress.toLowerCase();
    if (addr.contains('mirabad') || addr.contains('mirobod')) return 'Mirabad';
    if (addr.contains('yunusabad') || addr.contains('yunusobod')) return 'Yunusabad';
    if (addr.contains('yakkasaray') || addr.contains('yakkasaroy')) return 'Yakkasaray';
    if (addr.contains('chilanzar') || addr.contains('chilonzor')) return 'Chilanzar';
    return 'Central Tashkent';
  }
}

/// Global Riverpod provider for Sunday retrospective service.
final sundayRetrospectiveServiceProvider =
    Provider<SundayRetrospectiveService>((ref) => SundayRetrospectiveService());
