import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_accolades_engine.dart';
import 'package:around_app/core/services/season_ceremony_engine.dart';
import 'package:around_app/core/services/season_trophy_engine.dart';
import 'package:around_app/features/profile/widgets/curator_trophy_cabinet.dart';

void main() {
  group('P31-02: CuratorTrophyCabinet Widget Tests', () {
    testWidgets('renders crown badge, mastery tier, and empty state when no trophies', (tester) async {
      final engine = CuratorAccoladesEngine();
      final accolades = engine.buildAccolades(
        userId: 'u-1',
        username: 'nodir_scout',
        crownsCount: 0,
        trophies: [],
        laurels: [],
        totalCuratorXp: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTrophyCabinet(
                accolades: accolades,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Neighborhood Scout'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('crown_count_text'))).data, equals('0'));
      expect(find.text('No seasonal trophies yet. Join the monthly city quest!'), findsOneWidget);
      expect(find.byKey(const Key('share_accolades_button')), findsOneWidget);
    });

    testWidgets('renders trophies and opens bottom sheet on tap', (tester) async {
      final engine = CuratorAccoladesEngine();
      final trophies = [
        CuratorAccoladeTrophy(
          id: 't-101',
          seasonId: '2026-11',
          seasonTitle: 'Autumn in Tashkent',
          tier: CuratorTrophyTier.gold,
          completedChallengesCount: 3,
          xpBonus: 150,
          earnedAt: DateTime(2026, 11, 2),
        ),
      ];

      final accolades = engine.buildAccolades(
        userId: 'u-2',
        username: 'kamila_champion',
        crownsCount: 3,
        trophies: trophies,
        laurels: [
          const CuratorAccoladeLaurel(
            seasonId: '2026-10',
            district: 'Mirabad',
            rank: 1,
            laurel: CuratorLaurelTier.champion,
          ),
        ],
        totalCuratorXp: 850,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTrophyCabinet(
                accolades: accolades,
                locale: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Grand Master Curator'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('crown_count_text'))).data, equals('3'));
      expect(find.text('Autumn in Tashkent'), findsOneWidget);
      expect(find.text('Mirabad #1'), findsOneWidget);

      // Tap on trophy card
      final trophyFinder = find.byKey(const Key('trophy_card_t-101'));
      expect(trophyFinder, findsOneWidget);
      await tester.tap(trophyFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('GOLD TROPHY • 2026-11'), findsOneWidget);
      expect(find.text('+150 XP'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('GOLD TROPHY • 2026-11'), findsNothing);
    });

    testWidgets('triggers onShare callback when share button is tapped', (tester) async {
      final engine = CuratorAccoladesEngine();
      final accolades = engine.buildAccolades(
        userId: 'u-3',
        username: 'shohruh',
        crownsCount: 1,
        trophies: [],
        laurels: [],
      );

      var shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratorTrophyCabinet(
              accolades: accolades,
              locale: 'en',
              onShare: () {
                shareTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('share_accolades_button')));
      await tester.pump();

      expect(shareTapped, isTrue);
      expect(find.text('✓ Accolades summary copied to clipboard'), findsOneWidget);
    });
  });
}
