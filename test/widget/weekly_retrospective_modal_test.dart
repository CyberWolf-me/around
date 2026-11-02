import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:around_app/core/services/sunday_retrospective_service.dart';
import 'package:around_app/features/feed/widgets/weekly_retrospective_modal.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('WeeklyRetrospectiveModal Widget Tests', () {
    testWidgets('renders secured retrospective card with stats and action callback', (tester) async {
      var actionTriggered = false;
      var dismissTriggered = false;

      const securedCard = SundayRetrospectiveCard(
        title: '🎉 Weekly Tashkent Retrospective',
        message: 'Great exploration! You reviewed 3 spots this week, securing your 4-week streak.',
        ctaText: 'View Taste Passport',
        ctaRoute: '/profile',
        isAtRisk: false,
        dropsThisWeek: 3,
        streakWeeks: 4,
        circleDropsThisWeek: 12,
        topDistrict: 'Mirabad',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyRetrospectiveModal(
              card: securedCard,
              onAction: () => actionTriggered = true,
              onDismiss: () => dismissTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and status
      expect(find.text('STREAK SECURED'), findsOneWidget);
      expect(find.text('🎉 Weekly Tashkent Retrospective'), findsOneWidget);
      expect(find.text('Secured'), findsOneWidget);
      expect(find.text('3 this wk'), findsOneWidget);
      expect(find.text('4 wks'), findsOneWidget);
      expect(find.text('12 spots'), findsOneWidget);

      // Verify action button
      expect(find.text('View Taste Passport'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_retro_action')));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);

      // Verify dismiss button
      await tester.tap(find.byKey(const Key('btn_retro_dismiss')));
      await tester.pumpAndSettle();
      expect(dismissTriggered, isTrue);
    });

    testWidgets('renders urgent streak alert card with rescue CTA when streak is at risk', (tester) async {
      var rescueTriggered = false;

      const atRiskCard = SundayRetrospectiveCard(
        title: '⚠️ Sunday Evening: Streak At Risk!',
        message: 'Only hours remain in the week! Drop a spot tonight to protect your 5-week streak.',
        ctaText: 'Drop Spot Now',
        ctaRoute: '/create-post',
        isAtRisk: true,
        dropsThisWeek: 0,
        streakWeeks: 5,
        circleDropsThisWeek: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyRetrospectiveModal(
              card: atRiskCard,
              onAction: () => rescueTriggered = true,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify at risk indicators
      expect(find.text('STREAK AT RISK'), findsOneWidget);
      expect(find.text('⚠️ Sunday Evening: Streak At Risk!'), findsOneWidget);
      expect(find.text('0 this wk'), findsOneWidget);
      expect(find.text('5 wks'), findsOneWidget);
      expect(find.text('Drop Spot Now'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_retro_action')));
      await tester.pumpAndSettle();
      expect(rescueTriggered, isTrue);
    });

    testWidgets('presents modal via WeeklyRetrospectiveModal.show helper', (tester) async {
      var actionTriggered = false;

      const card = SundayRetrospectiveCard(
        title: 'Sunday Recap',
        message: 'Explore your weekly stats.',
        ctaText: 'Open Profile',
        ctaRoute: '/profile',
        isAtRisk: false,
        dropsThisWeek: 1,
        streakWeeks: 2,
        circleDropsThisWeek: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('trigger_retro_modal'),
                onPressed: () {
                  WeeklyRetrospectiveModal.show(
                    context: ctx,
                    card: card,
                    onAction: () => actionTriggered = true,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('trigger_retro_modal')));
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyRetrospectiveModal), findsOneWidget);
      expect(find.text('Sunday Recap'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_retro_action')));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
      // Modal should be dismissed after action
      expect(find.byType(WeeklyRetrospectiveModal), findsNothing);
    });
  });
}
