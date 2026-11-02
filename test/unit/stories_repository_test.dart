import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/stories_repository.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  group('StoriesRepository 24h Stories Tests (P9-02)', () {
    late ProviderContainer container;
    late StoriesRepository notifier;

    setUp(() async {
      await StorageService.clearAll();
      container = ProviderContainer();
      notifier = container.read(storiesRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state contains default Tashkent venue stories with 24h expiry', () {
      final stories = container.read(storiesRepositoryProvider);
      expect(stories.isNotEmpty, isTrue);
      expect(stories.any((s) => s.placeId == 'breadly'), isTrue);
      expect(stories.any((s) => s.placeId == 'steam'), isTrue);

      final first = stories.first;
      expect(first.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('createStory prepends a new 24-hour venue story', () async {
      final initialCount = container.read(storiesRepositoryProvider).length;
      final success = await notifier.createStory(
        placeId: 'kitobxon',
        mediaUrl: 'assets/images/kitobxon.jpg',
        caption: 'Quiet corner for afternoon reading.',
        audience: 'friends',
      );

      expect(success, isTrue);
      final updated = container.read(storiesRepositoryProvider);
      expect(updated.length, equals(initialCount + 1));
      expect(updated.first.placeId, equals('kitobxon'));
      expect(updated.first.caption, equals('Quiet corner for afternoon reading.'));
      expect(updated.first.expiresAt.difference(DateTime.now()).inHours, greaterThanOrEqualTo(23));
    });

    test('deleteStory removes story from state', () async {
      final initialCount = container.read(storiesRepositoryProvider).length;
      await notifier.deleteStory('story-breadly-1');

      final updated = container.read(storiesRepositoryProvider);
      expect(updated.length, equals(initialCount - 1));
      expect(updated.any((s) => s.id == 'story-breadly-1'), isFalse);
    });

    test('getStoriesForPlace returns stories strictly matching venue ID or slug', () {
      final breadlyStories = notifier.getStoriesForPlace('breadly');
      expect(breadlyStories.isNotEmpty, isTrue);
      expect(breadlyStories.every((s) => s.placeId == 'breadly'), isTrue);

      final nonExistent = notifier.getStoriesForPlace('non_existent_venue');
      expect(nonExistent, isEmpty);
    });
  });
}
