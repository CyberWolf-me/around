import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:around_app/main.dart';
import 'package:around_app/core/theme/app_theme.dart';
import 'package:around_app/data/services/storage_service.dart';
import 'package:around_app/features/places/screens/place_detail_screen.dart';
import 'package:around_app/features/create_post/screens/create_drop_sheet.dart';
import 'package:around_app/features/auth/screens/onboarding_screen.dart';
import 'package:around_app/features/auth/screens/auth_screen.dart';
import 'package:around_app/features/feed/screens/notifications_screen.dart';
import 'package:around_app/features/settings/screens/settings_screen.dart';
import 'package:around_app/features/profile/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '.',
    );
    GoogleFonts.config.allowRuntimeFetching = false;
    await StorageService.init();
    await StorageService.setOnboarded(true);
    await StorageService.setAuthUserEmail('explorer@tashkent.uz');
  });

  testWidgets('1. Feed Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const ProviderScope(child: AroundApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(AroundApp),
      matchesGoldenFile('../screenshots/1_feed_screen.png'),
    );
  });

  testWidgets('2. Explore Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const ProviderScope(child: AroundApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('EXPLORE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(AroundApp),
      matchesGoldenFile('../screenshots/2_explore_screen.png'),
    );
  });

  testWidgets('3. Saved Places Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const ProviderScope(child: AroundApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('SAVED'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(AroundApp),
      matchesGoldenFile('../screenshots/3_saved_screen.png'),
    );
  });

  testWidgets('4. Profile Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const ProviderScope(child: AroundApp()));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('YOU'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(AroundApp),
      matchesGoldenFile('../screenshots/4_profile_screen.png'),
    );
  });

  testWidgets('5. Place Detail Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceDetailScreen(placeId: 'breadly'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/5_place_detail_screen.png'),
    );
  });

  testWidgets('6. Create Drop Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CreateDropSheet(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/6_create_drop_sheet.png'),
    );
  });

  testWidgets('7. Onboarding Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/7_onboarding_screen.png'),
    );
  });

  testWidgets('8. Auth Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/8_auth_screen.png'),
    );
  });

  testWidgets('9. Activity Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/9_activity_screen.png'),
    );
  });

  testWidgets('10. Settings Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/10_settings_screen.png'),
    );
  });

  testWidgets('11. User Profile Screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const UserProfileScreen(userId: 'kamila'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/11_user_profile_screen.png'),
    );
  });
}
