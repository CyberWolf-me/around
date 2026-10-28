import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/main.dart';

void main() {
  testWidgets('AroundApp smoke test - verifies bottom nav and feed loading', (WidgetTester tester) async {
    // Build AroundApp inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: AroundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand header in RichText
    expect(find.textContaining('Around', findRichText: true), findsOneWidget);

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
