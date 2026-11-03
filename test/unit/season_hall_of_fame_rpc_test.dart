import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_ceremony_engine.dart';
import 'package:around_app/data/repositories/season_hall_of_fame_repository.dart';

void main() {
  group('P30-04: Season Hall of Fame SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00021 exists and defines schema, RLS, and archive RPC', () {
      final migrationFile = File('supabase/migrations/00021_seasonal_snapshots_and_hall_of_fame.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00021 must exist');

      final content = migrationFile.readAsStringSync();

      // Schema checks
      expect(content, contains('CREATE TABLE IF NOT EXISTS public.season_hall_of_fame'));
      expect(content, contains('season_id TEXT NOT NULL'));
      expect(content, contains('user_id UUID NOT NULL REFERENCES public.profiles(id)'));
      expect(content, contains('district TEXT NOT NULL'));
      expect(content, contains('rank INTEGER NOT NULL'));
      expect(content, contains('laurel TEXT NOT NULL'));
      expect(content, contains('CONSTRAINT unique_season_district_user UNIQUE(season_id, district, user_id)'));

      // Indexes
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_hall_of_fame_season'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_hall_of_fame_district'));
      expect(content, contains('CREATE INDEX IF NOT EXISTS idx_hall_of_fame_user'));

      // RLS
      expect(content, contains('ALTER TABLE public.season_hall_of_fame ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('CREATE POLICY season_hall_of_fame_read'));
      expect(content, contains('CREATE POLICY season_hall_of_fame_insert'));
      expect(content, contains('WITH CHECK (auth.uid() = user_id)'));

      // RPC & Security Invariant Rule C
      expect(content, contains('CREATE OR REPLACE FUNCTION public.archive_season_standing'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('INSERT INTO public.season_hall_of_fame'));
      expect(content, contains('crowns_count = COALESCE(crowns_count, 0) + 1'));

      // Grants
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.archive_season_standing(TEXT, TEXT, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;'));
    });

    test('SeasonHallOfFameRepository archives standing locally when offline or unauthenticated', () async {
      final repo = SeasonHallOfFameRepository();
      final res = await repo.archiveSeasonStanding(
        seasonId: '2026-11',
        district: 'Mirabad',
        rank: 1,
        seasonXp: 450,
        placesCount: 9,
        laurel: CuratorLaurelTier.champion,
      );

      expect(res['success'], isTrue);
      expect(res['offline'], isTrue);
      expect(res['season_id'], equals('2026-11'));
      expect(res['district'], equals('Mirabad'));
      expect(res['rank'], equals(1));
      expect(res['season_xp'], equals(450));
      expect(res['places_count'], equals(9));
      expect(res['laurel'], equals('champion'));
    });

    test('SeasonHallOfFameRepository rejects empty seasonId', () async {
      final repo = SeasonHallOfFameRepository();
      final res = await repo.archiveSeasonStanding(
        seasonId: '   ',
        district: 'Yakkasaray',
        rank: 2,
        seasonXp: 280,
      );

      expect(res['success'], isFalse);
      expect(res['error'], contains('Season ID cannot be empty'));
    });

    test('SeasonHallOfFameRepository handles getHallOfFameEntries when uninitialized', () async {
      final repo = SeasonHallOfFameRepository();
      final entries = await repo.getHallOfFameEntries(district: 'Mirabad');

      expect(entries, isEmpty);
    });

    test('Riverpod provider initializes SeasonHallOfFameRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(seasonHallOfFameRepositoryProvider);
      expect(repo, isA<SeasonHallOfFameRepository>());
    });
  });
}
