import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/venue_soundscape_engine.dart';

void main() {
  group('P36-01: VenueSoundscapeEngine Unit Tests', () {
    late VenueSoundscapeEngine engine;

    setUp(() {
      engine = VenueSoundscapeEngine();
    });

    test('retrieves config for all 5 presets with emojis and default volumes', () {
      for (final preset in VenueSoundscapePreset.values) {
        final config = engine.getConfig(preset);
        expect(config.preset, equals(preset));
        expect(config.id, isNotEmpty);
        expect(config.emoji, isNotEmpty);
        expect(config.defaultVolume, inInclusiveRange(0.0, 1.0));
        expect(config.loopDurationSeconds, greaterThan(0));
      }
    });

    test('recommends appropriate ambient presets based on category and time of day', () {
      // 1. Speakeasy / Bar
      expect(
        engine.recommendPreset(venueCategory: 'Cocktail Bar & Speakeasy', hourOfDay: 21),
        equals(VenueSoundscapePreset.jazzLounge),
      );

      // 2. Library / Co-working
      expect(
        engine.recommendPreset(venueCategory: 'Study Library & Bookshop', hourOfDay: 14),
        equals(VenueSoundscapePreset.quietLibrary),
      );

      // 3. Park / Courtyard
      expect(
        engine.recommendPreset(venueCategory: 'Botanical Garden & Courtyard', hourOfDay: 11),
        equals(VenueSoundscapePreset.courtyardFountain),
      );

      // 4. Bazaar / Heritage
      expect(
        engine.recommendPreset(venueCategory: 'Chorsu Traditional Market', hourOfDay: 10),
        equals(VenueSoundscapePreset.orientalBazaar),
      );

      // 5. Default Cafe
      expect(
        engine.recommendPreset(venueCategory: 'Specialty Coffee Roastery', hourOfDay: 9),
        equals(VenueSoundscapePreset.espressoMurmur),
      );

      // 6. Late night fallback (23:00)
      expect(
        engine.recommendPreset(venueCategory: 'General Lounge', hourOfDay: 23),
        equals(VenueSoundscapePreset.jazzLounge),
      );
    });

    test('formats localized preset titles and descriptions in EN, UZ, and RU', () {
      final config = engine.getConfig(VenueSoundscapePreset.espressoMurmur);

      expect(config.localizedTitle(locale: 'en'), equals('Espresso Murmur'));
      expect(config.localizedTitle(locale: 'uz'), equals('Qahvaxona Shovqini'));
      expect(config.localizedTitle(locale: 'ru'), equals('Кофейный Гул'));

      expect(config.localizedDescription(locale: 'en'), contains('coffee grinding'));
      expect(config.localizedDescription(locale: 'uz'), contains('Mayin qahva'));
      expect(config.localizedDescription(locale: 'ru'), contains('Мягкий помол'));

      // Check courtyard fountain
      final fountainConfig = engine.getConfig(VenueSoundscapePreset.courtyardFountain);
      expect(fountainConfig.localizedTitle(locale: 'uz'), equals('Hovli Favvorasi'));
      expect(fountainConfig.localizedTitle(locale: 'ru'), equals('Дворовый Фонтан'));
    });

    test('clamps volume within valid range', () {
      expect(engine.clampVolume(-0.5), equals(0.0));
      expect(engine.clampVolume(1.8), equals(1.0));
      expect(engine.clampVolume(0.42), equals(0.42));
    });

    test('Riverpod provider initializes VenueSoundscapeEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(venueSoundscapeEngineProvider);
      expect(service, isA<VenueSoundscapeEngine>());
    });
  });
}
