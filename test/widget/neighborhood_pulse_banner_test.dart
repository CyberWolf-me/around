import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/places/widgets/neighborhood_pulse_banner.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P17-02: NeighborhoodPulseBanner Widget Tests', () {
    final places = [
      const PlaceModel(
        id: 'place_breadly',
        name: 'Breadly Bakery',
        slug: 'breadly',
        category: 'Cafe',
        streetAddress: 'Mirabad st 12',
        district: 'Mirabad',
        latitude: 41.3000,
        longitude: 69.2600,
        heroImageUrl: 'https://images.unsplash.com/photo-breadly',
      ),
      const PlaceModel(
        id: 'place_ecopark',
        name: 'Ecopark Tashkent',
        slug: 'ecopark',
        category: 'Park',
        streetAddress: 'Yunusabad district',
        district: 'Yunusabad',
        latitude: 41.3200,
        longitude: 69.2800,
        heroImageUrl: 'https://images.unsplash.com/photo-ecopark',
      ),
    ];

    PostModel createTestDrop({
      required String id,
      required String authorId,
      required String placeId,
      required DateTime createdAt,
    }) {
      return PostModel(
        id: id,
        authorId: authorId,
        authorName: 'User $authorId',
        authorUsername: 'user_$authorId',
        placeId: placeId,
        placeName: 'Sample Place',
        placeCategory: 'Cafe',
        placeAddress: 'Mirabad, Tashkent',
        note: 'Note',
        audience: PostAudience.friends,
        createdAt: createdAt,
      );
    }

    testWidgets('renders hot district banner and triggers callback on tap', (tester) async {
      final now = DateTime.now();

      final drops = [
        createTestDrop(
          id: 'd1',
          authorId: 'kamila',
          placeId: 'place_breadly',
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        createTestDrop(
          id: 'd2',
          authorId: 'diyor',
          placeId: 'place_breadly',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        createTestDrop(
          id: 'd3',
          authorId: 'bekzod',
          placeId: 'place_ecopark',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

      String? tappedDistrict;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeighborhoodPulseBanner(
                overrideFriends: const ['kamila', 'diyor', 'bekzod'],
                overrideDrops: drops,
                overridePlaces: places,
                activeDistrict: 'Mirabad',
                onDistrictSelected: (d) => tappedDistrict = d,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify banner title and subtitle
      expect(find.text('HOT RIGHT NOW'), findsOneWidget);
      expect(find.text('2 friends active in Mirabad'), findsOneWidget);

      // Verify chips for both Mirabad and Yunusabad
      expect(find.text('Mirabad'), findsOneWidget);
      expect(find.text('Yunusabad'), findsOneWidget);

      // Tap Yunusabad chip
      await tester.tap(find.text('Yunusabad'));
      await tester.pumpAndSettle();

      expect(tappedDistrict, equals('Yunusabad'));
    });

    testWidgets('renders quiet state when no friend activity exists', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NeighborhoodPulseBanner(
                overrideFriends: [],
                overrideDrops: [],
                overridePlaces: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AROUND TASHKENT'), findsOneWidget);
      expect(find.text('All neighborhoods peaceful'), findsOneWidget);
    });
  });
}
