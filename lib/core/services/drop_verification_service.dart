import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Verification status result for a place drop.
class DropVerificationResult {
  final bool isValid;
  final String compactSeal;
  final String authorId;
  final String placeId;
  final DateTime createdAt;
  final String? failureReason;

  const DropVerificationResult({
    required this.isValid,
    required this.compactSeal,
    required this.authorId,
    required this.placeId,
    required this.createdAt,
    this.failureReason,
  });

  /// Localized badge label for genuine on-device verified drops.
  String localizedLabel(String lang) {
    if (!isValid) {
      switch (lang.toLowerCase()) {
        case 'uz':
          return 'Tasdiqlanmagan';
        case 'ru':
          return 'Не подтверждено';
        case 'en':
        default:
          return 'Unverified';
      }
    }

    switch (lang.toLowerCase()) {
      case 'uz':
        return '✓ Tasdiqlangan Tashrif ($compactSeal)';
      case 'ru':
        return '✓ Подтвержденный визит ($compactSeal)';
      case 'en':
      default:
        return '✓ Verified Visit ($compactSeal)';
    }
  }
}

/// Cryptographic Drop Anti-Tamper & Verified Visit Seal Engine (`P22-04`).
/// Computes cryptographic HMAC-SHA256 signatures ensuring genuine,
/// tamper-evident place visits and check-in provenance in Tashkent.
class DropVerificationService {
  static const String _defaultProvenanceKey = 'around_tashkent_provenance_v1';

  /// Generates HMAC-SHA256 verification hash for a drop.
  static String generateVerificationHash({
    required String authorId,
    required String placeId,
    required DateTime createdAt,
    String secretKey = _defaultProvenanceKey,
  }) {
    final payload = '$authorId:$placeId:${createdAt.toUtc().toIso8601String()}';
    final keyBytes = utf8.encode(secretKey);
    final messageBytes = utf8.encode(payload);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    return digest.toString();
  }

  /// Formats compact 12-character seal code: `AR-XXXX-XXXX`.
  static String formatCompactSeal(String fullHash) {
    if (fullHash.length < 8) return 'AR-DEV-SEAL';
    final p1 = fullHash.substring(0, 4).toUpperCase();
    final p2 = fullHash.substring(4, 8).toUpperCase();
    return 'AR-$p1-$p2';
  }

  /// Verifies tamper-evident integrity of a drop given authorId, placeId, timestamp, and signature.
  static DropVerificationResult verifyDrop({
    required String authorId,
    required String placeId,
    required DateTime createdAt,
    required String providedHash,
    String secretKey = _defaultProvenanceKey,
  }) {
    if (providedHash.trim().isEmpty) {
      return DropVerificationResult(
        isValid: false,
        compactSeal: 'AR-NONE',
        authorId: authorId,
        placeId: placeId,
        createdAt: createdAt,
        failureReason: 'Missing verification signature.',
      );
    }

    final expectedHash = generateVerificationHash(
      authorId: authorId,
      placeId: placeId,
      createdAt: createdAt,
      secretKey: secretKey,
    );

    // Constant-time string comparison to prevent timing attacks
    final isValid = _constantTimeCompare(providedHash.toLowerCase(), expectedHash.toLowerCase());

    return DropVerificationResult(
      isValid: isValid,
      compactSeal: isValid ? formatCompactSeal(expectedHash) : 'AR-INVALID',
      authorId: authorId,
      placeId: placeId,
      createdAt: createdAt,
      failureReason: isValid ? null : 'Cryptographic signature mismatch.',
    );
  }

  /// Validates whether a drop's timestamp is within an acceptable freshness window.
  static bool isVisitWindowFresh({
    required DateTime createdAt,
    Duration maxAge = const Duration(days: 30),
    DateTime? referenceNow,
  }) {
    final now = (referenceNow ?? DateTime.now()).toUtc();
    final dropTime = createdAt.toUtc();

    if (dropTime.isAfter(now.add(const Duration(minutes: 5)))) {
      return false; // Future drop rejection
    }

    return now.difference(dropTime) <= maxAge;
  }

  /// Constant-time string comparison.
  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
