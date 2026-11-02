import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/locale_service.dart';
import 'package:around_app/data/services/storage_service.dart';
import 'package:around_app/features/settings/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleService & Trilingual Localization Engine Tests (P11-04)', () {
    setUp(() async {
      await StorageService.clearAll();
    });

    test('LocaleService.tr provides accurate Uzbek, Russian, and English translations', () {
      // Feed
      expect(LocaleService.tr('feed', 'en'), equals('Feed'));
      expect(LocaleService.tr('feed', 'uz'), equals('Lenta'));
      expect(LocaleService.tr('feed', 'ru'), equals('Лента'));

      // Explore
      expect(LocaleService.tr('explore', 'en'), equals('Explore'));
      expect(LocaleService.tr('explore', 'uz'), equals('Kashfiyot'));
      expect(LocaleService.tr('explore', 'ru'), equals('Поиск'));

      // Taste Passport
      expect(LocaleService.tr('tastePassport', 'en'), equals('Tashkent Taste Passport'));
      expect(LocaleService.tr('tastePassport', 'uz'), equals('Toshkent Ta’m Pasporti'));
      expect(LocaleService.tr('tastePassport', 'ru'), equals('Паспорт Вкуса Ташкента'));

      // Atmosphere Rhythms
      expect(LocaleService.tr('morningBrew', 'uz'), equals('Tonggi Qahva'));
      expect(LocaleService.tr('morningBrew', 'ru'), equals('Утренний Кофе'));
      expect(LocaleService.tr('goldenHour', 'uz'), equals('Oltin Soat'));
      expect(LocaleService.tr('goldenHour', 'ru'), equals('Золотой Час'));
    });

    test('LocaleService falls back to English when key or code is unknown', () {
      expect(LocaleService.tr('feed', 'fr'), equals('Feed'));
      expect(LocaleService.tr('nonexistent_key', 'uz'), equals('nonexistent_key'));
    });

    test('StorageService persists and retrieves language preference', () async {
      expect(StorageService.getAppLanguage(), equals('en'));

      await StorageService.setAppLanguage('uz');
      expect(StorageService.getAppLanguage(), equals('uz'));

      await StorageService.setAppLanguage('ru');
      expect(StorageService.getAppLanguage(), equals('ru'));
    });

    test('appLocaleProvider updates Riverpod state and calls StorageService', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appLocaleProvider), equals('en'));

      await container.read(appLocaleProvider.notifier).setLocale('uz');
      expect(container.read(appLocaleProvider), equals('uz'));
      expect(StorageService.getAppLanguage(), equals('uz'));

      await container.read(appLocaleProvider.notifier).setLocale('ru');
      expect(container.read(appLocaleProvider), equals('ru'));
      expect(StorageService.getAppLanguage(), equals('ru'));
    });

    testWidgets('SettingsScreen displays language options and updates preference on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to Language Section if needed
      await tester.scrollUntilVisible(find.text('LANGUAGE & LOCALIZATION'), 300);

      // Verify Language Section Title
      expect(find.text('LANGUAGE & LOCALIZATION'), findsOneWidget);

      // Verify All 3 Languages Rendered
      expect(find.text("O'zbekcha"), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Tap Uzbek button
      await tester.tap(find.text("O'zbekcha"));
      await tester.pumpAndSettle();

      expect(StorageService.getAppLanguage(), equals('uz'));

      // Tap Russian button
      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      expect(StorageService.getAppLanguage(), equals('ru'));
    });
  });
}
