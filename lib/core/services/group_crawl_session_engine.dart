import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrawlParticipant {
  final String userId;
  final String name;
  final String avatarInitials;
  final String? currentPlaceId;
  final Set<String> visitedStopIds;
  final DateTime lastActive;
  final bool isHost;

  const CrawlParticipant({
    required this.userId,
    required this.name,
    required this.avatarInitials,
    this.currentPlaceId,
    this.visitedStopIds = const {},
    required this.lastActive,
    this.isHost = false,
  });

  CrawlParticipant copyWith({
    String? currentPlaceId,
    Set<String>? visitedStopIds,
    DateTime? lastActive,
    bool? isHost,
  }) {
    return CrawlParticipant(
      userId: userId,
      name: name,
      avatarInitials: avatarInitials,
      currentPlaceId: currentPlaceId ?? this.currentPlaceId,
      visitedStopIds: visitedStopIds ?? this.visitedStopIds,
      lastActive: lastActive ?? this.lastActive,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'name': name,
    'avatar_initials': avatarInitials,
    'current_place_id': currentPlaceId,
    'visited_stop_ids': visitedStopIds.toList(),
    'last_active': lastActive.toIso8601String(),
    'is_host': isHost,
  };

  factory CrawlParticipant.fromJson(Map<String, dynamic> json) => CrawlParticipant(
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    avatarInitials: json['avatar_initials']?.toString() ?? 'U',
    currentPlaceId: json['current_place_id']?.toString(),
    visitedStopIds: (json['visited_stop_ids'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {},
    lastActive: json['last_active'] != null
        ? DateTime.tryParse(json['last_active'].toString()) ?? DateTime.now()
        : DateTime.now(),
    isHost: json['is_host'] == true,
  );
}

class GroupCrawlSession {
  final String sessionCode;
  final String routeId;
  final String routeTitle;
  final String hostUserId;
  final List<CrawlParticipant> participants;
  final DateTime createdAt;
  final bool isActive;
  final int squadBonusXp;

  const GroupCrawlSession({
    required this.sessionCode,
    required this.routeId,
    required this.routeTitle,
    required this.hostUserId,
    required this.participants,
    required this.createdAt,
    this.isActive = true,
    this.squadBonusXp = 200,
  });

  GroupCrawlSession copyWith({
    List<CrawlParticipant>? participants,
    bool? isActive,
  }) {
    return GroupCrawlSession(
      sessionCode: sessionCode,
      routeId: routeId,
      routeTitle: routeTitle,
      hostUserId: hostUserId,
      participants: participants ?? this.participants,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      squadBonusXp: squadBonusXp,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_code': sessionCode,
    'route_id': routeId,
    'route_title': routeTitle,
    'host_user_id': hostUserId,
    'participants': participants.map((p) => p.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
    'squad_bonus_xp': squadBonusXp,
  };

  factory GroupCrawlSession.fromJson(Map<String, dynamic> json) => GroupCrawlSession(
    sessionCode: json['session_code']?.toString() ?? '',
    routeId: json['route_id']?.toString() ?? '',
    routeTitle: json['route_title']?.toString() ?? '',
    hostUserId: json['host_user_id']?.toString() ?? '',
    participants: (json['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CrawlParticipant.fromJson)
            .toList() ??
        [],
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
    isActive: json['is_active'] ?? true,
    squadBonusXp: (json['squad_bonus_xp'] as num?)?.toInt() ?? 200,
  );
}

class CollectiveProgress {
  final int totalRouteStops;
  final int stopsCoveredByGroup;
  final int stopsCoveredByAll;
  final int completionPercentage;
  final bool isSquadComplete;
  final Map<String, List<String>> activeStopParticipants;

  const CollectiveProgress({
    required this.totalRouteStops,
    required this.stopsCoveredByGroup,
    required this.stopsCoveredByAll,
    required this.completionPercentage,
    required this.isSquadComplete,
    required this.activeStopParticipants,
  });
}

class GroupCrawlSessionEngine {
  static String generateSessionCode([String districtPrefix = 'MRB']) {
    final randomNum = (10 + math.Random().nextInt(90)).toString();
    final cleanPrefix = districtPrefix.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = cleanPrefix.length >= 3 ? cleanPrefix.substring(0, 3) : 'TAS';
    return 'CR-$prefix-$randomNum';
  }

  static GroupCrawlSession createSession({
    required String routeId,
    required String routeTitle,
    required String hostUserId,
    required String hostName,
    required String hostInitials,
    String districtPrefix = 'MRB',
  }) {
    final now = DateTime.now();
    final host = CrawlParticipant(
      userId: hostUserId,
      name: hostName,
      avatarInitials: hostInitials,
      lastActive: now,
      isHost: true,
    );

    return GroupCrawlSession(
      sessionCode: generateSessionCode(districtPrefix),
      routeId: routeId,
      routeTitle: routeTitle,
      hostUserId: hostUserId,
      participants: [host],
      createdAt: now,
      isActive: true,
      squadBonusXp: 200,
    );
  }

  static GroupCrawlSession joinSession(
    GroupCrawlSession session, {
    required String userId,
    required String name,
    required String initials,
  }) {
    if (session.participants.any((p) => p.userId == userId)) {
      return session;
    }

    final newParticipant = CrawlParticipant(
      userId: userId,
      name: name,
      avatarInitials: initials,
      lastActive: DateTime.now(),
      isHost: false,
    );

    return session.copyWith(
      participants: [...session.participants, newParticipant],
    );
  }

  static GroupCrawlSession recordCheckIn(
    GroupCrawlSession session, {
    required String userId,
    required String placeId,
  }) {
    final now = DateTime.now();
    final updatedParticipants = session.participants.map((p) {
      if (p.userId == userId) {
        final newVisited = {...p.visitedStopIds, placeId};
        return p.copyWith(
          currentPlaceId: placeId,
          visitedStopIds: newVisited,
          lastActive: now,
        );
      }
      return p;
    }).toList();

    return session.copyWith(participants: updatedParticipants);
  }

  static CollectiveProgress calculateProgress(
    GroupCrawlSession session,
    List<String> routeStopPlaceIds,
  ) {
    if (routeStopPlaceIds.isEmpty || session.participants.isEmpty) {
      return const CollectiveProgress(
        totalRouteStops: 0,
        stopsCoveredByGroup: 0,
        stopsCoveredByAll: 0,
        completionPercentage: 0,
        isSquadComplete: false,
        activeStopParticipants: {},
      );
    }

    final totalStops = routeStopPlaceIds.length;
    final groupVisited = <String>{};
    final activeStopMap = <String, List<String>>{};

    for (final p in session.participants) {
      groupVisited.addAll(p.visitedStopIds);
      if (p.currentPlaceId != null) {
        activeStopMap.putIfAbsent(p.currentPlaceId!, () => []).add(p.name);
      }
    }

    final stopsCoveredByGroup = routeStopPlaceIds.where(groupVisited.contains).length;

    // Stops visited by every participant in the group
    int stopsCoveredByAll = 0;
    for (final stopId in routeStopPlaceIds) {
      final visitedByEveryone = session.participants.every((p) => p.visitedStopIds.contains(stopId));
      if (visitedByEveryone) {
        stopsCoveredByAll += 1;
      }
    }

    final percentage = ((stopsCoveredByGroup / totalStops) * 100).round();
    final isSquadComplete = stopsCoveredByAll == totalStops;

    return CollectiveProgress(
      totalRouteStops: totalStops,
      stopsCoveredByGroup: stopsCoveredByGroup,
      stopsCoveredByAll: stopsCoveredByAll,
      completionPercentage: percentage,
      isSquadComplete: isSquadComplete,
      activeStopParticipants: activeStopMap,
    );
  }
}

final groupCrawlEngineProvider = Provider<GroupCrawlSessionEngine>((ref) {
  return GroupCrawlSessionEngine();
});
