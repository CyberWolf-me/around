import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/main.dart';
import 'package:around_app/data/services/storage_service.dart';

void main() {
  setUp(() async {
    await StorageService.setOnboarded(true);
    await StorageService.setAuthUserEmail('explorer@tashkent.uz');
  });
  testWidgets('AroundApp smoke test - verifies non-empty feed and bottom navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AroundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand header in RichText
    expect(find.textContaining('Around', findRichText: true), findsOneWidget);

    // Verify Friends Feed renders seeded Tashkent drops on launch
    expect(find.text('Breadly Bakery & Café'), findsWidgets);

    // Verify navigation tabs
    expect(find.text('FEED'), findsOneWidget);
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('DROP'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('YOU'), findsOneWidget);

    // Switch to Explore tab
    await tester.tap(find.text('EXPLORE'));
    await tester.pumpAndSettle();
    expect(find.text('Tashkent Community'), findsOneWidget);

    // Switch to Saved tab
    await tester.tap(find.text('SAVED'));
    await tester.pumpAndSettle();
    expect(find.text('Your shortlist'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('YOU'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);
  });
}
