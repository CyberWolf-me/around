import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/beta_access_service.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P12-08: Closed Beta Invite Code Access Gate Tests', () {
    setUp(() async {
      await StorageService.init();
      await BetaAccessService.revokeAccess();
    });

    test('Validates recognized 6-character cohort codes case-insensitively', () {
      final res1 = BetaAccessService.validateCode('TASH50');
      expect(res1.isValid, isTrue);
      expect(res1.cohort, equals('Founding 50 Beta Cohort'));
      expect(res1.code, equals('TASH50'));

      final res2 = BetaAccessService.validateCode('  mirab1  ');
      expect(res2.isValid, isTrue);
      expect(res2.cohort, equals('Mirabad Coffee & Culture Beta'));
      expect(res2.code, equals('MIRAB1'));

      final res3 = BetaAccessService.validateCode('yakk02');
      expect(res3.isValid, isTrue);
      expect(res3.cohort, equals('Yakkasaray Creative Circle'));

      final res4 = BetaAccessService.validateCode('chorsu');
      expect(res4.isValid, isTrue);
      expect(res4.cohort, equals('Old City Taste Pioneers'));

      final res5 = BetaAccessService.validateCode('DEVVIP');
      expect(res5.isValid, isTrue);
      expect(res5.cohort, equals('Internal Development VIP'));

      final res6 = BetaAccessService.validateCode('strava');
      expect(res6.isValid, isTrue);
      expect(res6.cohort, equals('Strava for Places Beta'));
    });

    test('Validates mutual friend invite tokens starting with inv_', () {
      final res = BetaAccessService.validateCode('inv_a1b2c3d4e5f6');
      expect(res.isValid, isTrue);
      expect(res.cohort, equals('Friend Invite Circle'));
      expect(res.code, equals('inv_a1b2c3d4e5f6'));
    });

    test('Rejects empty or blank invite codes', () {
      final res1 = BetaAccessService.validateCode('');
      expect(res1.isValid, isFalse);
      expect(res1.error, contains('enter a beta invite code'));

      final res2 = BetaAccessService.validateCode('   ');
      expect(res2.isValid, isFalse);
    });

    test('Rejects invalid length codes (< 6 or > 6 chars)', () {
      final resShort = BetaAccessService.validateCode('ABC');
      expect(resShort.isValid, isFalse);
      expect(resShort.error, contains('must be 6 characters'));

      final resLong = BetaAccessService.validateCode('TOOLONGCODE');
      expect(resLong.isValid, isFalse);
      expect(resLong.error, contains('must be 6 characters'));
    });

    test('Rejects unknown 6-character codes', () {
      final res = BetaAccessService.validateCode('FAKE99');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Invalid beta invite code'));
    });

    test('Rejects truncated friend invite tokens', () {
      final res = BetaAccessService.validateCode('inv_12');
      expect(res.isValid, isFalse);
      expect(res.error, contains('Invalid or truncated'));
    });

    test('activateWithCode persists access and cohort to StorageService', () async {
      expect(BetaAccessService.hasAccess(), isFalse);

      final res = await BetaAccessService.activateWithCode('TASH50');
      expect(res.isValid, isTrue);
      expect(BetaAccessService.hasAccess(), isTrue);
      expect(BetaAccessService.getActiveCohort(), equals('Founding 50 Beta Cohort'));

      // Test revocation
      await BetaAccessService.revokeAccess();
      expect(BetaAccessService.hasAccess(), isFalse);
    });

    test('activateWithCode fails cleanly on invalid code without granting access', () async {
      final res = await BetaAccessService.activateWithCode('INVALID');
      expect(res.isValid, isFalse);
      expect(BetaAccessService.hasAccess(), isFalse);
    });
  });
}
