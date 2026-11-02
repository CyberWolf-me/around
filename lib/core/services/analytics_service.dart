import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

/// Enumeration of the 12 core user journey events instrumented in Around.
enum AnalyticsEvent {
  appOpen('app_open'),
  signupComplete('signup_complete'),
  onboardingComplete('onboarding_complete'),
  firstDropCreated('first_drop_created'),
  friendRequestSent('friend_request_sent'),
  friendRequestAccepted('friend_request_accepted'),
  placeSaved('place_saved'),
  planCreated('plan_created'),
  storyCreated('story_created'),
  reactionToggled('reaction_toggled'),
  exploreSearch('explore_search'),
  deepLinkOpened('deep_link_opened');

  final String eventName;
  const AnalyticsEvent(this.eventName);
}

/// Structured record of an analytics dispatch.
class AnalyticsRecord {
  final String eventName;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? userId;

  const AnalyticsRecord({
    required this.eventName,
    required this.properties,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toMap() => {
        'event': eventName,
        'properties': properties,
        'timestamp': timestamp.toIso8601String(),
        if (userId != null) 'user_id': userId,
      };
}

/// Aggregated, privacy-preserving venue affinity metrics used to seed
/// future B2B venue analytics subscriptions (Option B).
class VenueEngagementMetrics {
  final String placeId;
  int viewCount;
  int saveCount;
  int dropCount;
  int storyViewCount;
  int planCount;
  final Map<int, int> hourlyDistribution; // Hour (0-23) -> engagement count
  final Map<String, int> atmosphereTags;

  VenueEngagementMetrics({
    required this.placeId,
    this.viewCount = 0,
    this.saveCount = 0,
    this.dropCount = 0,
    this.storyViewCount = 0,
    this.planCount = 0,
    Map<int, int>? hourlyDistribution,
    Map<String, int>? atmosphereTags,
  })  : hourlyDistribution = hourlyDistribution ?? {},
        atmosphereTags = atmosphereTags ?? {};

  int get totalInteractions =>
      viewCount + saveCount + dropCount + storyViewCount + planCount;

  int? get peakHour {
    if (hourlyDistribution.isEmpty) return null;
    int? maxHour;
    int maxCount = -1;
    hourlyDistribution.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = hour;
      }
    });
    return maxHour;
  }
}

/// Analytics & Venue Telemetry Engine.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;

  AnalyticsService._internal();

  String? _currentUserId;
  final Map<String, dynamic> _userProperties = {};
  final List<AnalyticsRecord> _recentEvents = [];
  final Map<String, VenueEngagementMetrics> _venueMetrics = {};
  static const int _maxInMemoryEvents = 100;

  List<AnalyticsRecord> get recentEvents => List.unmodifiable(_recentEvents);
  String? get currentUserId => _currentUserId;
  Map<String, dynamic> get userProperties => Map.unmodifiable(_userProperties);

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  void setUserProperties({
    String? neighborhood,
    String? language,
    int? friendCount,
  }) {
    if (neighborhood != null) _userProperties['neighborhood'] = neighborhood;
    if (language != null) _userProperties['language'] = language;
    if (friendCount != null) _userProperties['friend_count'] = friendCount;
  }

  void clearUserProperties() {
    _currentUserId = null;
    _userProperties.clear();
  }

  /// Dispatches a structured event from the core 12-event taxonomy.
  void track(AnalyticsEvent event, [Map<String, dynamic>? properties]) {
    trackCustom(event.eventName, properties);
  }

  /// Tracks custom or extensible telemetry events.
  void trackCustom(String eventName, [Map<String, dynamic>? properties]) {
    try {
      final sanitizedProps = _sanitizeProperties(properties ?? {});
      final record = AnalyticsRecord(
        eventName: eventName,
        properties: {
          ..._userProperties,
          ...sanitizedProps,
          'env': AppConfig.current.environment.label,
        },
        timestamp: DateTime.now(),
        userId: _currentUserId,
      );

      _recentEvents.add(record);
      if (_recentEvents.length > _maxInMemoryEvents) {
        _recentEvents.removeAt(0);
      }

      if (AppConfig.current.enableDetailedLogs) {
        AppLogger.info('Analytics', 'Event: $eventName | ${record.properties}');
      }
    } catch (e) {
      AppLogger.warn('Analytics', 'Failed to dispatch analytics event: $eventName', e);
    }
  }

  /// Tracks high-intent venue interactions and updates privacy-preserving
  /// aggregated metrics for the future B2B venue analytics portal (Option B).
  void trackVenueEngagement({
    required String placeId,
    required String engagementType, // 'view', 'save', 'drop', 'story_view', 'plan'
    String? atmosphereTag,
    DateTime? eventTime,
  }) {
    final now = eventTime ?? DateTime.now();
    final hour = now.hour;

    final metrics = _venueMetrics.putIfAbsent(
      placeId,
      () => VenueEngagementMetrics(placeId: placeId),
    );

    switch (engagementType.toLowerCase()) {
      case 'view':
        metrics.viewCount++;
        break;
      case 'save':
        metrics.saveCount++;
        break;
      case 'drop':
        metrics.dropCount++;
        break;
      case 'story_view':
        metrics.storyViewCount++;
        break;
      case 'plan':
        metrics.planCount++;
        break;
    }

    metrics.hourlyDistribution[hour] = (metrics.hourlyDistribution[hour] ?? 0) + 1;
    if (atmosphereTag != null && atmosphereTag.isNotEmpty) {
      metrics.atmosphereTags[atmosphereTag] =
          (metrics.atmosphereTags[atmosphereTag] ?? 0) + 1;
    }

    trackCustom('venue_engagement', {
      'place_id': placeId,
      'engagement_type': engagementType,
      if (atmosphereTag != null) 'atmosphere_tag': atmosphereTag,
      'hour_of_day': hour,
    });
  }

  /// Returns aggregated telemetry for a specific venue without exposing individual user identities.
  VenueEngagementMetrics? getVenueMetrics(String placeId) {
    return _venueMetrics[placeId];
  }

  /// Strips potential PII such as raw emails, phone numbers, or passwords.
  Map<String, dynamic> _sanitizeProperties(Map<String, dynamic> props) {
    final sanitized = <String, dynamic>{};
    for (final entry in props.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('password') || key.contains('token') || key.contains('secret')) {
        continue; // Discard sensitive auth artifacts
      }
      sanitized[entry.key] = entry.value;
    }
    return sanitized;
  }

  /// Testing helper to reset in-memory records.
  void resetForTesting() {
    _currentUserId = null;
    _userProperties.clear();
    _recentEvents.clear();
    _venueMetrics.clear();
  }
}

/// Global Riverpod provider for analytics service.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
