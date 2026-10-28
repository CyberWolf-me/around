import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/saved_places_repository.dart';

void main() {
  group('SavedPlacesNotifier Tests', () {
    late ProviderContainer container;
    late SavedPlacesNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(savedPlacesProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial saved list contains seed places', () {
      final saved = container.read(savedPlacesProvider);
      expect(saved.contains('kettle'), isTrue);
      expect(saved.contains('sable'), isTrue);
      expect(notifier.isSaved('kettle'), isTrue);
    });

    test('toggleSave removes place if currently saved', () {
      expect(notifier.isSaved('kettle'), isTrue);
      notifier.toggleSave('kettle');
      expect(notifier.isSaved('kettle'), isFalse);
      expect(container.read(savedPlacesProvider).contains('kettle'), isFalse);
    });

    test('toggleSave adds place if not currently saved', () {
      expect(notifier.isSaved('fern'), isFalse);
      notifier.toggleSave('fern');
      expect(notifier.isSaved('fern'), isTrue);
      expect(container.read(savedPlacesProvider).contains('fern'), isTrue);
    });

    test('remove deletes place from saved list', () {
      expect(notifier.isSaved('sable'), isTrue);
      notifier.remove('sable');
      expect(notifier.isSaved('sable'), isFalse);
      expect(container.read(savedPlacesProvider).contains('sable'), isFalse);
    });
  });
}
