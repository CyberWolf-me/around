import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_accolades_engine.dart';
import 'package:around_app/data/repositories/curator_accolades_repository.dart';

void main() {
  group('P31-04: Curator Accolades SQL Migration & RPC Repository Tests', () {
    test('SQL migration 00022 exists and defines get_curator_accolades aggregation RPC', () {
      final migrationFile = File('supabase/migrations/00022_curator_accolades_aggregation.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00022 must exist');

      final content = migrationFile.readAsStringSync();

      // RPC signature & security definition
      expect(content, contains('CREATE OR REPLACE FUNCTION public.get_curator_accolades(p_user_id UUID DEFAULT NULL)'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_target_user := COALESCE(p_user_id, auth.uid());'));
      expect(content, contains('IF v_target_user IS NULL THEN'));

      // Queries & Aggregation
      expect(content, contains('COALESCE(crowns_count, 0)'));
      expect(content, contains('FROM public.profiles'));
      expect(content, contains('FROM public.seasonal_trophies'));
      expect(content, contains('FROM public.season_hall_of_fame'));
      expect(content, contains('jsonb_agg('));

      // Permissions
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.get_curator_accolades(UUID) TO anon, authenticated;'));
    });

    test('CuratorAccoladesRepository returns clean offline fallback when uninitialized', () async {
      final repo = CuratorAccoladesRepository();
      final accolades = await repo.getCuratorAccolades(
        userId: 'test_user_offline',
        username: 'test_scout',
      );

      expect(accolades.userId, equals('test_user_offline'));
      expect(accolades.username, equals('test_scout'));
      expect(accolades.crownsCount, equals(0));
      expect(accolades.trophies, isEmpty);
      expect(accolades.laurels, isEmpty);
      expect(accolades.masteryTier, equals(CuratorMasteryTier.scout));
    });

    test('Riverpod provider initializes CuratorAccoladesRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(curatorAccoladesRepositoryProvider);
      expect(repo, isA<CuratorAccoladesRepository>());
    });
  });
}
