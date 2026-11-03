import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/craft_workshop_repository.dart';

void main() {
  group('P44-04: Craft Workshop Schema, RPC & Repository Tests', () {
    test('migration 00035_craft_workshops.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00035_craft_workshops.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.craft_workshops'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.workshop_masterclasses'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_workshop_reservations'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.craft_workshops ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.workshop_masterclasses ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_workshop_reservations ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with curated studios
      expect(sql, contains('studio-rishtan-ceramics'));
      expect(sql, contains('Rishtan Blue Glaze Pottery House'));
      expect(sql, contains('studio-chorsu-woodcarving'));
      expect(sql, contains('studio-yakkasaray-silk'));
      expect(sql, contains('studio-mirabad-copper'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.reserve_craft_masterclass'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('seats_remaining'));
    });

    test('CraftWorkshopRepository returns curated studios in offline fallback', () async {
      final repository = CraftWorkshopRepository();
      final studios = await repository.getStudios();

      expect(studios, isNotEmpty);
      expect(studios.length, equals(4));
      expect(studios.first.id, equals('studio-rishtan-ceramics'));
      expect(studios.first.craftDiscipline, equals('Ceramics'));
      expect(studios.first.masterclasses.length, equals(2));
    });

    test('CraftWorkshopRepository returns user reservations in offline fallback', () async {
      final repository = CraftWorkshopRepository();
      final reservations = await repository.getUserReservations();

      expect(reservations, isNotEmpty);
      expect(reservations.containsKey('class-kickwheel-pottery'), isTrue);
      expect(reservations['class-kickwheel-pottery'], equals('confirmed'));
    });

    test('CraftWorkshopRepository reserves masterclass and awards +40 XP', () async {
      final repository = CraftWorkshopRepository();
      final result = await repository.reserveMasterclass(
        studioSlug: 'studio-rishtan-ceramics',
        classKey: 'class-kickwheel-pottery',
      );

      expect(result.success, isTrue);
      expect(result.reservationStatus, equals('confirmed'));
      expect(result.xpAwarded, equals(40));
      expect(result.seatsRemaining, equals(1));
    });

    test('Riverpod providers initialize cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(craftWorkshopRepositoryProvider);
      expect(repo, isNotNull);

      final studiosAsync = await container.read(craftStudiosProvider.future);
      expect(studiosAsync.length, equals(4));

      final reservationsAsync = await container.read(userWorkshopReservationsProvider.future);
      expect(reservationsAsync, isNotEmpty);
    });
  });
}
