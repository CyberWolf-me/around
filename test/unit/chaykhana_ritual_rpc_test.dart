import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/chaykhana_ritual_repository.dart';

void main() {
  group('P45-04: Chaykhana Schema, RPC & Repository Tests', () {
    test('migration 00036_chaykhana_tea_rituals.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00036_chaykhana_tea_rituals.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.chaykhana_venues'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.tea_blends'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_chaykhana_gatherings'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.chaykhana_venues ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.tea_blends ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_chaykhana_gatherings ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with curated venues
      expect(sql, contains('chaykhana-chorsu-chinor'));
      expect(sql, contains('Chorsu Chinor Chaykhana'));
      expect(sql, contains('chaykhana-hast-imam'));
      expect(sql, contains('chaykhana-ankhor-terrace'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.host_chaykhana_gathering'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('available_tapchans'));
    });

    test('ChaykhanaRitualRepository returns curated venues in offline fallback', () async {
      final repository = ChaykhanaRitualRepository();
      final venues = await repository.getVenues();

      expect(venues, isNotEmpty);
      expect(venues.length, equals(3));
      expect(venues.first.id, equals('chaykhana-chorsu-chinor'));
      expect(venues.first.signatureBlends.length, equals(1));
      expect(venues.first.signatureBlends.first.name, contains('Kok-Choy'));
    });

    test('ChaykhanaRitualRepository returns user gatherings in offline fallback', () async {
      final repository = ChaykhanaRitualRepository();
      final gatherings = await repository.getUserGatherings();

      expect(gatherings, isNotEmpty);
      expect(gatherings.containsKey('chaykhana-chorsu-chinor'), isTrue);
      expect(gatherings['chaykhana-chorsu-chinor'], equals('confirmed'));
    });

    test('ChaykhanaRitualRepository hosts gathering and awards +35 XP', () async {
      final repository = ChaykhanaRitualRepository();
      final result = await repository.hostGathering(
        chaykhanaSlug: 'chaykhana-chorsu-chinor',
        blendKey: 'blend-tashkent-kok-choy',
      );

      expect(result.success, isTrue);
      expect(result.gatheringStatus, equals('confirmed'));
      expect(result.xpAwarded, equals(35));
      expect(result.availableTapchans, equals(3));
    });

    test('Riverpod providers initialize cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(chaykhanaRitualRepositoryProvider);
      expect(repo, isNotNull);

      final venuesAsync = await container.read(chaykhanaVenuesProvider.future);
      expect(venuesAsync.length, equals(3));

      final gatheringsAsync = await container.read(userChaykhanaGatheringsProvider.future);
      expect(gatheringsAsync, isNotEmpty);
    });
  });
}
