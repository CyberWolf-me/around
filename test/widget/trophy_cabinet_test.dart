import 'package:around_app/features/profile/widgets/trophy_cabinet_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrophyCabinetWidget & TrophyItem Tests', () {
    test('createDefaultTrophies builds accurate list of 12 trophies across categories', () {
      final trophies = TrophyCabinetWidget.createDefaultTrophies(
        visitedPlaceIds: {'breadly', 'tims', 'pie-republic'},
        streakWeeks: 4,
        userDropDistricts: ['Mirabad', 'Mirabad', 'Mirabad'],
        heldDistrictCrowns: {'Mirabad'},
      );

      expect(trophies.length, 12);

      final crowns = trophies.where((t) => t.category == TrophyCategory.crowns).toList();
      final streaks = trophies.where((t) => t.category == TrophyCategory.streaks).toList();
      final quests = trophies.where((t) => t.category == TrophyCategory.quests).toList();

      expect(crowns.length, 4);
      expect(streaks.length, 4);
      expect(quests.length, 4);

      // Mirabad crown should be unlocked
      final mirabadCrown = crowns.firstWhere((c) => c.id == 'crown_mirabad');
      expect(mirabadCrown.isUnlocked, isTrue);

      // 4-week streak should be unlocked, 8-week locked
      final s4 = streaks.firstWhere((s) => s.id == 'streak_4wk');
      final s8 = streaks.firstWhere((s) => s.id == 'streak_8wk');
      expect(s4.isUnlocked, isTrue);
      expect(s8.isUnlocked, isFalse);

      // Coffee quest should be unlocked
      final coffee = quests.firstWhere((q) => q.id == 'quest_coffee');
      expect(coffee.isUnlocked, isTrue);
    });

    testWidgets('renders category filter chips and filters grid properly', (tester) async {
      final trophies = TrophyCabinetWidget.createDefaultTrophies(
        visitedPlaceIds: {'breadly'},
        streakWeeks: 2,
        userDropDistricts: ['Mirabad'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrophyCabinetWidget(
                trophies: trophies,
                curatorName: 'Malika',
              ),
            ),
          ),
        ),
      );

      expect(find.text('TROPHY CABINET'), findsOneWidget);
      expect(find.text('Achievements & Accolades'), findsOneWidget);

      // Filter chips should be present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Crowns'), findsOneWidget);
      expect(find.text('Streaks'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);

      // Tap 'Crowns' filter
      await tester.tap(find.text('Crowns'));
      await tester.pumpAndSettle();

      expect(find.text('Mirabad Legend'), findsOneWidget);
      expect(find.text('Central Maestro'), findsOneWidget);
      expect(find.text('2-Week Spark'), findsNothing);

      // Tap 'Streaks' filter
      await tester.tap(find.text('Streaks'));
      await tester.pumpAndSettle();

      expect(find.text('Mirabad Legend'), findsNothing);
      expect(find.text('2-Week Spark'), findsOneWidget);
      expect(find.text('4-Week Flame'), findsOneWidget);
    });

    testWidgets('tapping a trophy card opens details modal bottom sheet', (tester) async {
      final trophies = TrophyCabinetWidget.createDefaultTrophies(
        visitedPlaceIds: {'breadly', 'tims', 'pie-republic'},
        streakWeeks: 5,
        userDropDistricts: ['Mirabad', 'Mirabad', 'Mirabad'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrophyCabinetWidget(
                trophies: trophies,
                curatorName: 'Aziz',
              ),
            ),
          ),
        ),
      );

      // Tap on Mirabad Legend trophy
      await tester.tap(find.text('Mirabad Legend'));
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with Close button
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('DISTRICT CROWN'), findsOneWidget);
      expect(find.textContaining('Earned by becoming the leading curator'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsNothing);
    });
  });
}
