import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  group('PlacesRepository Tests', () {
    late PlacesRepository repository;

    setUp(() {
      repository = PlacesRepository();
    });

    test('getPlaceById finds canonical Tashkent venues and resolves legacy aliases', () {
      final breadly = repository.getPlaceById('breadly');
      expect(breadly, isNotNull);
      expect(breadly!.name, equals('Breadly Bakery & Café'));
      expect(breadly.district, equals('Mirabad'));
      expect(breadly.canonicalUuid, equals('11111111-1111-4111-8111-111111111101'));

      final bnb = repository.getPlaceById('bnb');
      expect(bnb, isNotNull);
      expect(bnb!.name, equals('B&B Coffee House'));

      // Legacy alias resolution without duplicating venues in getAllPlaces()
      final legacyKettle = repository.getPlaceById('kettle');
      expect(legacyKettle, isNotNull);
      expect(legacyKettle!.id, equals('breadly'));
    });

    test('getPlaceById returns null for non-existent venue ID', () {
      final nonExistent = repository.getPlaceById('non-existent-xyz');
      expect(nonExistent, isNull);
    });

    test('getAllPlaces and getNearbyPlaces return all 50 canonical Tashkent venues without duplicate aliases', () async {
      final allPlaces = repository.getAllPlaces();
      expect(allPlaces.length, equals(50));
      final uniqueAllIds = allPlaces.map((p) => p.id).toSet();
      expect(uniqueAllIds.length, equals(50));

      final places = await repository.getNearbyPlaces(limit: 60);
      expect(places.length, equals(50));
      final uniqueIds = places.map((p) => p.id).toSet();
      expect(uniqueIds.length, equals(places.length));

      // Verify newly added high-vibe venues (Sprint 1 & Phase 12B)
      expect(repository.getPlaceById('sette'), isNotNull);
      expect(repository.getPlaceById('socials'), isNotNull);
      expect(repository.getPlaceById('afsona'), isNotNull);
      expect(repository.getPlaceById('caravan'), isNotNull);
      expect(repository.getPlaceById('teplo'), isNotNull);
      expect(repository.getPlaceById('pie-republic'), isNotNull);
      expect(repository.getPlaceById('besh-qozon-plov'), isNotNull);
      expect(repository.getPlaceById('humo-arena-plaza'), isNotNull);
    });

    test('getNearbyPlaces filters by category accurately', () async {
      final cafes = await repository.getNearbyPlaces(category: 'Café');
      expect(cafes.isNotEmpty, isTrue);
      for (final place in cafes) {
        final matches = place.category.toLowerCase().contains('café') ||
            place.category.toLowerCase().contains('cafe') ||
            place.tags.any((t) => t.toLowerCase().contains('café') || t.toLowerCase().contains('cafe'));
        expect(matches, isTrue);
      }
    });

    test('getNearbyPlaces filters by search query matching venue name or district', () async {
      final results = await repository.getNearbyPlaces(searchQuery: 'Breadly');
      expect(results.length, equals(1));
      expect(results.first.id, equals('breadly'));
    });

    test('getNearbyPlaces returns empty list when search yields no matches', () async {
      final results = await repository.getNearbyPlaces(searchQuery: 'UnknownNonExistentVenue999');
      expect(results.isEmpty, isTrue);
    });

    test('getNearbyPlaces supports deterministic keyset cursor pagination without duplicate venues (P8-01)', () async {
      // Fetch Page 1 with limit 5
      final page1 = await repository.getNearbyPlaces(limit: 5);
      expect(page1.length, equals(5));

      final lastVenue = page1.last;
      final lastDist = lastVenue.distanceMeters;

      // Fetch Page 2 using cursor from last item of Page 1
      final page2 = await repository.getNearbyPlaces(
        limit: 5,
        cursorDistance: lastDist,
        cursorId: lastVenue.id,
      );

      expect(page2.isNotEmpty, isTrue);
      // Ensure zero overlap between Page 1 and Page 2
      final page1Ids = page1.map((p) => p.id).toSet();
      for (final p in page2) {
        expect(page1Ids.contains(p.id), isFalse, reason: 'Venue ${p.id} duplicated across cursor boundaries');
      }
    });

    test('getRecommendedPlaces ranks friend-recommended venues highest and excludes been places (Phase 6)', () {
      final recs = repository.getRecommendedPlaces(
        acceptedFriendPlaceIds: {'breadly', 'tims'},
        savedPlaceIds: {'breadly', 'bnb'},
        savedStatuses: {'bnb': 'been', 'breadly': 'want_to_go'},
      );

      expect(recs.isNotEmpty, isTrue);
      // 'bnb' is marked as 'been' and must be excluded from new discovery recommendations
      expect(recs.any((r) => r.place.id == 'bnb'), isFalse);
      // Top recommendations must be the friend-recommended spots with explainable reasons
      expect({'breadly', 'tims'}.contains(recs.first.place.id), isTrue);
      expect(recs.first.explanation, contains('Recommended by your accepted friends'));
    });
  });
}
