import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/group_crawl_session_engine.dart';

void main() {
  group('P26-01: GroupCrawlSessionEngine Unit Tests', () {
    test('generateSessionCode generates structured 9-character crawl codes', () {
      final code = GroupCrawlSessionEngine.generateSessionCode('MRB');
      expect(code, startsWith('CR-MRB-'));
      expect(code.length, equals(9));

      final fallbackCode = GroupCrawlSessionEngine.generateSessionCode('X');
      expect(fallbackCode, startsWith('CR-TAS-'));
    });

    test('createSession initializes session with host participant', () {
      final session = GroupCrawlSessionEngine.createSession(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
        districtPrefix: 'MRB',
      );

      expect(session.routeId, equals('mirabad_coffee_crawl'));
      expect(session.hostUserId, equals('user_kamila'));
      expect(session.participants.length, equals(1));
      expect(session.participants.first.isHost, isTrue);
      expect(session.participants.first.name, equals('Kamila'));
      expect(session.squadBonusXp, equals(200));
      expect(session.isActive, isTrue);
    });

    test('joinSession appends new members and ignores duplicates', () {
      var session = GroupCrawlSessionEngine.createSession(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
      );

      session = GroupCrawlSessionEngine.joinSession(
        session,
        userId: 'user_bekzod',
        name: 'Bekzod',
        initials: 'BA',
      );

      expect(session.participants.length, equals(2));
      expect(session.participants[1].userId, equals('user_bekzod'));
      expect(session.participants[1].isHost, isFalse);

      // Attempt joining again
      final duplicated = GroupCrawlSessionEngine.joinSession(
        session,
        userId: 'user_bekzod',
        name: 'Bekzod',
        initials: 'BA',
      );
      expect(duplicated.participants.length, equals(2));
    });

    test('recordCheckIn updates participant current place and visited stop set', () {
      var session = GroupCrawlSessionEngine.createSession(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
      );

      session = GroupCrawlSessionEngine.recordCheckIn(
        session,
        userId: 'user_kamila',
        placeId: 'place_breadly',
      );

      final host = session.participants.first;
      expect(host.currentPlaceId, equals('place_breadly'));
      expect(host.visitedStopIds.contains('place_breadly'), isTrue);
    });

    test('calculateProgress tracks group coverage and squad completion', () {
      final routeStops = ['place_breadly', 'place_socials', 'place_ekler'];

      var session = GroupCrawlSessionEngine.createSession(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
      );

      session = GroupCrawlSessionEngine.joinSession(
        session,
        userId: 'user_bekzod',
        name: 'Bekzod',
        initials: 'BA',
      );

      // Initial progress: 0%
      final initialProg = GroupCrawlSessionEngine.calculateProgress(session, routeStops);
      expect(initialProg.stopsCoveredByGroup, equals(0));
      expect(initialProg.completionPercentage, equals(0));
      expect(initialProg.isSquadComplete, isFalse);

      // Kamila visits Breadly, Bekzod visits Breadly
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_kamila', placeId: 'place_breadly');
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_bekzod', placeId: 'place_breadly');

      final prog1 = GroupCrawlSessionEngine.calculateProgress(session, routeStops);
      expect(prog1.stopsCoveredByGroup, equals(1));
      expect(prog1.stopsCoveredByAll, equals(1));
      expect(prog1.completionPercentage, equals(33));
      expect(prog1.activeStopParticipants['place_breadly'], containsAll(['Kamila', 'Bekzod']));
      expect(prog1.isSquadComplete, isFalse);

      // Kamila moves to Socials, Bekzod moves to Socials
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_kamila', placeId: 'place_socials');
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_bekzod', placeId: 'place_socials');

      // Both visit Ekler
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_kamila', placeId: 'place_ekler');
      session = GroupCrawlSessionEngine.recordCheckIn(session, userId: 'user_bekzod', placeId: 'place_ekler');

      final progFinal = GroupCrawlSessionEngine.calculateProgress(session, routeStops);
      expect(progFinal.stopsCoveredByGroup, equals(3));
      expect(progFinal.stopsCoveredByAll, equals(3));
      expect(progFinal.completionPercentage, equals(100));
      expect(progFinal.isSquadComplete, isTrue);
    });

    test('GroupCrawlSession serializes and deserializes accurately', () {
      final session = GroupCrawlSessionEngine.createSession(
        routeId: 'mirabad_coffee_crawl',
        routeTitle: 'Mirabad Specialty Coffee Crawl',
        hostUserId: 'user_kamila',
        hostName: 'Kamila',
        hostInitials: 'KR',
      );

      final json = session.toJson();
      expect(json['session_code'], startsWith('CR-MRB-'));
      expect(json['route_id'], equals('mirabad_coffee_crawl'));
      expect(json['squad_bonus_xp'], equals(200));

      final parsed = GroupCrawlSession.fromJson(json);
      expect(parsed.sessionCode, equals(session.sessionCode));
      expect(parsed.hostUserId, equals(session.hostUserId));
      expect(parsed.participants.length, equals(1));
      expect(parsed.participants.first.name, equals('Kamila'));
    });

    test('Riverpod groupCrawlEngineProvider provides initialized singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(groupCrawlEngineProvider);
      expect(engine, isNotNull);
    });
  });
}
