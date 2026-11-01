import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/main.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  testWidgets('Fresh install starts on Onboarding and routes to Auth', (WidgetTester tester) async {
    // Reset to brand new install state
    await StorageService.clearAuthSession();
    await StorageService.setOnboarded(false);

    await tester.pumpWidget(
      const ProviderScope(
        child: AroundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Onboarding screen is shown
    expect(find.text('Where should\nwe go?'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Skip to complete onboarding
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify Auth screen is shown
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Continue as Guest (Read-Only)'), findsOneWidget);

    // Tap Continue as Guest
    await tester.tap(find.text('Continue as Guest (Read-Only)'));
    await tester.pumpAndSettle();

    // Verify user is now on Feed
    expect(find.text('FEED'), findsOneWidget);
    expect(find.text('EXPLORE'), findsOneWidget);
  });
}
