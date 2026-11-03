import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/tandoor_bakery_engine.dart';
import 'package:around_app/features/explore/widgets/tandoor_bread_card_widget.dart';

void main() {
  group('TandoorBreadCardWidget Tests (P48-02)', () {
    final sampleBakery = TandoorBakeryEngine.defaultBakeries.firstWhere(
      (b) => b.id == 'bakery-chorsu-kattabog',
    );

    Widget buildTestHarness({
      required TandoorBakeryVenue bakery,
      bool isReserved = false,
      String languageCode = 'en',
      void Function(BreadVariety variety, int count)? onReserveBatch,
      VoidCallback? onTapDetails,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TandoorBreadCardWidget(
              bakery: bakery,
              isReserved: isReserved,
              languageCode: languageCode,
              onReserveBatch: onReserveBatch,
              onTapDetails: onTapDetails,
            ),
          ),
        ),
      );
    }

    testWidgets('renders bakery title, head baker, district badge, and bread variety pills', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(bakery: sampleBakery),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('tandoor_bakery_card_${sampleBakery.id}')), findsOneWidget);
      expect(find.text(sampleBakery.name), findsOneWidget);
      expect(find.text(sampleBakery.headBaker), findsOneWidget);
      expect(find.byKey(const Key('bakery_district_badge')), findsOneWidget);
      expect(find.byKey(const Key('freshness_status_badge')), findsOneWidget);
      expect(find.textContaining('Rishtan Ochre Refractory Clay'), findsOneWidget);
      expect(find.byKey(const Key('reserve_bread_button')), findsOneWidget);
    });

    testWidgets('increments and decrements loaves count and triggers onReserveBatch with count', (tester) async {
      BreadVariety? reservedVariety;
      int? reservedCount;

      await tester.pumpWidget(
        buildTestHarness(
          bakery: sampleBakery,
          isReserved: false,
          onReserveBatch: (variety, count) {
            reservedVariety = variety;
            reservedCount = count;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Initial count should be 2
      expect(find.text('2'), findsOneWidget);

      // Increment to 3
      await tester.tap(find.byKey(const Key('increment_loaves_button')));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // Switch variety to Patir
      final patirPill = find.byKey(const Key('variety_pill_patir'));
      expect(patirPill, findsOneWidget);
      await tester.tap(patirPill);
      await tester.pumpAndSettle();

      // Reserve button tap
      await tester.tap(find.byKey(const Key('reserve_bread_button')));
      await tester.pumpAndSettle();

      expect(reservedVariety, equals(BreadVariety.patir));
      expect(reservedCount, equals(3));
    });

    testWidgets('renders reserved state with disabled button', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          bakery: sampleBakery,
          isReserved: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reserved (+30 XP)'), findsOneWidget);
      final elevatedButton = tester.widget<ElevatedButton>(find.byKey(const Key('reserve_bread_button')));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('respects Uzbek and Russian localizations properly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        buildTestHarness(
          bakery: sampleBakery,
          languageCode: 'uz',
          isReserved: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nonni band qilish (+30 XP)'), findsOneWidget);
      expect(find.textContaining('Tandirdan uzilgan'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        buildTestHarness(
          bakery: sampleBakery,
          languageCode: 'ru',
          isReserved: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Забронировано (+30 XP)'), findsOneWidget);
      expect(find.textContaining('С пылу с жару'), findsOneWidget);
    });
  });
}
