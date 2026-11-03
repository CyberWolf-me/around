import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/place_sound_bite_engine.dart';
import 'package:around_app/data/repositories/place_sound_bite_repository.dart';

void main() {
  group('P38-04: Place Sound Bites RPC & Repository Tests', () {
    test('migration 00029_place_sound_bites.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00029_place_sound_bites.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.place_sound_bites'));
      expect(sql, contains('ALTER TABLE public.place_sound_bites ENABLE ROW LEVEL SECURITY;'));
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_place_sound_bites'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_place_sound_bites(UUID, INTEGER) TO authenticated, anon;'));
      expect(sql, contains('hide_visits_history, false) = false'));
      expect(sql, contains('auth.uid() = user_id'));
    });

    test('PlaceSoundBiteRepository returns rich offline seeds when Supabase is uninitialized', () async {
      final repo = PlaceSoundBiteRepository();
      final allBites = await repo.getPlaceSoundBites(placeId: 'all');

      expect(allBites, isNotEmpty);
      expect(allBites.length, equals(4));

      final breadlyBite = allBites.firstWhere(
        (b) => b.placeId == 'pl-breadly',
      );
      expect(breadlyBite.authorName, equals('Kamila Karimova'));
      expect(breadlyBite.categoryTag, equals('barista_tip'));
      expect(breadlyBite.durationSeconds, equals(22));
    });

    test('PlaceSoundBiteRepository filters voice notes by venue identifier', () async {
      final repo = PlaceSoundBiteRepository();

      final chorsuBites = await repo.getPlaceSoundBites(placeId: 'pl-chorsu');
      expect(chorsuBites.length, equals(1));
      expect(chorsuBites.first.placeName, contains('Chorsu'));
      expect(chorsuBites.first.categoryTag, equals('whisper'));

      final kukeldashBites = await repo.getPlaceSoundBites(placeId: 'pl-kukeldash');
      expect(kukeldashBites.length, equals(1));
      expect(kukeldashBites.first.authorName, equals('Aziza Tursunova'));
    });

    test('Riverpod providers initialize PlaceSoundBiteRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(placeSoundBiteRepositoryProvider);
      expect(repo, isA<PlaceSoundBiteRepository>());

      final bitesAsync = await container.read(placeSoundBitesProvider('pl-breadly').future);
      expect(bitesAsync, isA<List<PlaceSoundBite>>());
      expect(bitesAsync, isNotEmpty);
      expect(bitesAsync.first.placeId, equals('pl-breadly'));
    });
  });
}
