import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/deep_link_service.dart';
import 'package:around_app/core/services/friend_invite_service.dart';
import 'package:around_app/data/models/profile_model.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/features/profile/screens/friend_invite_screen.dart';

class _MockProfileNotifier extends ProfileNotifier {
  final ProfileModel _initial;
  _MockProfileNotifier(this._initial);

  @override
  ProfileModel build() => _initial;
}

class _MockBlockedUsersNotifier extends BlockedUsersNotifier {
  final Set<String> _initial;
  _MockBlockedUsersNotifier(this._initial);

  @override
  Set<String> build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FriendInviteService & Mutual Connection Engine Tests (P11-02)', () {
    test('generateInviteCode produces deterministic codes and parses accurately', () {
      final fixedDate = DateTime(2026, 11, 2, 12, 0, 0);
      final code = FriendInviteService.generateInviteCode(
        inviterId: 'kamila',
        username: 'kamilar',
        fullName: 'Kamila Rahimova',
        neighborhood: 'Mirabad',
        timestamp: fixedDate,
      );

      expect(code, startsWith('inv_'));

      final payload = FriendInviteService.parseInviteCode(code);
      expect(payload, isNotNull);
      expect(payload!.inviterId, equals('kamila'));
      expect(payload.username, equals('kamilar'));
      expect(payload.fullName, equals('Kamila Rahimova'));
      expect(payload.neighborhood, equals('Mirabad'));
      expect(payload.createdAt, equals(fixedDate));
      expect(payload.isExpired, isFalse);
    });

    test('parseInviteCode handles corrupted or missing payload safely', () {
      expect(FriendInviteService.parseInviteCode(''), isNull);
      expect(FriendInviteService.parseInviteCode('inv_malformed!base64'), isNull);
      expect(FriendInviteService.parseInviteCode('inv_eyJob3N0IjogInRlc3QifQ'), isNull); // missing required fields
    });

    test('isExpired detects codes older than 14 days', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 15));
      final expiredCode = FriendInviteService.generateInviteCode(
        inviterId: 'bekzod',
        username: 'bekalimov',
        fullName: 'Bekzod Alimov',
        neighborhood: 'Yakkasaray',
        timestamp: oldDate,
      );

      final payload = FriendInviteService.parseInviteCode(expiredCode);
      expect(payload, isNotNull);
      expect(payload!.isExpired, isTrue);
    });

    test('DeepLinkService routes invite URIs to internal /invite/:code', () {
      final code = FriendInviteService.generateInviteCode(
        inviterId: 'diyor',
        username: 'diyor_u',
        fullName: 'Diyor Usmanov',
        neighborhood: 'Mirabad',
      );

      final appRoute = DeepLinkService.resolveRouteFromUri(Uri.parse('around://invite/$code'));
      expect(appRoute, equals('/invite/$code'));

      final webRoute = DeepLinkService.resolveRouteFromUri(
        Uri.parse('https://around.tashkent.app/invite/$code'),
      );
      expect(webRoute, equals('/invite/$code'));
    });

    testWidgets('FriendInviteScreen displays inviter card and connects on tap', (tester) async {
      final code = FriendInviteService.generateInviteCode(
        inviterId: 'rustam',
        username: 'rustamm',
        fullName: 'Rustam Mirzaev',
        neighborhood: 'Mirabad',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FriendInviteScreen(inviteCode: code),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card elements
      expect(find.text('TASHKENT FRIEND INVITE'), findsOneWidget);
      expect(find.text('MIRABAD'), findsOneWidget);
      expect(find.text('Rustam Mirzaev'), findsOneWidget);
      expect(find.text('@rustamm · Mirabad'), findsOneWidget);
      expect(find.text('Connect as Friends'), findsOneWidget);

      // Tap connect
      await tester.tap(find.text('Connect as Friends'));
      await tester.pumpAndSettle();

      // UI should transition to accepted state
      expect(find.text('View Profile & Drops'), findsOneWidget);
    });

    testWidgets('FriendInviteScreen detects self-invite code gracefully', (tester) async {
      const myProfile = ProfileModel(
        id: 'kamila',
        username: 'kamilar',
        fullName: 'Kamila Rahimova',
        bio: 'Matcha enthusiast',
        neighborhood: 'Mirabad',
        dropsCount: 18,
        friendsCount: 5,
        savedCount: 10,
        hideVisitsHistory: false,
        defaultAudience: 'friends',
        discoverableByFriends: true,
        quietHours: false,
        allowFriendRequests: true,
      );

      final selfCode = FriendInviteService.generateInviteCode(
        inviterId: myProfile.id,
        username: myProfile.username,
        fullName: myProfile.fullName,
        neighborhood: myProfile.neighborhood,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith(() => _MockProfileNotifier(myProfile)),
          ],
          child: MaterialApp(
            home: FriendInviteScreen(inviteCode: selfCode),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Your Personal Invite Link'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
    });

    testWidgets('FriendInviteScreen enforces block precedence (Security Invariant Rule C)', (tester) async {
      final code = FriendInviteService.generateInviteCode(
        inviterId: 'blocked_spammer',
        username: 'spammer_user',
        fullName: 'Spammer User',
        neighborhood: 'Chilanzar',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blockedUsersProvider.overrideWith(() => _MockBlockedUsersNotifier({'blocked_spammer'})),
          ],
          child: MaterialApp(
            home: FriendInviteScreen(inviteCode: code),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Connection Unavailable'), findsOneWidget);
      expect(find.text('You cannot connect with this user due to privacy preferences.'), findsOneWidget);
      expect(find.text('Connect as Friends'), findsNothing);
    });

    testWidgets('FriendInviteScreen displays invalid state for corrupted codes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendInviteScreen(inviteCode: 'inv_corrupted_garbage_token'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Invalid or Expired Invite'), findsOneWidget);
      expect(find.text('Return to Feed'), findsOneWidget);
    });
  });
}
