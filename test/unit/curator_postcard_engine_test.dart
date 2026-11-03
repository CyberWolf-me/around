import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_postcard_engine.dart';

void main() {
  group('P27-01: CuratorPostcardEngine Unit Tests', () {
    test('generateReceiptNumber generates formatted receipt code', () {
      final rec = CuratorPostcardEngine.generateReceiptNumber('Mirabad');
      expect(rec, startsWith('REC-MIR-'));
      expect(rec, contains('${DateTime.now().year}'));

      final fallbackRec = CuratorPostcardEngine.generateReceiptNumber('X');
      expect(fallbackRec, startsWith('REC-TAS-'));
    });

    test('createPostcard builds valid model with specified parameters', () {
      final postcard = CuratorPostcardEngine.createPostcard(
        placeId: 'place_breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        atmosphereTag: 'Morning Brew',
        verifiedSeal: 'AR-B742-1894',
        nearestSubway: 'Oybek',
        curatorName: 'Kamila',
        curatorHandle: 'kamilar',
        curatorTier: 'tashkentLegend',
        curatorXp: 2450,
        itemsVisitedCount: 3,
        theme: PostcardTheme.warmPaper,
        aspectRatio: PostcardAspectRatio.story9x16,
      );

      expect(postcard.placeId, equals('place_breadly'));
      expect(postcard.placeName, equals('Breadly Bakery & Café'));
      expect(postcard.district, equals('Mirabad'));
      expect(postcard.verifiedSeal, equals('AR-B742-1894'));
      expect(postcard.nearestSubway, equals('Oybek'));
      expect(postcard.curatorName, equals('Kamila'));
      expect(postcard.curatorXp, equals(2450));
      expect(postcard.itemsVisitedCount, equals(3));
      expect(postcard.theme, equals(PostcardTheme.warmPaper));
      expect(postcard.aspectRatio, equals(PostcardAspectRatio.story9x16));
    });

    test('copyWith allows theme and aspect ratio updates', () {
      final original = CuratorPostcardEngine.createPostcard(
        placeId: 'place_breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        atmosphereTag: 'Morning Brew',
        verifiedSeal: 'AR-B742-1894',
        nearestSubway: 'Oybek',
        curatorName: 'Kamila',
        curatorHandle: 'kamilar',
        curatorTier: 'tashkentLegend',
        curatorXp: 2450,
      );

      final modified = original.copyWith(
        theme: PostcardTheme.darkCarbon,
        aspectRatio: PostcardAspectRatio.square1x1,
      );

      expect(modified.theme, equals(PostcardTheme.darkCarbon));
      expect(modified.aspectRatio, equals(PostcardAspectRatio.square1x1));
      expect(modified.placeName, equals(original.placeName));
      expect(modified.receiptNumber, equals(original.receiptNumber));
    });

    test('CuratorPostcard serializes and deserializes accurately', () {
      final postcard = CuratorPostcardEngine.createPostcard(
        placeId: 'place_breadly',
        placeName: 'Breadly Bakery & Café',
        district: 'Mirabad',
        atmosphereTag: 'Morning Brew',
        verifiedSeal: 'AR-B742-1894',
        nearestSubway: 'Oybek',
        curatorName: 'Kamila',
        curatorHandle: 'kamilar',
        curatorTier: 'tashkentLegend',
        curatorXp: 2450,
        theme: PostcardTheme.matchaMint,
      );

      final json = postcard.toJson();
      expect(json['place_id'], equals('place_breadly'));
      expect(json['theme'], equals('matchaMint'));
      expect(json['aspect_ratio'], equals('story9x16'));

      final parsed = CuratorPostcard.fromJson(json);
      expect(parsed.placeId, equals(postcard.placeId));
      expect(parsed.theme, equals(PostcardTheme.matchaMint));
      expect(parsed.aspectRatio, equals(PostcardAspectRatio.story9x16));
      expect(parsed.curatorXp, equals(2450));
    });

    test('Localizations for themes and receipt header', () {
      expect(CuratorPostcardEngine.getLocalizedThemeName(PostcardTheme.warmPaper, 'uz'), equals('Issiq Qog‘oz'));
      expect(CuratorPostcardEngine.getLocalizedThemeName(PostcardTheme.darkCarbon, 'ru'), equals('Тёмный карбон'));
      expect(CuratorPostcardEngine.getLocalizedThemeName(PostcardTheme.matchaMint, 'en'), equals('Matcha Mint'));

      expect(CuratorPostcardEngine.getLocalizedReceiptHeader('uz'), equals('TOSHKENT MADANIY CHEKI & KARTA'));
      expect(CuratorPostcardEngine.getLocalizedReceiptHeader('ru'), equals('ТАШКЕНТСКИЙ КУЛЬТУРНЫЙ ЧЕК'));
      expect(CuratorPostcardEngine.getLocalizedReceiptHeader('en'), equals('TASHKENT CULTURAL RECEIPT'));
    });

    test('Riverpod curatorPostcardEngineProvider exposes service singleton', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(curatorPostcardEngineProvider);
      expect(engine, isNotNull);
    });
  });
}
