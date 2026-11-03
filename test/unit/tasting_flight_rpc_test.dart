import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/tasting_flight_repository.dart';

void main() {
  group('P42-04: Tasting Flights Schema, RPC & Repository Tests', () {
    test('migration 00033_artisan_tasting_flights.sql is syntactically hardened', () {
      final migrationFile = File('supabase/migrations/00033_artisan_tasting_flights.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.tasting_flights'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.tasting_flight_stops'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_tasting_logs'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_tasting_certificates'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.tasting_flights ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.tasting_flight_stops ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_tasting_logs ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.user_tasting_certificates ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.record_tasting_flight_cupping'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('certificate_awarded_now'));
    });

    test('TastingFlightRepository returns default flights in offline fallback', () async {
      final repository = TastingFlightRepository();
      final flights = await repository.getFlights();

      expect(flights, isNotEmpty);
      expect(flights.length, greaterThanOrEqualTo(2));
      expect(flights.first.slug, equals('tashkent-specialty-coffee-flight'));
      expect(flights.first.stops.length, equals(3));
    });

    test('TastingFlightRepository returns cupping logs and records offline cupping', () async {
      final repository = TastingFlightRepository();

      final logs = await repository.getUserTastingLogs();
      expect(logs, isNotEmpty);
      expect(logs.containsKey('breadly-cupping'), isTrue);
      expect(logs['breadly-cupping']!.rating, equals(9.3));

      final result = await repository.recordCupping(
        flightSlug: 'tashkent-specialty-coffee-flight',
        stopKey: 'breadly-cupping',
        rating: 9.5,
        flavorNotes: ['Bergamot', 'Jasmine'],
      );
      expect(result.success, isTrue);
      expect(result.flightSlug, equals('tashkent-specialty-coffee-flight'));
      expect(result.stopKey, equals('breadly-cupping'));
      expect(result.averageScore, equals(9.5));
    });

    test('TastingCuppingResult parses map responses cleanly', () {
      final map = {
        'success': true,
        'flight_slug': 'tashkent-specialty-coffee-flight',
        'stop_key': 'bb-anaerobic',
        'completed_count': 3,
        'required_stops': 3,
        'average_score': 9.1,
        'is_completed': true,
        'certificate_awarded_now': true,
        'curator_title': 'Specialty Coffee Cupping Certificate',
        'xp_awarded': 50,
      };

      final parsed = TastingCuppingResult.fromMap(map);
      expect(parsed.success, isTrue);
      expect(parsed.isCompleted, isTrue);
      expect(parsed.certificateAwardedNow, isTrue);
      expect(parsed.averageScore, equals(9.1));
      expect(parsed.xpAwarded, equals(50));
      expect(parsed.curatorTitle, equals('Specialty Coffee Cupping Certificate'));
    });

    test('Riverpod providers initialize repository and future providers cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(tastingFlightRepositoryProvider);
      expect(repo, isA<TastingFlightRepository>());

      final flights = await container.read(tastingFlightsProvider.future);
      expect(flights.length, greaterThanOrEqualTo(2));

      final logs = await container.read(userTastingLogsProvider.future);
      expect(logs, isNotEmpty);
    });
  });
}
