import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_ceremony_engine.dart';

void main() {
  group('P30-01: SeasonCeremonyEngine Unit Tests', () {
    test('evaluateLaurel maps district ranks to correct laurel tiers', () {
      expect(SeasonCeremonyEngine.evaluateLaurel(1), equals(CuratorLaurelTier.champion));
      expect(SeasonCeremonyEngine.evaluateLaurel(2), equals(CuratorLaurelTier.podium));
      expect(SeasonCeremonyEngine.evaluateLaurel(3), equals(CuratorLaurelTier.podium));
      expect(SeasonCeremonyEngine.evaluateLaurel(4), equals(CuratorLaurelTier.topTen));
      expect(SeasonCeremonyEngine.evaluateLaurel(10), equals(CuratorLaurelTier.topTen));
      expect(SeasonCeremonyEngine.evaluateLaurel(11), equals(CuratorLaurelTier.explorer));
      expect(SeasonCeremonyEngine.evaluateLaurel(50), equals(CuratorLaurelTier.explorer));
      expect(SeasonCeremonyEngine.evaluateLaurel(0), equals(CuratorLaurelTier.explorer));
    });

    test('calculateCeremonyBonusXp returns tiered celebration XP rewards', () {
      expect(SeasonCeremonyEngine.calculateCeremonyBonusXp(CuratorLaurelTier.champion), equals(500));
      expect(SeasonCeremonyEngine.calculateCeremonyBonusXp(CuratorLaurelTier.podium), equals(250));
      expect(SeasonCeremonyEngine.calculateCeremonyBonusXp(CuratorLaurelTier.topTen), equals(100));
      expect(SeasonCeremonyEngine.calculateCeremonyBonusXp(CuratorLaurelTier.explorer), equals(50));
    });

    test('generateWrapupReport awards crowns and champion laurel for rank 1', () {
      final report = SeasonCeremonyEngine.generateWrapupReport(
        seasonId: '2026-10',
        seasonTitleEn: 'October in Tashkent',
        seasonTitleUz: 'Toshkentda Oktyabr',
        seasonTitleRu: 'Октябрь в Ташкенте',
        totalSeasonXp: 1250,
        totalPlacesVisited: 18,
        topDistrict: 'Mirabad',
        districtRank: 1,
        cityRank: 2,
      );

      expect(report.seasonId, equals('2026-10'));
      expect(report.totalSeasonXp, equals(1250));
      expect(report.totalPlacesVisited, equals(18));
      expect(report.topDistrict, equals('Mirabad'));
      expect(report.districtRank, equals(1));
      expect(report.cityRank, equals(2));
      expect(report.laurelTier, equals(CuratorLaurelTier.champion));
      expect(report.crownsAwarded, equals(1));
      expect(report.bonusXpAwarded, equals(500));
      expect(report.isChampion, isTrue);

      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'en'), contains('Mirabad Champion'));
      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'uz'), contains('Mirabad Tuman Chempionisiz'));
      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'ru'), contains('Чемпион Района Mirabad'));
    });

    test('generateWrapupReport handles podium rankings without crowns', () {
      final report = SeasonCeremonyEngine.generateWrapupReport(
        seasonId: '2026-10',
        totalSeasonXp: 750,
        totalPlacesVisited: 12,
        topDistrict: 'Yakkasaray',
        districtRank: 3,
        cityRank: 8,
      );

      expect(report.laurelTier, equals(CuratorLaurelTier.podium));
      expect(report.crownsAwarded, equals(0));
      expect(report.bonusXpAwarded, equals(250));
      expect(report.isChampion, isFalse);

      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'en'), contains('#3 in Yakkasaray'));
      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'uz'), contains('#3-O‘rinni'));
      expect(SeasonCeremonyEngine.getLocalizedCelebrationHeadline(report, 'ru'), contains('#3 место'));
    });

    test('getLocalizedLaurelName translates across Uzbek, Russian, and English', () {
      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.champion, 'en'), equals('District Champion Crown'));
      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.champion, 'uz'), equals('Tuman Chempioni Toji'));
      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.champion, 'ru'), equals('Корона Чемпиона Района'));

      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.podium, 'uz'), equals('Kumush Lavr Medali'));
      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.topTen, 'ru'), equals('Бронзовый Лавр Топ-10'));
      expect(SeasonCeremonyEngine.getLocalizedLaurelName(CuratorLaurelTier.explorer, 'en'), equals('Explorer Season Ribbon'));
    });

    test('Riverpod provider initializes SeasonCeremonyEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(seasonCeremonyEngineProvider);
      expect(engine, isA<SeasonCeremonyEngine>());
    });
  });
}
