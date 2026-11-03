import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_activity_ticker_engine.dart';
import 'package:around_app/features/explore/widgets/district_activity_ticker_widget.dart';

void main() {
  group('P34-02: DistrictActivityTickerWidget Widget Tests', () {
    testWidgets('renders empty state cleanly with localized copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistrictActivityTickerWidget(
              events: [],
              locale: 'en',
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('Quiet across Tashkent'), findsOneWidget);

      // Russian localization
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistrictActivityTickerWidget(
              events: [],
              locale: 'ru',
            ),
          ),
        ),
      );

      expect(find.text('ПУЛЬС'), findsOneWidget);
      expect(find.text('В Ташкенте пока спокойно'), findsOneWidget);
    });

    testWidgets('renders populated event and handles user tap callback', (tester) async {
      DistrictActivityEvent? tappedEvent;

      final event = DistrictActivityEvent(
        id: 'ev-1',
        type: DistrictActivityType.dropCreated,
        userId: 'u1',
        username: '@kamila',
        userFullName: 'Kamila K',
        district: 'Mirabad',
        placeName: 'Breadly Bakery',
        timestamp: DateTime.now().subtract(const Duration(seconds: 15)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistrictActivityTickerWidget(
              events: [event],
              locale: 'en',
              onEventTap: (e) => tappedEvent = e,
            ),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('📸'), findsOneWidget);
      expect(find.byKey(const Key('district_activity_ticker_gesture')), findsOneWidget);

      // Tap on ticker
      await tester.tap(find.byKey(const Key('district_activity_ticker_gesture')));
      await tester.pump();

      expect(tappedEvent?.id, equals('ev-1'));
      expect(tappedEvent?.username, equals('@kamila'));
    });

    testWidgets('rotates to next event upon interval tick', (tester) async {
      final event1 = DistrictActivityEvent(
        id: 'ev-1',
        type: DistrictActivityType.dropCreated,
        userId: 'u1',
        username: '@kamila',
        userFullName: 'Kamila K',
        district: 'Mirabad',
        placeName: 'Breadly Bakery',
        timestamp: DateTime.now(),
      );

      final event2 = DistrictActivityEvent(
        id: 'ev-2',
        type: DistrictActivityType.crownOvertake,
        userId: 'u2',
        username: '@jasur',
        userFullName: 'Jasur A',
        district: 'Chilanzar',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistrictActivityTickerWidget(
              events: [event1, event2],
              locale: 'en',
              rotationInterval: const Duration(seconds: 2),
            ),
          ),
        ),
      );

      // Initially event 1 is displayed
      expect(find.byKey(const ValueKey<String>('ev-1')), findsOneWidget);
      expect(find.text('📸'), findsOneWidget);

      // Advance time by 2.5 seconds to trigger rotation
      await tester.pump(const Duration(seconds: 2, milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400)); // Finish transition

      // Now event 2 is displayed
      expect(find.byKey(const ValueKey<String>('ev-2')), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
    });
  });
}
