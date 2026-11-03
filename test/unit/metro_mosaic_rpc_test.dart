import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/metro_mosaic_engine.dart';
import 'package:around_app/data/repositories/metro_mosaic_repository.dart';

void main() {
  group('P46-04: Metro Mosaic Schema, RPC & Repository Tests', () {
    test('migration 00037_metro_mosaic_stamps.sql is syntactically hardened and secure', () {
      final migrationFile = File('supabase/migrations/00037_metro_mosaic_stamps.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration file must exist');

      final sql = migrationFile.readAsStringSync();

      // Schema verification
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.metro_stations'));
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.metro_mosaic_stamps'));

      // Row-Level Security
      expect(sql, contains('ALTER TABLE public.metro_stations ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('ALTER TABLE public.metro_mosaic_stamps ENABLE ROW LEVEL SECURITY;'));

      // Dual-layer privacy invariant (Rule C & Security mandate)
      expect(sql, contains('hide_visits_history'));
      expect(sql, contains('auth.uid() = user_id'));

      // Seed data with canonical stations
      expect(sql, contains('kosmonavtlar'));
      expect(sql, contains('alisher_navoiy'));
      expect(sql, contains('pakhtakor'));
      expect(sql, contains('mustaqillik_maydoni'));
      expect(sql, contains('bodomzor'));
      expect(sql, contains('beruniy'));

      // RPC signature & security definer
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.collect_metro_mosaic_stamp'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('auth.uid()'));
      expect(sql, contains('points_awarded'));
    });

    test('MetroMosaicRepository returns curated stations in offline fallback', () async {
      final repository = MetroMosaicRepository();
      final stations = await repository.getStations();

      expect(stations, isNotEmpty);
      expect(stations.length, greaterThanOrEqualTo(6));

      final kosmonavtlar = stations.firstWhere((s) => s.id == 'kosmonavtlar');
      expect(kosmonavtlar.nameEn, equals('Cosmonauts'));
      expect(kosmonavtlar.architect, equals('S. Sultonov'));
      expect(kosmonavtlar.mosaicArtist, equals('Arnold Gan'));
      expect(kosmonavtlar.stampPoints, equals(30));
    });

    test('MetroMosaicRepository filters stations by MetroLine', () async {
      final repository = MetroMosaicRepository();
      final chilanzarStations = await repository.getStations(line: MetroLine.chilanzar);

      expect(chilanzarStations, isNotEmpty);
      expect(chilanzarStations.every((s) => s.line == MetroLine.chilanzar), isTrue);
      expect(chilanzarStations.map((s) => s.id), contains('pakhtakor'));
    });

    test('MetroMosaicRepository collects stamp and awards +30 XP in offline fallback', () async {
      final repository = MetroMosaicRepository();
      final result = await repository.collectStationStamp(
        stationKey: 'alisher_navoiy',
        notes: 'Magnificent blue cupolas',
      );

      expect(result.success, isTrue);
      expect(result.alreadyStamped, isFalse);
      expect(result.stationKey, equals('alisher_navoiy'));
      expect(result.pointsAwarded, equals(30));
      expect(result.errorMessage, isNull);

      // Unknown station failure
      final invalidResult = await repository.collectStationStamp(
        stationKey: 'non_existent_station',
      );
      expect(invalidResult.success, isFalse);
      expect(invalidResult.errorMessage, contains('not found'));
    });

    test('MetroStampResult deserializes map payload cleanly', () {
      final map = {
        'success': true,
        'already_stamped': true,
        'station_key': 'pakhtakor',
        'points_awarded': 30,
        'created_at': '2026-11-03T18:00:00.000Z',
      };

      final result = MetroStampResult.fromMap(map);
      expect(result.success, isTrue);
      expect(result.alreadyStamped, isTrue);
      expect(result.stationKey, equals('pakhtakor'));
      expect(result.pointsAwarded, equals(30));
      expect(result.createdAt, isNotNull);
    });

    test('Riverpod providers initialize in ProviderContainer cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(metroMosaicRepositoryProvider);
      expect(repo, isNotNull);

      final stationsAsync = container.read(metroStationsProvider);
      expect(stationsAsync, isNotNull);

      final stampsAsync = container.read(userMetroStampsProvider);
      expect(stampsAsync, isNotNull);
    });
  });
}
