import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/data/repositories/district_radio_repository.dart';

void main() {
  group('P43-04: District Radio Channels Schema, RPC & Repository Tests', () {
    test('migration 00034_district_radio_channels.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00034_district_radio_channels.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.district_radio_channels'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.radio_listening_sessions'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.district_radio_channels ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.radio_listening_sessions ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with curated stations
      expect(sql, contains('station-chorsu-fm'));
      expect(sql, contains('CHRS 88.4'));
      expect(sql, contains('station-mirabad-beat'));
      expect(sql, contains('MRBD 94.2'));
      expect(sql, contains('station-yunusabad-rain'));
      expect(sql, contains('station-yakkasaray-breeze'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.tune_into_district_radio'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('immersion_achieved'));
      expect(sql, contains('xp_awarded_now'));
    });

    test('DistrictRadioRepository returns curated channels in offline mode', () async {
      final repository = DistrictRadioRepository();
      final channels = await repository.getRadioChannels();

      expect(channels, isNotEmpty);
      expect(channels.length, equals(4));
      expect(channels.first.callsign, equals('CHRS 88.4'));
      expect(channels.first.frequencyMhz, equals(88.4));
      expect(channels[1].callsign, equals('MRBD 94.2'));
    });

    test('DistrictRadioRepository returns user listening sessions in offline fallback', () async {
      final repository = DistrictRadioRepository();
      final sessions = await repository.getUserListeningSessions();

      expect(sessions, isNotEmpty);
      expect(sessions.containsKey('station-chorsu-fm'), isTrue);
      expect(sessions['station-chorsu-fm'], equals(420));
      expect(sessions['station-mirabad-beat'], equals(650));
    });

    test('DistrictRadioRepository logs listening session and awards XP at immersion threshold', () async {
      final repository = DistrictRadioRepository();

      // Under threshold (< 600s)
      final subThresholdResult = await repository.tuneIntoRadio(
        stationKey: 'station-chorsu-fm',
        durationSeconds: 120,
      );
      expect(subThresholdResult.success, isTrue);
      expect(subThresholdResult.durationSeconds, equals(120));
      expect(subThresholdResult.xpAwardedNow, equals(0));
      expect(subThresholdResult.immersionAchieved, isFalse);

      // Reaching immersion threshold (600s)
      final immersionResult = await repository.tuneIntoRadio(
        stationKey: 'station-chorsu-fm',
        durationSeconds: 600,
      );
      expect(immersionResult.success, isTrue);
      expect(immersionResult.durationSeconds, equals(600));
      expect(immersionResult.xpAwardedNow, equals(25));
      expect(immersionResult.totalXpEarned, equals(25));
      expect(immersionResult.immersionAchieved, isTrue);
    });

    test('Riverpod providers initialize cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(districtRadioRepositoryProvider);
      expect(repo, isNotNull);

      final channelsAsync = await container.read(districtRadioStationsProvider.future);
      expect(channelsAsync.length, equals(4));

      final sessionsAsync = await container.read(userRadioSessionsProvider.future);
      expect(sessionsAsync, isNotEmpty);
    });
  });
}
