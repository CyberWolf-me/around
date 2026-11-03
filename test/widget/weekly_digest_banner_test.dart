import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/feed/widgets/weekly_digest_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P15-01: WeeklyDigestBanner Widget Tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('WeeklyDigestBanner is hidden on weekday non-weekend window', (tester) async {
      final wednesdayNoon = DateTime(2026, 11, 4, 12, 0); // Wednesday 12:00

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeeklyDigestBanner(
                simulatedTime: wednesdayNoon,
                forceVisible: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weekly_digest_banner')), findsNothing);
    });

    testWidgets('WeeklyDigestBanner renders on Friday evening and opens coordination sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fridayEvening = DateTime(2026, 11, 6, 19, 0); // Friday 19:00
      String? copiedInvite;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WeeklyDigestBanner(
                simulatedTime: fridayEvening,
                forceVisible: true,
                onInviteCopied: (msg) => copiedInvite = msg,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should be visible
      expect(find.byKey(const Key('weekly_digest_banner')), findsOneWidget);
      expect(find.text('🔥 FRIDAY NIGHT RHYTHM'), findsOneWidget);

      // Tap banner to open bottom sheet
      await tester.tap(find.byKey(const Key('weekly_digest_banner')));
      await tester.pumpAndSettle();

      // Bottom sheet contents
      expect(find.text('Tashkent Weekend Digest'), findsOneWidget);
      expect(find.byKey(const Key('btn_copy_weekend_invite')), findsOneWidget);
      expect(find.byKey(const Key('btn_telegram_weekend_invite')), findsOneWidget);

      // Tap Copy Invite
      await tester.tap(find.byKey(const Key('btn_copy_weekend_invite')));
      await tester.pumpAndSettle();

      expect(copiedInvite, isNotNull);
      expect(copiedInvite, contains('https://around.tashkent.app'));
    });
  });
}
