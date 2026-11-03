import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_trophy_engine.dart';

void main() {
  group('P28-01: SeasonTrophyEngine Unit Tests', () {
    test('getSeasonId formats year and zero-padded month string', () {
      expect(SeasonTrophyEngine.getSeasonId(DateTime(2026, 11, 3)), equals('2026-11'));
      expect(SeasonTrophyEngine.getSeasonId(DateTime(2026, 3, 15)), equals('2026-03'));
      expect(SeasonTrophyEngine.getSeasonId(DateTime(2027, 1, 1)), equals('2027-01'));
    });

    test('SeasonalChallenge computes completion and progress percentage correctly', () {
      const challenge = SeasonalChallenge(
        id: 'district_explorer',
        titleEn: 'District Pioneer',
        titleUz: 'Tuman Kashfiyotchisi',
        titleRu: 'Первопроходец Районов',
        descriptionEn: 'Discover verified places across 3 distinct Tashkent districts',
        descriptionUz: 'Toshkentning 3 ta turli tumanida tasdiqlangan joylarni kashf eting',
        descriptionRu: 'Посетите проверенные места в 3 различных районах Ташкента',
        icon: '🧭',
        targetCount: 3,
        currentCount: 1,
        xpReward: 200,
      );

      expect(challenge.isCompleted, isFalse);
      expect(challenge.progressPercentage, closeTo(0.333, 0.01));

      final updated = challenge.copyWith(currentCount: 3);
      expect(updated.isCompleted, isTrue);
      expect(updated.progressPercentage, equals(1.0));

      // Overcompletion clamp
      final over = challenge.copyWith(currentCount: 5);
      expect(over.isCompleted, isTrue);
      expect(over.progressPercentage, equals(1.0));
    });

    test('SeasonalChallenge provides localized titles and descriptions', () {
      const challenge = SeasonalChallenge(
        id: 'metro_nomad',
        titleEn: 'Metro Line Nomad',
        titleUz: 'Metro Chizig‘i Sayyohi',
        titleRu: 'Кочевник Метрополитена',
        descriptionEn: 'Check in near 3 different Tashkent subway stations',
        descriptionUz: 'Toshkent metrosining 3 ta turli bekati yaqinida ro‘yxatdan o‘ting',
        descriptionRu: 'Сделайте отметки около 3 разных станций ташкентского метро',
        icon: '🚇',
        targetCount: 3,
        xpReward: 150,
      );

      expect(challenge.getLocalizedTitle('en'), equals('Metro Line Nomad'));
      expect(challenge.getLocalizedTitle('uz'), equals('Metro Chizig‘i Sayyohi'));
      expect(challenge.getLocalizedTitle('ru'), equals('Кочевник Метрополитена'));

      expect(challenge.getLocalizedDescription('en'), contains('subway stations'));
      expect(challenge.getLocalizedDescription('uz'), contains('bekati'));
      expect(challenge.getLocalizedDescription('ru'), contains('метро'));
    });

    test('CuratorSeason correctly computes overall trophy tier and earned XP', () {
      final season = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 3, // Complete (200 XP)
        metroCount: 3,    // Complete (150 XP)
        weekendCount: 0,  // Incomplete (target 2)
      );

      expect(season.seasonId, equals('2026-11'));
      expect(season.completedCount, equals(2));
      expect(season.totalChallenges, equals(3));
      expect(season.overallProgress, closeTo(0.666, 0.01));
      expect(season.totalXpAvailable, equals(500));
      expect(season.totalXpEarned, equals(350));
      expect(season.earnedTrophyTier, equals(CuratorTrophyTier.silver));
    });

    test('CuratorSeason awards Gold tier when all 3 challenges are completed', () {
      final season = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 3,
        metroCount: 3,
        weekendCount: 2,
      );

      expect(season.completedCount, equals(3));
      expect(season.earnedTrophyTier, equals(CuratorTrophyTier.gold));
      expect(season.totalXpEarned, equals(500));
    });

    test('CuratorSeason awards Bronze tier when 1 challenge is completed', () {
      final season = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 3,
        metroCount: 0,
        weekendCount: 0,
      );

      expect(season.completedCount, equals(1));
      expect(season.earnedTrophyTier, equals(CuratorTrophyTier.bronze));
    });

    test('CuratorSeason awards no tier when 0 challenges are completed', () {
      final season = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 0,
        metroCount: 0,
        weekendCount: 0,
      );

      expect(season.completedCount, equals(0));
      expect(season.earnedTrophyTier, isNull);
    });

    test('calculateDaysRemaining computes difference correctly and clamps', () {
      final now = DateTime(2026, 11, 10);
      final endOfMonth = DateTime(2026, 11, 30);
      final remaining = SeasonTrophyEngine.calculateDaysRemaining(endOfMonth, now);

      expect(remaining, equals(20));

      final pastDate = DateTime(2026, 11, 5);
      final zeroRemaining = SeasonTrophyEngine.calculateDaysRemaining(pastDate, now);
      expect(zeroRemaining, equals(0));
    });

    test('getLocalizedTierName translates tiers across all 3 languages', () {
      expect(SeasonTrophyEngine.getLocalizedTierName(CuratorTrophyTier.gold, 'en'), equals('Gold Trophy'));
      expect(SeasonTrophyEngine.getLocalizedTierName(CuratorTrophyTier.gold, 'uz'), equals('Oltin Kubok'));
      expect(SeasonTrophyEngine.getLocalizedTierName(CuratorTrophyTier.gold, 'ru'), equals('Золотой Трофей'));

      expect(SeasonTrophyEngine.getLocalizedTierName(CuratorTrophyTier.silver, 'uz'), equals('Kumush Kubok'));
      expect(SeasonTrophyEngine.getLocalizedTierName(CuratorTrophyTier.bronze, 'ru'), equals('Бронзовый Трофей'));
    });

    test('Riverpod providers initialize cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(seasonTrophyEngineProvider);
      expect(engine, isA<SeasonTrophyEngine>());

      final currentSeason = container.read(currentSeasonProvider);
      expect(currentSeason, isA<CuratorSeason>());
      expect(currentSeason.challenges.length, equals(3));
    });
  });
}
