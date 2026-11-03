import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_radio_engine.dart';
import 'package:around_app/features/explore/widgets/district_radio_player_widget.dart';

void main() {
  group('DistrictRadioPlayerWidget Tests', () {
    testWidgets('renders initial frequency with locked station details and controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictRadioPlayerWidget(
                initialFrequency: 88.4,
                initialPlaying: false,
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('district_radio_player_widget')), findsOneWidget);
      expect(find.byKey(const Key('radio_station_callsign')), findsOneWidget);
      expect(find.text('CHRS 88.4'), findsOneWidget);
      expect(find.text('LOCK'), findsOneWidget);
      expect(find.byKey(const Key('radio_frequency_display')), findsOneWidget);
      final freqText = tester.widget<Text>(find.byKey(const Key('radio_frequency_display')));
      expect(freqText.data, '88.4');
      expect(find.byKey(const Key('radio_signal_quality_badge')), findsOneWidget);
      expect(find.text('Clear Signal'), findsOneWidget);
      expect(find.byKey(const Key('radio_listener_count_badge')), findsOneWidget);
      expect(find.byKey(const Key('radio_play_pause_button')), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('toggles play/pause state and triggers onTuningChanged callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool? lastPlaying;
      RadioStation? lastStation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictRadioPlayerWidget(
                initialFrequency: 88.4,
                initialPlaying: false,
                onTuningChanged: (freq, station, isPlaying, quality) {
                  lastPlaying = isPlaying;
                  lastStation = station;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Play
      await tester.tap(find.byKey(const Key('radio_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPlaying, isTrue);
      expect(lastStation?.callsign, 'CHRS 88.4');
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      // Tap Pause
      await tester.tap(find.byKey(const Key('radio_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(lastPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('tapping quick-jump station tab tunes to station and updates state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      double? tunedFreq;
      RadioStation? tunedStation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictRadioPlayerWidget(
                initialFrequency: 88.4,
                initialPlaying: false,
                onTuningChanged: (freq, station, isPlaying, quality) {
                  tunedFreq = freq;
                  tunedStation = station;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Mirabad station tab (94.2 MHz)
      final mirabadTab = find.byKey(const Key('radio_station_tab_station-mirabad-beat'));
      expect(mirabadTab, findsOneWidget);
      await tester.tap(mirabadTab);
      await tester.pumpAndSettle();

      expect(tunedFreq, 94.2);
      expect(tunedStation?.callsign, 'MRBD 94.2');
      expect(find.text('MRBD 94.2'), findsOneWidget);
      final tunedDisplay = tester.widget<Text>(find.byKey(const Key('radio_frequency_display')));
      expect(tunedDisplay.data, '94.2');
    });

    testWidgets('renders Uzbek and Russian localization correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Test Uzbek
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictRadioPlayerWidget(
                initialFrequency: 88.4,
                locale: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aniq signal'), findsOneWidget);

      // Test Russian
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictRadioPlayerWidget(
                initialFrequency: 88.4,
                locale: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Четкий сигнал'), findsOneWidget);
    });
  });
}
