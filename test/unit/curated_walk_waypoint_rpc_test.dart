import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_walk_waypoint_engine.dart';
import 'package:around_app/data/repositories/curated_walk_waypoint_repository.dart';

void main() {
  group('P35-04: Curated Walk Waypoint RPC & Migration Tests', () {
    test('migration 00026_curated_walk_waypoints.sql is syntactically hardened', () {
      final file = File('supabase/migrations/00026_curated_walk_waypoints.sql');
      expect(file.existsSync(), isTrue);

      final sql = file.readAsStringSync();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.route_waypoint_checkins'));
      expect(sql, contains('ENABLE ROW LEVEL SECURITY'));
      expect(sql, contains('CREATE OR REPLACE FUNCTION public.record_route_waypoint_progress'));
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('SET search_path = public, extensions'));
      expect(sql, contains('GRANT EXECUTE ON FUNCTION public.record_route_waypoint_progress(UUID, UUID, INTEGER, INTEGER) TO authenticated;'));
      expect(sql, contains('auth.uid() = user_id'));
    });

    test('CuratedWalkWaypointRepository manages offline checkins cleanly', () async {
      final repo = CuratedWalkWaypointRepository();
      repo.clearOfflineCache();

      final waypoints = [
        const RouteWaypoint(
          id: 'wp-1',
          routeId: 'rt-1',
          placeId: 'pl-dome',
          placeName: 'Chorsu Dome',
          orderIndex: 0,
          category: 'Heritage',
          hint: 'Central market dome',
          xpAwarded: 20,
        ),
        const RouteWaypoint(
          id: 'wp-2',
          routeId: 'rt-1',
          placeId: 'pl-kukeldash',
          placeName: 'Kukeldash',
          orderIndex: 1,
          category: 'Architecture',
          hint: 'Madrasah portal',
          xpAwarded: 25,
        ),
      ];

      // Initial progress: 0 completed
      var summary = await repo.getRouteProgress(
        routeId: 'rt-1',
        routeName: 'Heritage Route',
        district: 'Shaikhontokhur',
        waypoints: waypoints,
      );
      expect(summary.visitedWaypointsCount, equals(0));
      expect(summary.isCompleted, isFalse);
      expect(summary.nextTargetWaypoint?.id, equals('wp-1'));

      // Check in to first stop
      final success1 = await repo.recordWaypointCheckin(
        routeId: 'rt-1',
        placeId: 'pl-dome',
      );
      expect(success1, isTrue);

      summary = await repo.getRouteProgress(
        routeId: 'rt-1',
        routeName: 'Heritage Route',
        district: 'Shaikhontokhur',
        waypoints: waypoints,
      );
      expect(summary.visitedWaypointsCount, equals(1));
      expect(summary.nextTargetWaypoint?.id, equals('wp-2'));
      expect(summary.totalXpEarned, equals(20));

      // Check in to second stop (completing route)
      final success2 = await repo.recordWaypointCheckin(
        routeId: 'rt-1',
        placeId: 'pl-kukeldash',
      );
      expect(success2, isTrue);

      summary = await repo.getRouteProgress(
        routeId: 'rt-1',
        routeName: 'Heritage Route',
        district: 'Shaikhontokhur',
        waypoints: waypoints,
        completionBonusXp: 50,
      );
      expect(summary.visitedWaypointsCount, equals(2));
      expect(summary.isCompleted, isTrue);
      expect(summary.nextTargetWaypoint, isNull);
      // 20 + 25 + 50 (bonus) = 95 XP
      expect(summary.totalXpEarned, equals(95));
    });

    test('Riverpod provider initializes CuratedWalkWaypointRepository cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(curatedWalkWaypointRepositoryProvider);
      expect(repo, isA<CuratedWalkWaypointRepository>());
    });
  });
}
