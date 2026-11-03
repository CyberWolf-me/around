import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/architectural_badge_engine.dart';
import 'package:around_app/features/profile/widgets/architectural_badge_card_widget.dart';

void main() {
  group('ArchitecturalBadgeCardWidget Tests', () {
    late ArchitecturalQuest testQuest;

    setUp(() {
      testQuest = ArchitecturalBadgeEngine.defaultQuests.first; // Soviet Modernism
    });

    testWidgets('renders in-progress quest card with partial progress and stop list', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchitecturalBadgeCardWidget(
                quest: testQuest,
                visitedPlaceOrStopIds: const {'hotel-uzbekistan-canonical'},
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modernist Connoisseur'), findsOneWidget);
      expect(find.text(testQuest.title), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('1 of 3 locations visited'), findsOneWidget);
      expect(find.text('Hotel Uzbekistan'), findsOneWidget);
      expect(find.text('Tashkent State Circus'), findsOneWidget);
      expect(find.text('Explore Next Landmark'), findsOneWidget);
    });

    testWidgets('renders fully unlocked badge state with XP award and share button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchitecturalBadgeCardWidget(
                quest: testQuest,
                visitedPlaceOrStopIds: const {
                  'hotel-uzbekistan-canonical',
                  'tashkent-circus-canonical',
                  'blue-domes-cafe-canonical',
                },
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('Completed! Badge Unlocked (+50 XP)'), findsOneWidget);
      expect(find.text('Share Badge'), findsOneWidget);
    });

    testWidgets('triggers callbacks on stop tap, info tap, and share tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      QuestStop? tappedStop;
      QuestStop? factStop;
      bool shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchitecturalBadgeCardWidget(
                quest: testQuest,
                visitedPlaceOrStopIds: const {
                  'hotel-uzbekistan-canonical',
                  'tashkent-circus-canonical',
                  'blue-domes-cafe-canonical',
                },
                locale: 'en',
                onStopTap: (stop) => tappedStop = stop,
                onViewFactTap: (stop) => factStop = stop,
                onClaimOrShare: () => shareTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on landmark stop row
      await tester.tap(find.text('Hotel Uzbekistan'));
      await tester.pumpAndSettle();
      expect(tappedStop, isNotNull);
      expect(tappedStop!.name, equals('Hotel Uzbekistan'));

      // Tap on info icon
      await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(factStop, isNotNull);
      expect(factStop!.name, equals('Hotel Uzbekistan'));

      // Tap on share button
      await tester.tap(find.text('Share Badge'));
      await tester.pumpAndSettle();
      expect(shareTapped, isTrue);
    });

    testWidgets('renders trilingual localization accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Uzbek
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchitecturalBadgeCardWidget(
                quest: testQuest,
                visitedPlaceOrStopIds: const {'hotel-uzbekistan-canonical'},
                locale: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1/3 to‘xtash joyi tashrif buyurildi'), findsOneWidget);
      expect(find.text('Keyingi lokatsiyani kashf qilish'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArchitecturalBadgeCardWidget(
                quest: testQuest,
                visitedPlaceOrStopIds: const {'hotel-uzbekistan-canonical'},
                locale: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Посещено 1 из 3 локаций'), findsOneWidget);
      expect(find.text('Исследовать следующую локацию'), findsOneWidget);
    });
  });
}
