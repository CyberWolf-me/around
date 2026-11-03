import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:around_app/core/services/architectural_badge_engine.dart';

void main() {
  group('ArchitecturalBadgeEngine Unit Tests', () {
    late ArchitecturalBadgeEngine engine;

    setUp(() {
      engine = ArchitecturalBadgeEngine();
    });

    test('getAllQuests returns curated catalog of Tashkent quests', () {
      final quests = engine.getAllQuests();
      expect(quests.length, greaterThanOrEqualTo(3));

      final modernism = engine.getQuestById('quest-soviet-modernism');
      expect(modernism, isNotNull);
      expect(modernism!.badgeName, equals('Modernist Connoisseur'));
      expect(modernism.stops.length, equals(3));
      expect(modernism.stops.first.name, equals('Hotel Uzbekistan'));
      expect(modernism.stops.first.yearBuilt, equals(1974));

      final heritage = engine.getQuestById('silk-road-heritage');
      expect(heritage, isNotNull);
      expect(heritage!.badgeName, equals('Silk Road Custodian'));
      expect(heritage.requiredStopsCount, equals(3));

      final contemporary = engine.getQuestById('quest-contemporary-courtyards');
      expect(contemporary, isNotNull);
      expect(contemporary!.stops.length, equals(2));
      expect(contemporary.stops.first.district, equals('Mirabad'));
    });

    test('calculateProgress evaluates partial and completed quest progress', () {
      final quest = engine.getQuestById('quest-soviet-modernism')!;

      // 0 stops visited
      final progressEmpty = engine.calculateProgress(quest, {});
      expect(progressEmpty.visitedStopIds, isEmpty);
      expect(progressEmpty.isCompleted, isFalse);
      expect(progressEmpty.completionPercentage, equals(0.0));
      expect(progressEmpty.remainingStops, equals(3));

      // 1 stop visited by placeId
      final progress1 = engine.calculateProgress(
        quest,
        {'hotel-uzbekistan-canonical'},
      );
      expect(progress1.visitedStopIds, contains('stop-hotel-uzbekistan'));
      expect(progress1.isCompleted, isFalse);
      expect(progress1.completionPercentage, closeTo(0.33, 0.01));
      expect(progress1.remainingStops, equals(2));

      // All 3 stops visited
      final progressAll = engine.calculateProgress(quest, {
        'hotel-uzbekistan-canonical',
        'tashkent-circus-canonical',
        'blue-domes-cafe-canonical',
      });
      expect(progressAll.visitedStopIds.length, equals(3));
      expect(progressAll.isCompleted, isTrue);
      expect(progressAll.completionPercentage, equals(1.0));
      expect(progressAll.remainingStops, equals(0));
      expect(progressAll.unlockedAt, isNotNull);
    });

    test('isBadgeUnlocked and calculateTotalXp compute rewards accurately', () {
      final quests = engine.getAllQuests();
      final visited = {
        'breadly-shevchenko-canonical',
        'bb-coffee-canonical', // Completes contemporary quest
      };

      final contemporaryQuest = engine.getQuestById('quest-contemporary-courtyards')!;
      expect(engine.isBadgeUnlocked(contemporaryQuest, visited), isTrue);

      final modernismQuest = engine.getQuestById('quest-soviet-modernism')!;
      expect(engine.isBadgeUnlocked(modernismQuest, visited), isFalse);

      final totalXp = engine.calculateTotalXp(quests, visited);
      expect(totalXp, equals(50));
    });

    test('isNearStop validates proximity to landmark stops using Haversine formula', () {
      final hotelStop = engine.getQuestById('quest-soviet-modernism')!.stops.first;

      // Close position (within 10 meters of Hotel Uzbekistan)
      final isNear = engine.isNearStop(
        userLat: 41.31151,
        userLng: 69.27961,
        stop: hotelStop,
        radiusMeters: 80.0,
      );
      expect(isNear, isTrue);

      // Far position (Chorsu Bazaar ~4km away)
      final isFar = engine.isNearStop(
        userLat: 41.3268,
        userLng: 69.2348,
        stop: hotelStop,
        radiusMeters: 80.0,
      );
      expect(isFar, isFalse);
    });

    test('formatProgressLabel returns trilingual messages', () {
      final quest = engine.getQuestById('quest-soviet-modernism')!;
      final partial = engine.calculateProgress(quest, {'stop-hotel-uzbekistan'});
      final completed = engine.calculateProgress(quest, {
        'stop-hotel-uzbekistan',
        'stop-tashkent-circus',
        'stop-blue-domes',
      });

      // Partial copy
      expect(
        engine.formatProgressLabel(partial, 3, 'en'),
        equals('1 of 3 locations visited'),
      );
      expect(
        engine.formatProgressLabel(partial, 3, 'uz'),
        equals('1/3 to‘xtash joyi tashrif buyurildi'),
      );
      expect(
        engine.formatProgressLabel(partial, 3, 'ru'),
        equals('Посещено 1 из 3 локаций'),
      );

      // Completed copy
      expect(
        engine.formatProgressLabel(completed, 3, 'en'),
        contains('Completed! Badge Unlocked'),
      );
      expect(
        engine.formatProgressLabel(completed, 3, 'uz'),
        contains('Bajarildi! Nishon ochildi'),
      );
      expect(
        engine.formatProgressLabel(completed, 3, 'ru'),
        contains('Завершено! Бейдж открыт'),
      );
    });

    test('JSON serialization roundtrips QuestStop, ArchitecturalQuest, and QuestProgress', () {
      final quest = engine.getQuestById('quest-soviet-modernism')!;
      final questJson = quest.toJson();
      final restoredQuest = ArchitecturalQuest.fromJson(questJson);

      expect(restoredQuest.id, equals(quest.id));
      expect(restoredQuest.stops.length, equals(3));
      expect(restoredQuest.stops.first.name, equals('Hotel Uzbekistan'));

      final progress = engine.calculateProgress(quest, {'stop-hotel-uzbekistan'});
      final progressJson = progress.toJson();
      final restoredProgress = QuestProgress.fromJson(progressJson);

      expect(restoredProgress.questId, equals(progress.questId));
      expect(restoredProgress.visitedStopIds, equals(progress.visitedStopIds));
      expect(restoredProgress.isCompleted, equals(progress.isCompleted));
    });

    test('architecturalBadgeEngineProvider initializes cleanly in ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final providedEngine = container.read(architecturalBadgeEngineProvider);
      expect(providedEngine, isA<ArchitecturalBadgeEngine>());
      expect(providedEngine.getAllQuests().length, greaterThanOrEqualTo(3));
    });
  });
}
