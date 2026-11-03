import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_trophy_engine.dart';
import 'package:around_app/features/explore/widgets/season_trophy_card.dart';

void main() {
  group('P28-02: SeasonTrophyCard Widget Tests', () {
    testWidgets('renders season card with challenges and days remaining', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeasonTrophyCard(
              districtCount: 1,
              metroCount: 2,
              weekendCount: 0,
              languageCode: 'en',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('season_trophy_card')), findsOneWidget);
      expect(find.text('MONTHLY SEASON'), findsOneWidget);
      expect(find.byKey(const Key('challenge_item_district_explorer')), findsOneWidget);
      expect(find.byKey(const Key('challenge_item_metro_nomad')), findsOneWidget);
      expect(find.byKey(const Key('challenge_item_weekend_rhythm')), findsOneWidget);

      expect(find.text('+200 XP'), findsOneWidget);
      expect(find.text('+150 XP'), findsNWidgets(2));
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
    });

    testWidgets('renders Uzbek and Russian localizations correctly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeasonTrophyCard(
              languageCode: 'uz',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OYLIK MAVSUM'), findsOneWidget);
      expect(find.textContaining('kun qoldi'), findsOneWidget);
      expect(find.text('Tuman Kashfiyotchisi'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeasonTrophyCard(
              languageCode: 'ru',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('СЕЗОН МЕСЯЦА'), findsOneWidget);
      expect(find.textContaining('Осталось'), findsOneWidget);
      expect(find.text('Первопроходец Районов'), findsOneWidget);
    });

    testWidgets('shows unlocked trophy tier banner and invokes claim callback', (tester) async {
      bool claimed = false;

      // Season with 2 challenges completed (Silver Trophy)
      final silverSeason = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 3,
        metroCount: 3,
        weekendCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonTrophyCard(
              customSeason: silverSeason,
              languageCode: 'en',
              onClaimTrophy: () {
                claimed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silver Trophy Unlocked!'), findsOneWidget);
      expect(find.text('350 / 500 XP'), findsOneWidget);

      final claimBtn = find.byKey(const Key('claim_trophy_button'));
      expect(claimBtn, findsOneWidget);

      await tester.tap(claimBtn);
      await tester.pumpAndSettle();

      expect(claimed, isTrue);
    });

    testWidgets('shows encouragement banner when 0 challenges are completed', (tester) async {
      final zeroSeason = SeasonTrophyEngine.getCurrentSeason(
        referenceDate: DateTime(2026, 11, 15),
        districtCount: 0,
        metroCount: 0,
        weekendCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonTrophyCard(
              customSeason: zeroSeason,
              languageCode: 'en',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete challenges to earn trophies'), findsOneWidget);
      expect(find.byKey(const Key('claim_trophy_button')), findsNothing);
    });
  });
}
