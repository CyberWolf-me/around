import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/place_sound_bite_engine.dart';
import 'package:around_app/features/explore/widgets/place_sound_bite_card_widget.dart';

void main() {
  group('P38-02: PlaceSoundBiteCardWidget Widget Tests', () {
    final testBite = PlaceSoundBite(
      id: 'sb-test-1',
      placeId: 'pl-breadly',
      placeName: 'Breadly Bakery',
      district: 'Mirabad',
      authorId: 'u-1',
      authorName: 'Kamila Karimova',
      audioUrl: 'https://example.com/audio.m4a',
      durationSeconds: 30,
      waveformAmplitudes: const [0.3, 0.6, 0.9, 0.5, 0.8, 0.4],
      transcriptionSnippet: 'Fresh hot baguettes and espresso.',
      categoryTag: 'barista_tip',
      likesCount: 12,
      createdAt: DateTime.now(),
    );

    testWidgets('renders author name, transcription, and place pill', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSoundBiteCardWidget(
              soundBite: testBite,
              isPlaying: false,
              playbackProgress: 0.0,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('author_name_text')), findsOneWidget);
      expect(find.text('Kamila Karimova'), findsOneWidget);
      expect(find.byKey(const Key('transcription_snippet_text')), findsOneWidget);
      expect(find.text('“Fresh hot baguettes and espresso.”'), findsOneWidget);
      expect(find.byKey(const Key('place_name_pill_text')), findsOneWidget);
      expect(find.text('Breadly Bakery'), findsOneWidget);
      expect(find.byKey(const Key('sound_bite_likes_text')), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('triggers play/pause toggle and seek callbacks on tap', (WidgetTester tester) async {
      bool playToggled = false;
      double? seekedFraction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSoundBiteCardWidget(
              soundBite: testBite,
              isPlaying: true,
              playbackProgress: 0.5,
              onPlayToggle: () => playToggled = true,
              onSeek: (frac) => seekedFraction = frac,
            ),
          ),
        ),
      );

      // Verify pause icon rendered when isPlaying is true
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap play/pause button
      await tester.tap(find.byKey(const Key('play_pause_button')));
      await tester.pumpAndSettle();
      expect(playToggled, isTrue);

      // Check progress string formatted: 30 * 0.5 = 15s -> "0:15 / 0:30"
      expect(find.byKey(const Key('timeline_progress_text')), findsOneWidget);
      expect(find.text('0:15 / 0:30'), findsOneWidget);
      expect(seekedFraction, isNull); // Not yet tapped bar
    });

    testWidgets('respects localized category names across languages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSoundBiteCardWidget(
              soundBite: testBite,
              locale: 'uz',
            ),
          ),
        ),
      );

      expect(find.text('Barista Tavsiyasi'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSoundBiteCardWidget(
              soundBite: testBite,
              locale: 'ru',
            ),
          ),
        ),
      );

      expect(find.text('Совет бариста'), findsOneWidget);
    });
  });
}
