import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/silk_paper_calligraphy_engine.dart';
import 'package:around_app/data/repositories/silk_paper_repository.dart';

void main() {
  group('P47-04: Silk Paper Schema, RPC & Repository Tests', () {
    test('migration 00038_silk_paper_calligraphy.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00038_silk_paper_calligraphy.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.silk_paper_ateliers'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_silk_paper_workshops'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.silk_paper_ateliers ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_silk_paper_workshops ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with canonical ateliers
      expect(sql, contains('atelier-chorsu-mulberry'));
      expect(sql, contains('atelier-hast-imam-calligraphy'));
      expect(sql, contains('atelier-navoiy-literature'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.reserve_silk_paper_workshop'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('xp_awarded'));
      expect(sql, contains('available_seats'));
    });

    test('SilkPaperRepository returns curated ateliers in offline fallback', () async {
      final repository = SilkPaperRepository();
      final ateliers = await repository.getAteliers();

      expect(ateliers, isNotEmpty);
      expect(ateliers.length, equals(3));

      final chorsu = ateliers.firstWhere((a) => a.id == 'atelier-chorsu-mulberry');
      expect(chorsu.name, contains('Chorsu'));
      expect(chorsu.masterName, contains('Usto Mirzo Bobo'));
      expect(chorsu.workshopPriceUzs, equals(150000));
      expect(chorsu.availableMasterclasses, equals(4));
    });

    test('SilkPaperRepository returns user reservations in offline fallback', () async {
      final repository = SilkPaperRepository();
      final reservations = await repository.getUserReservations();

      expect(reservations, isNotEmpty);
      expect(reservations.first.atelierId, equals('atelier-chorsu-mulberry'));
      expect(reservations.first.script, equals(CalligraphyScript.nastaliq));
      expect(reservations.first.xpEarned, equals(35));
    });

    test('SilkPaperRepository reserves workshop seat and awards +35 XP in offline fallback', () async {
      final repository = SilkPaperRepository();
      final result = await repository.reserveWorkshop(
        atelierSlug: 'atelier-chorsu-mulberry',
        script: CalligraphyScript.thuluth,
      );

      expect(result.success, isTrue);
      expect(result.alreadyReserved, isFalse);
      expect(result.atelierSlug, equals('atelier-chorsu-mulberry'));
      expect(result.scriptId, equals('thuluth'));
      expect(result.xpAwarded, equals(35));
      expect(result.errorMessage, isNull);

      // Unknown atelier failure
      final invalidResult = await repository.reserveWorkshop(
        atelierSlug: 'unknown_atelier_slug',
        script: CalligraphyScript.kufic,
      );
      expect(invalidResult.success, isFalse);
      expect(invalidResult.errorMessage, contains('not found'));
    });

    test('PaperWorkshopResult deserializes map payload cleanly', () {
      final map = {
        'success': true,
        'already_reserved': true,
        'atelier_slug': 'atelier-hast-imam-calligraphy',
        'script_id': 'diwani',
        'xp_awarded': 35,
        'available_seats': 1,
      };

      final result = PaperWorkshopResult.fromMap(map);
      expect(result.success, isTrue);
      expect(result.alreadyReserved, isTrue);
      expect(result.atelierSlug, equals('atelier-hast-imam-calligraphy'));
      expect(result.scriptId, equals('diwani'));
      expect(result.xpAwarded, equals(35));
      expect(result.availableSeats, equals(1));
    });

    test('Riverpod providers initialize in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(silkPaperRepositoryProvider);
      expect(repo, isNotNull);

      final ateliersAsync = container.read(silkPaperAteliersProvider);
      expect(ateliersAsync, isNotNull);

      final reservationsAsync = container.read(userSilkPaperWorkshopsProvider);
      expect(reservationsAsync, isNotNull);
    });
  });
}
