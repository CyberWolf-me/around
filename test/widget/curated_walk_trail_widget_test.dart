import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_walk_waypoint_engine.dart';
import 'package:around_app/features/explore/widgets/curated_walk_trail_widget.dart';

void main() {
  group('P35-02: CuratedWalkTrailWidget Widget Tests', () {
    final testWaypoints = [
      const RouteWaypoint(
        id: 'wp-1',
        routeId: 'rt-chorsu',
        placeId: 'pl-1',
        placeName: 'Chorsu Bazaar Dome',
        orderIndex: 0,
        category: 'Heritage',
        hint: 'Find the blue dome spice pavilion',
        xpAwarded: 20,
      ),
      const RouteWaypoint(
        id: 'wp-2',
        routeId: 'rt-chorsu',
        placeId: 'pl-2',
        placeName: 'Kukeldash Madrasah',
        orderIndex: 1,
        category: 'Architecture',
        hint: 'Admire the tilework at the portal',
        xpAwarded: 25,
      ),
      const RouteWaypoint(
        id: 'wp-3',
        routeId: 'rt-chorsu',
        placeId: 'pl-3',
        placeName: 'Chaikhana Samarkand',
        orderIndex: 2,
        category: 'Tea House',
        hint: 'Sip Kok choy on the tapchan',
        xpAwarded: 15,
      ),
    ];

    testWidgets('renders partial progress stepper and handles taps', (tester) async {
      RouteWaypoint? tappedWaypoint;

      final engine = CuratedWalkWaypointEngine();
      final summary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: {'pl-1'}, // Visited stop 1 only
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratedWalkTrailWidget(
                summary: summary,
                locale: 'en',
                onWaypointTap: (wp) => tappedWaypoint = wp,
              ),
            ),
          ),
        ),
      );

      // Verify route name & header
      expect(find.text('Chorsu Heritage Trail'), findsOneWidget);
      expect(find.text('Shaikhontokhur • 1 of 3 stops completed'), findsOneWidget);
      expect(find.byKey(const Key('total_xp_badge_text')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('total_xp_badge_text'))).data,
        equals('+20 XP'),
      );

      // Verify waypoints
      expect(find.text('Chorsu Bazaar Dome'), findsOneWidget);
      expect(find.text('Kukeldash Madrasah'), findsOneWidget);
      expect(find.text('Chaikhana Samarkand'), findsOneWidget);

      // Tap on Kukeldash Madrasah (next target)
      await tester.tap(find.byKey(const Key('waypoint_item_wp-2')));
      await tester.pump();

      expect(tappedWaypoint?.id, equals('wp-2'));
      expect(tappedWaypoint?.placeName, equals('Kukeldash Madrasah'));
    });

    testWidgets('renders completed route celebration banner with bonus XP', (tester) async {
      final engine = CuratedWalkWaypointEngine();
      final summary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: {'pl-1', 'pl-2', 'pl-3'}, // All visited
        completionBonusXp: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratedWalkTrailWidget(
                summary: summary,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Shaikhontokhur • Route completed! 🏆'), findsOneWidget);
      // Total XP = 20 + 25 + 15 + 50 = 110 XP
      expect(find.text('+110 XP'), findsOneWidget);

      // Completion callout
      expect(
        find.text('Route Completed! +50 Bonus XP Awarded'),
        findsOneWidget,
      );

      // Russian localization check
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratedWalkTrailWidget(
                summary: summary,
                locale: 'ru',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Поздравляем! Маршрут завершен (+50 бонусных XP)'),
        findsOneWidget,
      );
    });
  });
}
