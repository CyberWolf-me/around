import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_accolades_engine.dart';
import 'package:around_app/core/services/season_trophy_engine.dart';

void main() {
  group('P31-01: CuratorAccoladesEngine Unit Tests', () {
    late CuratorAccoladesEngine engine;

    setUp(() {
      engine = CuratorAccoladesEngine();
    });

    test('determines scout tier when user has no crowns or trophies', () {
      final tier = engine.determineMasteryTier(
        crownsCount: 0,
        trophies: [],
      );
      expect(tier, equals(CuratorMasteryTier.scout));
    });

    test('determines pioneer tier when user has bronze or silver trophies', () {
      final trophies = [
        CuratorAccoladeTrophy(
          id: 't-1',
          seasonId: '2026-10',
          seasonTitle: 'October Harvest',
          tier: CuratorTrophyTier.bronze,
          completedChallengesCount: 1,
          earnedAt: DateTime(2026, 10, 31),
        ),
      ];

      final tier = engine.determineMasteryTier(
        crownsCount: 0,
        trophies: trophies,
      );
      expect(tier, equals(CuratorMasteryTier.pioneer));
    });

    test('determines legend tier when user has 1 crown or 1 gold trophy', () {
      final tierWithCrown = engine.determineMasteryTier(
        crownsCount: 1,
        trophies: [],
      );
      expect(tierWithCrown, equals(CuratorMasteryTier.legend));

      final goldTrophies = [
        CuratorAccoladeTrophy(
          id: 't-gold',
          seasonId: '2026-11',
          seasonTitle: 'Autumn in Tashkent',
          tier: CuratorTrophyTier.gold,
          completedChallengesCount: 3,
          earnedAt: DateTime(2026, 11, 2),
        ),
      ];

      final tierWithGold = engine.determineMasteryTier(
        crownsCount: 0,
        trophies: goldTrophies,
      );
      expect(tierWithGold, equals(CuratorMasteryTier.legend));
    });

    test('determines grandMaster tier with 3+ crowns or 1 crown + 2 gold trophies', () {
      final tierThreeCrowns = engine.determineMasteryTier(
        crownsCount: 3,
        trophies: [],
      );
      expect(tierThreeCrowns, equals(CuratorMasteryTier.grandMaster));

      final twoGolds = [
        CuratorAccoladeTrophy(
          id: 'g-1',
          seasonId: '2026-09',
          seasonTitle: 'September Heritage',
          tier: CuratorTrophyTier.gold,
          earnedAt: DateTime(2026, 9, 30),
        ),
        CuratorAccoladeTrophy(
          id: 'g-2',
          seasonId: '2026-10',
          seasonTitle: 'October Harvest',
          tier: CuratorTrophyTier.gold,
          earnedAt: DateTime(2026, 10, 31),
        ),
      ];

      final tierCrownAndGolds = engine.determineMasteryTier(
        crownsCount: 1,
        trophies: twoGolds,
      );
      expect(tierCrownAndGolds, equals(CuratorMasteryTier.grandMaster));
    });

    test('formats mastery titles localized in UZ, RU, and EN', () {
      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.grandMaster, locale: 'en'),
        equals('Grand Master Curator'),
      );
      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.grandMaster, locale: 'uz'),
        equals('Katta Kurator Ustasi'),
      );
      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.grandMaster, locale: 'ru'),
        equals('Гранд-Мастер Куратор'),
      );

      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.legend, locale: 'en'),
        equals('Tashkent Legend'),
      );
      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.pioneer, locale: 'uz'),
        equals('Tuman Kashfiyotchisi'),
      );
      expect(
        engine.formatMasteryTitle(CuratorMasteryTier.scout, locale: 'ru'),
        equals('Разведчик Махалли'),
      );
    });

    test('calculates accurate weighted honor score', () {
      final trophies = [
        CuratorAccoladeTrophy(
          id: 't-1',
          seasonId: '2026-10',
          seasonTitle: 'October',
          tier: CuratorTrophyTier.gold,
          earnedAt: DateTime(2026, 10, 31),
        ),
        CuratorAccoladeTrophy(
          id: 't-2',
          seasonId: '2026-09',
          seasonTitle: 'September',
          tier: CuratorTrophyTier.silver,
          earnedAt: DateTime(2026, 9, 30),
        ),
      ];

      final laurels = [
        const CuratorAccoladeLaurel(
          seasonId: '2026-10',
          district: 'Mirabad',
          rank: 1,
          laurel: CuratorLaurelTier.champion,
        ),
      ];

      final accolades = engine.buildAccolades(
        userId: 'u-123',
        username: 'kamila_tashkent',
        crownsCount: 1,
        trophies: trophies,
        laurels: laurels,
        totalCuratorXp: 500,
      );

      // Score: 1 crown (1000) + 1 gold (500) + 1 silver (250) + 1 laurel (150) + 500/10 (50) = 1950
      final score = engine.calculateAccoladesScore(accolades);
      expect(score, equals(1950));
    });

    test('generates social share summary containing badges and taste passport URL', () {
      final trophies = [
        CuratorAccoladeTrophy(
          id: 't-1',
          seasonId: '2026-11',
          seasonTitle: 'Autumn in Tashkent',
          tier: CuratorTrophyTier.gold,
          earnedAt: DateTime(2026, 11, 2),
        ),
      ];

      final accolades = engine.buildAccolades(
        userId: 'u-456',
        username: 'sardor_curates',
        crownsCount: 1,
        trophies: trophies,
        laurels: [],
        totalCuratorXp: 320,
      );

      final summaryEn = engine.generateShareSummary(accolades, locale: 'en');
      expect(summaryEn, contains('Tashkent Legend — @sardor_curates'));
      expect(summaryEn, contains('👑 1 District Crowns'));
      expect(summaryEn, contains('🥇1'));
      expect(summaryEn, contains('https://around.tashkent.app/passport/sardor_curates'));

      final summaryUz = engine.generateShareSummary(accolades, locale: 'uz');
      expect(summaryUz, contains('Toshkent Afsonasi'));
      expect(summaryUz, contains('ta\'m pasportimni ko\'ring'));
    });

    test('serializes and deserializes trophies and laurels correctly', () {
      final now = DateTime(2026, 11, 3, 10, 0);
      final trophy = CuratorAccoladeTrophy(
        id: 't-99',
        seasonId: '2026-11',
        seasonTitle: 'Tashkent Autumn',
        tier: CuratorTrophyTier.gold,
        completedChallengesCount: 3,
        xpBonus: 150,
        earnedAt: now,
      );

      final json = trophy.toJson();
      final parsed = CuratorAccoladeTrophy.fromJson(json);

      expect(parsed.id, equals('t-99'));
      expect(parsed.seasonId, equals('2026-11'));
      expect(parsed.tier, equals(CuratorTrophyTier.gold));
      expect(parsed.completedChallengesCount, equals(3));
      expect(parsed.xpBonus, equals(150));

      final laurel = const CuratorAccoladeLaurel(
        seasonId: '2026-10',
        district: 'Yakkasaray',
        rank: 2,
        laurel: CuratorLaurelTier.podium,
      );

      final laurelJson = laurel.toJson();
      final parsedLaurel = CuratorAccoladeLaurel.fromJson(laurelJson);
      expect(parsedLaurel.district, equals('Yakkasaray'));
      expect(parsedLaurel.rank, equals(2));
      expect(parsedLaurel.laurel, equals(CuratorLaurelTier.podium));
    });

    test('returns next tier requirement string localized', () {
      final scout = engine.buildAccolades(
        userId: 'u-1',
        username: 'scout_user',
        crownsCount: 0,
        trophies: [],
        laurels: [],
      );

      expect(
        engine.getNextTierRequirement(scout, locale: 'en'),
        contains('Earn your first seasonal trophy'),
      );
      expect(
        engine.getNextTierRequirement(scout, locale: 'uz'),
        contains('Birinchi mavsumiy kubokni yuting'),
      );
    });

    test('Riverpod provider initializes CuratorAccoladesEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(curatorAccoladesEngineProvider);
      expect(service, isA<CuratorAccoladesEngine>());
    });
  });
}
