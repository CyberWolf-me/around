import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/features/profile/widgets/taste_radar_widget.dart';

void main() {
  group('P15-02: TasteRadarWidget Tests', () {
    const coffeePlace = PlaceModel(
      id: 'p_coffee_1',
      slug: 'breadly-bakery',
      name: 'Breadly Bakery & Café',
      category: 'Specialty Coffee · Bakery',
      streetAddress: '24 Mirobod',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3002,
      longitude: 69.2715,
      distanceMeters: 200,
      walkTimeMinutes: 3,
      priceTier: r'$$',
      hours: '8:00 AM - 11:00 PM',
      statusLine: 'Open now',
      description: 'Artisan espresso and pastries.',
      heroImageUrl: 'assets/cafe.jpg',
      ratingAvg: 4.8,
      ratingCount: 300,
      tags: ['coffee', 'croissant'],
      photos: ['assets/cafe.jpg'],
    );

    const nationalPlace = PlaceModel(
      id: 'p_national_1',
      slug: 'central-plov-center',
      name: 'Central Asian Plov Centre',
      category: 'National Cuisine · Plov',
      streetAddress: '1 Guard Street',
      district: 'Yunusabad',
      city: 'Tashkent',
      latitude: 41.3654,
      longitude: 69.2888,
      distanceMeters: 1200,
      walkTimeMinutes: 15,
      priceTier: r'$',
      hours: '10:00 AM - 4:00 PM',
      statusLine: 'Open now',
      description: 'Giant kazan wedding plov.',
      heroImageUrl: 'assets/plov.jpg',
      ratingAvg: 4.9,
      ratingCount: 1500,
      tags: ['plov', 'osh', 'national'],
      photos: ['assets/plov.jpg'],
    );

    testWidgets('TasteRadarWidget renders radar bars and calculated archetype', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TasteRadarWidget(
              places: [coffeePlace, nationalPlace],
              languageCode: 'en',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('taste_radar_widget')), findsOneWidget);
      expect(find.text('Urban Taste Radar'), findsOneWidget);
      expect(find.text('Specialty Coffee'), findsOneWidget);
      expect(find.text('National Dining'), findsOneWidget);
      expect(find.text('Curator Footprint'), findsOneWidget);
      expect(find.textContaining('2 spots'), findsOneWidget);
    });

    testWidgets('TasteRadarWidget renders localized Uzbek titles', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TasteRadarWidget(
              places: [coffeePlace],
              languageCode: 'uz',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Qahva Bilagdoni'), findsOneWidget);
    });
  });
}
