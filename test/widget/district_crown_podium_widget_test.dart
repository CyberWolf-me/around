import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_crown_leaderboard_engine.dart';
import 'package:around_app/features/explore/widgets/district_crown_podium_widget.dart';

void main() {
  group('DistrictCrownPodiumWidget', () {
    testWidgets('renders empty podium placeholders correctly', (tester) async {
      const podium = DistrictCrownPodium(
        district: 'Yakkasaray',
        seasonId: '2026-11',
        totalCuratorsCount: 0,
        champion: null,
        silver: null,
        bronze: null,
        runnersUp: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictCrownPodiumWidget(
                podium: podium,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('Yakkasaray District'), findsOneWidget);
      expect(find.text('2026-11 Season • 0 Curators'), findsOneWidget);
      expect(find.text('Crown Board'), findsOneWidget);

      // Verify pillars and default "Open" labels
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('Open'), findsNWidgets(3));
    });

    testWidgets('renders populated podium and runners-up correctly', (tester) async {
      const champ = DistrictCuratorStanding(
        userId: 'u1',
        username: '@jasur_brew',
        fullName: 'Jasur Aliyev',
        district: 'Mirabad',
        seasonXp: 1250,
        placesCount: 8,
        crownsCount: 3,
        rank: 1,
      );

      const silver = DistrictCuratorStanding(
        userId: 'u2',
        username: '@kamila_tashkent',
        fullName: 'Kamila Karimova',
        district: 'Mirabad',
        seasonXp: 980,
        placesCount: 6,
        crownsCount: 1,
        rank: 2,
      );

      const bronze = DistrictCuratorStanding(
        userId: 'u3',
        username: '@nodir_walks',
        fullName: 'Nodir Usmanov',
        district: 'Mirabad',
        seasonXp: 720,
        placesCount: 5,
        crownsCount: 0,
        rank: 3,
      );

      const runner4 = DistrictCuratorStanding(
        userId: 'u4',
        username: '@diana_art',
        fullName: 'Diana Lee',
        district: 'Mirabad',
        seasonXp: 610,
        placesCount: 4,
        crownsCount: 0,
        rank: 4,
      );

      const podium = DistrictCrownPodium(
        district: 'Mirabad',
        seasonId: '2026-11',
        totalCuratorsCount: 4,
        champion: champ,
        silver: silver,
        bronze: bronze,
        runnersUp: [runner4],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictCrownPodiumWidget(
                podium: podium,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      // Verify curators
      expect(find.text('@jasur_brew'), findsOneWidget);
      expect(find.text('1250 XP'), findsOneWidget);
      expect(find.text('@kamila_tashkent'), findsOneWidget);
      expect(find.text('980 XP'), findsOneWidget);
      expect(find.text('@nodir_walks'), findsOneWidget);
      expect(find.text('720 XP'), findsOneWidget);

      // Runner up section
      expect(find.text('Contenders & Runners-up'), findsOneWidget);
      expect(find.text('Diana Lee'), findsOneWidget);
      expect(find.text('610 XP'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
    });

    testWidgets('triggers onCuratorTap callback on pillar and runner taps', (tester) async {
      DistrictCuratorStanding? tappedCurator;

      const champ = DistrictCuratorStanding(
        userId: 'u1',
        username: '@jasur_brew',
        fullName: 'Jasur Aliyev',
        district: 'Chilanzar',
        seasonXp: 850,
        placesCount: 5,
        crownsCount: 2,
        rank: 1,
      );

      const runner = DistrictCuratorStanding(
        userId: 'u4',
        username: '@diana_art',
        fullName: 'Diana Lee',
        district: 'Chilanzar',
        seasonXp: 500,
        placesCount: 3,
        crownsCount: 0,
        rank: 4,
      );

      const podium = DistrictCrownPodium(
        district: 'Chilanzar',
        seasonId: '2026-11',
        totalCuratorsCount: 2,
        champion: champ,
        silver: null,
        bronze: null,
        runnersUp: [runner],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictCrownPodiumWidget(
                podium: podium,
                locale: 'uz',
                onCuratorTap: (curator) => tappedCurator = curator,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chilanzar tumani'), findsOneWidget);

      // Tap Champion pillar
      await tester.tap(find.byKey(const Key('podium_pillar_rank_1')));
      await tester.pump();
      expect(tappedCurator?.userId, 'u1');

      // Tap Runner up item
      await tester.tap(find.byKey(const Key('runner_up_item_u4')));
      await tester.pump();
      expect(tappedCurator?.userId, 'u4');
    });

    testWidgets('respects Russian localization', (tester) async {
      const podium = DistrictCrownPodium(
        district: 'Yunusabad',
        seasonId: '2026-11',
        totalCuratorsCount: 0,
        champion: null,
        silver: null,
        bronze: null,
        runnersUp: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DistrictCrownPodiumWidget(
                podium: podium,
                locale: 'ru',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Yunusabad район'), findsOneWidget);
      expect(find.text('Корона'), findsOneWidget);
      expect(find.text('Свободно'), findsNWidgets(3));
    });
  });
}
