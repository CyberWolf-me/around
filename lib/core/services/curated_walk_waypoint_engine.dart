import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A sequential checkpoint/stop along a curated Tashkent crawl route.
class RouteWaypoint {
  final String id;
  final String routeId;
  final String placeId;
  final String placeName;
  final int orderIndex;
  final String category;
  final String hint;
  final int xpAwarded;

  const RouteWaypoint({
    required this.id,
    required this.routeId,
    required this.placeId,
    required this.placeName,
    required this.orderIndex,
    required this.category,
    required this.hint,
    this.xpAwarded = 15,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'route_id': routeId,
    'place_id': placeId,
    'place_name': placeName,
    'order_index': orderIndex,
    'category': category,
    'hint': hint,
    'xp_awarded': xpAwarded,
  };

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      id: json['id'] as String? ?? '',
      routeId: json['route_id'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      placeName: json['place_name'] as String? ?? 'Place',
      orderIndex: json['order_index'] as int? ?? 0,
      category: json['category'] as String? ?? 'General',
      hint: json['hint'] as String? ?? '',
      xpAwarded: json['xp_awarded'] as int? ?? 15,
    );
  }
}

/// A route waypoint paired with user verification status.
class WaypointWithStatus {
  final RouteWaypoint waypoint;
  final bool isVisited;
  final DateTime? visitedAt;
  final String? dropId;

  const WaypointWithStatus({
    required this.waypoint,
    required this.isVisited,
    this.visitedAt,
    this.dropId,
  });
}

/// Detailed evaluation of a user's progress through a curated walk route.
class RouteProgressSummary {
  final String routeId;
  final String routeName;
  final String district;
  final int totalWaypointsCount;
  final int visitedWaypointsCount;
  final double completionPercentage;
  final bool isCompleted;
  final RouteWaypoint? nextTargetWaypoint;
  final int totalXpEarned;
  final int completionBonusXp;
  final List<WaypointWithStatus> waypointsWithStatus;

  const RouteProgressSummary({
    required this.routeId,
    required this.routeName,
    required this.district,
    required this.totalWaypointsCount,
    required this.visitedWaypointsCount,
    required this.completionPercentage,
    required this.isCompleted,
    this.nextTargetWaypoint,
    required this.totalXpEarned,
    required this.completionBonusXp,
    required this.waypointsWithStatus,
  });
}

/// Computes sequential checkpoint verification, progress percentages, and waypoint badges.
class CuratedWalkWaypointEngine {
  /// Evaluates user completion status across ordered waypoints for a route.
  RouteProgressSummary evaluateProgress({
    required String routeId,
    required String routeName,
    required String district,
    required List<RouteWaypoint> waypoints,
    required Set<String> visitedPlaceIds,
    int completionBonusXp = 50,
  }) {
    if (waypoints.isEmpty) {
      return RouteProgressSummary(
        routeId: routeId,
        routeName: routeName,
        district: district,
        totalWaypointsCount: 0,
        visitedWaypointsCount: 0,
        completionPercentage: 0.0,
        isCompleted: false,
        nextTargetWaypoint: null,
        totalXpEarned: 0,
        completionBonusXp: completionBonusXp,
        waypointsWithStatus: const [],
      );
    }

    // Ensure waypoints are sorted by sequential orderIndex
    final sorted = List<RouteWaypoint>.from(waypoints)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final evaluatedWaypoints = <WaypointWithStatus>[];
    int visitedCount = 0;
    int xpAccumulated = 0;
    RouteWaypoint? nextTarget;

    for (final wp in sorted) {
      final isVisited = visitedPlaceIds.contains(wp.placeId);
      if (isVisited) {
        visitedCount++;
        xpAccumulated += wp.xpAwarded;
      } else {
        nextTarget ??= wp;
      }

      evaluatedWaypoints.add(WaypointWithStatus(
        waypoint: wp,
        isVisited: isVisited,
      ));
    }

    final isAllCompleted = visitedCount == sorted.length && sorted.isNotEmpty;
    if (isAllCompleted) {
      xpAccumulated += completionBonusXp;
    }

    final percentage = sorted.isNotEmpty ? visitedCount / sorted.length : 0.0;

    return RouteProgressSummary(
      routeId: routeId,
      routeName: routeName,
      district: district,
      totalWaypointsCount: sorted.length,
      visitedWaypointsCount: visitedCount,
      completionPercentage: percentage,
      isCompleted: isAllCompleted,
      nextTargetWaypoint: nextTarget,
      totalXpEarned: xpAccumulated,
      completionBonusXp: completionBonusXp,
      waypointsWithStatus: evaluatedWaypoints,
    );
  }

  /// Formats trilingual progress title.
  String formatProgressTitle(RouteProgressSummary summary, {String locale = 'en'}) {
    final lang = locale.toLowerCase();

    if (summary.isCompleted) {
      if (lang.startsWith('uz')) return 'Marshrut yakunlandi! 🏆';
      if (lang.startsWith('ru')) return 'Маршрут пройден! 🏆';
      return 'Route completed! 🏆';
    }

    if (lang.startsWith('uz')) {
      return '${summary.totalWaypointsCount} tadan ${summary.visitedWaypointsCount} ta bekat bajarildi';
    } else if (lang.startsWith('ru')) {
      return 'Пройдено ${summary.visitedWaypointsCount} из ${summary.totalWaypointsCount} остановок';
    }
    return '${summary.visitedWaypointsCount} of ${summary.totalWaypointsCount} stops completed';
  }

  /// Formats trilingual prompt for next target stop.
  String formatNextTargetPrompt(RouteWaypoint? nextTarget, {String locale = 'en'}) {
    if (nextTarget == null) {
      final lang = locale.toLowerCase();
      if (lang.startsWith('uz')) return 'Barcha bekatlar ziyorat qilindi!';
      if (lang.startsWith('ru')) return 'Все остановки исследованы!';
      return 'All checkpoints explored!';
    }

    final lang = locale.toLowerCase();
    if (lang.startsWith('uz')) {
      return 'Navbatdagi bekat: ${nextTarget.placeName}';
    } else if (lang.startsWith('ru')) {
      return 'Следующая цель: ${nextTarget.placeName}';
    }
    return 'Next stop: ${nextTarget.placeName}';
  }
}

final curatedWalkWaypointEngineProvider = Provider<CuratedWalkWaypointEngine>((ref) {
  return CuratedWalkWaypointEngine();
});
