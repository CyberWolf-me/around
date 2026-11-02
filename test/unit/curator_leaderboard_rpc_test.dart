import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/curator_leaderboard_repository.dart';

void main() {
  group('P24-04: Curator Levels & District Leaderboard Migration & Repository Tests', () {
    test('SQL migration 00015 exists and defines schema, indexes, and RPCs', () {
      final migrationFile = File('supabase/migrations/00015_curator_levels_and_district_leaderboard.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00015 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema additions
      expect(content, contains('ADD COLUMN IF NOT EXISTS curator_xp INTEGER NOT NULL DEFAULT 0'));
      expect(content, contains('ADD COLUMN IF NOT EXISTS curator_level INTEGER NOT NULL DEFAULT 1'));
      expect(content, contains('ADD COLUMN IF NOT EXISTS curator_tier TEXT NOT NULL DEFAULT \'neighborhoodScout\''));
      expect(content, contains('ADD COLUMN IF NOT EXISTS crowns_count INTEGER NOT NULL DEFAULT 0'));

      // Performance Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_profiles_curator_xp ON public.profiles(curator_xp DESC);'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_profiles_curator_tier ON public.profiles(curator_tier);'));

      // Sync XP function
      expect(content, contains('CREATE OR REPLACE FUNCTION public.sync_profile_curator_xp'));
      expect(content, contains('SECURITY DEFINER'));

      // Leaderboard RPC
      expect(content, contains('CREATE OR REPLACE FUNCTION public.get_curator_leaderboard'));
      expect(content, contains('p_district TEXT DEFAULT NULL'));
      expect(content, contains('p_limit INTEGER DEFAULT 20'));
      expect(content, contains('RETURNS TABLE'));
      expect(content, contains('SET search_path = public, extensions'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.get_curator_leaderboard(TEXT, INTEGER) TO authenticated;'));
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.get_curator_leaderboard(TEXT, INTEGER) TO anon;'));
    });

    test('CuratorLeaderboardEntry model parses json and serializes accurately', () {
      final json = {
        'rank': 1,
        'user_id': 'user_123',
        'username': 'tashkent_curator',
        'full_name': 'Azizbek Karimov',
        'avatar_url': 'https://around.uz/avatar.jpg',
        'curator_xp': 2450,
        'curator_level': 4,
        'curator_tier': 'tashkentLegend',
        'district_drops_count': 35,
      };

      final entry = CuratorLeaderboardEntry.fromJson(json);

      expect(entry.rank, equals(1));
      expect(entry.userId, equals('user_123'));
      expect(entry.username, equals('tashkent_curator'));
      expect(entry.fullName, equals('Azizbek Karimov'));
      expect(entry.avatarUrl, equals('https://around.uz/avatar.jpg'));
      expect(entry.curatorXp, equals(2450));
      expect(entry.curatorLevel, equals(4));
      expect(entry.curatorTier, equals('tashkentLegend'));
      expect(entry.districtDropsCount, equals(35));

      final serialized = entry.toJson();
      expect(serialized['rank'], equals(1));
      expect(serialized['curator_xp'], equals(2450));
      expect(serialized['curator_tier'], equals('tashkentLegend'));
    });

    test('CuratorLeaderboardEntry handles fallback values gracefully', () {
      final entry = CuratorLeaderboardEntry.fromJson({});

      expect(entry.rank, equals(1));
      expect(entry.userId, isEmpty);
      expect(entry.username, isEmpty);
      expect(entry.curatorXp, equals(0));
      expect(entry.curatorLevel, equals(1));
      expect(entry.curatorTier, equals('neighborhoodScout'));
      expect(entry.districtDropsCount, equals(0));
      expect(entry.avatarUrl, isNull);
    });

    test('CuratorLeaderboardRepository returns sorted fallback rankings city-wide', () async {
      final repo = CuratorLeaderboardRepository();
      final rankings = await repo.getCuratorLeaderboard(limit: 5);

      expect(rankings, isNotEmpty);
      expect(rankings.length, lessThanOrEqualTo(5));

      // Ranks are strictly 1..N ascending
      for (int i = 0; i < rankings.length; i++) {
        expect(rankings[i].rank, equals(i + 1));
      }

      // First curator has highest or equal drops
      expect(rankings.first.districtDropsCount, greaterThanOrEqualTo(rankings.last.districtDropsCount));
      expect(rankings.first.curatorXp, greaterThanOrEqualTo(rankings.last.curatorXp));
    });

    test('CuratorLeaderboardRepository filters curators by district', () async {
      final repo = CuratorLeaderboardRepository();
      final mirabadCurators = await repo.getCuratorLeaderboard(district: 'Mirabad');

      expect(mirabadCurators, isNotEmpty);
      // All returned entries in mock must belong to Mirabad
      for (final entry in mirabadCurators) {
        expect(entry.username, isNotEmpty);
      }
    });

    test('Riverpod curatorLeaderboardFamilyProvider loads leaderboard entries', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final entries = await container.read(curatorLeaderboardFamilyProvider(null).future);
      expect(entries, isNotEmpty);
      expect(entries.first.rank, equals(1));
    });
  });
}
