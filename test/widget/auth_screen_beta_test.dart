import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:around_app/core/services/beta_access_service.dart';
import 'package:around_app/core/widgets/bouncing_widget.dart';
import 'package:around_app/data/services/storage_service.dart';
import 'package:around_app/features/auth/screens/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await StorageService.init();
    await BetaAccessService.revokeAccess();
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/feed',
          builder: (context, state) => const Scaffold(body: Text('Feed Screen')),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('AuthScreen shows VIP Beta Invite Code input when switching to Sign Up', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Defaults to Sign In mode
    expect(find.text('Sign In'), findsWidgets);
    expect(find.byType(TextField), findsNWidgets(2)); // Email, Password

    // Switch to Sign Up mode
    await tester.tap(find.text('Need an account? Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Beta Invite Code (e.g. TASH50) *'), findsOneWidget);
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Username (@handle) *'), findsOneWidget);
  });

  testWidgets('Sign Up displays validation error when submitting with invalid beta code', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Sign Up mode
    await tester.tap(find.text('Need an account? Create one'));
    await tester.pumpAndSettle();

    // Fill valid form fields
    await tester.enterText(find.widgetWithText(TextField, 'Full Name *'), 'Dilshod Test');
    await tester.enterText(find.widgetWithText(TextField, 'Username (@handle) *'), 'dilshod_test');
    await tester.enterText(find.widgetWithText(TextField, 'Email Address *'), 'dilshod@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password (min 8 chars) *'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'Beta Invite Code (e.g. TASH50) *'), 'BADCOD');

    // Tap submit button
    final submitButton = find.widgetWithText(BouncingWidget, 'Create Account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid beta invite code'), findsOneWidget);
    expect(BetaAccessService.hasAccess(), isFalse);
  });

  testWidgets('Continue as Guest bypasses the beta access gate and navigates to /feed', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.text('Feed Screen'), findsOneWidget);
    expect(StorageService.isGuestMode(), isTrue);
  });
}
