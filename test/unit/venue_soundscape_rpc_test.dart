import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/venue_soundscape_engine.dart';
import 'package:around_app/data/repositories/venue_soundscape_repository.dart';

void main() {
  group('P36-04: Venue Soundscape Presets RPC & Migration Tests', () {
    test('migration 00027_venue_soundscape_presets.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00027_venue_soundscape_presets.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('ALTER TABLE public.places'));
      expect(sql, contains('ADD COLUMN IF NOT EXISTS soundscape_preset'));
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.get_venue_soundscape_preset'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.get_venue_soundscape_preset(UUID) TO authenticated, anon;'));
    });

    test('VenueSoundscapeRepository resolves contextual soundscapes in offline mode', () async {
      final repo = VenueSoundscapeRepository();

      // Coffee shop -> espresso murmur
      final cafeConfig = await repo.getVenueSoundscape(
        placeId: 'pl-breadly',
        placeCategory: 'Specialty Coffee & Bakery',
      );
      expect(cafeConfig.preset, equals(VenueSoundscapePreset.espressoMurmur));
      expect(cafeConfig.emoji, equals('☕'));

      // Park -> courtyard fountain
      final parkConfig = await repo.getVenueSoundscape(
        placeId: 'pl-park',
        placeCategory: 'Courtyard & Botanical Garden',
      );
      expect(parkConfig.preset, equals(VenueSoundscapePreset.courtyardFountain));
      expect(parkConfig.emoji, equals('⛲'));

      // Bazaar -> oriental bazaar
      final bazaarConfig = await repo.getVenueSoundscape(
        placeId: 'pl-chorsu',
        placeCategory: 'Chorsu Spice Bazaar',
      );
      expect(bazaarConfig.preset, equals(VenueSoundscapePreset.orientalBazaar));
      expect(bazaarConfig.emoji, equals('🕌'));
    });

    test('Riverpod providers initialize VenueSoundscapeRepository cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(venueSoundscapeRepositoryProvider);
      expect(repo, isA<VenueSoundscapeRepository>());

      final configAsync = await container.read(venueSoundscapePresetProvider('pl-1').future);
      expect(configAsync, isA<SoundscapePresetConfig>());
      expect(configAsync.id, isNotEmpty);
    });
  });
}
