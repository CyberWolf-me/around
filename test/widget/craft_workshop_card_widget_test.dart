import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/craft_workshop_engine.dart';
import 'package:around_app/features/explore/widgets/craft_workshop_card_widget.dart';

void main() {
  group('CraftWorkshopCardWidget Tests', () {
    late CraftStudio testStudio;

    setUp(() {
      testStudio = CraftWorkshopEngine.defaultStudios.first; // Rishtan Blue Glaze
    });

    testWidgets('renders studio card with discipline, credentials, materials, and masterclasses', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CraftWorkshopCardWidget(
                studio: testStudio,
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('craft_workshop_card_${testStudio.id}')), findsOneWidget);
      expect(find.text('CERAMICS'), findsOneWidget);
      expect(find.text('Shaykhontohur'), findsOneWidget);
      expect(find.text(testStudio.title), findsOneWidget);
      expect(find.textContaining('Usto Alisher Nazirov'), findsOneWidget);
      expect(find.byKey(const Key('studio_materials_wrap')), findsOneWidget);
      expect(find.text('Fergana Red Clay'), findsOneWidget);
      expect(find.text('Foot-Powered Kickwheel Pitcher Throwing'), findsOneWidget);
      expect(find.text('180 000 UZS'), findsOneWidget);
      expect(find.text('+40 XP'), findsOneWidget);
      expect(find.text('Reserve Seat'), findsOneWidget);
      expect(find.text('Fully Booked'), findsOneWidget);
    });

    testWidgets('tapping reserve button triggers onMasterclassSelected callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      WorkshopMasterclass? selectedClass;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CraftWorkshopCardWidget(
                studio: testStudio,
                onMasterclassSelected: (st, mc) {
                  selectedClass = mc;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reserveBtn = find.byKey(const Key('workshop_reserve_btn_class-kickwheel-pottery'));
      expect(reserveBtn, findsOneWidget);
      await tester.tap(reserveBtn);
      await tester.pumpAndSettle();

      expect(selectedClass, isNotNull);
      expect(selectedClass!.id, equals('class-kickwheel-pottery'));
      expect(selectedClass!.durationMinutes, equals(90));
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
              child: CraftWorkshopCardWidget(
                studio: testStudio,
                reservedMasterclassId: 'class-kickwheel-pottery',
                locale: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rishton Moviy Sir Kulolchilik Uyi'), findsOneWidget);
      expect(find.text('Band qilingan (+40 XP)'), findsOneWidget);
      expect(find.text('Barcha joylar band'), findsOneWidget);

      // Test Russian
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CraftWorkshopCardWidget(
                studio: testStudio,
                reservedMasterclassId: 'class-kickwheel-pottery',
                locale: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Гончарный Дом Риштанской Лазури'), findsOneWidget);
      expect(find.text('Забронировано (+40 XP)'), findsOneWidget);
      expect(find.text('Все места заняты'), findsOneWidget);
    });
  });
}
