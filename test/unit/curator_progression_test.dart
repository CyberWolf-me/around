import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_progression_engine.dart';

void main() {
  group('P23-01: CuratorProgressionEngine Unit Tests', () {
    test('fresh account defaults to Tier 1 Neighborhood Scout with 0 XP', () {
      final p = CuratorProgressionEngine.calculate(
        dropsCount: 0,
        streakWeeks: 0,
        districtCrowns: 0,
      );

      expect(p.totalXp, equals(0));
      expect(p.tier, equals(CuratorTier.neighborhoodScout));
      expect(p.level, equals(1));
      expect(p.progressFraction, equals(0.0));
      expect(p.xpToNextTier, equals(250));
      expect(p.tier.badgeEmoji, equals('🌱'));
    });

    test('5 drops awards 250 XP and unlocks Tier 2 District Curator', () {
      final p = CuratorProgressionEngine.calculate(
        dropsCount: 5, // 5 * 50 = 250 XP
        streakWeeks: 0,
      );

      expect(p.totalXp, equals(250));
      expect(p.tier, equals(CuratorTier.districtCurator));
      expect(p.level, equals(2));
      expect(p.progressFraction, equals(0.0));
      expect(p.xpToNextTier, equals(500)); // 750 - 250 = 500
      expect(p.tier.badgeEmoji, equals('🧭'));
    });

    test('10 drops and 3-week streak unlocks Tier 3 City Pioneer', () {
      final p = CuratorProgressionEngine.calculate(
        dropsCount: 10, // 500 XP
        streakWeeks: 3,  // 300 XP -> total 800 XP
      );

      expect(p.totalXp, equals(800));
      expect(p.tier, equals(CuratorTier.cityPioneer));
      expect(p.level, equals(3));
      // In tier 3 (750 to 2000, range 1250), 50 XP into tier = 50 / 1250 = 0.04
      expect(p.progressFraction, closeTo(0.04, 0.001));
      expect(p.xpToNextTier, equals(1200));
      expect(p.tier.badgeEmoji, equals('⚡'));
    });

    test('30 drops, 5 streak weeks, and 2 crowns unlocks Tier 4 Tashkent Legend', () {
      final p = CuratorProgressionEngine.calculate(
        dropsCount: 30, // 1500 XP
        streakWeeks: 5,  // 500 XP
        districtCrowns: 2, // 500 XP -> total 2500 XP
      );

      expect(p.totalXp, equals(2500));
      expect(p.tier, equals(CuratorTier.tashkentLegend));
      expect(p.level, equals(4));
      expect(p.nextTierBaseXp, isNull);
      expect(p.progressFraction, equals(1.0));
      expect(p.xpToNextTier, equals(0));
      expect(p.tier.badgeEmoji, equals('👑'));
    });

    test('localizedTitle and formattedProgressLabel localize across all 3 languages', () {
      final scout = CuratorProgressionEngine.calculate(dropsCount: 2, streakWeeks: 0); // 100 XP
      expect(scout.localizedTitle('uz'), equals('Mahalla Izquvari'));
      expect(scout.localizedTitle('ru'), equals('Разведчик района'));
      expect(scout.localizedTitle('en'), equals('Neighborhood Scout'));
      expect(scout.formattedProgressLabel('uz'), contains('150 XP'));
      expect(scout.formattedProgressLabel('ru'), contains('150 XP'));
      expect(scout.formattedProgressLabel('en'), contains('150 XP'));

      final legend = CuratorProgressionEngine.calculate(dropsCount: 50, streakWeeks: 10);
      expect(legend.localizedTitle('uz'), equals('Toshkent Afsonasi'));
      expect(legend.localizedTitle('ru'), equals('Легенда Ташкента'));
      expect(legend.localizedTitle('en'), equals('Tashkent Legend'));
      expect(legend.formattedProgressLabel('uz'), equals('Eng yuqori cho‘qqi!'));
      expect(legend.formattedProgressLabel('ru'), equals('Максимальный уровень!'));
      expect(legend.formattedProgressLabel('en'), equals('Max Level Reached!'));
    });

    test('handles negative inputs defensively without exceptions', () {
      final p = CuratorProgressionEngine.calculate(
        dropsCount: -5,
        streakWeeks: -2,
        districtCrowns: -1,
        bonusXp: -100,
      );

      expect(p.totalXp, equals(0));
      expect(p.level, equals(1));
    });
  });
}
