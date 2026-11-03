import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/metro_stamp_engine.dart';
import 'package:around_app/features/profile/widgets/metro_stamp_book_widget.dart';

void main() {
  group('P39-02: MetroStampBookWidget Widget Tests', () {
    final sampleStamps = [
      MetroStamp(
        stationId: 'kosmonavtlar',
        stationName: 'Kosmonavtlar',
        line: MetroLine.uzbekistan,
        stampMotif: 'Cosmos Blue Medallion',
        stampColorHex: '#1E88E5',
        claimedAt: DateTime.now(),
      ),
      MetroStamp(
        stationId: 'chorsu',
        stationName: 'Chorsu',
        line: MetroLine.uzbekistan,
        stampMotif: 'Turquoise Bazaar Dome',
        stampColorHex: '#1E88E5',
        claimedAt: DateTime.now(),
      ),
    ];

    testWidgets('renders header, total count, and active line progress', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetroStampBookWidget(
              claimedStamps: sampleStamps,
              initialLine: MetroLine.uzbekistan,
              locale: 'en',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('stamp_book_header_text')), findsOneWidget);
      expect(find.text('Metro Passport Seals'), findsOneWidget);

      expect(find.byKey(const Key('total_stamps_count_text')), findsOneWidget);
      expect(find.text('2 / 12'), findsOneWidget);

      expect(find.byKey(const Key('active_line_title_text')), findsOneWidget);
      expect(find.text('Uzbekistan Line'), findsOneWidget);

      expect(find.byKey(const Key('line_completion_pct_text')), findsOneWidget);
      expect(find.text('2/4 (50%)'), findsOneWidget);

      // Verify claimed vs locked cards
      expect(find.byKey(const Key('stamp_card_kosmonavtlar')), findsOneWidget);
      expect(find.text('Kosmonavtlar'), findsOneWidget);
      expect(find.text('Cosmos Blue Medallion'), findsOneWidget);

      expect(find.byKey(const Key('stamp_card_alisher_navoiy')), findsOneWidget);
      expect(find.text('Alisher Navoiy'), findsOneWidget);
    });

    testWidgets('switches line tabs and invokes onStationTap callback', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      MetroStation? tappedStation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetroStampBookWidget(
              claimedStamps: sampleStamps,
              initialLine: MetroLine.uzbekistan,
              onStationTap: (s) => tappedStation = s,
            ),
          ),
        ),
      );

      // Switch to Chilanzar line
      await tester.tap(find.byKey(const Key('metro_tab_chilanzar')));
      await tester.pumpAndSettle();

      expect(find.text('Chilanzar Line'), findsOneWidget);
      expect(find.byKey(const Key('stamp_card_mustaqillik_maydoni')), findsOneWidget);

      // Tap Mustaqillik Maydoni stamp card
      await tester.tap(find.byKey(const Key('stamp_card_mustaqillik_maydoni')));
      await tester.pumpAndSettle();

      expect(tappedStation, isNotNull);
      expect(tappedStation!.id, equals('mustaqillik_maydoni'));
    });

    testWidgets('respects Uzbek and Russian localizations', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetroStampBookWidget(
              claimedStamps: sampleStamps,
              locale: 'uz',
            ),
          ),
        ),
      );

      expect(find.text('Metro Pasport Muhrlari'), findsOneWidget);
      expect(find.text('O\'zbekiston yo\'li'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetroStampBookWidget(
              claimedStamps: sampleStamps,
              locale: 'ru',
            ),
          ),
        ),
      );

      expect(find.text('Метро-Печати Паспорта'), findsOneWidget);
      expect(find.text('Узбекистанская линия'), findsOneWidget);
    });
  });
}
