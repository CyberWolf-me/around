import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/metro_mosaic_engine.dart';
import 'package:around_app/features/explore/widgets/metro_mosaic_card_widget.dart';

void main() {
  group('MetroMosaicCardWidget Tests (P46-02)', () {
    final sampleStation = MetroMosaicEngine.defaultStations.firstWhere(
      (s) => s.id == 'kosmonavtlar',
    );

    Widget buildTestHarness({
      required MetroStationModel station,
      bool isStamped = false,
      bool isAudioPlaying = false,
      String languageCode = 'en',
      VoidCallback? onCollectStamp,
      VoidCallback? onToggleAudio,
      VoidCallback? onTapDetails,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MetroMosaicCardWidget(
              station: station,
              isStamped: isStamped,
              isAudioPlaying: isAudioPlaying,
              languageCode: languageCode,
              onCollectStamp: onCollectStamp,
              onToggleAudio: onToggleAudio,
              onTapDetails: onTapDetails,
            ),
          ),
        ),
      );
    }

    testWidgets('renders station metadata, line badge, architectural style, and mosaic artist', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(station: sampleStation),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('metro_station_card_${sampleStation.id}')), findsOneWidget);
      expect(find.text('Cosmonauts'), findsOneWidget);
      expect(find.text('Uzbekistan Line'), findsOneWidget);
      expect(find.text('Opened 1984'), findsOneWidget);
      expect(find.text('Arnold Gan'), findsOneWidget);
      expect(find.byKey(const Key('architectural_style_pill')), findsOneWidget);
      expect(find.byKey(const Key('mosaic_artist_pill')), findsOneWidget);
      expect(find.byKey(const Key('audio_guide_button')), findsOneWidget);
      expect(find.byKey(const Key('stamp_button')), findsOneWidget);
    });

    testWidgets('triggers onCollectStamp when uncollected stamp button is tapped', (tester) async {
      bool stampCollected = false;

      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          isStamped: false,
          onCollectStamp: () {
            stampCollected = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      final stampBtn = find.byKey(const Key('stamp_button'));
      expect(stampBtn, findsOneWidget);
      expect(find.text('Collect Stamp (+30 XP)'), findsOneWidget);

      await tester.tap(stampBtn);
      await tester.pumpAndSettle();

      expect(stampCollected, isTrue);
    });

    testWidgets('renders stamped state with STAMPED badge and disabled stamp button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          isStamped: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STAMPED'), findsOneWidget);
      expect(find.text('Stamp Collected (+30 XP)'), findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(find.byKey(const Key('stamp_button')));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('toggles audio guide button state and triggers onToggleAudio callback', (tester) async {
      bool audioToggled = false;

      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          isAudioPlaying: false,
          onToggleAudio: () {
            audioToggled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audio Guide'), findsOneWidget);
      await tester.tap(find.byKey(const Key('audio_guide_button')));
      await tester.pumpAndSettle();

      expect(audioToggled, isTrue);

      // Re-render in playing state
      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          isAudioPlaying: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pause Guide'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    });

    testWidgets('respects Uzbek and Russian localizations properly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          languageCode: 'uz',
          isStamped: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kosmonavtlar'), findsOneWidget);
      expect(find.text("O'zbekiston yo'li"), findsOneWidget);
      expect(find.text('1984-yilda ochilgan'), findsOneWidget);
      expect(find.text("Shtampni olish (+30 XP)"), findsOneWidget);
      expect(find.text("Audio qo'llanma"), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        buildTestHarness(
          station: sampleStation,
          languageCode: 'ru',
          isStamped: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Космонавтов'), findsOneWidget);
      expect(find.text('Узбекистанская линия'), findsOneWidget);
      expect(find.text('Открыта в 1984 г.'), findsOneWidget);
      expect(find.text('Штамп получен (+30 XP)'), findsOneWidget);
    });
  });
}
