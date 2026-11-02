import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/crown_rivalry_engine.dart';
import 'package:around_app/core/services/district_legend_engine.dart';

void main() {
  group('P18-04: CrownRivalryEngine Tests', () {
    final now = DateTime(2026, 11, 3, 14, 0);

    DistrictLegend createLegend({
      required String district,
      required String userId,
      required String userName,
      required int dropCount,
    }) {
      return DistrictLegend(
        district: district,
        userId: userId,
        userName: userName,
        username: userId,
        dropCount: dropCount,
        lastDropAt: now,
        badgeTitleEn: '$district Local Legend',
        badgeTitleRu: 'Легенда района $district',
        badgeTitleUz: '$district Afsonasi',
      );
    }

    test('detects usurped crown when rival takes first place in district', () {
      final prevBoard = DistrictLegendLeaderboard(
        districtLegends: {
          'mirabad': createLegend(
            district: 'Mirabad',
            userId: 'kamila',
            userName: 'Kamila Rahimova',
            dropCount: 4,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 10,
      );

      final currBoard = DistrictLegendLeaderboard(
        districtLegends: {
          'mirabad': createLegend(
            district: 'Mirabad',
            userId: 'aziz',
            userName: 'Aziz Karimov',
            dropCount: 5,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 11,
      );

      final transitions = CrownRivalryEngine.detectTransitions(
        previousLeaderboard: prevBoard,
        currentLeaderboard: currBoard,
        eventTime: now,
      );

      expect(transitions.length, equals(1));
      final event = transitions.first;
      expect(event.type, equals(CrownTransitionType.usurped));
      expect(event.district, equals('Mirabad'));
      expect(event.newLeaderId, equals('aziz'));
      expect(event.newLeaderDrops, equals(5));
      expect(event.previousLeaderId, equals('kamila'));

      // Copy checks
      expect(
        event.getLocalizedNotification('en'),
        contains('Aziz Karimov just claimed the Mirabad Local Legend crown (5 drops) from Kamila Rahimova!'),
      );
      expect(
        event.getLocalizedNotification('uz'),
        contains('Mirobod afsonasi tojini qoʻlga kiritdi'),
      );
    });

    test('detects claimed crown when previously open district is crowned', () {
      final prevBoard = const DistrictLegendLeaderboard(
        districtLegends: {},
        userLegends: {},
        totalQualifyingDrops: 0,
      );

      final currBoard = DistrictLegendLeaderboard(
        districtLegends: {
          'yunusabad': createLegend(
            district: 'Yunusabad',
            userId: 'bekzod',
            userName: 'Bekzod Alimov',
            dropCount: 3,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 3,
      );

      final transitions = CrownRivalryEngine.detectTransitions(
        previousLeaderboard: prevBoard,
        currentLeaderboard: currBoard,
        eventTime: now,
      );

      expect(transitions.length, equals(1));
      final event = transitions.first;
      expect(event.type, equals(CrownTransitionType.claimed));
      expect(event.district, equals('Yunusabad'));
      expect(event.newLeaderId, equals('bekzod'));
      expect(event.newLeaderDrops, equals(3));
      expect(event.previousLeaderId, isNull);

      expect(
        event.getLocalizedNotification('en'),
        contains('Bekzod Alimov became the first Local Legend in Yunusabad'),
      );
    });

    test('detects extended lead when current leader increases drop count', () {
      final prevBoard = DistrictLegendLeaderboard(
        districtLegends: {
          'yakkasaray': createLegend(
            district: 'Yakkasaray',
            userId: 'diyor',
            userName: 'Diyor Usmanov',
            dropCount: 3,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 5,
      );

      final currBoard = DistrictLegendLeaderboard(
        districtLegends: {
          'yakkasaray': createLegend(
            district: 'Yakkasaray',
            userId: 'diyor',
            userName: 'Diyor Usmanov',
            dropCount: 4,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 6,
      );

      final transitions = CrownRivalryEngine.detectTransitions(
        previousLeaderboard: prevBoard,
        currentLeaderboard: currBoard,
        eventTime: now,
      );

      expect(transitions.length, equals(1));
      final event = transitions.first;
      expect(event.type, equals(CrownTransitionType.extended));
      expect(event.newLeaderId, equals('diyor'));
      expect(event.newLeaderDrops, equals(4));
    });

    test('returns empty list when no leader changes occurred', () {
      final board = DistrictLegendLeaderboard(
        districtLegends: {
          'mirabad': createLegend(
            district: 'Mirabad',
            userId: 'kamila',
            userName: 'Kamila Rahimova',
            dropCount: 4,
          ),
        },
        userLegends: {},
        totalQualifyingDrops: 4,
      );

      final transitions = CrownRivalryEngine.detectTransitions(
        previousLeaderboard: board,
        currentLeaderboard: board,
        eventTime: now,
      );

      expect(transitions, isEmpty);
    });
  });
}
