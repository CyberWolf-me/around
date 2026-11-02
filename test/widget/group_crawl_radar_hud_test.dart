import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curated_route_engine.dart';
import 'package:around_app/core/services/group_crawl_session_engine.dart';
import 'package:around_app/features/explore/widgets/group_crawl_radar_hud.dart';

void main() {
  group('P26-02: GroupCrawlRadarHUD Widget Tests', () {
    final route = CuratedRouteEngine.getRouteById('mirabad_coffee_crawl')!;

    testWidgets('renders HUD with squad code, bonus XP, and participant avatars', (tester) async {
      final session = GroupCrawlSession(
        sessionCode: 'CR-MRB-77',
        routeId: route.id,
        routeTitle: route.title,
        hostUserId: 'user_kamila',
        participants: [
          CrawlParticipant(
            userId: 'user_kamila',
            name: 'Kamila',
            avatarInitials: 'KR',
            currentPlaceId: 'place_breadly',
            visitedStopIds: const {'place_breadly'},
            lastActive: DateTime.now(),
            isHost: true,
          ),
          CrawlParticipant(
            userId: 'user_bekzod',
            name: 'Bekzod',
            avatarInitials: 'BA',
            currentPlaceId: null,
            visitedStopIds: const {},
            lastActive: DateTime.now(),
            isHost: false,
          ),
        ],
        createdAt: DateTime.now(),
        isActive: true,
        squadBonusXp: 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
                languageCode: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('SQUAD CRAWL'), findsOneWidget);
      expect(find.text('CR-MRB-77'), findsOneWidget);
      expect(find.text('+200 XP Squad'), findsOneWidget);
      expect(find.text('Mirabad Specialty Coffee Crawl'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget); // 1 of 3 stops covered
      expect(find.text('Kamila'), findsOneWidget); // On Breadly stop
      expect(find.text('KR'), findsOneWidget);
      expect(find.text('BA'), findsOneWidget);
    });

    testWidgets('triggers onCheckInStop callback when check in button is tapped', (tester) async {
      String? checkedInPlace;

      final session = GroupCrawlSession(
        sessionCode: 'CR-MRB-77',
        routeId: route.id,
        routeTitle: route.title,
        hostUserId: 'user_kamila',
        participants: [
          CrawlParticipant(
            userId: 'user_kamila',
            name: 'Kamila',
            avatarInitials: 'KR',
            lastActive: DateTime.now(),
            isHost: true,
          ),
        ],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
                onCheckInStop: (p) => checkedInPlace = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('check_in_btn_place_breadly')));
      await tester.pumpAndSettle();

      expect(checkedInPlace, equals('place_breadly'));
    });

    testWidgets('triggers onTapShare callback when session code pill is tapped', (tester) async {
      bool shareTapped = false;

      final session = GroupCrawlSession(
        sessionCode: 'CR-MRB-77',
        routeId: route.id,
        routeTitle: route.title,
        hostUserId: 'user_kamila',
        participants: [
          CrawlParticipant(
            userId: 'user_kamila',
            name: 'Kamila',
            avatarInitials: 'KR',
            lastActive: DateTime.now(),
            isHost: true,
          ),
        ],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
                onTapShare: () => shareTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('share_session_code_btn')));
      await tester.pumpAndSettle();

      expect(shareTapped, isTrue);
    });

    testWidgets('renders squad complete state (100%)', (tester) async {
      final session = GroupCrawlSession(
        sessionCode: 'CR-MRB-77',
        routeId: route.id,
        routeTitle: route.title,
        hostUserId: 'user_kamila',
        participants: [
          CrawlParticipant(
            userId: 'user_kamila',
            name: 'Kamila',
            avatarInitials: 'KR',
            visitedStopIds: const {'place_breadly', 'place_socials', 'place_ekler'},
            lastActive: DateTime.now(),
            isHost: true,
          ),
        ],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('supports Uzbek and Russian localizations', (tester) async {
      final session = GroupCrawlSession(
        sessionCode: 'CR-MRB-77',
        routeId: route.id,
        routeTitle: route.title,
        hostUserId: 'user_kamila',
        participants: [
          CrawlParticipant(
            userId: 'user_kamila',
            name: 'Kamila',
            avatarInitials: 'KR',
            lastActive: DateTime.now(),
            isHost: true,
          ),
        ],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
                languageCode: 'uz',
              ),
            ),
          ),
        ),
      );
      expect(find.text('GURUH SAYRI'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GroupCrawlRadarHUD(
                session: session,
                routeStops: route.stops,
                languageCode: 'ru',
              ),
            ),
          ),
        ),
      );
      expect(find.text('ГРУППОВОЙ МАРШРУТ'), findsOneWidget);
    });
  });
}
