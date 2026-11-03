import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/silk_paper_calligraphy_engine.dart';
import 'package:around_app/features/explore/widgets/silk_paper_card_widget.dart';

void main() {
  group('SilkPaperCardWidget Tests (P47-02)', () {
    final sampleAtelier = SilkPaperCalligraphyEngine.defaultAteliers.firstWhere(
      (a) => a.id == 'atelier-chorsu-mulberry',
    );

    Widget buildTestHarness({
      required SilkPaperAtelier atelier,
      bool isReserved = false,
      String languageCode = 'en',
      ValueChanged<CalligraphyScript>? onReserveMasterclass,
      VoidCallback? onTapDetails,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SilkPaperCardWidget(
              atelier: atelier,
              isReserved: isReserved,
              languageCode: languageCode,
              onReserveMasterclass: onReserveMasterclass,
              onTapDetails: onTapDetails,
            ),
          ),
        ),
      );
    }

    testWidgets('renders atelier metadata, craftsman attribution, and script pills', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(atelier: sampleAtelier),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('silk_paper_card_${sampleAtelier.id}')), findsOneWidget);
      expect(find.text(sampleAtelier.name), findsOneWidget);
      expect(find.text(sampleAtelier.masterName), findsOneWidget);
      expect(find.byKey(const Key('district_badge')), findsOneWidget);
      expect(find.textContaining('White Mulberry'), findsOneWidget);
      expect(find.textContaining('150 000 UZS'), findsOneWidget);
      expect(find.byKey(const Key('reserve_masterclass_button')), findsOneWidget);
    });

    testWidgets('allows selecting script and invokes onReserveMasterclass with selected script', (tester) async {
      CalligraphyScript? selectedScript;

      await tester.pumpWidget(
        buildTestHarness(
          atelier: sampleAtelier,
          isReserved: false,
          onReserveMasterclass: (script) {
            selectedScript = script;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Thuluth script pill
      final thuluthPill = find.byKey(const Key('script_pill_thuluth'));
      expect(thuluthPill, findsOneWidget);
      await tester.tap(thuluthPill);
      await tester.pumpAndSettle();

      // Tap reserve button
      final reserveBtn = find.byKey(const Key('reserve_masterclass_button'));
      await tester.tap(reserveBtn);
      await tester.pumpAndSettle();

      expect(selectedScript, equals(CalligraphyScript.thuluth));
    });

    testWidgets('renders reserved state with ENROLLED badge and disabled button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          atelier: sampleAtelier,
          isReserved: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ENROLLED'), findsOneWidget);
      expect(find.text('Reserved (+35 XP)'), findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(find.byKey(const Key('reserve_masterclass_button')));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('renders fully booked state when availableMasterclasses is zero', (tester) async {
      const fullAtelier = SilkPaperAtelier(
        id: 'atelier-full',
        name: 'Full Atelier',
        district: 'Old City',
        masterName: 'Usto Full',
        centuryTradition: 'Ancient Guild',
        mulberryVariety: 'Morus Alba',
        burnishStoneType: 'Agate',
        latitude: 41.3,
        longitude: 69.2,
        supportedScripts: [CalligraphyScript.nastaliq],
        workshopPriceUzs: 150000,
        availableMasterclasses: 0,
        maxCapacity: 8,
      );

      await tester.pumpWidget(
        buildTestHarness(
          atelier: fullAtelier,
          isReserved: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fully Booked'), findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(find.byKey(const Key('reserve_masterclass_button')));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('respects Uzbek and Russian localizations properly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        buildTestHarness(
          atelier: sampleAtelier,
          languageCode: 'uz',
          isReserved: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Joyni band qilish (+35 XP)'), findsOneWidget);
      expect(find.textContaining("ta joy ochiq"), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        buildTestHarness(
          atelier: sampleAtelier,
          languageCode: 'ru',
          isReserved: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Забронировано (+35 XP)'), findsOneWidget);
      expect(find.textContaining('мест свободно'), findsOneWidget);
    });
  });
}
