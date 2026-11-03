import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/puppet_theater_engine.dart';
import 'package:around_app/features/explore/widgets/puppet_theater_card_widget.dart';

void main() {
  group('P49-02: PuppetTheaterCardWidget Widget Tests', () {
    final testStage = PuppetTheaterEngine.defaultStages.first;

    testWidgets('renders stage title, district, and chief puppeteer details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: testStage,
            ),
          ),
        ),
      );

      expect(find.text(testStage.name), findsOneWidget);
      expect(find.textContaining('Yakkasaray Kosmonavtlar'), findsOneWidget);
      expect(find.textContaining('Usto Mansur'), findsOneWidget);
      expect(find.textContaining('48 seats'), findsOneWidget);
      expect(find.text('Current Repertoire'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
    });

    testWidgets('switches selected performance on choice chip tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: testStage,
            ),
          ),
        ),
      );

      // Initially first show is selected
      expect(find.textContaining('11:00 AM & 3:00 PM'), findsOneWidget);
      expect(find.textContaining('Polvon Kachal outwitting greedy merchants'), findsOneWidget);

      // Tap on second performance
      final secondChip = find.byKey(const Key('repertoire_chip_show-simurgh-legend'));
      expect(secondChip, findsOneWidget);
      await tester.tap(secondChip);
      await tester.pumpAndSettle();

      // Verified schedule updated
      expect(find.textContaining('6:30 PM'), findsOneWidget);
      expect(find.textContaining('golden Simurgh'), findsOneWidget);
      expect(find.text('50 000 UZS'), findsOneWidget);
    });

    testWidgets('increments and decrements seats count and updates total price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: testStage,
            ),
          ),
        ),
      );

      // Initial 1 seat at 35 000 UZS
      expect(find.text('1'), findsOneWidget);
      expect(find.text('35 000 UZS'), findsOneWidget);

      // Increment
      final incrementBtn = find.byKey(const Key('increment_seats_button'));
      await tester.tap(incrementBtn);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('70 000 UZS'), findsOneWidget);

      // Decrement back
      final decrementBtn = find.byKey(const Key('decrement_seats_button'));
      await tester.tap(decrementBtn);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('35 000 UZS'), findsOneWidget);
    });

    testWidgets('dispatches onReserveTickets callback when reserve CTA is tapped', (tester) async {
      PuppetPerformance? reservedPerf;
      int? reservedSeats;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: testStage,
              onReserveTickets: (perf, count) {
                reservedPerf = perf;
                reservedSeats = count;
              },
            ),
          ),
        ),
      );

      // Increment to 2 seats
      await tester.tap(find.byKey(const Key('increment_seats_button')));
      await tester.pumpAndSettle();

      // Tap reserve
      final reserveBtn = find.byKey(const Key('reserve_puppet_tickets_button'));
      await tester.tap(reserveBtn);
      await tester.pumpAndSettle();

      expect(reservedPerf, isNotNull);
      expect(reservedPerf!.id, equals('show-polvon-kachal-wedding'));
      expect(reservedSeats, equals(2));
    });

    testWidgets('displays reserved state and disables button when isReserved is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: testStage,
              isReserved: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byKey(const Key('reserve_puppet_tickets_button')));
      expect(button.onPressed, isNull);
      expect(find.text('Reserved (+35 XP)'), findsOneWidget);
    });

    testWidgets('displays Sold Out when available seats is zero', (tester) async {
      const soldOutStage = PuppetTheaterStage(
        id: 'theater-sold-out',
        name: 'Historic Puppet Stage',
        district: 'Old City',
        chiefMaster: 'Usto Botir',
        foundedYear: 1950,
        availableSeats: 0,
        latitude: 41.31,
        longitude: 69.24,
        repertoire: [],
        signatureFigures: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PuppetTheaterCardWidget(
              stage: soldOutStage,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byKey(const Key('reserve_puppet_tickets_button')));
      expect(button.onPressed, isNull);
      expect(find.text('Sold Out'), findsOneWidget);
    });
  });
}
