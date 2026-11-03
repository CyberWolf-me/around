import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/tandoor_bakery_engine.dart';
import 'package:around_app/data/repositories/tandoor_bakery_repository.dart';

void main() {
  group('P48-04: Tandoor Bakery Schema, RPC & Repository Tests', () {
    test('migration 00039_tandoor_bakeries.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00039_tandoor_bakeries.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.tandoor_bakeries'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_bread_reservations'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.tandoor_bakeries ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_bread_reservations ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with canonical bakeries
      expect(sql, contains('bakery-chorsu-kattabog'));
      expect(sql, contains('bakery-chigatoy-shirmoy'));
      expect(sql, contains('bakery-keles-jizzali'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.reserve_fresh_bread_batch'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('xp_awarded'));
      expect(sql, contains('current_batch_hot_loaves'));
    });

    test('TandoorBakeryRepository returns curated bakeries in offline fallback', () async {
      final repository = TandoorBakeryRepository();
      final bakeries = await repository.getBakeries();

      expect(bakeries, isNotEmpty);
      expect(bakeries.length, equals(3));

      final chorsu = bakeries.firstWhere((b) => b.id == 'bakery-chorsu-kattabog');
      expect(chorsu.name, contains('Chorsu Kattabog'));
      expect(chorsu.headBaker, contains('Novvoyboshi Usto Shuhrat'));
      expect(chorsu.currentBatchHotLoaves, equals(32));
      expect(chorsu.signatureBreads, contains(BreadVariety.obiNon));
    });

    test('TandoorBakeryRepository returns user reservations in offline fallback', () async {
      final repository = TandoorBakeryRepository();
      final reservations = await repository.getUserReservations();

      expect(reservations, isNotEmpty);
      expect(reservations.first.bakeryId, equals('bakery-chorsu-kattabog'));
      expect(reservations.first.variety, equals(BreadVariety.obiNon));
      expect(reservations.first.loavesCount, equals(2));
      expect(reservations.first.xpEarned, equals(30));
    });

    test('TandoorBakeryRepository reserves fresh bread batch and awards +30 XP in offline fallback', () async {
      final repository = TandoorBakeryRepository();
      final result = await repository.reserveBreadBatch(
        bakerySlug: 'bakery-chorsu-kattabog',
        variety: BreadVariety.patir,
        loavesCount: 3,
      );

      expect(result.success, isTrue);
      expect(result.bakerySlug, equals('bakery-chorsu-kattabog'));
      expect(result.varietyId, equals('patir'));
      expect(result.loavesCount, equals(3));
      expect(result.xpAwarded, equals(30));
      expect(result.remainingHotLoaves, equals(29)); // 32 - 3
      expect(result.errorMessage, isNull);

      // Unknown bakery failure
      final invalidResult = await repository.reserveBreadBatch(
        bakerySlug: 'unknown_bakery_slug',
        variety: BreadVariety.shirmoy,
        loavesCount: 2,
      );
      expect(invalidResult.success, isFalse);
      expect(invalidResult.errorMessage, contains('not found'));
    });

    test('BreadReservationResult deserializes map payload cleanly', () {
      final map = {
        'success': true,
        'bakery_slug': 'bakery-chigatoy-shirmoy',
        'variety_id': 'shirmoy',
        'loaves_count': 4,
        'xp_awarded': 30,
        'remaining_hot_loaves': 14,
      };

      final result = BreadReservationResult.fromMap(map);
      expect(result.success, isTrue);
      expect(result.bakerySlug, equals('bakery-chigatoy-shirmoy'));
      expect(result.varietyId, equals('shirmoy'));
      expect(result.loavesCount, equals(4));
      expect(result.xpAwarded, equals(30));
      expect(result.remainingHotLoaves, equals(14));
    });

    test('Riverpod providers initialize in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(tandoorBakeryRepositoryProvider);
      expect(repo, isNotNull);

      final bakeriesAsync = container.read(tandoorBakeriesProvider);
      expect(bakeriesAsync, isNotNull);

      final reservationsAsync = container.read(userBreadReservationsProvider);
      expect(reservationsAsync, isNotNull);
    });
  });
}
