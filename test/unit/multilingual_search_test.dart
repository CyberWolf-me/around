import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/transliteration_service.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  group('P14-02: Multilingual Cyrillic/Latin Uzbek & Russian Search Normalizer Tests', () {
    test('TransliterationService converts Uzbek and Russian Cyrillic to normalized Latin', () {
      expect(TransliterationService.cyrillicToLatin('кофе'), 'kofe');
      expect(TransliterationService.cyrillicToLatin('Миробод'), 'Mirobod');
      expect(TransliterationService.cyrillicToLatin('чойхона'), 'choyxona');
      expect(TransliterationService.cyrillicToLatin('ўзбек'), "o'zbek");
      expect(TransliterationService.cyrillicToLatin('ғиждувон'), "g'ijduvon");
      expect(TransliterationService.cyrillicToLatin('қаҳва'), 'qahva');
    });

    test('TransliterationService normalizes varied apostrophe characters', () {
      expect(TransliterationService.normalizeApostrophes("o'zbek"), "o'zbek");
      expect(TransliterationService.normalizeApostrophes("o’zbek"), "o'zbek");
      expect(TransliterationService.normalizeApostrophes("oʻzbek"), "o'zbek");
      expect(TransliterationService.normalizeApostrophes("oʼzbek"), "o'zbek");
      expect(TransliterationService.normalizeApostrophes("o`zbek"), "o'zbek");
    });

    test('TransliterationService expands cross-language synonyms across Russian, Uzbek, English', () {
      final coffeeTerms = TransliterationService.expandSearchTerms('кофе');
      expect(coffeeTerms.contains('coffee'), isTrue);
      expect(coffeeTerms.contains('kofe'), isTrue);
      expect(coffeeTerms.contains('qahva'), isTrue);

      final bakeryTerms = TransliterationService.expandSearchTerms('пекарня');
      expect(bakeryTerms.contains('bakery'), isTrue);
      expect(bakeryTerms.contains('nonvoyxona'), isTrue);

      final plovTerms = TransliterationService.expandSearchTerms('плов');
      expect(plovTerms.contains('plov'), isTrue);
      expect(plovTerms.contains('osh'), isTrue);
    });

    test('PlacesRepository searchPlacesMultilingual resolves Cyrillic queries to canonical places', () {
      final repo = PlacesRepository();

      // Russian query for coffee
      final coffeeResults = repo.searchPlacesMultilingual('кофе');
      expect(coffeeResults.isNotEmpty, isTrue);
      expect(coffeeResults.any((p) => p.name.contains('Breadly') || p.category.contains('Coffee')), isTrue);

      // Uzbek Cyrillic query for Mirabad district
      final mirabadResults = repo.searchPlacesMultilingual('Миробод');
      expect(mirabadResults.isNotEmpty, isTrue);
      for (final p in mirabadResults) {
        expect(p.district, 'Mirabad');
      }

      // Russian query for bakery
      final bakeryResults = repo.searchPlacesMultilingual('выпечка');
      expect(bakeryResults.isNotEmpty, isTrue);

      // Russian query for wine
      final wineResults = repo.searchPlacesMultilingual('вино');
      expect(wineResults.isNotEmpty, isTrue);
      expect(wineResults.any((p) => p.tags.contains('natural wine') || p.category.contains('Wine')), isTrue);

      // Empty query returns entire catalog
      final allResults = repo.searchPlacesMultilingual('');
      expect(allResults.length, repo.getAllPlaces().length);
    });

    test('PlacesRepository getNearbyPlaces filters with multilingual search queries', () async {
      final repo = PlacesRepository();

      final paginatedResults = await repo.getNearbyPlaces(
        searchQuery: 'кофейня',
        limit: 10,
      );

      expect(paginatedResults.isNotEmpty, isTrue);
      expect(paginatedResults.any((p) => p.tags.contains('coffee') || p.category.contains('Coffee') || p.category.contains('Café')), isTrue);
    });
  });
}
