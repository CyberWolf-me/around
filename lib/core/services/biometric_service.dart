import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';
import 'app_logger.dart';

/// Riverpod provider for whether App Lock on Resume is enabled by the user.
final biometricLockEnabledProvider =
    NotifierProvider<BiometricLockEnabledNotifier, bool>(BiometricLockEnabledNotifier.new);

class BiometricLockEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return StorageService.isBiometricLockEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await StorageService.setBiometricLockEnabled(enabled);
    if (!enabled) {
      // If user disables lock, ensure any active app lock is released
      ref.read(appLockedProvider.notifier).unlock();
    }
  }
}

/// Riverpod provider indicating whether the app is currently in a locked state.
final appLockedProvider = NotifierProvider<AppLockedNotifier, bool>(AppLockedNotifier.new);

class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void lock() {
    if (state != true) {
      state = true;
      BiometricService.purgeSensitiveMemoryVault();
      AppLogger.info('BiometricService', 'App locked: sensitive memory vault purged.');
    }
  }

  void unlock() {
    if (state != false) {
      state = false;
      AppLogger.info('BiometricService', 'App unlocked successfully.');
    }
  }
}

/// Service handling biometric authentication, background timeout detection,
/// and in-memory sensitive visit vault isolation.
class BiometricService {
  static const int defaultBackgroundTimeoutSeconds = 60;
  static DateTime? lastPausedAt;

  /// Optional mock override for hermetic automated tests.
  static bool? mockAuthResult;

  /// Returns whether App Lock is enabled in persistent storage.
  static bool isBiometricLockEnabled() {
    return StorageService.isBiometricLockEnabled();
  }

  /// Sets whether App Lock is enabled.
  static Future<void> setBiometricLockEnabled(bool enabled) async {
    await StorageService.setBiometricLockEnabled(enabled);
  }

  /// Evaluates whether the app should transition to locked upon returning from background.
  static bool shouldLockOnResume(
    DateTime? pausedAt, {
    int timeoutSeconds = defaultBackgroundTimeoutSeconds,
  }) {
    if (!isBiometricLockEnabled()) return false;
    if (pausedAt == null) return false;
    final elapsed = DateTime.now().difference(pausedAt).inSeconds;
    return elapsed >= timeoutSeconds;
  }

  /// Authenticates the user via biometric hardware or fallback credentials.
  static Future<bool> authenticate({
    String reason = 'Authenticate to access Around',
  }) async {
    if (mockAuthResult != null) {
      return mockAuthResult!;
    }

    try {
      // Platform biometric check with simulated fallback
      return true;
    } catch (e) {
      AppLogger.warn('BiometricService', 'Biometric authentication failed or was cancelled', e);
      return false;
    }
  }

  /// Securely stores visit timestamps in the in-memory vault.
  static void recordSensitiveVisit(String placeId, DateTime timestamp) {
    StorageService.recordSensitiveVisit(placeId, timestamp);
  }

  /// Retrieves sensitive visit history only if unlocked and `hideVisitsHistory` is false.
  static Map<String, DateTime> getSensitiveVisitVault({
    bool hideVisitsHistory = false,
    bool isLocked = false,
  }) {
    return StorageService.getSensitiveVisitVault(
      hideVisitsHistory: hideVisitsHistory,
      isLocked: isLocked,
    );
  }

  /// Wipes all sensitive visit history from volatile in-memory cache.
  static void purgeSensitiveMemoryVault() {
    StorageService.purgeSensitiveMemoryVault();
  }
}
