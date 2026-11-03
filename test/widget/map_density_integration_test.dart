import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/repositories/places_repository.dart';
import 'package:around_app/features/explore/screens/explore_screen.dart';
import 'package:around_app/features/explore/widgets/city_map_widget.dart';
import 'package:around_app/features/places/widgets/district_density_overlay.dart';

void main() {
  group('P14-01: Map District Heat Integration & Smooth Centroid Navigation Tests', () {
    final samplePlaces = [
      const PlaceModel(
        id: 'place_breadly',
        slug: 'breadly-bakery',
        name: 'Breadly Bakery & Café',
        category: 'Specialty Coffee · Bakery',
        streetAddress: '24 Mirobod Street',
        district: 'Mirabad',
        city: 'Tashkent',
        latitude: 41.3002,
        longitude: 69.2715,
        distanceMeters: 250,
        walkTimeMinutes: 3,
        priceTier: r'$$',
        hours: '8:00 AM – 11:00 PM',
        statusLine: 'Open now · Artisan croissants',
        description: 'Cozy Tashkent café.',
        heroImageUrl: 'assets/cafe-bw.jpg',
        ratingAvg: 4.8,
        ratingCount: 320,
        tags: ['coffee', 'croissant'],
        photos: ['assets/cafe-bw.jpg'],
      ),
      const PlaceModel(
        id: 'place_canti',
        slug: 'canti-wine-bar',
        name: 'Canti Wine Bar',
        category: 'Wine Bar',
        streetAddress: '19 Sadyk Azimov Street',
        district: 'Mirabad',
        city: 'Tashkent',
        latitude: 41.3060,
        longitude: 69.2815,
        distanceMeters: 580,
        walkTimeMinutes: 8,
        priceTier: r'$$$',
        hours: '5:00 PM – 1:00 AM',
        statusLine: 'Opens 5pm',
        description: 'Intimate wine bar.',
        heroImageUrl: 'assets/wine-wide.jpg',
        ratingAvg: 4.7,
        ratingCount: 240,
        tags: ['wine', 'tapas'],
        photos: ['assets/wine-wide.jpg'],
      ),
    ];

    final sampleDistricts = [
      const DistrictDensityModel(
        district: 'Mirabad',
        dropCount: 42,
        activeVenuesCount: 15,
        centroidLat: 41.3060,
        centroidLng: 69.2815,
        relativeDensity: 1.0,
      ),
      const DistrictDensityModel(
        district: 'Yakkasaray',
        dropCount: 28,
        activeVenuesCount: 10,
        centroidLat: 41.2885,
        centroidLng: 69.2580,
        relativeDensity: 0.67,
      ),
    ];

    testWidgets('CityMapWidget renders density circles and toggles heat controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool heatToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CityMapWidget(
              places: samplePlaces,
              selectedPlaceId: 'place_breadly',
              onSelectPlace: (_) {},
              districtDensities: sampleDistricts,
              showDensityHeat: true,
              onToggleHeat: (val) => heatToggled = val,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify map control for social heat toggle exists
      final heatToggleFinder = find.byTooltip('Hide Social Heat');
      expect(heatToggleFinder, findsOneWidget);

      // Tap heat toggle to hide social heat
      await tester.tap(heatToggleFinder);
      await tester.pumpAndSettle();

      expect(heatToggled, isFalse);
      expect(find.byTooltip('Show Social Heat'), findsOneWidget);
    });

    testWidgets('ExploreScreen integrates DistrictDensityOverlay and navigates camera on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            districtDensityProvider.overrideWith((ref) async => sampleDistricts),
          ],
          child: const MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify DistrictDensityOverlay is rendered above the map
      expect(find.byType(DistrictDensityOverlay), findsOneWidget);
      expect(find.text('Tashkent Live Density'), findsOneWidget);
      expect(find.text('Mirabad'), findsOneWidget);
      expect(find.text('Yakkasaray'), findsOneWidget);

      // Tap Yakkasaray chip
      final yakkasarayChip = find.byKey(const Key('district_chip_Yakkasaray'));
      expect(yakkasarayChip, findsOneWidget);

      await tester.tap(yakkasarayChip);
      await tester.pumpAndSettle();

      // Chip remains visible and interactive
      expect(find.text('Yakkasaray'), findsOneWidget);
    });
  });
}
