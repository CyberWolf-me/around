import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/quest_model.dart';
import 'package:around_app/data/repositories/quests_repository.dart';
import 'package:around_app/features/profile/widgets/taste_quests_card.dart';

void main() {
  group('P13-01: Tashkent Taste Quests & Local Legend Badges Tests', () {
    late QuestsRepository repository;

    setUp(() {
      repository = QuestsRepository();
    });

    test('QuestsRepository provides at least 4 curated Tashkent city quests', () {
      final quests = repository.getQuests();
      expect(quests.length, greaterThanOrEqualTo(4));

      final ids = quests.map((q) => q.id).toSet();
      expect(ids.length, equals(quests.length), reason: 'All quest IDs must be unique');

      for (final quest in quests) {
        expect(quest.title.isNotEmpty, isTrue);
        expect(quest.description.isNotEmpty, isTrue);
        expect(quest.district.isNotEmpty, isTrue);
        expect(quest.badgeName.isNotEmpty, isTrue);
        expect(quest.targetPlaceIds.isNotEmpty, isTrue);
        expect(quest.requiredCount, greaterThan(0));
      }
    });

    test('Progress calculations reflect visited places and clamp accurately', () {
      final quest = const QuestModel(
        id: 'test_quest',
        title: 'Test Coffee Crawl',
        description: 'Test description',
        district: 'Mirabad',
        category: 'Coffee',
        icon: '☕',
        badgeName: 'Test Badge',
        targetPlaceIds: ['breadly', 'tims', 'pie-republic'],
        requiredCount: 2,
      );

      // Empty visited
      expect(quest.completedCount({}), equals(0));
      expect(quest.progressFraction({}), equals(0.0));
      expect(quest.isCompleted({}), isFalse);

      // 1 of 2 visited
      expect(quest.completedCount({'breadly'}), equals(1));
      expect(quest.progressFraction({'breadly'}), equals(0.5));
      expect(quest.isCompleted({'breadly'}), isFalse);

      // 2 of 2 visited (completed!)
      expect(quest.completedCount({'breadly', 'tims'}), equals(2));
      expect(quest.progressFraction({'breadly', 'tims'}), equals(1.0));
      expect(quest.isCompleted({'breadly', 'tims'}), isTrue);

      // 3 of 2 visited (clamps to 1.0)
      expect(quest.completedCount({'breadly', 'tims', 'pie-republic'}), equals(3));
      expect(quest.progressFraction({'breadly', 'tims', 'pie-republic'}), equals(1.0));
      expect(quest.isCompleted({'breadly', 'tims', 'pie-republic'}), isTrue);
    });

    test('getCompletedQuests and getUnlockedBadges unlock badge flair upon quest completion', () {
      // Complete the Mirabad Coffee Trail (requires 3 of ['breadly', 'tims', 'pie-republic', 'coffee-milk', 'blend-coffee'])
      final visited = {'breadly', 'tims', 'pie-republic'};

      final completed = repository.getCompletedQuests(visited);
      expect(completed.isNotEmpty, isTrue);
      expect(completed.any((q) => q.id == 'mirabad_coffee_trail'), isTrue);

      final badges = repository.getUnlockedBadges(visited);
      expect(badges.contains('Mirabad Roastmaster'), isTrue);
    });

    test('getQuestStats returns accurate progress percentage and unlocked badges summary', () {
      final statsEmpty = repository.getQuestStats({});
      expect(statsEmpty['completedQuests'], equals(0));
      expect(statsEmpty['progressPercent'], equals(0));
      expect(statsEmpty['hasBadges'], isFalse);

      // Complete both coffee trail and plov connoisseur
      final visited = {'breadly', 'tims', 'pie-republic', 'chorsu', 'besh-qozon-plov'};
      final statsActive = repository.getQuestStats(visited);
      expect(statsActive['completedQuests'], greaterThanOrEqualTo(2));
      expect(statsActive['progressPercent'], greaterThan(0));
      expect(statsActive['hasBadges'], isTrue);
      expect(statsActive['unlockedBadges'], contains('Mirabad Roastmaster'));
      expect(statsActive['unlockedBadges'], contains('Master Oshpaz'));
    });

    testWidgets('TasteQuestsCard renders quest items, progress indicators, and badges', (tester) async {
      final quests = repository.getQuests();
      final visited = {'breadly', 'tims', 'pie-republic'}; // Mirabad coffee trail complete

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TasteQuestsCard(
                quests: quests,
                visitedPlaceIds: visited,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TASHKENT TASTE QUESTS'), findsOneWidget);
      expect(find.text('Explore trails & earn Local Legend status'), findsOneWidget);
      expect(find.text('Mirabad Specialty Coffee Trail'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsWidgets);
      expect(find.textContaining('Mirabad Roastmaster'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });
}
