import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_route_engine.dart';

void main() {
  group('P25-01: CuratedRouteEngine Unit Tests', () {
    test('getAllRoutes returns at least 3 curated Tashkent routes with stops', () {
      final routes = CuratedRouteEngine.getAllRoutes();
      expect(routes.length, greaterThanOrEqualTo(3));

      for (final route in routes) {
        expect(route.id, isNotEmpty);
        expect(route.title, isNotEmpty);
        expect(route.district, isNotEmpty);
        expect(route.stops, isNotEmpty);
        expect(route.totalEstimatedMinutes, greaterThan(0));
        expect(route.totalDistanceMeters, greaterThan(0));
        expect(route.startSubway, isNotEmpty);
        expect(route.endSubway, isNotEmpty);
        expect(route.xpReward, greaterThanOrEqualTo(100));
      }
    });

    test('RouteStop and CuratedRoute serialize to json accurately', () {
      const stop = RouteStop(
        placeId: 'place_breadly',
        name: 'Breadly Bakery & Café',
        district: 'Mirabad',
        latitude: 41.2985,
        longitude: 69.2741,
        recommendedOrder: 1,
        atmosphereTag: 'Morning Brew',
        nearestSubway: 'Oybek',
        walkingMinutesFromPrevious: 0,
      );

      final stopJson = stop.toJson();
      expect(stopJson['place_id'], equals('place_breadly'));
      expect(stopJson['nearest_subway'], equals('Oybek'));

      final parsedStop = RouteStop.fromJson(stopJson);
      expect(parsedStop.placeId, equals(stop.placeId));
      expect(parsedStop.latitude, equals(stop.latitude));

      final route = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl');
      expect(route, isNotNull);

      final routeJson = route!.toJson();
      expect(routeJson['id'], equals('mirabad_coffee_crawl'));
      expect(routeJson['stops'], isList);
      expect((routeJson['stops'] as List).length, equals(3));
    });

    test('getRouteById returns accurate route or null', () {
      final coffeeRoute = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl');
      expect(coffeeRoute, isNotNull);
      expect(coffeeRoute?.district, equals('Mirabad'));

      final missing = CuratedRouteEngine.getRouteById('non_existent_route');
      expect(missing, isNull);
    });

    test('getRoutesForDistrict filters routes accurately', () {
      final mirabadRoutes = CuratedRouteEngine.getRoutesForDistrict('Mirabad');
      expect(mirabadRoutes.length, equals(1));
      expect(mirabadRoutes.first.id, equals('mirabad_coffee_crawl'));

      final empty = CuratedRouteEngine.getRoutesForDistrict('Chilanzar');
      expect(empty, isEmpty);
    });

    test('computeProgress accurately tracks 0%, 33%, and 100% completion', () {
      final route = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl')!;

      // 0% visited
      final reportZero = CuratedRouteEngine.computeProgress(route, {});
      expect(reportZero.completedStops, equals(0));
      expect(reportZero.completionPercentage, equals(0));
      expect(reportZero.isCompleted, isFalse);
      expect(reportZero.nextPendingStop?.placeId, equals('place_breadly'));

      // Partial visit (1 of 3 stops = 33%)
      final reportPartial = CuratedRouteEngine.computeProgress(route, {'place_breadly'});
      expect(reportPartial.completedStops, equals(1));
      expect(reportPartial.completionPercentage, equals(33));
      expect(reportPartial.isCompleted, isFalse);
      expect(reportPartial.nextPendingStop?.placeId, equals('place_socials'));

      // 100% completion
      final reportFull = CuratedRouteEngine.computeProgress(
        route,
        {'place_breadly', 'place_socials', 'place_ekler'},
      );
      expect(reportFull.completedStops, equals(3));
      expect(reportFull.completionPercentage, equals(100));
      expect(reportFull.isCompleted, isTrue);
      expect(reportFull.nextPendingStop, isNull);
    });

    test('calculateDistanceMeters and estimateWalkingMinutes compute urban metrics', () {
      // Breadly (41.2985, 69.2741) to Socials (41.3005, 69.2770) ~330m
      final dist = CuratedRouteEngine.calculateDistanceMeters(
        41.2985,
        69.2741,
        41.3005,
        69.2770,
      );
      expect(dist, inInclusiveRange(300, 360));

      final walkingMinutes = CuratedRouteEngine.estimateWalkingMinutes(dist);
      expect(walkingMinutes, inInclusiveRange(4, 5));

      expect(CuratedRouteEngine.estimateWalkingMinutes(0), equals(0));
    });

    test('getLocalizedTitle translates accurately across languages', () {
      final route = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl')!;

      expect(CuratedRouteEngine.getLocalizedTitle(route, 'uz'), equals('Mirobod Qahva Sayri'));
      expect(CuratedRouteEngine.getLocalizedTitle(route, 'ru'), equals('Кофейный маршрут по Мирабаду'));
      expect(CuratedRouteEngine.getLocalizedTitle(route, 'en'), equals('Mirabad Specialty Coffee Crawl'));
    });

    test('Riverpod curatedRouteEngineProvider and allCuratedRoutesProvider expose routes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final routes = container.read(allCuratedRoutesProvider);
      expect(routes.length, greaterThanOrEqualTo(3));
      expect(routes.first.id, equals('mirabad_coffee_crawl'));
    });
  });
}
