import '../../data/services/storage_service.dart';
import 'app_logger.dart';

class BetaAccessResult {
  final bool isValid;
  final String? cohort;
  final String? error;
  final String? code;

  const BetaAccessResult({
    required this.isValid,
    this.cohort,
    this.error,
    this.code,
  });

  factory BetaAccessResult.success({
    required String cohort,
    required String code,
  }) {
    return BetaAccessResult(
      isValid: true,
      cohort: cohort,
      code: code,
    );
  }

  factory BetaAccessResult.failure(String error) {
    return BetaAccessResult(
      isValid: false,
      error: error,
    );
  }
}

/// Service governing closed beta VIP access gates and cohort activation (`P12-08`).
class BetaAccessService {
  static const Map<String, String> _validCohorts = {
    'TASH50': 'Founding 50 Beta Cohort',
    'MIRAB1': 'Mirabad Coffee & Culture Beta',
    'YAKK02': 'Yakkasaray Creative Circle',
    'CHORSU': 'Old City Taste Pioneers',
    'DEVVIP': 'Internal Development VIP',
    'STRAVA': 'Strava for Places Beta',
  };

  /// Validates a 6-character cohort access code or friend invite token.
  static BetaAccessResult validateCode(String rawCode) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      return BetaAccessResult.failure('Please enter a beta invite code.');
    }

    // Support friend invite tokens (e.g. inv_...)
    if (trimmed.toLowerCase().startsWith('inv_')) {
      if (trimmed.length >= 10) {
        return BetaAccessResult.success(
          cohort: 'Friend Invite Circle',
          code: trimmed,
        );
      } else {
        return BetaAccessResult.failure('Invalid or truncated friend invite code.');
      }
    }

    final normalized = trimmed.toUpperCase();
    if (normalized.length != 6) {
      return BetaAccessResult.failure('Beta activation codes must be 6 characters (e.g. TASH50).');
    }

    final cohort = _validCohorts[normalized];
    if (cohort != null) {
      return BetaAccessResult.success(
        cohort: cohort,
        code: normalized,
      );
    }

    return BetaAccessResult.failure('Invalid beta invite code. Around is currently in closed beta.');
  }

  /// Checks if the device has already unlocked closed beta access.
  static bool hasAccess() {
    return StorageService.hasBetaAccess();
  }

  /// Activates closed beta access if the provided code is valid.
  static Future<BetaAccessResult> activateWithCode(String rawCode) async {
    final result = validateCode(rawCode);
    if (result.isValid) {
      await StorageService.setBetaAccess(true);
      if (result.cohort != null) {
        await StorageService.setBetaCohort(result.cohort!);
      }
      AppLogger.info('BetaAccessService', 'Beta access activated for cohort: ${result.cohort}');
    } else {
      AppLogger.warn('BetaAccessService', 'Beta access activation failed: ${result.error}');
    }
    return result;
  }

  /// Revokes beta access (used for testing or resetting session).
  static Future<void> revokeAccess() async {
    await StorageService.setBetaAccess(false);
  }

  /// Returns the name of the currently active cohort or null if unactivated.
  static String? getActiveCohort() {
    return StorageService.getBetaCohort();
  }
}
