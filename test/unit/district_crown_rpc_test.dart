import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_crown_leaderboard_engine.dart';
import 'package:around_app/data/repositories/district_crown_repository.dart';

void main() {
  group('P33-04: District Crown Standings RPC & Migration Tests', () {
    test('migration 00024_district_crown_standings.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00024_district_crown_standings.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_district_crown_standings'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_district_crown_standings(TEXT, TEXT) TO authenticated, anon;'));
      expect(sql, contains('p_district TEXT'));
      expect(sql, contains('total_curators_count'));
    });

    test('DistrictCrownRepository returns robust offline podium when Supabase is uninitialized', () async {
      final repo = DistrictCrownRepository();
      final podium = await repo.getDistrictCrownPodium(
        district: 'Mirabad',
        seasonId: '2026-11',
      );

      expect(podium.district, equals('Mirabad'));
      expect(podium.seasonId, equals('2026-11'));
      expect(podium.totalCuratorsCount, greaterThanOrEqualTo(3));

      // Champion
      expect(podium.champion, isNotNull);
      expect(podium.champion!.rank, equals(1));
      expect(podium.champion!.isReigningChampion, isTrue);
      expect(podium.champion!.crownsCount, greaterThan(0));

      // Silver
      expect(podium.silver, isNotNull);
      expect(podium.silver!.rank, equals(2));
      expect(podium.silver!.isPodium, isTrue);

      // Bronze
      expect(podium.bronze, isNotNull);
      expect(podium.bronze!.rank, equals(3));
      expect(podium.bronze!.isPodium, isTrue);

      // Runners up
      expect(podium.runnersUp, isNotEmpty);
      expect(podium.runnersUp[0].rank, equals(4));
    });

    test('DistrictCrownRepository defaults to current year-month seasonId when omitted', () async {
      final repo = DistrictCrownRepository();
      final podium = await repo.getDistrictCrownPodium(district: 'Yakkasaray');

      final now = DateTime.now();
      final expectedSeasonPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      expect(podium.seasonId, equals(expectedSeasonPrefix));
      expect(podium.district, equals('Yakkasaray'));
    });

    test('Riverpod providers initialize DistrictCrownRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(districtCrownRepositoryProvider);
      expect(repo, isA<DistrictCrownRepository>());

      final podiumAsync = await container.read(districtCrownPodiumProvider('Chilanzar').future);
      expect(podiumAsync, isA<DistrictCrownPodium>());
      expect(podiumAsync.district, equals('Chilanzar'));
      expect(podiumAsync.champion, isNotNull);
    });
  });
}
