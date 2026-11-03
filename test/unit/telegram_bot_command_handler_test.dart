import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/telegram_bot_command_handler.dart';

void main() {
  group('P32-03: TelegramBotCommandHandler Unit Tests', () {
    late TelegramBotCommandHandler handler;

    setUp(() {
      handler = TelegramBotCommandHandler();
    });

    test('handles standard /start command with Mini App launcher button', () {
      final reply = handler.handleMessage(
        messageText: '/start',
        fromUsername: 'sardor_tashkent',
        languageCode: 'en',
      );

      expect(reply.command, equals(TelegramBotCommand.start));
      expect(reply.text, contains('Welcome, @sardor_tashkent!'));
      expect(reply.text, contains('Around is Tashkent\'s places-first social discovery platform'));
      expect(reply.inlineKeyboard, isNotEmpty);
      expect(reply.inlineKeyboard[0][0].text, equals('🚀 Launch Mini App'));
      expect(reply.inlineKeyboard[0][0].webAppUrl, equals('https://t.me/around_tashkent_bot/app'));

      // Check Telegram JSON format
      final json = reply.toJson();
      expect(json['parse_mode'], equals('Markdown'));
      expect(json['reply_markup']['inline_keyboard'], isNotEmpty);
    });

    test('handles /start with route_ payload linking directly to route trail', () {
      final reply = handler.handleMessage(
        messageText: '/start route_mirabad_coffee_crawl',
        languageCode: 'uz',
      );

      expect(reply.command, equals(TelegramBotCommand.start));
      expect(reply.text, contains('Saralangan Marshrut'));
      expect(reply.inlineKeyboard[0][0].text, equals('🚶 Marshrutni Ochish'));
      expect(
        reply.inlineKeyboard[0][0].webAppUrl,
        equals('https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl'),
      );
    });

    test('handles /start with postcard_ payload linking directly to receipt', () {
      final reply = handler.handleMessage(
        messageText: '/start postcard_REC-MIR-2026-774',
        languageCode: 'ru',
      );

      expect(reply.command, equals(TelegramBotCommand.start));
      expect(reply.text, contains('Культурная Открытка и Чек'));
      expect(reply.inlineKeyboard[0][0].text, equals('💌 Посмотреть Открытку'));
      expect(
        reply.inlineKeyboard[0][0].webAppUrl,
        equals('https://t.me/around_tashkent_bot/app?startapp=postcard_REC-MIR-2026-774'),
      );
    });

    test('handles /passport command with specific curator handle', () {
      final reply = handler.handleMessage(
        messageText: '/passport @kamila_c',
        languageCode: 'en',
      );

      expect(reply.command, equals(TelegramBotCommand.passport));
      expect(reply.text, contains('@kamila_c\'s Taste Passport'));
      expect(
        reply.inlineKeyboard[0][0].webAppUrl,
        equals('https://t.me/around_tashkent_bot/app?startapp=passport_kamila_c'),
      );
    });

    test('handles /trophies command with trophies deep link', () {
      final reply = handler.handleMessage(
        messageText: '/trophies',
        languageCode: 'ru',
      );

      expect(reply.command, equals(TelegramBotCommand.trophies));
      expect(reply.text, contains('Сезонные Трофеи и Зал Славы'));
      expect(
        reply.inlineKeyboard[0][0].webAppUrl,
        equals('https://t.me/around_tashkent_bot/app?startapp=trophies'),
      );
    });

    test('handles /routes command with curated route preview list', () {
      final reply = handler.handleMessage(
        messageText: '/routes',
        languageCode: 'en',
      );

      expect(reply.command, equals(TelegramBotCommand.routes));
      expect(reply.text, contains('Mirabad Specialty Coffee Crawl'));
      expect(reply.text, contains('Chorsu & Old City Artisan Walk'));
      expect(
        reply.inlineKeyboard[0][0].webAppUrl,
        equals('https://t.me/around_tashkent_bot/app?startapp=routes'),
      );
    });

    test('handles /help command listing all available commands in Uzbek', () {
      final reply = handler.handleMessage(
        messageText: '/help',
        languageCode: 'uz',
      );

      expect(reply.command, equals(TelegramBotCommand.help));
      expect(reply.text, contains('/start — Ilovani ishga tushirish'));
      expect(reply.text, contains('/passport — O\'z ta\'m pasportingizni ko\'rish'));
      expect(reply.text, contains('/trophies — Oylik mavsumiy kuboklar'));
    });

    test('handles unknown command with friendly fallback', () {
      final reply = handler.handleMessage(
        messageText: '/xyz123',
        languageCode: 'en',
      );

      expect(reply.command, equals(TelegramBotCommand.unknown));
      expect(reply.text, contains('Unknown command: `/xyz123`'));
      expect(reply.text, contains('Send /help'));
    });

    test('Riverpod provider initializes TelegramBotCommandHandler cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(telegramBotCommandHandlerProvider);
      expect(service, isA<TelegramBotCommandHandler>());
    });
  });
}
