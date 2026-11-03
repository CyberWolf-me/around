import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/neighborhood_cluster_engine.dart';
import 'package:around_app/features/explore/widgets/neighborhood_cluster_overlay_widget.dart';

void main() {
  group('P37-02: NeighborhoodClusterOverlayWidget Widget Tests', () {
    const testCluster = NeighborhoodCluster(
      id: 'c-breadly',
      centroidLat: 41.3111,
      centroidLng: 69.2405,
      district: 'Mirabad',
      intensity: ClusterIntensity.buzzing,
      dropsCount: 7,
      venueNames: ['Breadly Bakery & Café', 'Ecocafe'],
      primaryVenueName: 'Breadly Bakery & Café',
    );

    testWidgets('renders cluster badge details and handles tap callback', (tester) async {
      NeighborhoodCluster? tappedCluster;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeighborhoodClusterOverlayWidget(
                cluster: testCluster,
                locale: 'en',
                onClusterTap: (c) => tappedCluster = c,
              ),
            ),
          ),
        ),
      );

      // Verify venue name & intensity emoji
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
      expect(find.text('Buzzing Hotspot'), findsOneWidget);

      // Verify summary and drops count badge
      expect(
        find.text('7 drops across Breadly Bakery & Café & nearby'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('cluster_drops_count_badge')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('cluster_drops_count_badge'))).data,
        equals('7'),
      );

      // Tap on cluster
      await tester.tap(find.byKey(const Key('neighborhood_cluster_pill_c-breadly')));
      await tester.pump();

      expect(tappedCluster?.id, equals('c-breadly'));
      expect(tappedCluster?.primaryVenueName, equals('Breadly Bakery & Café'));
    });

    testWidgets('respects Uzbek and Russian localizations', (tester) async {
      // Uzbek localization
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeighborhoodClusterOverlayWidget(
                cluster: testCluster,
                locale: 'uz',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Qaynoq Nuqta'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café va yaqinida 7 ta drop'), findsOneWidget);

      // Russian localization
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeighborhoodClusterOverlayWidget(
                cluster: testCluster,
                locale: 'ru',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Бурлящая точка'), findsOneWidget);
      expect(find.text('7 дроп(ов) в районе Breadly Bakery & Café и рядом'), findsOneWidget);
    });

    testWidgets('renders serene and peak intensity clusters appropriately', (tester) async {
      const sereneCluster = NeighborhoodCluster(
        id: 'c-serene',
        centroidLat: 41.3150,
        centroidLng: 69.2450,
        district: 'Yakkasaray',
        intensity: ClusterIntensity.serene,
        dropsCount: 2,
        venueNames: ['Courtyard Park'],
        primaryVenueName: 'Courtyard Park',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeighborhoodClusterOverlayWidget(
                cluster: sereneCluster,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('🍃'), findsOneWidget);
      expect(find.text('Serene Spot'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('cluster_drops_count_badge'))).data,
        equals('2'),
      );
    });
  });
}
