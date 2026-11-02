import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/saved_places_repository.dart';
import 'package:around_app/data/repositories/collections_repository.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  group('SavedPlacesNotifier & Statuses Tests', () {
    late ProviderContainer container;
    late SavedPlacesNotifier notifier;
    late SavedPlaceStatusesNotifier statusNotifier;

    setUp(() async {
      await StorageService.clearAll();
      container = ProviderContainer();
      notifier = container.read(savedPlacesProvider.notifier);
      statusNotifier = container.read(savedPlaceStatusesProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial saved list contains canonical Tashkent places', () {
      final saved = container.read(savedPlacesProvider);
      expect(saved.contains('breadly'), isTrue);
      expect(saved.contains('bnb'), isTrue);
      expect(notifier.isSaved('breadly'), isTrue);
      // Also resolves legacy alias
      expect(notifier.isSaved('kettle'), isTrue);
    });

    test('toggleSave removes place if currently saved and adds if not saved', () {
      expect(notifier.isSaved('breadly'), isTrue);
      notifier.toggleSave('breadly');
      expect(notifier.isSaved('breadly'), isFalse);

      expect(notifier.isSaved('chorsu'), isFalse);
      notifier.toggleSave('chorsu');
      expect(notifier.isSaved('chorsu'), isTrue);
    });

    test('SavedPlaceStatusesNotifier tracks and updates want_to_go vs been status', () async {
      expect(statusNotifier.getStatus('breadly'), equals('want_to_go'));
      expect(statusNotifier.getStatus('bnb'), equals('been'));

      await statusNotifier.setStatus('breadly', 'been');
      expect(statusNotifier.getStatus('breadly'), equals('been'));
    });

    test('remove deletes place from saved list', () {
      expect(notifier.isSaved('steam'), isTrue);
      notifier.remove('steam');
      expect(notifier.isSaved('steam'), isFalse);
    });
  });

  group('CollectionsNotifier Tests', () {
    late ProviderContainer container;
    late CollectionsNotifier notifier;

    setUp(() async {
      await StorageService.clearAll();
      container = ProviderContainer();
      notifier = container.read(collectionsRepositoryProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state loads default Tashkent collections', () {
      final collections = container.read(collectionsRepositoryProvider);
      expect(collections.isNotEmpty, isTrue);
      expect(collections.any((c) => c.id == 'col-coffee-1'), isTrue);
      expect(collections.any((c) => c.id == 'col-night-1'), isTrue);
    });

    test('createCollection creates and prepends a new custom collection', () async {
      final initialCount = container.read(collectionsRepositoryProvider).length;
      final created = await notifier.createCollection(
        title: 'Best Matcha Spots',
        description: 'Ceremonial grade matcha spots in Tashkent',
        audience: 'public',
      );

      final updated = container.read(collectionsRepositoryProvider);
      expect(updated.length, equals(initialCount + 1));
      expect(updated.first.id, equals(created.id));
      expect(updated.first.title, equals('Best Matcha Spots'));
      expect(updated.first.description, equals('Ceremonial grade matcha spots in Tashkent'));
      expect(updated.first.audience, equals('public'));
      expect(updated.first.placeIds, isEmpty);
    });

    test('addPlaceToCollection adds canonical place ID to collection', () async {
      await notifier.addPlaceToCollection('col-night-1', 'breadly');
      final collections = container.read(collectionsRepositoryProvider);
      final col = collections.firstWhere((c) => c.id == 'col-night-1');
      expect(col.placeIds.contains('breadly'), isTrue);

      // Verify idempotency (cannot add duplicate place ID)
      await notifier.addPlaceToCollection('col-night-1', 'breadly');
      final colAfterDuplicate = container.read(collectionsRepositoryProvider).firstWhere((c) => c.id == 'col-night-1');
      expect(colAfterDuplicate.placeIds.where((id) => id == 'breadly').length, equals(1));
    });

    test('removePlaceFromCollection removes place ID from collection', () async {
      await notifier.removePlaceFromCollection('col-coffee-1', 'breadly');
      final collections = container.read(collectionsRepositoryProvider);
      final col = collections.firstWhere((c) => c.id == 'col-coffee-1');
      expect(col.placeIds.contains('breadly'), isFalse);
      expect(col.placeIds.contains('bnb'), isTrue);
    });

    test('deleteCollection removes collection from state', () async {
      final initialCount = container.read(collectionsRepositoryProvider).length;
      await notifier.deleteCollection('col-night-1');
      final collections = container.read(collectionsRepositoryProvider);
      expect(collections.length, equals(initialCount - 1));
      expect(collections.any((c) => c.id == 'col-night-1'), isFalse);
    });
  });

  group('FriendPlansNotifier RSVP Tests', () {
    late ProviderContainer container;
    late FriendPlansNotifier plansNotifier;

    setUp(() async {
      await StorageService.clearAll();
      container = ProviderContainer();
      plansNotifier = container.read(friendPlansProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial plans contain seeded Tashkent friend plans', () {
      final plans = container.read(friendPlansProvider);
      expect(plans.isNotEmpty, isTrue);
      expect(plans.any((p) => p.placeId == 'breadly'), isTrue);
    });

    test('rsvpToPlan updates RSVP status and toggles off when selected again (P8-04)', () async {
      final plans = container.read(friendPlansProvider);
      final targetPlan = plans.first;
      expect(targetPlan.myRsvp, isNull);

      // RSVP 'going'
      await plansNotifier.rsvpToPlan(targetPlan.id, 'going');
      final goingPlan = container.read(friendPlansProvider).firstWhere((p) => p.id == targetPlan.id);
      expect(goingPlan.myRsvp, equals('going'));

      // Toggle off by selecting 'going' again
      await plansNotifier.rsvpToPlan(targetPlan.id, 'going');
      final toggledOffPlan = container.read(friendPlansProvider).firstWhere((p) => p.id == targetPlan.id);
      expect(toggledOffPlan.myRsvp, isNull);

      // Switch to 'declined'
      await plansNotifier.rsvpToPlan(targetPlan.id, 'declined');
      final declinedPlan = container.read(friendPlansProvider).firstWhere((p) => p.id == targetPlan.id);
      expect(declinedPlan.myRsvp, equals('declined'));
    });
  });
}
