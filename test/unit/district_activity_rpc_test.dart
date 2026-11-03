import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_activity_ticker_engine.dart';
import 'package:around_app/data/repositories/district_activity_repository.dart';

void main() {
  group('P34-04: District Activity Ticker RPC & Migration Tests', () {
    test('migration 00025_district_activity_ticker.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00025_district_activity_ticker.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_district_activity_ticker'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_district_activity_ticker(TEXT, INTEGER) TO authenticated, anon;'));
      expect(sql, contains('hide_visits_history, false) = false'));
      expect(sql, contains('po.privacy = \'public\''));
    });

    test('DistrictActivityRepository returns robust offline seed events when Supabase is uninitialized', () async {
      final repo = DistrictActivityRepository();
      final allEvents = await repo.getDistrictActivityEvents();

      expect(allEvents, isNotEmpty);
      expect(allEvents.length, greaterThanOrEqualTo(4));

      // Verify event structure
      final dropEvent = allEvents.firstWhere(
        (e) => e.type == DistrictActivityType.dropCreated,
      );
      expect(dropEvent.username, equals('@kamila_tashkent'));
      expect(dropEvent.placeName, contains('Breadly'));
      expect(dropEvent.district, equals('Mirabad'));
    });

    test('DistrictActivityRepository filters by district in offline fallback', () async {
      final repo = DistrictActivityRepository();

      final mirabadEvents = await repo.getDistrictActivityEvents(district: 'Mirabad');
      expect(mirabadEvents.length, equals(2));
      for (final ev in mirabadEvents) {
        expect(ev.district.toLowerCase(), equals('mirabad'));
      }

      final chilanzarEvents = await repo.getDistrictActivityEvents(district: 'Chilanzar');
      expect(chilanzarEvents.length, equals(1));
      expect(chilanzarEvents.first.type, equals(DistrictActivityType.routeCompleted));
    });

    test('Riverpod providers initialize DistrictActivityRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(districtActivityRepositoryProvider);
      expect(repo, isA<DistrictActivityRepository>());

      final eventsAsync = await container.read(districtActivityEventsProvider('Mirabad').future);
      expect(eventsAsync, isA<List<DistrictActivityEvent>>());
      expect(eventsAsync, isNotEmpty);
    });
  });
}
