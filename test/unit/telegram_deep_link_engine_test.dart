import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/telegram_deep_link_engine.dart';

void main() {
  group('P29-01: TelegramDeepLinkEngine Unit Tests', () {
    test('parseStartParam handles null, empty, and whitespace safely', () {
      final nullTarget = TelegramDeepLinkEngine.parseStartParam(null);
      expect(nullTarget.type, equals(TelegramDeepLinkType.unknown));
      expect(nullTarget.appRoute, equals('/explore'));
      expect(nullTarget.isValid, isFalse);

      final emptyTarget = TelegramDeepLinkEngine.parseStartParam('   ');
      expect(emptyTarget.type, equals(TelegramDeepLinkType.unknown));
      expect(emptyTarget.appRoute, equals('/explore'));
    });

    test('parseStartParam parses route payloads with optional referral', () {
      final target = TelegramDeepLinkEngine.parseStartParam('route_mirabad_coffee_crawl');
      expect(target.type, equals(TelegramDeepLinkType.route));
      expect(target.resourceId, equals('mirabad_coffee_crawl'));
      expect(target.appRoute, equals('/explore/routes/mirabad_coffee_crawl'));
      expect(target.referrerId, isNull);
      expect(target.isValid, isTrue);

      final withRef = TelegramDeepLinkEngine.parseStartParam('route_mirabad_coffee_crawl__ref_kamila');
      expect(withRef.type, equals(TelegramDeepLinkType.route));
      expect(withRef.resourceId, equals('mirabad_coffee_crawl'));
      expect(withRef.referrerId, equals('kamila'));
      expect(withRef.appRoute, equals('/explore/routes/mirabad_coffee_crawl'));
    });

    test('parseStartParam parses postcard and cultural receipt payloads', () {
      final target = TelegramDeepLinkEngine.parseStartParam('postcard_REC-MIR-2026-774');
      expect(target.type, equals(TelegramDeepLinkType.postcard));
      expect(target.resourceId, equals('REC-MIR-2026-774'));
      expect(target.appRoute, equals('/explore/postcards/REC-MIR-2026-774'));
      expect(target.isValid, isTrue);
    });

    test('parseStartParam parses season and group crawl payloads', () {
      final season = TelegramDeepLinkEngine.parseStartParam('season_2026-11');
      expect(season.type, equals(TelegramDeepLinkType.season));
      expect(season.resourceId, equals('2026-11'));
      expect(season.appRoute, equals('/explore/seasons/2026-11'));

      final crawl = TelegramDeepLinkEngine.parseStartParam('crawl_CR-MRB-77');
      expect(crawl.type, equals(TelegramDeepLinkType.crawl));
      expect(crawl.resourceId, equals('CR-MRB-77'));
      expect(crawl.appRoute, equals('/explore/crawl/CR-MRB-77'));
    });

    test('parseStartParam parses curator referral link', () {
      final ref = TelegramDeepLinkEngine.parseStartParam('ref_kamila_tashkent');
      expect(ref.type, equals(TelegramDeepLinkType.referral));
      expect(ref.resourceId, equals('kamila_tashkent'));
      expect(ref.referrerId, equals('kamila_tashkent'));
      expect(ref.appRoute, equals('/explore'));
    });

    test('buildBotUrl formats canonical Telegram URLs', () {
      final routeUrl = TelegramDeepLinkEngine.buildBotUrl(
        type: TelegramDeepLinkType.route,
        resourceId: 'mirabad_coffee_crawl',
      );
      expect(routeUrl, equals('https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl'));

      final withRefUrl = TelegramDeepLinkEngine.buildBotUrl(
        type: TelegramDeepLinkType.route,
        resourceId: 'mirabad_coffee_crawl',
        referrerId: 'kamila',
      );
      expect(withRefUrl, equals('https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl__ref_kamila'));

      final refUrl = TelegramDeepLinkEngine.buildBotUrl(
        type: TelegramDeepLinkType.referral,
        resourceId: 'kamila',
      );
      expect(refUrl, equals('https://t.me/around_tashkent_bot/app?startapp=ref_kamila'));
    });

    test('formatShareMessage generates attractive localized messages', () {
      final uzMsg = TelegramDeepLinkEngine.formatShareMessage(
        type: TelegramDeepLinkType.route,
        title: 'Mirabad Specialty Coffee Crawl',
        url: 'https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl',
        language: 'uz',
      );
      expect(uzMsg, contains('Toshkent bo‘ylab sayr'));
      expect(uzMsg, contains('Around ilovasida'));

      final ruMsg = TelegramDeepLinkEngine.formatShareMessage(
        type: TelegramDeepLinkType.postcard,
        title: 'Breadly Bakery & Cafe',
        url: 'https://t.me/around_tashkent_bot/app?startapp=postcard_REC-MIR-2026-774',
        language: 'ru',
      );
      expect(ruMsg, contains('Ташкентский Культурный Чек'));

      final enMsg = TelegramDeepLinkEngine.formatShareMessage(
        type: TelegramDeepLinkType.season,
        title: 'Autumn in Tashkent',
        url: 'https://t.me/around_tashkent_bot/app?startapp=season_2026-11',
        language: 'en',
      );
      expect(enMsg, contains('Around Monthly Season'));
    });

    test('Riverpod provider initializes TelegramDeepLinkEngine cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final engine = container.read(telegramDeepLinkEngineProvider);
      expect(engine, isA<TelegramDeepLinkEngine>());
    });
  });
}
