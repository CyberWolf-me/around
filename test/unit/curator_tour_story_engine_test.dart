import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_tour_story_engine.dart';

void main() {
  group('P40-01: CuratorTourStoryEngine Unit Tests', () {
    const stop1 = TourStopStory(
      id: 'stop-1',
      tourId: 'tour-modernism',
      chapterIndex: 1,
      title: 'Cosmic Mosaic Portal',
      venueId: 'pl-kosmonavtlar',
      venueName: 'Kosmonavtlar Metro Hall',
      latitude: 41.3094,
      longitude: 69.2678,
      triggerRadiusMeters: 50.0,
      audioUrl: 'https://cdn.around.uz/audio/tour-ch1.m4a',
      durationSeconds: 180,
      transcript: 'Look up at the deep cobalt glass panels honoring early space pioneers.',
    );

    const stop2 = TourStopStory(
      id: 'stop-2',
      tourId: 'tour-modernism',
      chapterIndex: 2,
      title: 'Blue Cupola Rhythm',
      venueId: 'pl-chorsu',
      venueName: 'Chorsu Bazaar Center',
      latitude: 41.3271,
      longitude: 69.2365,
      triggerRadiusMeters: 60.0,
      audioUrl: 'https://cdn.around.uz/audio/tour-ch2.m4a',
      durationSeconds: 240,
      transcript: 'The geodesic lattice of concrete ribs was engineered to withstand severe tremors.',
    );

    const testTour = CuratorTour(
      id: 'tour-modernism',
      title: 'Tashkent Modernism & Cosmic Mosaics',
      subtitle: 'Walking through post-earthquake Soviet modernist landmarks',
      curatorId: 'u-aziza',
      curatorName: 'Aziza Tursunova',
      district: 'Central',
      stops: [stop1, stop2],
      estimatedWalkingMinutes: 50,
      xpReward: 120,
    );

    test('serializes and restores CuratorTour and TourStopStory models', () {
      final json = testTour.toJson();
      expect(json['id'], equals('tour-modernism'));
      expect(json['title'], contains('Modernism'));
      expect((json['stops'] as List).length, equals(2));

      final restored = CuratorTour.fromJson(json);
      expect(restored.id, equals(testTour.id));
      expect(restored.stops.length, equals(2));
      expect(restored.stops.first.title, equals('Cosmic Mosaic Portal'));
      expect(restored.stops.first.formattedDuration, equals('3:00'));
      expect(restored.totalDurationSeconds, equals(420));
      expect(restored.formattedTotalDuration, equals('7 min audio'));
    });

    test('calculates tour completion and identifies next chapter accurately', () {
      final engine = CuratorTourStoryEngine();

      // Zero completed
      expect(engine.calculateTourProgress(testTour, {}), equals(0.0));
      expect(engine.isTourCompleted(testTour, {}), isFalse);
      expect(engine.getNextChapter(testTour, {})?.id, equals('stop-1'));

      // 1 of 2 completed
      expect(engine.calculateTourProgress(testTour, {'stop-1'}), equals(50.0));
      expect(engine.isTourCompleted(testTour, {'stop-1'}), isFalse);
      expect(engine.getNextChapter(testTour, {'stop-1'})?.id, equals('stop-2'));

      // All completed
      expect(engine.calculateTourProgress(testTour, {'stop-1', 'stop-2'}), equals(100.0));
      expect(engine.isTourCompleted(testTour, {'stop-1', 'stop-2'}), isTrue);
      expect(engine.getNextChapter(testTour, {'stop-1', 'stop-2'}), isNull);
    });

    test('checks geotargeted arrival trigger within radius threshold', () {
      final engine = CuratorTourStoryEngine();

      // Exactly at stop1 (within 50m)
      expect(engine.isWithinTriggerRadius(41.3094, 69.2678, stop1), isTrue);

      // 20m away from stop1 (within 50m)
      expect(engine.isWithinTriggerRadius(41.3095, 69.2679, stop1), isTrue);

      // 300m away (exceeds 50m radius)
      expect(engine.isWithinTriggerRadius(41.3120, 69.2700, stop1), isFalse);
    });

    test('formats chapter progress and localized durations across languages', () {
      final engine = CuratorTourStoryEngine();

      expect(engine.formatChapterProgress(2, 4, locale: 'en'), equals('Chapter 2 of 4'));
      expect(engine.formatChapterProgress(2, 4, locale: 'uz'), equals('4 tadan 2-bob'));
      expect(engine.formatChapterProgress(2, 4, locale: 'ru'), equals('Глава 2 из 4'));

      expect(engine.localizedDuration(420, locale: 'en'), equals('7 min audio tour'));
      expect(engine.localizedDuration(420, locale: 'uz'), equals('7 daqiqalik audio sayohat'));
      expect(engine.localizedDuration(420, locale: 'ru'), equals('7 мин. аудиотур'));
    });

    test('Riverpod provider initializes CuratorTourStoryEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(curatorTourStoryEngineProvider);
      expect(engine, isA<CuratorTourStoryEngine>());
    });
  });
}
