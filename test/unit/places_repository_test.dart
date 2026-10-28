import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  group('PlacesRepository Tests', () {
    late PlacesRepository repository;

    setUp(() {
      repository = PlacesRepository();
    });

    test('getPlaceById finds existing venues by ID', () {
      final kettle = repository.getPlaceById('kettle');
      expect(kettle, isNotNull);
      expect(kettle!.name, equals('Kettle & Loaf'));
      expect(kettle.district, equals('Barlow Hill'));

      final fern = repository.getPlaceById('fern');
      expect(fern, isNotNull);
      expect(fern!.name, equals('The Fern Room'));
    });

    test('getPlaceById returns null for non-existent venue ID', () {
      final nonExistent = repository.getPlaceById('non-existent-xyz');
      expect(nonExistent, isNull);
    });

    test('getNearbyPlaces returns all seed venues when category is All and search is empty', () async {
      final places = await repository.getNearbyPlaces();
      expect(places.length, greaterThanOrEqualTo(5));
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

    test('getNearbyPlaces filters by search query matching venue name', () async {
      final results = await repository.getNearbyPlaces(searchQuery: 'Kettle');
      expect(results.length, equals(1));
      expect(results.first.id, equals('kettle'));
    });

    test('getNearbyPlaces returns empty list when search yields no matches', () async {
      final results = await repository.getNearbyPlaces(searchQuery: 'UnknownNonExistentVenue999');
      expect(results.isEmpty, isTrue);
    });
  });
}
