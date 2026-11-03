import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/puppet_theater_repository.dart';

void main() {
  group('P49-04: Puppet Theater Schema, RPC & Repository Tests', () {
    test('migration 00040_puppet_theater.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00040_puppet_theater.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.puppet_theaters'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_puppet_tickets'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.puppet_theaters ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_puppet_tickets ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with canonical venues
      expect(sql, contains('theater-state-puppet-kosmonavtlar'));
      expect(sql, contains('atelier-old-city-chodir'));
      expect(sql, contains('studio-chilonzor-marionette'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.reserve_puppet_theater_ticket'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('xp_awarded'));
      expect(sql, contains('available_seats'));
    });

    test('PuppetTheaterRepository returns curated stages in offline fallback', () async {
      final repository = PuppetTheaterRepository();
      final stages = await repository.getStages();

      expect(stages, isNotEmpty);
      expect(stages.length, equals(3));

      final stateTheater = stages.firstWhere((s) => s.id == 'theater-state-puppet-kosmonavtlar');
      expect(stateTheater.name, contains('State Puppet'));
      expect(stateTheater.district, contains('Yakkasaray'));
      expect(stateTheater.chiefMaster, contains('Usto Mansur'));
      expect(stateTheater.repertoire, isNotEmpty);
    });

    test('PuppetTheaterRepository returns user reservations in offline fallback', () async {
      final repository = PuppetTheaterRepository();
      final reservations = await repository.getUserReservations();

      expect(reservations, isNotEmpty);
      expect(reservations.first.stageId, equals('theater-state-puppet-kosmonavtlar'));
      expect(reservations.first.performanceId, equals('show-polvon-kachal-wedding'));
      expect(reservations.first.seatsCount, equals(2));
      expect(reservations.first.xpEarned, equals(35));
    });

    test('PuppetTheaterRepository reserves ticket and awards +35 XP in offline fallback', () async {
      final repository = PuppetTheaterRepository();
      final result = await repository.reserveTicket(
        theaterSlug: 'theater-state-puppet-kosmonavtlar',
        performanceId: 'show-simurgh-legend',
        seatsCount: 3,
      );

      expect(result.success, isTrue);
      expect(result.theaterSlug, equals('theater-state-puppet-kosmonavtlar'));
      expect(result.performanceId, equals('show-simurgh-legend'));
      expect(result.seatsCount, equals(3));
      expect(result.xpAwarded, equals(35));
      expect(result.remainingSeats, equals(45)); // 48 - 3
      expect(result.errorMessage, isNull);

      // Unknown theater failure
      final invalidResult = await repository.reserveTicket(
        theaterSlug: 'unknown_theater_slug',
        performanceId: 'show-simurgh-legend',
        seatsCount: 1,
      );
      expect(invalidResult.success, isFalse);
      expect(invalidResult.errorMessage, contains('not found'));
    });

    test('PuppetTicketResult deserializes map payload cleanly', () {
      final map = {
        'success': true,
        'theater_slug': 'studio-chilonzor-marionette',
        'performance_id': 'show-tahir-zuhra',
        'seats_count': 2,
        'xp_awarded': 35,
        'remaining_seats': 22,
      };

      final result = PuppetTicketResult.fromMap(map);
      expect(result.success, isTrue);
      expect(result.theaterSlug, equals('studio-chilonzor-marionette'));
      expect(result.performanceId, equals('show-tahir-zuhra'));
      expect(result.seatsCount, equals(2));
      expect(result.xpAwarded, equals(35));
      expect(result.remainingSeats, equals(22));
    });

    test('Riverpod providers initialize in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(puppetTheaterRepositoryProvider);
      expect(repo, isNotNull);

      final stagesAsync = container.read(puppetStagesProvider);
      expect(stagesAsync, isNotNull);

      final reservationsAsync = container.read(userPuppetTicketsProvider);
      expect(reservationsAsync, isNotNull);
    });
  });
}
