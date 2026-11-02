import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/biometric_service.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  group('Biometric App Lock & In-Memory Sensitive Visit History Vault (P9-03)', () {
    late ProviderContainer container;

    setUp(() async {
      await StorageService.clearAll();
      BiometricService.mockAuthResult = null;
      BiometricService.lastPausedAt = null;
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      BiometricService.mockAuthResult = null;
      BiometricService.lastPausedAt = null;
    });

    test('Initial biometric lock preference is disabled by default', () {
      expect(StorageService.isBiometricLockEnabled(), isFalse);
      expect(BiometricService.isBiometricLockEnabled(), isFalse);
      expect(container.read(biometricLockEnabledProvider), isFalse);
      expect(container.read(appLockedProvider), isFalse);
    });

    test('Toggling biometric lock updates Riverpod state and persists to storage', () async {
      final notifier = container.read(biometricLockEnabledProvider.notifier);
      await notifier.setEnabled(true);

      expect(container.read(biometricLockEnabledProvider), isTrue);
      expect(StorageService.isBiometricLockEnabled(), isTrue);
      expect(BiometricService.isBiometricLockEnabled(), isTrue);

      await notifier.setEnabled(false);
      expect(container.read(biometricLockEnabledProvider), isFalse);
      expect(StorageService.isBiometricLockEnabled(), isFalse);
    });

    test('Disabling biometric lock automatically unlocks any currently locked state', () async {
      final lockEnabledNotifier = container.read(biometricLockEnabledProvider.notifier);
      final appLockedNotifier = container.read(appLockedProvider.notifier);

      await lockEnabledNotifier.setEnabled(true);
      appLockedNotifier.lock();
      expect(container.read(appLockedProvider), isTrue);

      await lockEnabledNotifier.setEnabled(false);
      expect(container.read(appLockedProvider), isFalse);
    });

    test('shouldLockOnResume returns false if biometric lock is disabled', () {
      final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));
      expect(BiometricService.shouldLockOnResume(twoMinutesAgo), isFalse);
    });

    test('shouldLockOnResume returns false if pausedAt is null', () async {
      await BiometricService.setBiometricLockEnabled(true);
      expect(BiometricService.shouldLockOnResume(null), isFalse);
    });

    test('shouldLockOnResume returns false when background duration is less than 60s', () async {
      await BiometricService.setBiometricLockEnabled(true);
      final thirtySecondsAgo = DateTime.now().subtract(const Duration(seconds: 30));
      expect(BiometricService.shouldLockOnResume(thirtySecondsAgo), isFalse);
    });

    test('shouldLockOnResume returns true when background duration is >= 60s', () async {
      await BiometricService.setBiometricLockEnabled(true);
      final sixtyOneSecondsAgo = DateTime.now().subtract(const Duration(seconds: 61));
      expect(BiometricService.shouldLockOnResume(sixtyOneSecondsAgo), isTrue);
    });

    test('Sensitive Visit History Vault records and isolates visited venue telemetry', () {
      final visitTime = DateTime.now();
      BiometricService.recordSensitiveVisit('breadly', visitTime);
      BiometricService.recordSensitiveVisit('ecorn', visitTime);

      // Normal unlocked view without hideVisitsHistory
      final vault = BiometricService.getSensitiveVisitVault(hideVisitsHistory: false, isLocked: false);
      expect(vault.length, equals(2));
      expect(vault['breadly'], equals(visitTime));
      expect(vault['ecorn'], equals(visitTime));

      // With hideVisitsHistory enabled -> vault strictly returns empty map
      final privateVault = BiometricService.getSensitiveVisitVault(hideVisitsHistory: true, isLocked: false);
      expect(privateVault.isEmpty, isTrue);

      // When app is locked -> vault strictly returns empty map
      final lockedVault = BiometricService.getSensitiveVisitVault(hideVisitsHistory: false, isLocked: true);
      expect(lockedVault.isEmpty, isTrue);
    });

    test('Locking app immediately purges volatile sensitive memory vault', () {
      BiometricService.recordSensitiveVisit('kitobxon', DateTime.now());
      expect(BiometricService.getSensitiveVisitVault().isNotEmpty, isTrue);

      final appLockedNotifier = container.read(appLockedProvider.notifier);
      appLockedNotifier.lock();

      expect(container.read(appLockedProvider), isTrue);
      // Memory vault purged
      expect(BiometricService.getSensitiveVisitVault().isEmpty, isTrue);
    });

    test('Biometric authentication evaluates mock and fallback results', () async {
      BiometricService.mockAuthResult = false;
      final fail = await BiometricService.authenticate();
      expect(fail, isFalse);

      BiometricService.mockAuthResult = true;
      final pass = await BiometricService.authenticate();
      expect(pass, isTrue);

      BiometricService.mockAuthResult = null;
      final livePass = await BiometricService.authenticate();
      expect(livePass, isTrue);
    });
  });
}
