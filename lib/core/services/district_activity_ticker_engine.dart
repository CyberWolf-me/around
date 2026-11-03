import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported types of ambient district activity.
enum DistrictActivityType {
  dropCreated,
  routeCompleted,
  crownOvertake,
  badgeUnlocked,
  placeVisited,
}

/// A sanitized, privacy-safe ambient district activity event in Tashkent.
class DistrictActivityEvent {
  final String id;
  final DistrictActivityType type;
  final String userId;
  final String username;
  final String userFullName;
  final String? userAvatarUrl;
  final String district;
  final String? placeName;
  final String? placeId;
  final String? routeName;
  final String? routeId;
  final String? badgeName;
  final int? xpAwarded;
  final DateTime timestamp;

  const DistrictActivityEvent({
    required this.id,
    required this.type,
    required this.userId,
    required this.username,
    required this.userFullName,
    this.userAvatarUrl,
    required this.district,
    this.placeName,
    this.placeId,
    this.routeName,
    this.routeId,
    this.badgeName,
    this.xpAwarded,
    required this.timestamp,
  });

  String get initials {
    final parts = userFullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CR';
  }

  String get iconEmoji {
    switch (type) {
      case DistrictActivityType.dropCreated:
        return '📸';
      case DistrictActivityType.routeCompleted:
        return '🚶';
      case DistrictActivityType.crownOvertake:
        return '👑';
      case DistrictActivityType.badgeUnlocked:
        return '🎖️';
      case DistrictActivityType.placeVisited:
        return '📍';
    }
  }

  /// Formats relative time in an obfuscated, privacy-conscious way (e.g. '2m ago', 'Hozirgina').
  String formatRelativeTime({String locale = 'en', DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final difference = currentTime.difference(timestamp);
    final lang = locale.toLowerCase();

    if (difference.inSeconds < 45) {
      if (lang.startsWith('uz')) return 'Hozirgina';
      if (lang.startsWith('ru')) return 'Только что';
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      if (lang.startsWith('uz')) return '$mins daq. oldin';
      if (lang.startsWith('ru')) return '$mins мин. назад';
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (lang.startsWith('uz')) return '$hours soat oldin';
      if (lang.startsWith('ru')) return '$hours ч. назад';
      return '${hours}h ago';
    } else {
      if (lang.startsWith('uz')) return 'Kecha';
      if (lang.startsWith('ru')) return 'Вчера';
      return 'Yesterday';
    }
  }

  /// Formats trilingual localized action description.
  String formatEventTitle({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    final targetPlace = placeName ?? 'a local spot';
    final targetRoute = routeName ?? 'curated route';
    final targetBadge = badgeName ?? 'Curator Badge';

    switch (type) {
      case DistrictActivityType.dropCreated:
        if (lang.startsWith('uz')) {
          return '$username $targetPlace da yangi Drop qoldirdi';
        } else if (lang.startsWith('ru')) {
          return '$username оставил(а) новый Дроп в $targetPlace';
        }
        return '$username shared a new Drop at $targetPlace';

      case DistrictActivityType.routeCompleted:
        final xpSuffix = xpAwarded != null ? ' (+$xpAwarded XP)' : '';
        if (lang.startsWith('uz')) {
          return '$username "$targetRoute" marshrutini tugatdi$xpSuffix';
        } else if (lang.startsWith('ru')) {
          return '$username завершил(а) маршрут "$targetRoute"$xpSuffix';
        }
        return '$username completed "$targetRoute"$xpSuffix';

      case DistrictActivityType.crownOvertake:
        if (lang.startsWith('uz')) {
          return '$username $district tumanida #1 Tojni egalladi!';
        } else if (lang.startsWith('ru')) {
          return '$username занял(а) #1 Корону в районе $district!';
        }
        return '$username took the #1 Crown in $district!';

      case DistrictActivityType.badgeUnlocked:
        if (lang.startsWith('uz')) {
          return '$username "$targetBadge" nishonini qo\'lga kiritdi';
        } else if (lang.startsWith('ru')) {
          return '$username получил(а) бейдж "$targetBadge"';
        }
        return '$username earned the "$targetBadge" badge';

      case DistrictActivityType.placeVisited:
        if (lang.startsWith('uz')) {
          return '$username $targetPlace ga tashrif buyurdi';
        } else if (lang.startsWith('ru')) {
          return '$username посетил(а) $targetPlace';
        }
        return '$username checked in at $targetPlace';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'user_id': userId,
    'username': username,
    'user_full_name': userFullName,
    'user_avatar_url': userAvatarUrl,
    'district': district,
    'place_name': placeName,
    'place_id': placeId,
    'route_name': routeName,
    'route_id': routeId,
    'badge_name': badgeName,
    'xp_awarded': xpAwarded,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DistrictActivityEvent.fromJson(Map<String, dynamic> json) {
    DistrictActivityType parsedType;
    final rawType = json['type'] as String? ?? 'dropCreated';
    try {
      parsedType = DistrictActivityType.values.byName(rawType);
    } catch (_) {
      parsedType = DistrictActivityType.dropCreated;
    }

    DateTime parsedTimestamp;
    try {
      parsedTimestamp = DateTime.parse(json['timestamp'] as String);
    } catch (_) {
      parsedTimestamp = DateTime.now();
    }

    return DistrictActivityEvent(
      id: json['id'] as String? ?? '',
      type: parsedType,
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? 'curator',
      userFullName: json['user_full_name'] as String? ?? json['username'] as String? ?? 'Curator',
      userAvatarUrl: json['user_avatar_url'] as String?,
      district: json['district'] as String? ?? 'Mirabad',
      placeName: json['place_name'] as String?,
      placeId: json['place_id'] as String?,
      routeName: json['route_name'] as String?,
      routeId: json['route_id'] as String?,
      badgeName: json['badge_name'] as String?,
      xpAwarded: json['xp_awarded'] as int?,
      timestamp: parsedTimestamp,
    );
  }
}

/// Processes real-time community pulses across Tashkent districts.
class DistrictActivityTickerEngine {
  /// Filters activity events for a specific district, or returns all if district is null/empty.
  List<DistrictActivityEvent> filterByDistrict(
    List<DistrictActivityEvent> events,
    String? district,
  ) {
    if (district == null || district.trim().isEmpty || district.toLowerCase() == 'all') {
      return List.unmodifiable(events);
    }
    final target = district.trim().toLowerCase();
    return events.where((e) => e.district.toLowerCase() == target).toList();
  }

  /// Formats single-line ticker summary string combining emoji, title, and relative time.
  String formatTickerSummary(
    DistrictActivityEvent event, {
    String locale = 'en',
    DateTime? now,
  }) {
    final title = event.formatEventTitle(locale: locale);
    final relativeTime = event.formatRelativeTime(locale: locale, now: now);
    return '${event.iconEmoji} $title • $relativeTime';
  }
}

final districtActivityTickerEngineProvider = Provider<DistrictActivityTickerEngine>((ref) {
  return DistrictActivityTickerEngine();
});
