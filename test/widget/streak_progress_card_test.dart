import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/profile/widgets/streak_progress_card.dart';
import 'package:around_app/core/services/explorer_streak_engine.dart';

void main() {
  group('P18-01: StreakProgressCard Widget Tests', () {
    testWidgets('renders active 4-week streak with secured badge and progress', (tester) async {
      final status = ExplorerStreakStatus(
        currentStreakWeeks: 4,
        longestStreakWeeks: 6,
        hasDroppedThisWeek: true,
        isAtRisk: false,
        daysRemainingInWeek: 4,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 6,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StreakProgressCard(
                userId: 'curator_1',
                customStatus: status,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Flame counter
      expect(find.text('4 WEEKS'), findsOneWidget);

      // Milestone badge title
      expect(find.text('🔥 4-Week Explorer'), findsOneWidget);

      // Secured badge
      expect(find.text('✓ Secured'), findsOneWidget);

      // Progress label
      expect(find.textContaining('4 / 8 weeks to Seasoned'), findsOneWidget);
      expect(find.text('Best: 6 wks'), findsOneWidget);
    });

    testWidgets('renders at-risk warning banner when drop is needed this week', (tester) async {
      final status = ExplorerStreakStatus(
        currentStreakWeeks: 3,
        longestStreakWeeks: 3,
        hasDroppedThisWeek: false,
        isAtRisk: true,
        daysRemainingInWeek: 2,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StreakProgressCard(
                userId: 'curator_risk',
                customStatus: status,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Urgent warning pill
      expect(find.text('⚠️ 2d left'), findsOneWidget);
      expect(find.textContaining('Streak at risk!'), findsOneWidget);
    });

    testWidgets('renders starting state for 0-week streak', (tester) async {
      final status = ExplorerStreakStatus(
        currentStreakWeeks: 0,
        longestStreakWeeks: 0,
        hasDroppedThisWeek: false,
        isAtRisk: false,
        daysRemainingInWeek: 5,
        currentWeekStart: DateTime(2026, 11, 2),
        totalQualifyingWeeks: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StreakProgressCard(
                userId: 'curator_new',
                customStatus: status,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 WEEKS'), findsOneWidget);
      expect(find.text('🧭 First Steps'), findsOneWidget);
      expect(find.textContaining('Discover a new spot in Tashkent this week'), findsOneWidget);
    });
  });
}
