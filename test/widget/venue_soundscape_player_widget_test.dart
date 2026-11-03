import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/venue_soundscape_engine.dart';
import 'package:around_app/features/explore/widgets/venue_soundscape_player_widget.dart';

void main() {
  group('P36-02: VenueSoundscapePlayerWidget Widget Tests', () {
    testWidgets('renders initial preset and toggles play/pause state', (tester) async {
      VenueSoundscapePreset? lastPreset;
      bool? lastIsPlaying;
      double? lastVolume;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSoundscapePlayerWidget(
                initialPreset: VenueSoundscapePreset.espressoMurmur,
                locale: 'en',
                onStateChanged: (p, isPlaying, vol) {
                  lastPreset = p;
                  lastIsPlaying = isPlaying;
                  lastVolume = vol;
                },
              ),
            ),
          ),
        ),
      );

      // Verify initial rendering
      expect(find.byKey(const Key('soundscape_title_text')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('soundscape_title_text'))).data,
        equals('Espresso Murmur'),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      // Tap Play
      await tester.tap(find.byKey(const Key('soundscape_play_pause_button')));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(lastPreset, equals(VenueSoundscapePreset.espressoMurmur));
      expect(lastIsPlaying, isTrue);
      expect(lastVolume, equals(0.65));

      // Tap Pause
      await tester.tap(find.byKey(const Key('soundscape_play_pause_button')));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(lastIsPlaying, isFalse);
    });

    testWidgets('switches preset chip upon user tap with localization', (tester) async {
      VenueSoundscapePreset? lastPreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSoundscapePlayerWidget(
                initialPreset: VenueSoundscapePreset.espressoMurmur,
                locale: 'uz',
                onStateChanged: (p, isPlaying, vol) {
                  lastPreset = p;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Uzbek initial label
      expect(find.text('Qahvaxona Shovqini'), findsWidgets);

      // Tap Courtyard Fountain chip
      await tester.tap(find.byKey(const Key('preset_chip_courtyard_fountain')));
      await tester.pump();

      expect(lastPreset, equals(VenueSoundscapePreset.courtyardFountain));
      expect(find.text('Hovli Favvorasi'), findsWidgets);
    });

    testWidgets('updates volume when slider value changes', (tester) async {
      double? updatedVolume;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueSoundscapePlayerWidget(
                initialPreset: VenueSoundscapePreset.quietLibrary,
                locale: 'en',
                onStateChanged: (p, isPlaying, vol) {
                  updatedVolume = vol;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('soundscape_volume_slider')), findsOneWidget);

      // Drag slider slightly to test volume change interaction
      await tester.drag(
        find.byKey(const Key('soundscape_volume_slider')),
        const Offset(60, 0),
      );
      await tester.pump();

      expect(updatedVolume, isNotNull);
      expect(updatedVolume, greaterThan(0.0));
      expect(updatedVolume, lessThanOrEqualTo(1.0));
    });
  });
}
