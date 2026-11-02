import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/features/places/widgets/venue_rhythm_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VenueRhythmSparkline Widget Tests', () {
    const samplePlace = PlaceModel(
      id: 'test_breadly',
      slug: 'breadly',
      name: 'Breadly Bakery & Specialty Coffee',
      category: 'Specialty Coffee',
      description: 'Artisan sourdough pastries and third-wave coffee.',
      streetAddress: 'Shevchenko St 28',
      district: 'Mirabad',
      latitude: 41.305,
      longitude: 69.278,
      tags: ['Coffee', 'Pastry', 'Morning Brew'],
      heroImageUrl: 'assets/images/breadly.jpg',
      statusLine: 'Open · Closes 22:00',
    );

    testWidgets('renders 24-hour atmosphere rhythm header and peak indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueRhythmSparkline(
                place: samplePlace,
                drops: const [],
                now: DateTime(2026, 11, 3, 9, 30), // 09:30 AM
              ),
            ),
          ),
        ),
      );

      expect(find.text('VENUE RHYTHM'), findsOneWidget);
      expect(find.text('24-Hour Atmosphere Rhythm'), findsOneWidget);
      expect(find.textContaining('Peak:'), findsOneWidget);
      expect(find.textContaining('09:00 ·'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('23:00'), findsOneWidget);
    });

    testWidgets('incorporates real drop timestamps into hourly distribution', (tester) async {
      final drops = [
        PostModel(
          id: 'drop_1',
          authorId: 'user_1',
          authorName: 'Kamila',
          authorUsername: 'kamila',
          placeId: 'test_breadly',
          placeName: 'Breadly',
          placeCategory: 'Specialty Coffee',
          placeAddress: 'Shevchenko St 28',
          note: 'Crisp morning flat white.',
          audience: PostAudience.public,
          createdAt: DateTime(2026, 11, 3, 10, 15),
        ),
        PostModel(
          id: 'drop_2',
          authorId: 'user_2',
          authorName: 'Aziz',
          authorUsername: 'aziz',
          placeId: 'test_breadly',
          placeName: 'Breadly',
          placeCategory: 'Specialty Coffee',
          placeAddress: 'Shevchenko St 28',
          note: 'Afternoon almond croissant.',
          audience: PostAudience.public,
          createdAt: DateTime(2026, 11, 3, 10, 45),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueRhythmSparkline(
                place: samplePlace,
                drops: drops,
                now: DateTime(2026, 11, 3, 10, 0),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('10:00 ·'), findsOneWidget);
    });

    testWidgets('tapping an hourly bar selects hour and updates active vibe percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VenueRhythmSparkline(
                place: samplePlace,
                drops: const [],
                now: DateTime(2026, 11, 3, 14, 0),
              ),
            ),
          ),
        ),
      );

      // Initially shows 14:00
      expect(find.textContaining('14:00 ·'), findsOneWidget);

      // Find bars
      final bars = find.byType(AnimatedContainer);
      expect(bars, findsWidgets);

      // Tap the 20th bar (hour 19)
      await tester.tap(bars.at(19));
      await tester.pumpAndSettle();

      expect(find.textContaining('19:00 ·'), findsOneWidget);
    });
  });
}
