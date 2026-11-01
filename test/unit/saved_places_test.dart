import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/saved_places_repository.dart';
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
}
