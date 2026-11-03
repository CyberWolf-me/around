import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_activity_ticker_engine.dart';

void main() {
  group('P34-01: DistrictActivityTickerEngine Unit Tests', () {
    late DistrictActivityTickerEngine engine;
    final testNow = DateTime(2026, 11, 3, 14, 0, 0);

    setUp(() {
      engine = DistrictActivityTickerEngine();
    });

    test('serializes and deserializes DistrictActivityEvent correctly', () {
      final event = DistrictActivityEvent(
        id: 'ev-1',
        type: DistrictActivityType.dropCreated,
        userId: 'u-10',
        username: '@kamila_tashkent',
        userFullName: 'Kamila Karimova',
        district: 'Mirabad',
        placeName: 'Breadly Bakery',
        placeId: 'pl-breadly',
        timestamp: testNow.subtract(const Duration(minutes: 5)),
      );

      final json = event.toJson();
      final parsed = DistrictActivityEvent.fromJson(json);

      expect(parsed.id, equals('ev-1'));
      expect(parsed.type, equals(DistrictActivityType.dropCreated));
      expect(parsed.userId, equals('u-10'));
      expect(parsed.username, equals('@kamila_tashkent'));
      expect(parsed.userFullName, equals('Kamila Karimova'));
      expect(parsed.initials, equals('KK'));
      expect(parsed.placeName, equals('Breadly Bakery'));
      expect(parsed.district, equals('Mirabad'));
      expect(parsed.iconEmoji, equals('📸'));
    });

    test('formats relative time accurately across EN, UZ, and RU', () {
      // Just now (< 45s)
      final recent = DistrictActivityEvent(
        id: '1',
        type: DistrictActivityType.placeVisited,
        userId: 'u1',
        username: '@nodir',
        userFullName: 'Nodir Usmanov',
        district: 'Mirabad',
        timestamp: testNow.subtract(const Duration(seconds: 20)),
      );
      expect(recent.formatRelativeTime(locale: 'en', now: testNow), equals('Just now'));
      expect(recent.formatRelativeTime(locale: 'uz', now: testNow), equals('Hozirgina'));
      expect(recent.formatRelativeTime(locale: 'ru', now: testNow), equals('Только что'));

      // Minutes (5m ago)
      final minutesAgo = DistrictActivityEvent(
        id: '2',
        type: DistrictActivityType.placeVisited,
        userId: 'u1',
        username: '@nodir',
        userFullName: 'Nodir Usmanov',
        district: 'Mirabad',
        timestamp: testNow.subtract(const Duration(minutes: 12)),
      );
      expect(minutesAgo.formatRelativeTime(locale: 'en', now: testNow), equals('12m ago'));
      expect(minutesAgo.formatRelativeTime(locale: 'uz', now: testNow), equals('12 daq. oldin'));
      expect(minutesAgo.formatRelativeTime(locale: 'ru', now: testNow), equals('12 мин. назад'));

      // Hours (2h ago)
      final hoursAgo = DistrictActivityEvent(
        id: '3',
        type: DistrictActivityType.placeVisited,
        userId: 'u1',
        username: '@nodir',
        userFullName: 'Nodir Usmanov',
        district: 'Mirabad',
        timestamp: testNow.subtract(const Duration(hours: 3)),
      );
      expect(hoursAgo.formatRelativeTime(locale: 'en', now: testNow), equals('3h ago'));
      expect(hoursAgo.formatRelativeTime(locale: 'uz', now: testNow), equals('3 soat oldin'));
      expect(hoursAgo.formatRelativeTime(locale: 'ru', now: testNow), equals('3 ч. назад'));

      // Yesterday
      final yesterday = DistrictActivityEvent(
        id: '4',
        type: DistrictActivityType.placeVisited,
        userId: 'u1',
        username: '@nodir',
        userFullName: 'Nodir Usmanov',
        district: 'Mirabad',
        timestamp: testNow.subtract(const Duration(days: 1, hours: 2)),
      );
      expect(yesterday.formatRelativeTime(locale: 'en', now: testNow), equals('Yesterday'));
      expect(yesterday.formatRelativeTime(locale: 'uz', now: testNow), equals('Kecha'));
      expect(yesterday.formatRelativeTime(locale: 'ru', now: testNow), equals('Вчера'));
    });

    test('formats event descriptions localized in Uzbek, Russian, and English', () {
      // 1. Drop created
      final dropEvent = DistrictActivityEvent(
        id: 'e1',
        type: DistrictActivityType.dropCreated,
        userId: 'u1',
        username: '@kamila',
        userFullName: 'Kamila K',
        district: 'Mirabad',
        placeName: 'Breadly Bakery',
        timestamp: testNow,
      );
      expect(
        dropEvent.formatEventTitle(locale: 'en'),
        equals('@kamila shared a new Drop at Breadly Bakery'),
      );
      expect(
        dropEvent.formatEventTitle(locale: 'uz'),
        equals('@kamila Breadly Bakery da yangi Drop qoldirdi'),
      );
      expect(
        dropEvent.formatEventTitle(locale: 'ru'),
        equals('@kamila оставил(а) новый Дроп в Breadly Bakery'),
      );

      // 2. Route completed
      final routeEvent = DistrictActivityEvent(
        id: 'e2',
        type: DistrictActivityType.routeCompleted,
        userId: 'u2',
        username: '@jasur',
        userFullName: 'Jasur A',
        district: 'Chilanzar',
        routeName: 'Chorsu Heritage Route',
        xpAwarded: 50,
        timestamp: testNow,
      );
      expect(
        routeEvent.formatEventTitle(locale: 'en'),
        equals('@jasur completed "Chorsu Heritage Route" (+50 XP)'),
      );
      expect(
        routeEvent.formatEventTitle(locale: 'uz'),
        equals('@jasur "Chorsu Heritage Route" marshrutini tugatdi (+50 XP)'),
      );
      expect(
        routeEvent.formatEventTitle(locale: 'ru'),
        equals('@jasur завершил(а) маршрут "Chorsu Heritage Route" (+50 XP)'),
      );

      // 3. Crown overtake
      final crownEvent = DistrictActivityEvent(
        id: 'e3',
        type: DistrictActivityType.crownOvertake,
        userId: 'u3',
        username: '@nodir',
        userFullName: 'Nodir U',
        district: 'Yakkasaray',
        timestamp: testNow,
      );
      expect(
        crownEvent.formatEventTitle(locale: 'en'),
        equals('@nodir took the #1 Crown in Yakkasaray!'),
      );
      expect(
        crownEvent.formatEventTitle(locale: 'uz'),
        equals('@nodir Yakkasaray tumanida #1 Tojni egalladi!'),
      );
      expect(
        crownEvent.formatEventTitle(locale: 'ru'),
        equals('@nodir занял(а) #1 Корону в районе Yakkasaray!'),
      );

      // 4. Badge unlocked
      final badgeEvent = DistrictActivityEvent(
        id: 'e4',
        type: DistrictActivityType.badgeUnlocked,
        userId: 'u4',
        username: '@aziza',
        userFullName: 'Aziza T',
        district: 'Yunusabad',
        badgeName: 'Coffee Maven',
        timestamp: testNow,
      );
      expect(
        badgeEvent.formatEventTitle(locale: 'en'),
        equals('@aziza earned the "Coffee Maven" badge'),
      );

      // 5. Place visited
      final checkinEvent = DistrictActivityEvent(
        id: 'e5',
        type: DistrictActivityType.placeVisited,
        userId: 'u5',
        username: '@sardor',
        userFullName: 'Sardor R',
        district: 'Mirabad',
        placeName: 'Afsona Restaurant',
        timestamp: testNow,
      );
      expect(
        checkinEvent.formatEventTitle(locale: 'en'),
        equals('@sardor checked in at Afsona Restaurant'),
      );
    });

    test('filters events by district accurately', () {
      final events = [
        DistrictActivityEvent(
          id: '1',
          type: DistrictActivityType.dropCreated,
          userId: 'u1',
          username: '@a',
          userFullName: 'A',
          district: 'Mirabad',
          timestamp: testNow,
        ),
        DistrictActivityEvent(
          id: '2',
          type: DistrictActivityType.placeVisited,
          userId: 'u2',
          username: '@b',
          userFullName: 'B',
          district: 'Chilanzar',
          timestamp: testNow,
        ),
        DistrictActivityEvent(
          id: '3',
          type: DistrictActivityType.crownOvertake,
          userId: 'u3',
          username: '@c',
          userFullName: 'C',
          district: 'mirabad',
          timestamp: testNow,
        ),
      ];

      final mirabadEvents = engine.filterByDistrict(events, 'Mirabad');
      expect(mirabadEvents.length, equals(2));

      final allEvents = engine.filterByDistrict(events, null);
      expect(allEvents.length, equals(3));

      final allKeywordEvents = engine.filterByDistrict(events, 'ALL');
      expect(allKeywordEvents.length, equals(3));
    });

    test('formatTickerSummary combines emoji, title, and relative time', () {
      final event = DistrictActivityEvent(
        id: 'e1',
        type: DistrictActivityType.dropCreated,
        userId: 'u1',
        username: '@kamila',
        userFullName: 'Kamila K',
        district: 'Mirabad',
        placeName: 'Breadly Bakery',
        timestamp: testNow.subtract(const Duration(minutes: 4)),
      );

      final summary = engine.formatTickerSummary(event, locale: 'en', now: testNow);
      expect(summary, equals('📸 @kamila shared a new Drop at Breadly Bakery • 4m ago'));
    });

    test('Riverpod provider initializes DistrictActivityTickerEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(districtActivityTickerEngineProvider);
      expect(service, isA<DistrictActivityTickerEngine>());
    });
  });
}
