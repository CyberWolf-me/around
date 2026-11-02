import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:around_app/core/services/curator_recommendation_engine.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/features/profile/widgets/curator_coffee_ping_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const member = CommunityMember(
    id: 'kamila',
    name: 'Kamila Rahimova',
    handle: 'kamilar',
    initials: 'KR',
    neighborhood: 'Mirabad',
    bio: 'Espresso & lavender matcha enthusiast.',
    dropsCount: 18,
  );

  const match = TasteOverlapMatch(
    curator: CuratorTasteProfile(
      userId: 'kamila',
      username: 'kamilar',
      fullName: 'Kamila Rahimova',
      neighborhood: 'Mirabad',
      streakWeeks: 4,
    ),
    similarityScore: 0.85,
    compatibilityPercent: 85,
    sharedPlaces: ['place_breadly_bakery'],
    sharedTags: ['Coffee', 'WorkFriendly'],
    sharedDistricts: ['Mirabad'],
    primaryHighlightEn: '85% Match · You both love Breadly Bakery',
    primaryHighlightUz: '85% Moslik · Ikkalangiz ham Breadly Bakery joyini yoqtirasiz',
    primaryHighlightRu: '85% Совпадение · Вы оба любите Breadly Bakery',
  );

  group('P21-01: CuratorCoffeePingSheet Widget Tests', () {
    test('buildInviteMessage formats personalized trilingual copies accurately', () {
      final msgEn = CuratorCoffeePingSheet.buildInviteMessage(
        curatorName: 'Kamila Rahimova',
        matchPercent: 85,
        venueName: 'Breadly Bakery',
        lang: 'en',
      );
      expect(msgEn, contains('Hey Kamila!'));
      expect(msgEn, contains('85% taste match'));
      expect(msgEn, contains('Breadly Bakery'));

      final msgUz = CuratorCoffeePingSheet.buildInviteMessage(
        curatorName: 'Kamila Rahimova',
        matchPercent: 85,
        venueName: 'Breadly Bakery',
        lang: 'uz',
      );
      expect(msgUz, contains('Salom Kamila!'));
      expect(msgUz, contains('85% mos tusharkan'));
      expect(msgUz, contains('Breadly Bakery'));

      final msgRu = CuratorCoffeePingSheet.buildInviteMessage(
        curatorName: 'Kamila Rahimova',
        matchPercent: 85,
        venueName: 'Breadly Bakery',
        lang: 'ru',
      );
      expect(msgRu, contains('Привет, Kamila!'));
      expect(msgRu, contains('совпадение вкусов 85%'));
      expect(msgRu, contains('Breadly Bakery'));
    });

    test('buildTelegramUri builds universal t.me link without duplicate at signs', () {
      final uri = CuratorCoffeePingSheet.buildTelegramUri(
        handle: '@kamilar',
        message: 'Hello Kamila',
      );
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('t.me'));
      expect(uri.path, equals('/kamilar'));
      expect(uri.queryParameters['text'], equals('Hello Kamila'));
    });

    testWidgets('renders coffee invite bottom sheet with candidate curator, match, and shared venue chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CuratorCoffeePingSheet(
              member: member,
              match: match,
              topVenueName: 'Breadly Bakery',
              languageCode: 'en',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COFFEE MEETUP PING'), findsOneWidget);
      expect(find.text('85% MATCH'), findsOneWidget);
      expect(find.text('Kamila Rahimova'), findsOneWidget);
      expect(find.text('@kamilar · Mirabad'), findsOneWidget);
      expect(find.text('Breadly Bakery'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);
      expect(find.text('Invite on TG'), findsOneWidget);
    });

    testWidgets('dispatches launch delegate with formatted telegram deep link', (tester) async {
      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CuratorCoffeePingSheet(
              member: member,
              match: match,
              topVenueName: 'Breadly Bakery',
              languageCode: 'en',
              onLaunchOverride: (url) => launchedUrl = url,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_telegram_coffee_invite')));
      await tester.pumpAndSettle();

      expect(launchedUrl, isNotNull);
      expect(launchedUrl, contains('https://t.me/kamilar?text='));
      expect(launchedUrl, contains('Breadly+Bakery'));
      expect(launchedUrl, contains('85%25+taste+match'));
    });

    testWidgets('presents sheet via CuratorCoffeePingSheet.show helper', (tester) async {
      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('trigger_coffee_sheet'),
                onPressed: () {
                  CuratorCoffeePingSheet.show(
                    context: ctx,
                    member: member,
                    match: match,
                    topVenueName: 'Breadly Bakery',
                    onLaunchOverride: (url) => launchedUrl = url,
                  );
                },
                child: const Text('Open Coffee Ping'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('trigger_coffee_sheet')));
      await tester.pumpAndSettle();

      expect(find.byType(CuratorCoffeePingSheet), findsOneWidget);
      expect(find.text('COFFEE MEETUP PING'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_telegram_coffee_invite')));
      await tester.pumpAndSettle();

      expect(launchedUrl, isNotNull);
      expect(find.byType(CuratorCoffeePingSheet), findsNothing);
    });
  });
}
