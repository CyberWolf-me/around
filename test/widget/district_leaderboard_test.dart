import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/district_legend_engine.dart';
import 'package:around_app/features/profile/widgets/district_leaderboard_sheet.dart';

void main() {
  group('P16-01: District Leaderboard & Local Legend Crown Tests', () {
    final mockLegend = DistrictLegend(
      district: 'Mirabad',
      userId: 'u_kamila',
      userName: 'Kamila Rustamova',
      username: 'kamila_r',
      dropCount: 5,
      lastDropAt: DateTime.now().subtract(const Duration(days: 2)),
      badgeTitleEn: 'Mirabad Local Legend',
      badgeTitleRu: 'Легенда района Mirabad',
      badgeTitleUz: 'Mirobod Afsonasi',
    );

    final mockLeaderboard = DistrictLegendLeaderboard(
      districtLegends: {
        'mirabad': mockLegend,
      },
      userLegends: {
        'u_kamila': [mockLegend],
      },
      totalQualifyingDrops: 5,
    );

    testWidgets('LocalLegendBadge renders crown, district name, and invokes callback on tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocalLegendBadge(
              legends: [mockLegend],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_local_legend_crown_badge')), findsOneWidget);
      expect(find.text('👑'), findsOneWidget);
      expect(find.text('Mirabad Local Legend'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_local_legend_crown_badge')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('DistrictLeaderboardSheet displays active legends and unclaimed neighborhoods', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DistrictLeaderboardSheet(
                customLeaderboard: mockLeaderboard,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('district_leaderboard_sheet')), findsOneWidget);
      expect(find.text('Tashkent Local Legends'), findsOneWidget);
      expect(find.text('30-Day Rolling'), findsOneWidget);

      // Mirabad active legend row
      expect(find.byKey(const Key('legend_row_mirabad')), findsOneWidget);
      expect(find.text('· Kamila Rustamova'), findsOneWidget);
      expect(find.text('5 drops'), findsOneWidget);

      // Yunusabad unclaimed row
      expect(find.byKey(const Key('legend_unclaimed_yunusabad')), findsOneWidget);
      expect(find.text('Crown Unclaimed · Post 3 drops to lead'), findsWidgets);
    });
  });
}
