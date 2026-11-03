import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_tour_story_engine.dart';
import 'package:around_app/features/explore/widgets/curator_tour_player_widget.dart';

void main() {
  group('P40-02: CuratorTourPlayerWidget Widget Tests', () {
    const stop1 = TourStopStory(
      id: 'st-1',
      tourId: 't-1',
      chapterIndex: 1,
      title: 'Cosmic Tile Mosaic',
      venueId: 'pl-kosmonavtlar',
      venueName: 'Kosmonavtlar Hall',
      latitude: 41.3094,
      longitude: 69.2678,
      audioUrl: 'https://cdn.around.uz/audio/ch1.m4a',
      durationSeconds: 120,
      transcript: 'The cylindrical columns reflect cobalt light.',
    );

    const stop2 = TourStopStory(
      id: 'st-2',
      tourId: 't-1',
      chapterIndex: 2,
      title: 'Turquoise Cupola',
      venueId: 'pl-chorsu',
      venueName: 'Chorsu Bazaar',
      latitude: 41.3271,
      longitude: 69.2365,
      audioUrl: 'https://cdn.around.uz/audio/ch2.m4a',
      durationSeconds: 180,
      transcript: 'A vast dome spanning the spice market.',
    );

    const testTour = CuratorTour(
      id: 't-1',
      title: 'Modernist Gems',
      subtitle: 'Architecture in Tashkent',
      curatorId: 'u-1',
      curatorName: 'Aziza T.',
      district: 'Central',
      stops: [stop1, stop2],
      estimatedWalkingMinutes: 40,
      xpReward: 100,
    );

    testWidgets('renders tour header, active chapter, and elapsed time', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorTourPlayerWidget(
              tour: testTour,
              activeChapterIndex: 1,
              isPlaying: false,
              chapterProgress: 0.5,
              completedStopIds: {'st-1'},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tour_title_text')), findsOneWidget);
      expect(find.text('Modernist Gems'), findsOneWidget);

      expect(find.byKey(const Key('tour_curator_byline_text')), findsOneWidget);
      expect(find.text('by Aziza T. • Central'), findsOneWidget);

      expect(find.byKey(const Key('overall_tour_progress_text')), findsOneWidget);
      expect(find.text('50% Complete'), findsOneWidget);

      expect(find.byKey(const Key('chapter_progress_header_text')), findsOneWidget);
      expect(find.text('Chapter 1 of 2'), findsOneWidget);

      expect(find.byKey(const Key('chapter_title_text')), findsOneWidget);
      expect(find.text('Cosmic Tile Mosaic'), findsOneWidget);

      expect(find.byKey(const Key('venue_name_pill_text')), findsOneWidget);
      expect(find.text('Kosmonavtlar Hall'), findsOneWidget);

      // Halfway through 120s = 60s -> 1:00
      expect(find.byKey(const Key('chapter_elapsed_text')), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
      expect(find.byKey(const Key('chapter_total_text')), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('toggles play/pause and switches chapters on skip button taps', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool playToggled = false;
      int? selectedChapter;
      bool navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratorTourPlayerWidget(
              tour: testTour,
              activeChapterIndex: 1,
              isPlaying: true,
              onPlayToggle: () => playToggled = true,
              onChapterSelected: (ch) => selectedChapter = ch,
              onNavigateToVenue: () => navigated = true,
            ),
          ),
        ),
      );

      // Verify pause icon when playing
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap play toggle button
      await tester.tap(find.byKey(const Key('tour_play_toggle_button')));
      await tester.pumpAndSettle();
      expect(playToggled, isTrue);

      // Tap next chapter button
      await tester.tap(find.byKey(const Key('next_chapter_button')));
      await tester.pumpAndSettle();
      expect(selectedChapter, equals(2));

      // Tap navigate venue pill
      await tester.tap(find.byKey(const Key('navigate_venue_pill')));
      await tester.pumpAndSettle();
      expect(navigated, isTrue);
    });

    testWidgets('respects Uzbek and Russian localizations for chapter progress', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorTourPlayerWidget(
              tour: testTour,
              activeChapterIndex: 2,
              locale: 'uz',
            ),
          ),
        ),
      );

      expect(find.text('2 tadan 2-bob'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorTourPlayerWidget(
              tour: testTour,
              activeChapterIndex: 1,
              locale: 'ru',
            ),
          ),
        ),
      );

      expect(find.text('Глава 1 из 2'), findsOneWidget);
    });
  });
}
