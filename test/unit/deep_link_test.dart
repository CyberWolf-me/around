import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/deep_link_service.dart';
import 'package:around_app/data/repositories/places_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeepLinkService & Universal Routing Tests (P10-01)', () {
    test('buildPlaceUri generates canonical web and custom scheme URIs', () {
      final webUri = DeepLinkService.buildPlaceUri('breadly', web: true);
      expect(webUri, equals('https://around.tashkent.app/places/breadly'));

      final appUri = DeepLinkService.buildPlaceUri('breadly', web: false);
      expect(appUri, equals('around://places/breadly'));
    });

    test('buildDropUri generates canonical web and custom scheme URIs', () {
      final webUri = DeepLinkService.buildDropUri('drop_tash_1', web: true);
      expect(webUri, equals('https://around.tashkent.app/drops/drop_tash_1'));

      final appUri = DeepLinkService.buildDropUri('drop_tash_1', web: false);
      expect(appUri, equals('around://drops/drop_tash_1'));
    });

    test('resolveRouteFromUri correctly maps custom app scheme URIs', () {
      final placeRoute = DeepLinkService.resolveRouteFromUri(Uri.parse('around://places/breadly'));
      expect(placeRoute, equals('/places/breadly'));

      final emptyPlaceRoute = DeepLinkService.resolveRouteFromUri(Uri.parse('around://places'));
      expect(emptyPlaceRoute, equals('/explore'));

      final dropRoute = DeepLinkService.resolveRouteFromUri(Uri.parse('around://drops/drop_tash_1'));
      expect(dropRoute, equals('/drops/drop_tash_1'));
    });

    test('resolveRouteFromUri correctly maps universal HTTPS links across supported domains', () {
      final canonicalPlace = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://around.tashkent.app/places/ecorn?ref=telegram'),
      );
      expect(canonicalPlace, equals('/places/ecorn'));

      final fallbackPlace = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://around.app/places/steam'),
      );
      expect(fallbackPlace, equals('/places/steam'));

      final dropRoute = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://around.tashkent.app/drops/drop_tash_2'),
      );
      expect(dropRoute, equals('/drops/drop_tash_2'));

      final feedRoute = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://around.tashkent.app/feed'),
      );
      expect(feedRoute, equals('/feed'));
    });

    test('resolveRouteFromUri ignores unknown domains safely', () {
      final untrustedRoute = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://malicious-phishing.com/places/breadly'),
      );
      expect(untrustedRoute, isNull);
    });

    test('copyPlaceShareLink and copyDropShareLink return canonical URLs', () async {
      final placeLink = await DeepLinkService.copyPlaceShareLink('kitobxon');
      expect(placeLink, equals('https://around.tashkent.app/places/kitobxon'));

      final dropLink = await DeepLinkService.copyDropShareLink('drop_tash_3');
      expect(dropLink, equals('https://around.tashkent.app/drops/drop_tash_3'));
    });

    test('Deep link place targets align with PlacesRepository canonical slug resolution', () {
      const alias = 'kettle';
      final canonical = PlacesRepository.resolveCanonicalId(alias);
      expect(canonical, equals('breadly'));

      final route = DeepLinkService.resolveRouteFromUri(Uri.parse('around://places/$canonical'));
      expect(route, equals('/places/breadly'));
    });
  });
}
