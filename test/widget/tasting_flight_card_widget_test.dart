import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/tasting_flight_engine.dart';
import 'package:around_app/features/explore/widgets/tasting_flight_card_widget.dart';

void main() {
  group('TastingFlightCardWidget Tests', () {
    late TastingFlight testFlight;

    setUp(() {
      testFlight = TastingFlightEngine.defaultFlights.first; // Specialty Coffee
    });

    testWidgets('renders in-progress tasting flight card with items and flavor tags', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastingFlightCardWidget(
                flight: testFlight,
                userLogs: const {},
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testFlight.title), findsOneWidget);
      expect(find.text(testFlight.curatorTitle), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 of 3 tastings logged'), findsOneWidget);
      expect(find.text('Ethiopia Sidama Natural Pour-Over'), findsOneWidget);
      expect(find.text('Bergamot'), findsOneWidget);
      expect(find.text('Explore Next Tasting'), findsOneWidget);
    });

    testWidgets('renders completed flight with cupping score and certificate action', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fullLogs = {
        'stop-breadly-cupping': TastingLog(
          stopId: 'stop-breadly-cupping',
          rating: 9.2,
          selectedFlavorNotes: const ['Bergamot', 'Wild Jasmine'],
          loggedAt: DateTime.now(),
        ),
        'stop-bb-anaerobic': TastingLog(
          stopId: 'stop-bb-anaerobic',
          rating: 8.8,
          selectedFlavorNotes: const ['Red Currant'],
          loggedAt: DateTime.now(),
        ),
        'stop-paul-bistro': TastingLog(
          stopId: 'stop-paul-bistro',
          rating: 9.0,
          selectedFlavorNotes: const ['Roasted Hazelnut'],
          loggedAt: DateTime.now(),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastingFlightCardWidget(
                flight: testFlight,
                userLogs: fullLogs,
                locale: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('Flight Completed! Cupping Certificate Unlocked (+50 XP)'), findsOneWidget);
      expect(find.text('View Cupping Certificate'), findsOneWidget);
      expect(find.text('9.2★'), findsOneWidget);
    });

    testWidgets('triggers callbacks on stop tap, cupping log tap, and certificate tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      TastingStop? tappedStop;
      TastingStop? logStop;
      bool certificateTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastingFlightCardWidget(
                flight: testFlight,
                userLogs: const {},
                locale: 'en',
                onStopTap: (stop) => tappedStop = stop,
                onLogCuppingTap: (stop) => logStop = stop,
                onCertificateOrShare: () => certificateTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on item row
      await tester.tap(find.text('Ethiopia Sidama Natural Pour-Over'));
      await tester.pumpAndSettle();
      expect(tappedStop, isNotNull);
      expect(tappedStop!.itemTitle, contains('Ethiopia'));

      // Tap on review button
      await tester.tap(find.byIcon(Icons.rate_review_outlined).first);
      await tester.pumpAndSettle();
      expect(logStop, isNotNull);
      expect(logStop!.itemTitle, contains('Ethiopia'));

      // Tap on action button
      await tester.tap(find.text('Explore Next Tasting'));
      await tester.pumpAndSettle();
      expect(certificateTapped, isTrue);
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
              child: TastingFlightCardWidget(
                flight: testFlight,
                userLogs: const {},
                locale: 'uz',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0/3 degustatsiya bajarildi'), findsOneWidget);
      expect(find.text('Keyingi ta\'mni tatib ko‘rish'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastingFlightCardWidget(
                flight: testFlight,
                userLogs: const {},
                locale: 'ru',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Оценено 0 из 3 дегустаций'), findsOneWidget);
      expect(find.text('Исследовать следующий вкус'), findsOneWidget);
    });
  });
}
