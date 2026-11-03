import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_route_engine.dart';
import 'package:around_app/features/explore/widgets/curated_route_card.dart';

void main() {
  group('P25-02: CuratedRouteCard Widget Tests', () {
    final testRoute = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl')!;

    testWidgets('renders route header, badges, walking duration, and metro connectors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratedRouteCard(
              route: testRoute,
              visitedPlaceIds: const {'place_breadly'},
              languageCode: 'en',
            ),
          ),
        ),
      );

      expect(find.text('☕'), findsOneWidget);
      expect(find.text('MIRABAD'), findsOneWidget);
      expect(find.text('+150 XP'), findsOneWidget);
      expect(find.text('Mirabad Specialty Coffee Crawl'), findsOneWidget);
      expect(find.text('The golden triangle of Tashkent morning coffee and pastry craft'), findsOneWidget);
      expect(find.text('12 min (850m)'), findsOneWidget);
      expect(find.text('3 stops'), findsOneWidget);
      expect(find.text('Oybek'), findsOneWidget);
      expect(find.text('Kosmonavtlar'), findsOneWidget);
      expect(find.text('1/3 visited'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('Start Crawl'), findsOneWidget);
    });

    testWidgets('expands and collapses stop timeline on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratedRouteCard(
                route: testRoute,
                initiallyExpanded: false,
                visitedPlaceIds: const {'place_breadly'},
              ),
            ),
          ),
        ),
      );

      // Initially collapsed: stops not visible in timeline
      expect(find.text('Breadly Bakery & Café'), findsNothing);

      // Tap header to expand
      await tester.tap(find.text('Mirabad Specialty Coffee Crawl'));
      await tester.pumpAndSettle();

      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('Socials Coffee Hub'), findsOneWidget);
      expect(find.text('Ekler Patisserie'), findsOneWidget);
      expect(find.text('Next Stop'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Mirabad Specialty Coffee Crawl'));
      await tester.pumpAndSettle();

      expect(find.text('Breadly Bakery & Café'), findsNothing);
    });

    testWidgets('triggers onSelectStop when stop row is tapped', (tester) async {
      RouteStop? selectedStop;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratedRouteCard(
                route: testRoute,
                initiallyExpanded: true,
                onSelectStop: (s) => selectedStop = s,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('stop_row_place_socials')));
      await tester.pumpAndSettle();

      expect(selectedStop, isNotNull);
      expect(selectedStop?.placeId, equals('place_socials'));
      expect(selectedStop?.name, equals('Socials Coffee Hub'));
    });

    testWidgets('triggers onStartRoute when footer button is tapped', (tester) async {
      CuratedRoute? startedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratedRouteCard(
              route: testRoute,
              onStartRoute: (r) => startedRoute = r,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(Key('start_route_btn_${testRoute.id}')));
      await tester.pumpAndSettle();

      expect(startedRoute, isNotNull);
      expect(startedRoute?.id, equals('mirabad_coffee_crawl'));
    });

    testWidgets('renders route completion badge when all stops are visited', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratedRouteCard(
              route: testRoute,
              visitedPlaceIds: const {'place_breadly', 'place_socials', 'place_ekler'},
            ),
          ),
        ),
      );

      expect(find.text('3/3 visited'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Route Completed 🏆'), findsOneWidget);
    });

    testWidgets('supports Uzbek and Russian localizations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratedRouteCard(
              route: testRoute,
              languageCode: 'uz',
            ),
          ),
        ),
      );
      expect(find.text('Mirobod Qahva Sayri'), findsOneWidget);
      expect(find.text('Sayrni Boshlash'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratedRouteCard(
              route: testRoute,
              languageCode: 'ru',
            ),
          ),
        ),
      );
      expect(find.text('Кофейный маршрут по Мирабаду'), findsOneWidget);
      expect(find.text('Начать маршрут'), findsOneWidget);
    });
  });
}
