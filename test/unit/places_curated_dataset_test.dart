import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  group('P12-07: 50-Seed Curated Tashkent Venue Dataset Integrity Tests', () {
    late PlacesRepository repository;

    setUp(() {
      repository = PlacesRepository();
    });

    test('Repository contains exactly 50 canonical Tashkent places', () {
      final places = repository.getAllPlaces();
      expect(places.length, equals(50));
    });

    test('All 50 places have unique IDs and unique canonical UUIDs', () {
      final places = repository.getAllPlaces();
      final ids = places.map((p) => p.id).toList();
      final uuids = places.map((p) => p.canonicalUuid).toList();

      expect(ids.toSet().length, equals(50), reason: 'All place IDs must be distinct');
      expect(uuids.toSet().length, equals(50), reason: 'All canonical UUIDs must be distinct');

      // UUID format check: 8-4-4-4-12 hex string
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
      for (final place in places) {
        expect(place.canonicalUuid, isNotNull);
        expect(uuidRegex.hasMatch(place.canonicalUuid!), isTrue,
            reason: 'Place ${place.id} has invalid UUID format: ${place.canonicalUuid}');
      }
    });

    test('All 50 places have unique, valid kebab-case slugs', () {
      final places = repository.getAllPlaces();
      final slugs = places.map((p) => p.slug).toList();

      expect(slugs.toSet().length, equals(50), reason: 'All venue slugs must be unique');

      final slugRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      for (final place in places) {
        expect(slugRegex.hasMatch(place.slug), isTrue,
            reason: 'Place ${place.id} slug "${place.slug}" is not valid kebab-case');
      }
    });

    test('All 50 places fall strictly within the Tashkent metropolitan bounding box', () {
      final places = repository.getAllPlaces();

      // Tashkent metropolitan bounding box: [41.20, 69.15] to [41.40, 69.40]
      const double minLat = 41.20;
      const double maxLat = 41.40;
      const double minLng = 69.15;
      const double maxLng = 69.40;

      for (final place in places) {
        expect(place.latitude, greaterThanOrEqualTo(minLat),
            reason: 'Place ${place.id} latitude (${place.latitude}) is below Tashkent min ($minLat)');
        expect(place.latitude, lessThanOrEqualTo(maxLat),
            reason: 'Place ${place.id} latitude (${place.latitude}) is above Tashkent max ($maxLat)');
        expect(place.longitude, greaterThanOrEqualTo(minLng),
            reason: 'Place ${place.id} longitude (${place.longitude}) is below Tashkent min ($minLng)');
        expect(place.longitude, lessThanOrEqualTo(maxLng),
            reason: 'Place ${place.id} longitude (${place.longitude}) is above Tashkent max ($maxLng)');
      }
    });

    test('Curated dataset spans all 5 central districts of Tashkent', () {
      final places = repository.getAllPlaces();
      final districts = places.map((p) => p.district).toSet();

      expect(districts.contains('Mirabad'), isTrue, reason: 'Mirabad must be represented');
      expect(districts.contains('Yakkasaray'), isTrue, reason: 'Yakkasaray must be represented');
      expect(districts.contains('Central Tashkent'), isTrue, reason: 'Central Tashkent must be represented');
      expect(districts.contains('Yunusabad'), isTrue, reason: 'Yunusabad must be represented');
      expect(districts.contains('Shaykhontohur'), isTrue, reason: 'Shaykhontohur must be represented');

      // Verify healthy venue distribution per district (at least 5 places per central district)
      for (final district in ['Mirabad', 'Yakkasaray', 'Central Tashkent', 'Yunusabad', 'Shaykhontohur']) {
        final count = places.where((p) => p.district == district).length;
        expect(count, greaterThanOrEqualTo(5),
            reason: 'District $district has only $count venues; expected >= 5');
      }
    });

    test('All 50 places have complete, non-empty metadata fields', () {
      final places = repository.getAllPlaces();

      for (final place in places) {
        expect(place.name.trim().isNotEmpty, isTrue, reason: 'Venue ${place.id} must have a name');
        expect(place.category.trim().isNotEmpty, isTrue, reason: 'Venue ${place.id} must have a category');
        expect(place.streetAddress.trim().isNotEmpty, isTrue, reason: 'Venue ${place.id} must have an address');
        expect(place.city, equals('Tashkent'), reason: 'Venue ${place.id} city must be Tashkent');
        expect(place.description.trim().isNotEmpty, isTrue, reason: 'Venue ${place.id} must have a description');
        expect(place.heroImageUrl.trim().isNotEmpty, isTrue, reason: 'Venue ${place.id} must have a hero image');
        expect(place.ratingAvg, inInclusiveRange(4.0, 5.0), reason: 'Venue ${place.id} rating must be 4.0-5.0');
        expect(place.ratingCount, greaterThan(0), reason: 'Venue ${place.id} ratingCount must be > 0');
        expect(place.tags.isNotEmpty, isTrue, reason: 'Venue ${place.id} must have tags');
        expect(place.photos.isNotEmpty, isTrue, reason: 'Venue ${place.id} must have photos');
      }
    });

    test('SQL migration file 00012 exists and contains idempotent ON CONFLICT (id) DO UPDATE', () {
      final migrationFile = File('supabase/migrations/00012_curated_tashkent_venues.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00012 file must exist');

      final content = migrationFile.readAsStringSync();
      expect(content.contains('INSERT INTO public.places'), isTrue);
      expect(content.contains('ON CONFLICT (id) DO UPDATE SET'), isTrue);
      expect(content.contains('11111111-1111-4111-8111-111111111101'), isTrue);
      expect(content.contains('11111111-1111-4111-8111-111111111150'), isTrue);
    });
  });
}
