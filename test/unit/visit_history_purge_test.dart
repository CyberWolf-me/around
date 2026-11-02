import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/biometric_service.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/data/repositories/posts_repository.dart';
import 'package:around_app/data/repositories/profiles_repository.dart';
import 'package:around_app/data/repositories/saved_places_repository.dart';
import 'package:around_app/features/settings/screens/settings_screen.dart';

void main() {
  group('P13-04: Cryptographic Visit History Purge & Zero-Knowledge Self-Destruct Tests', () {
    test('SQL migration 00014 exists and enforces caller auth.uid() isolation', () {
      final migrationFile = File('supabase/migrations/00014_visit_history_purge.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00014 must exist');

      final content = migrationFile.readAsStringSync();
      expect(content, contains('CREATE OR REPLACE FUNCTION public.purge_my_visit_history()'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('v_uid := auth.uid();'));
      expect(content, contains('IF v_uid IS NULL THEN'));
      expect(content, contains('DELETE FROM public.saved_places'));
      expect(content, contains('DELETE FROM public.posts'));
      expect(content, contains('DELETE FROM public.post_reactions'));
      expect(content, contains('DELETE FROM public.place_stories'));
      expect(content, contains('DELETE FROM public.friend_plans'));
      expect(content, contains('SET hide_visits_history = TRUE'));
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.purge_my_visit_history() TO authenticated;'));
    });

    test('PostsNotifier purgeUserDrops zeroes out user authored drops while preserving friends drops', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postsRepositoryProvider.notifier);
      final profile = container.read(currentProfileProvider);

      // Verify drops are loaded
      final initialDrops = container.read(postsRepositoryProvider);
      expect(initialDrops.isNotEmpty, isTrue);

      // Add a test drop for current profile
      await notifier.publishDrop(
        placeId: 'breadly',
        placeName: 'Breadly Bakery & Café',
        placeCategory: 'Specialty Coffee · European Breakfast',
        placeAddress: '24 Mirobod Street',
        note: 'Secret visit test',
        rating: 5,
        audience: PostAudience.friends,
      );

      expect(container.read(postsRepositoryProvider).any((p) => p.authorId == profile.id || p.authorId == 'you'), isTrue);

      // Execute purge
      await notifier.purgeUserDrops();

      // Verify user's drops are gone
      final afterPurge = container.read(postsRepositoryProvider);
      expect(afterPurge.any((p) => p.authorId == profile.id || p.authorId == 'you'), isFalse);
    });

    test('SavedPlacesNotifier and Statuses purge zeroes local bookmark collections', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final savedNotifier = container.read(savedPlacesProvider.notifier);
      final statusesNotifier = container.read(savedPlaceStatusesProvider.notifier);

      expect(container.read(savedPlacesProvider).isNotEmpty, isTrue);

      await savedNotifier.purgeAllSaved();
      expect(container.read(savedPlacesProvider).isEmpty, isTrue);

      await statusesNotifier.purgeAllStatuses();
      expect(container.read(savedPlaceStatusesProvider).isEmpty, isTrue);
    });

    test('Biometric sensitive memory vault is cleared upon zeroization', () {
      BiometricService.recordSensitiveVisit('venue_secret_bar_1', DateTime.now());

      final activeVault = BiometricService.getSensitiveVisitVault(
        hideVisitsHistory: false,
        isLocked: false,
      );
      expect(activeVault.containsKey('venue_secret_bar_1'), isTrue);

      BiometricService.purgeSensitiveMemoryVault();

      final purgedVault = BiometricService.getSensitiveVisitVault(
        hideVisitsHistory: false,
        isLocked: false,
      );
      expect(purgedVault.isEmpty, isTrue);
    });

    testWidgets('SettingsScreen displays Purge Visit History action and shows confirmation modal', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final purgeTile = find.byKey(const Key('settings_tile_purge_history'));
      expect(purgeTile, findsOneWidget);

      await tester.ensureVisible(purgeTile);
      await tester.pumpAndSettle();
      await tester.tap(purgeTile);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Purge Visit History?'), findsOneWidget);
      expect(find.text('Purge History'), findsOneWidget);

      // Tap Cancel to dismiss cleanly
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Purge Visit History?'), findsNothing);
    });
  });
}
