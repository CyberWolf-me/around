import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:around_app/core/services/analytics_service.dart';
import 'package:around_app/core/services/friend_invite_service.dart';
import 'package:around_app/core/services/telegram_share_service.dart';

void main() {
  group('TelegramShareService & Growth Loop Tests (P12-04)', () {
    setUp(() {
      AnalyticsService.instance.resetForTesting();
    });

    test('buildShareUri creates valid universal HTTPS web share URL with encoded query params', () {
      final uri = TelegramShareService.buildShareUri(
        url: 'https://around.tashkent.app/invite/inv_abc123',
        text: 'Join me on Around Tashkent! Coffee & food spots.',
        useNativeProtocol: false,
      );

      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('t.me'));
      expect(uri.path, equals('/share/url'));
      expect(uri.queryParameters['url'], equals('https://around.tashkent.app/invite/inv_abc123'));
      expect(uri.queryParameters['text'], equals('Join me on Around Tashkent! Coffee & food spots.'));
    });

    test('buildShareUri creates valid native tg:// scheme URL when requested', () {
      final uri = TelegramShareService.buildShareUri(
        url: 'https://around.tashkent.app/invite/inv_xyz789',
        text: 'Where friends actually go in Mirabad',
        useNativeProtocol: true,
      );

      expect(uri.scheme, equals('tg'));
      expect(uri.host, equals('msg_url'));
      expect(uri.queryParameters['url'], equals('https://around.tashkent.app/invite/inv_xyz789'));
      expect(uri.queryParameters['text'], equals('Where friends actually go in Mirabad'));
    });

    test('buildInviteMessage formats conversational Tashkent copy with neighborhood and link', () {
      final msg = TelegramShareService.buildInviteMessage(
        fullName: 'Kamila R.',
        neighborhood: 'Mirabad',
        inviteUrl: 'https://around.tashkent.app/invite/inv_test',
      );

      expect(msg.contains('Around Tashkent'), isTrue);
      expect(msg.contains('Mirabad'), isTrue);
      expect(msg.contains('https://around.tashkent.app/invite/inv_test'), isTrue);
      expect(msg.contains('not anonymous reviews'), isTrue);
    });

    test('buildPassportMessage formats curator taste passport message', () {
      final msg = TelegramShareService.buildPassportMessage(
        fullName: 'Aziz K.',
        username: 'aziz_tashkent',
        neighborhood: 'Yakkasaray',
        placeCount: 7,
        passportUrl: 'https://around.tashkent.app/u/aziz_tashkent/passport',
      );

      expect(msg.contains('Tashkent Taste Passport'), isTrue);
      expect(msg.contains('7 curated venues'), isTrue);
      expect(msg.contains('Yakkasaray'), isTrue);
      expect(msg.contains('@aziz_tashkent'), isTrue);
      expect(msg.contains('https://around.tashkent.app/u/aziz_tashkent/passport'), isTrue);
    });

    test('buildVenueShareMessage formats venue recommendation with neighborhood', () {
      final msg = TelegramShareService.buildVenueShareMessage(
        venueName: 'Breadly Bakery',
        neighborhood: 'Mirabad',
        curatorName: 'Jasur M.',
        venueUrl: 'https://around.tashkent.app/places/breadly-bakery',
      );

      expect(msg.contains('Breadly Bakery'), isTrue);
      expect(msg.contains('Mirabad'), isTrue);
      expect(msg.contains('Jasur M.'), isTrue);
      expect(msg.contains('https://around.tashkent.app/places/breadly-bakery'), isTrue);
    });

    test('launchShare succeeds with native protocol and dispatches analytics event', () async {
      final launchedUris = <Uri>[];
      final launchedModes = <LaunchMode>[];

      final success = await TelegramShareService.launchShare(
        url: 'https://around.tashkent.app/invite/test_1',
        text: 'Join me!',
        launcher: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          launchedModes.add(mode);
          return true;
        },
      );

      expect(success, isTrue);
      expect(launchedUris.length, equals(1));
      expect(launchedUris.first.scheme, equals('tg'));
      expect(launchedModes.first, equals(LaunchMode.externalApplication));

      final events = AnalyticsService.instance.recentEvents;
      expect(events.any((e) => e.eventName == 'friend_request_sent'), isTrue);
      final ev = events.firstWhere((e) => e.eventName == 'friend_request_sent');
      expect(ev.properties['method'], equals('telegram_share'));
    });

    test('launchShare falls back to web URL when native tg:// protocol fails', () async {
      final launchedUris = <Uri>[];

      final success = await TelegramShareService.launchShare(
        url: 'https://around.tashkent.app/invite/test_2',
        text: 'Join me!',
        launcher: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          // Fail the native scheme, succeed on https
          if (uri.scheme == 'tg') {
            return false;
          }
          return true;
        },
      );

      expect(success, isTrue);
      expect(launchedUris.length, equals(2));
      expect(launchedUris[0].scheme, equals('tg'));
      expect(launchedUris[1].scheme, equals('https'));
      expect(launchedUris[1].host, equals('t.me'));
    });

    test('launchShare handles launcher exceptions and tries fallback', () async {
      final launchedUris = <Uri>[];

      final success = await TelegramShareService.launchShare(
        url: 'https://around.tashkent.app/invite/test_3',
        text: 'Join me!',
        launcher: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          if (uri.scheme == 'tg') {
            throw Exception('Native app not found');
          }
          return true;
        },
      );

      expect(success, isTrue);
      expect(launchedUris.length, equals(2));
      expect(launchedUris[1].scheme, equals('https'));
    });

    test('shareInviteToTelegram generates valid deterministic invite code and invokes launcher', () async {
      Uri? capturedUri;

      final success = await TelegramShareService.shareInviteToTelegram(
        inviterId: 'user_kamila_123',
        username: 'kamila_r',
        fullName: 'Kamila Rustamova',
        neighborhood: 'Mirabad',
        launcher: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          capturedUri = uri;
          return true;
        },
      );

      expect(success, isTrue);
      expect(capturedUri, isNotNull);
      final rawUrl = capturedUri!.queryParameters['url']!;
      expect(rawUrl.contains('https://around.tashkent.app/invite/inv_'), isTrue);

      // Verify the generated code is parseable by FriendInviteService
      final code = rawUrl.split('/invite/').last;
      final payload = FriendInviteService.parseInviteCode(code);
      expect(payload, isNotNull);
      expect(payload!.inviterId, equals('user_kamila_123'));
      expect(payload.username, equals('kamila_r'));
      expect(payload.neighborhood, equals('Mirabad'));
    });

    test('sharePassportToTelegram prepares passport URL and dispatches share', () async {
      Uri? capturedUri;

      final success = await TelegramShareService.sharePassportToTelegram(
        fullName: 'Dilshod B.',
        username: 'dilshod_b',
        neighborhood: 'Central Tashkent',
        placeCount: 12,
        launcher: (Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          capturedUri = uri;
          return true;
        },
      );

      expect(success, isTrue);
      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['url'], equals('https://around.tashkent.app/u/dilshod_b/passport'));
      expect(capturedUri!.queryParameters['text']!.contains('12 curated venues'), isTrue);
    });
  });
}
