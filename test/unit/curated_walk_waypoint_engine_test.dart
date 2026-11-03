import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_walk_waypoint_engine.dart';

void main() {
  group('P35-01: CuratedWalkWaypointEngine Unit Tests', () {
    late CuratedWalkWaypointEngine engine;

    setUp(() {
      engine = CuratedWalkWaypointEngine();
    });

    final testWaypoints = [
      const RouteWaypoint(
        id: 'wp-1',
        routeId: 'rt-chorsu',
        placeId: 'pl-chorsu-bazaar',
        placeName: 'Chorsu Bazaar Dome',
        orderIndex: 0,
        category: 'Heritage',
        hint: 'Find the blue dome spice pavilion',
        xpAwarded: 20,
      ),
      const RouteWaypoint(
        id: 'wp-2',
        routeId: 'rt-chorsu',
        placeId: 'pl-kukeldash',
        placeName: 'Kukeldash Madrasah',
        orderIndex: 1,
        category: 'Architecture',
        hint: 'Admire the tilework at the portal',
        xpAwarded: 20,
      ),
      const RouteWaypoint(
        id: 'wp-3',
        routeId: 'rt-chorsu',
        placeId: 'pl-chorsu-plov',
        placeName: 'Chorsu National Plov Center',
        orderIndex: 2,
        category: 'Gastronomy',
        hint: 'Taste wedding plov with kazy',
        xpAwarded: 25,
      ),
      const RouteWaypoint(
        id: 'wp-4',
        routeId: 'rt-chorsu',
        placeId: 'pl-chorsu-tea',
        placeName: 'Chaikhana Samarkand',
        orderIndex: 3,
        category: 'Tea House',
        hint: 'Sip Kok choy on the tapchan',
        xpAwarded: 15,
      ),
    ];

    test('serializes and deserializes RouteWaypoint cleanly', () {
      final json = testWaypoints[0].toJson();
      final parsed = RouteWaypoint.fromJson(json);

      expect(parsed.id, equals('wp-1'));
      expect(parsed.placeName, equals('Chorsu Bazaar Dome'));
      expect(parsed.orderIndex, equals(0));
      expect(parsed.xpAwarded, equals(20));
      expect(parsed.category, equals('Heritage'));
    });

    test('handles empty waypoints cleanly', () {
      final summary = engine.evaluateProgress(
        routeId: 'rt-empty',
        routeName: 'Empty Trail',
        district: 'Mirabad',
        waypoints: [],
        visitedPlaceIds: {},
      );

      expect(summary.totalWaypointsCount, equals(0));
      expect(summary.visitedWaypointsCount, equals(0));
      expect(summary.completionPercentage, equals(0.0));
      expect(summary.isCompleted, isFalse);
      expect(summary.nextTargetWaypoint, isNull);
    });

    test('calculates partial progress and identifies next target stop', () {
      // User visited stop 0 and stop 1
      final visited = {'pl-chorsu-bazaar', 'pl-kukeldash'};

      final summary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: visited,
        completionBonusXp: 50,
      );

      expect(summary.totalWaypointsCount, equals(4));
      expect(summary.visitedWaypointsCount, equals(2));
      expect(summary.completionPercentage, equals(0.50));
      expect(summary.isCompleted, isFalse);
      // Next target should be stop #2
      expect(summary.nextTargetWaypoint, isNotNull);
      expect(summary.nextTargetWaypoint!.placeName, equals('Chorsu National Plov Center'));
      // XP: 20 + 20 = 40 (no bonus yet)
      expect(summary.totalXpEarned, equals(40));
    });

    test('awards completion bonus when all waypoints are visited', () {
      final allVisited = {
        'pl-chorsu-bazaar',
        'pl-kukeldash',
        'pl-chorsu-plov',
        'pl-chorsu-tea',
      };

      final summary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: allVisited,
        completionBonusXp: 50,
      );

      expect(summary.visitedWaypointsCount, equals(4));
      expect(summary.completionPercentage, equals(1.0));
      expect(summary.isCompleted, isTrue);
      expect(summary.nextTargetWaypoint, isNull);
      // Total XP = 20 + 20 + 25 + 15 + 50 (bonus) = 130
      expect(summary.totalXpEarned, equals(130));
    });

    test('formats localized titles and next target prompts', () {
      // Partial summary
      final partialSummary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: {'pl-chorsu-bazaar'},
      );

      expect(
        engine.formatProgressTitle(partialSummary, locale: 'en'),
        equals('1 of 4 stops completed'),
      );
      expect(
        engine.formatProgressTitle(partialSummary, locale: 'uz'),
        equals('4 tadan 1 ta bekat bajarildi'),
      );
      expect(
        engine.formatProgressTitle(partialSummary, locale: 'ru'),
        equals('Пройдено 1 из 4 остановок'),
      );

      // Completed summary
      final completedSummary = engine.evaluateProgress(
        routeId: 'rt-chorsu',
        routeName: 'Chorsu Heritage Trail',
        district: 'Shaikhontokhur',
        waypoints: testWaypoints,
        visitedPlaceIds: {
          'pl-chorsu-bazaar',
          'pl-kukeldash',
          'pl-chorsu-plov',
          'pl-chorsu-tea',
        },
      );

      expect(
        engine.formatProgressTitle(completedSummary, locale: 'en'),
        equals('Route completed! 🏆'),
      );
      expect(
        engine.formatProgressTitle(completedSummary, locale: 'uz'),
        equals('Marshrut yakunlandi! 🏆'),
      );
      expect(
        engine.formatProgressTitle(completedSummary, locale: 'ru'),
        equals('Маршрут пройден! 🏆'),
      );

      // Next target prompts
      expect(
        engine.formatNextTargetPrompt(partialSummary.nextTargetWaypoint, locale: 'en'),
        equals('Next stop: Kukeldash Madrasah'),
      );
      expect(
        engine.formatNextTargetPrompt(null, locale: 'en'),
        equals('All checkpoints explored!'),
      );
      expect(
        engine.formatNextTargetPrompt(null, locale: 'uz'),
        equals('Barcha bekatlar ziyorat qilindi!'),
      );
    });

    test('Riverpod provider initializes CuratedWalkWaypointEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(curatedWalkWaypointEngineProvider);
      expect(service, isA<CuratedWalkWaypointEngine>());
    });
  });
}
