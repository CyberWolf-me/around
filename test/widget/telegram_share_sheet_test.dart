import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/telegram_deep_link_engine.dart';
import 'package:around_app/features/explore/widgets/telegram_share_sheet.dart';

void main() {
  group('P29-02: TelegramShareSheet Widget Tests', () {
    testWidgets('renders Telegram share sheet with route preview and URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelegramShareSheet(
              type: TelegramDeepLinkType.route,
              resourceId: 'mirabad_coffee_crawl',
              title: 'Mirabad Specialty Coffee Crawl',
              subtitle: '4 stops · 1.8 km walking trail',
              languageCode: 'en',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('telegram_share_sheet')), findsOneWidget);
      expect(find.text('TELEGRAM MINI APP'), findsOneWidget);
      expect(find.text('Share to Telegram'), findsOneWidget);
      expect(find.text('Mirabad Specialty Coffee Crawl'), findsOneWidget);
      expect(find.text('4 stops · 1.8 km walking trail'), findsOneWidget);
      expect(find.textContaining('startapp=route_mirabad_coffee_crawl'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Send via Telegram'), findsOneWidget);
    });

    testWidgets('copy button triggers callback and changes label to Copied!', (tester) async {
      bool copyInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelegramShareSheet(
              type: TelegramDeepLinkType.postcard,
              resourceId: 'REC-MIR-2026-774',
              title: 'Breadly Bakery Receipt',
              onCopyLink: () {
                copyInvoked = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const Key('copy_link_btn'));
      expect(copyBtn, findsOneWidget);

      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(copyInvoked, isTrue);
      expect(find.text('Copied!'), findsOneWidget);
    });

    testWidgets('send via Telegram triggers callback with formatted message', (tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelegramShareSheet(
              type: TelegramDeepLinkType.route,
              resourceId: 'mirabad_coffee_crawl',
              title: 'Mirabad Coffee Crawl',
              onShareToTelegram: (msg) {
                sentMessage = msg;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final sendBtn = find.byKey(const Key('send_telegram_btn'));
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(sentMessage, isNotNull);
      expect(sentMessage, contains('Tashkent Walking Route'));
      expect(sentMessage, contains('startapp=route_mirabad_coffee_crawl'));
    });

    testWidgets('renders Uzbek and Russian localizations correctly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelegramShareSheet(
              type: TelegramDeepLinkType.route,
              resourceId: 'mirabad_coffee_crawl',
              title: 'Mirabad Sayri',
              languageCode: 'uz',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Telegramda Ulashish'), findsOneWidget);
      expect(find.text('Nusxa Olish'), findsOneWidget);
      expect(find.text('Telegramga Yuborish'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelegramShareSheet(
              type: TelegramDeepLinkType.route,
              resourceId: 'mirabad_coffee_crawl',
              title: 'Маршрут по Мирабаду',
              languageCode: 'ru',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Поделиться в Telegram'), findsOneWidget);
      expect(find.text('Копировать'), findsOneWidget);
      expect(find.text('Отправить в Telegram'), findsOneWidget);
    });
  });
}
