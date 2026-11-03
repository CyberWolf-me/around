import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_trophy_engine.dart';
import 'package:around_app/data/repositories/season_trophy_repository.dart';

void main() {
  group('P28-04: Season Trophy SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00019 exists and defines schema, RLS, and claim RPC', () {
      final migrationFile = File('supabase/migrations/00019_curator_seasons_and_trophy_wall.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00019 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema checks
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.seasonal_trophies'));
      expect(content, contains('user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE'));
      expect(content, contains('season_id TEXT NOT NULL'));
      expect(content, contains('trophy_tier TEXT NOT NULL'));
      expect(content, contains('CONSTRAINT unique_user_season_trophy UNIQUE(user_id, season_id)'));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_seasonal_trophies_user'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_seasonal_trophies_season'));

      // RLS
      expect(content, contains('ALTER TABLE public.seasonal_trophies ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY seasonal_trophies_read'));
      expect(content, contains('CREATE POLICY seasonal_trophies_insert'));
      expect(content, contains('WITH CHECK (auth.uid() = user_id)'));

      // RPC & Security Invariant Rule C
      expect(content, contains('CREATE OR REPLACE FUNCTION public.claim_seasonal_trophy'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('INSERT INTO public.seasonal_trophies'));
      expect(content, contains('UPDATE public.profiles'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.claim_seasonal_trophy(TEXT, TEXT, TEXT, INTEGER, INTEGER) TO authenticated;'));
    });

    test('SeasonTrophyRepository claims trophy locally when offline or unauthenticated', () async {
      final repo = SeasonTrophyRepository();
      final res = await repo.claimSeasonalTrophy(
        seasonId: '2026-11',
        seasonTitle: 'Autumn in Tashkent',
        tier: CuratorTrophyTier.gold,
        completedChallengesCount: 3,
        xpBonus: 150,
      );

      expect(res['success'], isTrue);
      expect(res['offline'], isTrue);
      expect(res['season_id'], equals('2026-11'));
      expect(res['trophy_tier'], equals('gold'));
      expect(res['xp_awarded'], equals(150));
    });

    test('SeasonTrophyRepository rejects empty seasonId', () async {
      final repo = SeasonTrophyRepository();
      final res = await repo.claimSeasonalTrophy(
        seasonId: '   ',
        seasonTitle: 'Autumn in Tashkent',
        tier: CuratorTrophyTier.silver,
        completedChallengesCount: 2,
      );

      expect(res['success'], isFalse);
      expect(res['error'], contains('Season ID cannot be empty'));
    });

    test('SeasonTrophyRepository handles getClaimedTrophies when offline', () async {
      final repo = SeasonTrophyRepository();
      final trophies = await repo.getClaimedTrophies();

      expect(trophies, isEmpty);
    });

    test('Riverpod provider initializes SeasonTrophyRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(seasonTrophyRepositoryProvider);
      expect(repo, isA<SeasonTrophyRepository>());
    });
  });
}
