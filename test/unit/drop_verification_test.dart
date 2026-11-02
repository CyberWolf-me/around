import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/drop_verification_service.dart';

void main() {
  group('P22-04: DropVerificationService Unit Tests', () {
    final baseTime = DateTime.utc(2026, 11, 3, 10, 0, 0);

    test('generateVerificationHash computes consistent 64-char hex SHA-256 HMAC', () {
      final hash1 = DropVerificationService.generateVerificationHash(
        authorId: 'user_kamila',
        placeId: 'place_breadly',
        createdAt: baseTime,
      );

      final hash2 = DropVerificationService.generateVerificationHash(
        authorId: 'user_kamila',
        placeId: 'place_breadly',
        createdAt: baseTime,
      );

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash1), isTrue);
    });

    test('verifyDrop confirms valid signature and formats compact seal', () {
      final validHash = DropVerificationService.generateVerificationHash(
        authorId: 'user_bekzod',
        placeId: 'place_bnb',
        createdAt: baseTime,
      );

      final result = DropVerificationService.verifyDrop(
        authorId: 'user_bekzod',
        placeId: 'place_bnb',
        createdAt: baseTime,
        providedHash: validHash,
      );

      expect(result.isValid, isTrue);
      expect(result.compactSeal, startsWith('AR-'));
      expect(result.compactSeal.length, equals(12)); // e.g. AR-XXXX-XXXX
      expect(result.failureReason, isNull);
    });

    test('verifyDrop rejects altered placeId (tamper detection)', () {
      final validHash = DropVerificationService.generateVerificationHash(
        authorId: 'user_bekzod',
        placeId: 'place_bnb',
        createdAt: baseTime,
      );

      // Attempt to attribute the hash to a different place
      final result = DropVerificationService.verifyDrop(
        authorId: 'user_bekzod',
        placeId: 'place_chorsu', // tampered
        createdAt: baseTime,
        providedHash: validHash,
      );

      expect(result.isValid, isFalse);
      expect(result.compactSeal, equals('AR-INVALID'));
      expect(result.failureReason, contains('mismatch'));
    });

    test('verifyDrop rejects altered authorId (impersonation prevention)', () {
      final validHash = DropVerificationService.generateVerificationHash(
        authorId: 'user_bekzod',
        placeId: 'place_bnb',
        createdAt: baseTime,
      );

      // Attempt to spoof author
      final result = DropVerificationService.verifyDrop(
        authorId: 'user_attacker', // tampered
        placeId: 'place_bnb',
        createdAt: baseTime,
        providedHash: validHash,
      );

      expect(result.isValid, isFalse);
      expect(result.compactSeal, equals('AR-INVALID'));
    });

    test('verifyDrop rejects empty or missing signatures', () {
      final result = DropVerificationService.verifyDrop(
        authorId: 'user_bekzod',
        placeId: 'place_bnb',
        createdAt: baseTime,
        providedHash: '',
      );

      expect(result.isValid, isFalse);
      expect(result.compactSeal, equals('AR-NONE'));
    });

    test('isVisitWindowFresh rejects future timestamps and stale drops', () {
      final now = DateTime.utc(2026, 11, 3, 12, 0, 0);

      // 2 hours ago - fresh
      expect(
        DropVerificationService.isVisitWindowFresh(
          createdAt: now.subtract(const Duration(hours: 2)),
          referenceNow: now,
        ),
        isTrue,
      );

      // 40 days ago - stale (> 30 days)
      expect(
        DropVerificationService.isVisitWindowFresh(
          createdAt: now.subtract(const Duration(days: 40)),
          referenceNow: now,
        ),
        isFalse,
      );

      // Future timestamp (+ 10 minutes) - rejected
      expect(
        DropVerificationService.isVisitWindowFresh(
          createdAt: now.add(const Duration(minutes: 10)),
          referenceNow: now,
        ),
        isFalse,
      );
    });

    test('localizedLabel formats trilingual verified visit badge', () {
      final validHash = DropVerificationService.generateVerificationHash(
        authorId: 'user_aziza',
        placeId: 'place_ecorn',
        createdAt: baseTime,
      );

      final result = DropVerificationService.verifyDrop(
        authorId: 'user_aziza',
        placeId: 'place_ecorn',
        createdAt: baseTime,
        providedHash: validHash,
      );

      expect(result.localizedLabel('uz'), contains('Tasdiqlangan Tashrif'));
      expect(result.localizedLabel('ru'), contains('Подтвержденный визит'));
      expect(result.localizedLabel('en'), contains('Verified Visit'));

      // Unverified state
      final invalid = DropVerificationResult(
        isValid: false,
        compactSeal: 'AR-INVALID',
        authorId: 'u',
        placeId: 'p',
        createdAt: DateTime.fromMicrosecondsSinceEpoch(0),
      );
      expect(invalid.localizedLabel('uz'), equals('Tasdiqlanmagan'));
      expect(invalid.localizedLabel('ru'), equals('Не подтверждено'));
      expect(invalid.localizedLabel('en'), equals('Unverified'));
    });
  });
}
