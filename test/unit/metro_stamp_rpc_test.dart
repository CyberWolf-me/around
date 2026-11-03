import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/metro_stamp_engine.dart';
import 'package:around_app/data/repositories/metro_stamp_repository.dart';

void main() {
  group('P39-04: Metro Station Stamps RPC & Repository Tests', () {
    test('migration 00030_metro_station_stamps.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00030_metro_station_stamps.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.user_metro_stamps'));
      expect(sql, contains('ALTER TABLE public.user_metro_stamps ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.claim_metro_station_stamp'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.claim_metro_station_stamp(TEXT, UUID) TO authenticated;'));
      expect(sql, contains('unique_user_station_stamp UNIQUE (user_id, station_id)'));
      expect(sql, contains('hide_visits_history, false) = false'));
      expect(sql, contains('auth.uid() = user_id'));
    });

    test('MetroStampRepository returns rich offline seeds when Supabase is uninitialized', () async {
      final repo = MetroStampRepository();
      final stamps = await repo.getUserStamps();

      expect(stamps, isNotEmpty);
      expect(stamps.length, equals(2));

      final kosmonavtlar = stamps.firstWhere((s) => s.stationId == 'kosmonavtlar');
      expect(kosmonavtlar.stationName, equals('Kosmonavtlar'));
      expect(kosmonavtlar.line, equals(MetroLine.uzbekistan));
      expect(kosmonavtlar.stampMotif, equals('Cosmos Blue Medallion'));
    });

    test('MetroStampRepository claims stamp cleanly in offline mode', () async {
      final repo = MetroStampRepository();

      final res = await repo.claimStamp('mustaqillik_maydoni');
      expect(res['success'], isTrue);
      expect(res['station_id'], equals('mustaqillik_maydoni'));
      expect(res['xp_awarded'], equals(25));
    });

    test('Riverpod providers initialize MetroStampRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(metroStampRepositoryProvider);
      expect(repo, isA<MetroStampRepository>());

      final stampsAsync = await container.read(userMetroStampsProvider.future);
      expect(stampsAsync, isA<List<MetroStamp>>());
      expect(stampsAsync.length, equals(2));
    });
  });
}
