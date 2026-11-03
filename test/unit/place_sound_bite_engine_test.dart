import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/place_sound_bite_engine.dart';

void main() {
  group('P38-01: PlaceSoundBiteEngine Unit Tests', () {
    test('serializes and deserializes PlaceSoundBite model accurately', () {
      final now = DateTime(2026, 11, 3, 19, 30);
      final bite = PlaceSoundBite(
        id: 'sb-1',
        placeId: 'pl-breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        authorId: 'u-101',
        authorName: 'Kamila K.',
        authorAvatarUrl: 'https://example.com/avatar.jpg',
        audioUrl: 'https://cdn.around.uz/audio/sb-1.m4a',
        durationSeconds: 28,
        waveformAmplitudes: const [0.2, 0.5, 0.8, 0.4, 0.9, 0.3],
        transcriptionSnippet: 'The almond croissants fresh at 9 AM are unbelievable.',
        categoryTag: 'barista_tip',
        likesCount: 19,
        createdAt: now,
      );

      final json = bite.toJson();
      expect(json['id'], equals('sb-1'));
      expect(json['place_id'], equals('pl-breadly'));
      expect(json['duration_seconds'], equals(28));
      expect(json['category_tag'], equals('barista_tip'));
      expect(json['waveform_amplitudes'], equals([0.2, 0.5, 0.8, 0.4, 0.9, 0.3]));

      final restored = PlaceSoundBite.fromJson(json);
      expect(restored.id, equals(bite.id));
      expect(restored.placeName, equals(bite.placeName));
      expect(restored.durationSeconds, equals(28));
      expect(restored.formattedDuration, equals('0:28'));
      expect(restored.waveformAmplitudes.length, equals(6));
      expect(restored.likesCount, equals(19));
    });

    test('validates duration bounds correctly', () {
      final engine = PlaceSoundBiteEngine();

      expect(engine.validateDuration(1), isFalse); // Below min (2s)
      expect(engine.validateDuration(2), isTrue);
      expect(engine.validateDuration(25), isTrue);
      expect(engine.validateDuration(45), isTrue);
      expect(engine.validateDuration(46), isFalse); // Exceeds max 45s
    });

    test('normalizes raw waveform samples into target visualizer bars', () {
      final engine = PlaceSoundBiteEngine();

      final rawSamples = [10, 50, 100, 30, 80, 20, 90, 40];
      final bars = engine.normalizeWaveform(rawSamples, targetBars: 12);

      expect(bars.length, equals(12));
      for (final bar in bars) {
        expect(bar, greaterThanOrEqualTo(0.08));
        expect(bar, lessThanOrEqualTo(1.0));
      }

      // Empty raw samples fallback
      final emptyBars = engine.normalizeWaveform([], targetBars: 8);
      expect(emptyBars.length, equals(8));
      for (final bar in emptyBars) {
        expect(bar, equals(0.2));
      }
    });

    test('formats timeline progress string accurately', () {
      final engine = PlaceSoundBiteEngine();

      expect(engine.formatProgress(12.4, 30), equals('0:12 / 0:30'));
      expect(engine.formatProgress(5.1, 45), equals('0:05 / 0:45'));
      expect(engine.formatProgress(65.0, 90), equals('1:05 / 1:30'));
    });

    test('filters sound bites by place and district', () {
      final engine = PlaceSoundBiteEngine();
      final now = DateTime.now();

      final bites = [
        PlaceSoundBite(
          id: 'b1',
          placeId: 'pl-1',
          placeName: 'Breadly',
          district: 'Mirabad',
          authorId: 'u1',
          authorName: 'A',
          audioUrl: '',
          durationSeconds: 15,
          waveformAmplitudes: const [0.5],
          createdAt: now,
        ),
        PlaceSoundBite(
          id: 'b2',
          placeId: 'pl-2',
          placeName: 'Chorsu',
          district: 'Shaykhontohur',
          authorId: 'u2',
          authorName: 'B',
          audioUrl: '',
          durationSeconds: 20,
          waveformAmplitudes: const [0.7],
          createdAt: now,
        ),
      ];

      final filteredPlace = engine.filterByPlace(bites, 'pl-1');
      expect(filteredPlace.length, equals(1));
      expect(filteredPlace.first.placeName, equals('Breadly'));

      final filteredDistrict = engine.filterByDistrict(bites, 'Shaykhontohur');
      expect(filteredDistrict.length, equals(1));
      expect(filteredDistrict.first.district, equals('Shaykhontohur'));

      final allDistrict = engine.filterByDistrict(bites, 'all');
      expect(allDistrict.length, equals(2));
    });

    test('formats localized categories across Uzbek, Russian, and English', () {
      final now = DateTime.now();
      final bite = PlaceSoundBite(
        id: 'b-cat',
        placeId: 'pl-1',
        placeName: 'Spot',
        district: 'Mirabad',
        authorId: 'u1',
        authorName: 'Author',
        audioUrl: '',
        durationSeconds: 12,
        waveformAmplitudes: const [0.5],
        categoryTag: 'barista_tip',
        createdAt: now,
      );

      expect(bite.localizedCategory(locale: 'en'), equals('Barista Tip'));
      expect(bite.localizedCategory(locale: 'uz'), equals('Barista Tavsiyasi'));
      expect(bite.localizedCategory(locale: 'ru'), equals('Совет бариста'));
    });

    test('Riverpod provider initializes PlaceSoundBiteEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(placeSoundBiteEngineProvider);
      expect(engine, isA<PlaceSoundBiteEngine>());
    });
  });
}
