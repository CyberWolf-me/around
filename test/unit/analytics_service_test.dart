import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/analytics_service.dart';

void main() {
  group('AnalyticsService & Venue Telemetry Engine Tests (P12-02)', () {
    late AnalyticsService analytics;

    setUp(() {
      analytics = AnalyticsService.instance;
      analytics.resetForTesting();
    });

    test('Core 12-event taxonomy contains all required user journey events', () {
      expect(AnalyticsEvent.values.length, equals(12));
      expect(AnalyticsEvent.appOpen.eventName, equals('app_open'));
      expect(AnalyticsEvent.signupComplete.eventName, equals('signup_complete'));
      expect(AnalyticsEvent.onboardingComplete.eventName, equals('onboarding_complete'));
      expect(AnalyticsEvent.firstDropCreated.eventName, equals('first_drop_created'));
      expect(AnalyticsEvent.friendRequestSent.eventName, equals('friend_request_sent'));
      expect(AnalyticsEvent.friendRequestAccepted.eventName, equals('friend_request_accepted'));
      expect(AnalyticsEvent.placeSaved.eventName, equals('place_saved'));
      expect(AnalyticsEvent.planCreated.eventName, equals('plan_created'));
      expect(AnalyticsEvent.storyCreated.eventName, equals('story_created'));
      expect(AnalyticsEvent.reactionToggled.eventName, equals('reaction_toggled'));
      expect(AnalyticsEvent.exploreSearch.eventName, equals('explore_search'));
      expect(AnalyticsEvent.deepLinkOpened.eventName, equals('deep_link_opened'));
    });

    test('track records event with attached user properties and environment', () {
      analytics.setUserId('usr_tashkent_42');
      analytics.setUserProperties(
        neighborhood: 'Mirabad',
        language: 'uz',
        friendCount: 5,
      );

      analytics.track(AnalyticsEvent.firstDropCreated, {
        'place_id': 'place_breadly',
        'audience': 'friends',
      });

      expect(analytics.recentEvents.length, equals(1));
      final record = analytics.recentEvents.first;
      expect(record.eventName, equals('first_drop_created'));
      expect(record.userId, equals('usr_tashkent_42'));
      expect(record.properties['neighborhood'], equals('Mirabad'));
      expect(record.properties['language'], equals('uz'));
      expect(record.properties['friend_count'], equals(5));
      expect(record.properties['place_id'], equals('place_breadly'));
      expect(record.properties['audience'], equals('friends'));
      expect(record.properties['env'], isNotNull);
    });

    test('Sanitization automatically strips passwords, tokens, and secret parameters', () {
      analytics.track(AnalyticsEvent.signupComplete, {
        'username': 'aziz_dev',
        'password': 'super_secret_password',
        'auth_token': 'jwt_bearer_token',
        'client_secret': 'oauth_secret',
        'valid_prop': 'tashkent_center',
      });

      expect(analytics.recentEvents.length, equals(1));
      final props = analytics.recentEvents.first.properties;
      expect(props['username'], equals('aziz_dev'));
      expect(props['valid_prop'], equals('tashkent_center'));
      expect(props.containsKey('password'), isFalse);
      expect(props.containsKey('auth_token'), isFalse);
      expect(props.containsKey('client_secret'), isFalse);
    });

    test('trackVenueEngagement aggregates place metrics and peak atmosphere hour (Option B)', () {
      const venueId = 'place_breadly_bakery';

      // Morning visits (09:00)
      final morning = DateTime(2026, 11, 2, 9, 30);
      analytics.trackVenueEngagement(
        placeId: venueId,
        engagementType: 'view',
        atmosphereTag: 'Morning Brew',
        eventTime: morning,
      );
      analytics.trackVenueEngagement(
        placeId: venueId,
        engagementType: 'save',
        atmosphereTag: 'Morning Brew',
        eventTime: morning,
      );
      analytics.trackVenueEngagement(
        placeId: venueId,
        engagementType: 'drop',
        atmosphereTag: 'Morning Brew',
        eventTime: morning,
      );

      // Afternoon visit (15:00)
      final afternoon = DateTime(2026, 11, 2, 15, 0);
      analytics.trackVenueEngagement(
        placeId: venueId,
        engagementType: 'story_view',
        atmosphereTag: 'Work Friendly',
        eventTime: afternoon,
      );

      final metrics = analytics.getVenueMetrics(venueId);
      expect(metrics, isNotNull);
      expect(metrics!.viewCount, equals(1));
      expect(metrics.saveCount, equals(1));
      expect(metrics.dropCount, equals(1));
      expect(metrics.storyViewCount, equals(1));
      expect(metrics.totalInteractions, equals(4));

      // Peak hour calculation
      expect(metrics.peakHour, equals(9));
      expect(metrics.hourlyDistribution[9], equals(3));
      expect(metrics.hourlyDistribution[15], equals(1));

      // Atmosphere tags aggregation
      expect(metrics.atmosphereTags['Morning Brew'], equals(3));
      expect(metrics.atmosphereTags['Work Friendly'], equals(1));
    });

    test('Riverpod analyticsServiceProvider yields singleton instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(analyticsServiceProvider);
      expect(service, equals(AnalyticsService.instance));
    });
  });
}
