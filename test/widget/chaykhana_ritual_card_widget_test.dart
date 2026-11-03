import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/chaykhana_ritual_engine.dart';
import 'package:around_app/features/explore/widgets/chaykhana_ritual_card_widget.dart';

void main() {
  group('ChaykhanaRitualCardWidget Tests', () {
    late ChaykhanaVenue testVenue;

    setUp(() {
      testVenue = ChaykhanaRitualEngine.defaultVenues.first; // Chorsu Chinor
    });

    testWidgets('renders venue card with credentials, tapchan status, Kaytarish steps and tea blends', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChaykhanaRitualCardWidget(
                venue: testVenue,
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('chaykhana_ritual_card_${testVenue.id}')), findsOneWidget);
      expect(find.text('CHAYKHANA'), findsOneWidget);
      expect(find.text('Shaykhontohur'), findsOneWidget);
      expect(find.text(testVenue.name), findsOneWidget);
      expect(find.text('4 tapchans free (of 12)'), findsOneWidget);
      expect(find.text('Usto Bobomurod Choychi'), findsOneWidget);
      expect(find.text('3-Step Kaytarish Aeration'), findsOneWidget);
      expect(find.text('33% Oxygenated'), findsOneWidget);
      expect(find.byKey(const Key('kaytarish_step_btn_1')), findsOneWidget);
      expect(find.byKey(const Key('kaytarish_step_btn_2')), findsOneWidget);
      expect(find.byKey(const Key('kaytarish_step_btn_3')), findsOneWidget);
      expect(find.text('First is mud, second is oil, third is tea'), findsOneWidget);
      expect(find.text('Old City Kok-Choy No. 95'), findsOneWidget);
      expect(find.text('Host Tapchan Gathering (+35 XP)'), findsOneWidget);
    });

    testWidgets('tapping Kaytarish steps switches active step and triggers callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int? tappedStep;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChaykhanaRitualCardWidget(
                venue: testVenue,
                onKaytarishStepChanged: (step) {
                  tappedStep = step;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap step 2 (Moy)
      await tester.tap(find.byKey(const Key('kaytarish_step_btn_2')));
      await tester.pumpAndSettle();

      expect(tappedStep, equals(2));
      expect(find.text('66% Oxygenated'), findsOneWidget);
      expect(find.textContaining('Moy (Oil)'), findsOneWidget);

      // Tap step 3 (Choy)
      await tester.tap(find.byKey(const Key('kaytarish_step_btn_3')));
      await tester.pumpAndSettle();

      expect(tappedStep, equals(3));
      expect(find.text('100% Oxygenated'), findsOneWidget);
      expect(find.textContaining('Choy (Tea)'), findsOneWidget);
    });

    testWidgets('tapping reserve tapchan button triggers onTapchanReserved callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ChaykhanaVenue? reservedVenue;
      TeaBlend? reservedBlend;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChaykhanaRitualCardWidget(
                venue: testVenue,
                onTapchanReserved: (venue, blend) {
                  reservedVenue = venue;
                  reservedBlend = blend;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reserveBtn = find.byKey(Key('reserve_tapchan_btn_${testVenue.id}'));
      expect(reserveBtn, findsOneWidget);
      await tester.tap(reserveBtn);
      await tester.pumpAndSettle();

      expect(reservedVenue, isNotNull);
      expect(reservedVenue!.id, equals(testVenue.id));
      expect(reservedBlend, isNotNull);
      expect(reservedBlend!.name, contains('Kok-Choy'));
    });

    testWidgets('renders Uzbek and Russian localization correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Test Uzbek
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChaykhanaRitualCardWidget(
                venue: testVenue,
                isReserved: true,
                locale: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chorsu Chinor Choyxonasi'), findsOneWidget);
      expect(find.text('Birinchi loy, ikkinchi moy, uchinchi choy'), findsOneWidget);
      expect(find.text('Tapchan band qilindi (+35 XP)'), findsOneWidget);

      // Test Russian
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChaykhanaRitualCardWidget(
                venue: testVenue,
                isReserved: true,
                locale: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Чайхана Чорсу Чинор'), findsOneWidget);
      expect(find.text('Первая — глина, вторая — масло, третья — чай'), findsOneWidget);
      expect(find.text('Тапчан забронирован (+35 XP)'), findsOneWidget);
    });
  });
}
