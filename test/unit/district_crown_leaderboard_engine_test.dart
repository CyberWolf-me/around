import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_crown_leaderboard_engine.dart';

void main() {
  group('P33-01: DistrictCrownLeaderboardEngine Unit Tests', () {
    late DistrictCrownLeaderboardEngine engine;

    setUp(() {
      engine = DistrictCrownLeaderboardEngine();
    });

    test('handles empty standings cleanly', () {
      final podium = engine.computePodium(
        rawStandings: [],
        district: 'Mirabad',
        seasonId: '2026-11',
      );

      expect(podium.district, equals('Mirabad'));
      expect(podium.totalCuratorsCount, equals(0));
      expect(podium.champion, isNull);
      expect(podium.silver, isNull);
      expect(podium.bronze, isNull);
      expect(podium.runnersUp, isEmpty);
    });

    test('correctly orders curators by crowns, season XP, and places visited', () {
      final curators = [
        const DistrictCuratorStanding(
          userId: 'u-1',
          username: 'nodir',
          fullName: 'Nodir Alimov',
          rank: 0,
          district: 'Mirabad',
          seasonXp: 400,
          placesCount: 5,
          crownsCount: 0,
        ),
        const DistrictCuratorStanding(
          userId: 'u-2',
          username: 'kamila',
          fullName: 'Kamila Karimova',
          rank: 0,
          district: 'Mirabad',
          seasonXp: 350,
          placesCount: 4,
          crownsCount: 1, // Crown takes precedence
        ),
        const DistrictCuratorStanding(
          userId: 'u-3',
          username: 'sardor',
          fullName: 'Sardor Rakhimov',
          rank: 0,
          district: 'Mirabad',
          seasonXp: 380,
          placesCount: 4,
          crownsCount: 0,
        ),
        const DistrictCuratorStanding(
          userId: 'u-4',
          username: 'malika',
          fullName: 'Malika Yusupova',
          rank: 0,
          district: 'Mirabad',
          seasonXp: 200,
          placesCount: 2,
          crownsCount: 0,
        ),
      ];

      final podium = engine.computePodium(
        rawStandings: curators,
        district: 'Mirabad',
        seasonId: '2026-11',
      );

      expect(podium.totalCuratorsCount, equals(4));
      // Champion: Kamila (1 crown)
      expect(podium.champion!.username, equals('kamila'));
      expect(podium.champion!.rank, equals(1));
      expect(podium.champion!.isReigningChampion, isTrue);
      expect(podium.champion!.gapToLeaderXp, equals(0));

      // Silver: Nodir (400 XP)
      expect(podium.silver!.username, equals('nodir'));
      expect(podium.silver!.rank, equals(2));
      expect(podium.silver!.isPodium, isTrue);

      // Bronze: Sardor (380 XP)
      expect(podium.bronze!.username, equals('sardor'));
      expect(podium.bronze!.rank, equals(3));
      expect(podium.bronze!.isPodium, isTrue);

      // Runner up: Malika (200 XP)
      expect(podium.runnersUp.length, equals(1));
      expect(podium.runnersUp[0].username, equals('malika'));
      expect(podium.runnersUp[0].rank, equals(4));
      expect(podium.runnersUp[0].isPodium, isFalse);
    });

    test('formats localized district titles and rank labels', () {
      expect(
        engine.formatDistrictTitle('Mirabad', locale: 'en'),
        equals('Mirabad District'),
      );
      expect(
        engine.formatDistrictTitle('Yakkasaray', locale: 'uz'),
        equals('Yakkasaray tumani'),
      );
      expect(
        engine.formatDistrictTitle('Chilanzar', locale: 'ru'),
        equals('Chilanzar район'),
      );

      expect(
        engine.formatCuratorRankLabel(1, locale: 'en'),
        equals('👑 Champion Crown'),
      );
      expect(
        engine.formatCuratorRankLabel(2, locale: 'uz'),
        equals('🥈 Kumush Shon-Sharaf'),
      );
      expect(
        engine.formatCuratorRankLabel(3, locale: 'ru'),
        equals('🥉 Бронзовый Лавр'),
      );
      expect(
        engine.formatCuratorRankLabel(5, locale: 'en'),
        equals('#5'),
      );
    });

    test('serializes and deserializes DistrictCuratorStanding correctly', () {
      const standing = DistrictCuratorStanding(
        userId: 'u-55',
        username: 'aziza_c',
        fullName: 'Aziza Tursunova',
        avatarUrl: 'https://images.unsplash.com/photo-1.jpg',
        rank: 1,
        district: 'Yunusabad',
        seasonXp: 620,
        placesCount: 8,
        crownsCount: 2,
        gapToLeaderXp: 0,
        gapToNextRankXp: 0,
      );

      final json = standing.toJson();
      final parsed = DistrictCuratorStanding.fromJson(json);

      expect(parsed.userId, equals('u-55'));
      expect(parsed.username, equals('aziza_c'));
      expect(parsed.fullName, equals('Aziza Tursunova'));
      expect(parsed.rank, equals(1));
      expect(parsed.crownsCount, equals(2));
      expect(parsed.seasonXp, equals(620));
      expect(parsed.initials, equals('AT'));
    });

    test('Riverpod provider initializes DistrictCrownLeaderboardEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(districtCrownLeaderboardEngineProvider);
      expect(service, isA<DistrictCrownLeaderboardEngine>());
    });
  });
}
