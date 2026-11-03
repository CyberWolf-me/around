import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/profile/widgets/curator_level_badge_widget.dart';

void main() {
  group('P23-02: CuratorLevelBadgeWidget Tests', () {
    testWidgets('renders Tier 1 Neighborhood Scout with level 1 badge and progress bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 2,
              streakWeeks: 0,
              languageCode: 'en',
            ),
          ),
        ),
      );

      expect(find.text('🌱'), findsOneWidget);
      expect(find.text('Neighborhood Scout'), findsOneWidget);
      expect(find.text('LVL 1'), findsOneWidget);
      expect(find.text('100 XP'), findsOneWidget);
      expect(find.text('150 XP to next level'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget); // 100 / 250 = 40%
    });

    testWidgets('renders Tier 2 District Curator with level 2 badge and metrics subtext', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 6, // 300 XP
              streakWeeks: 1, // 100 XP -> total 400 XP
              districtCrowns: 0,
              languageCode: 'en',
            ),
          ),
        ),
      );

      expect(find.text('🧭'), findsOneWidget);
      expect(find.text('District Curator'), findsOneWidget);
      expect(find.text('LVL 2'), findsOneWidget);
      expect(find.text('400 XP'), findsOneWidget);
      expect(find.text('350 XP to next level'), findsOneWidget); // 750 - 400 = 350
    });

    testWidgets('renders Tier 4 Tashkent Legend with max level label and 100%', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 40,
              streakWeeks: 8,
              districtCrowns: 2,
              languageCode: 'en',
            ),
          ),
        ),
      );

      expect(find.text('👑'), findsOneWidget);
      expect(find.text('Tashkent Legend'), findsOneWidget);
      expect(find.text('LVL 4'), findsOneWidget);
      expect(find.text('Max Level Reached!'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('👑 2'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 5,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('curator_level_badge_card')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('supports Uzbek and Russian localizations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 1,
              languageCode: 'uz',
            ),
          ),
        ),
      );
      expect(find.text('Mahalla Izquvari'), findsOneWidget);
      expect(find.text('Keyingi darajagacha 200 XP'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorLevelBadgeWidget(
              dropsCount: 1,
              languageCode: 'ru',
            ),
          ),
        ),
      );
      expect(find.text('Разведчик района'), findsOneWidget);
      expect(find.text('До след. уровня: 200 XP'), findsOneWidget);
    });
  });
}
