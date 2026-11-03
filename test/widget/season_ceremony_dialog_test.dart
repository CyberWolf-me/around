import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/season_ceremony_engine.dart';
import 'package:around_app/features/explore/widgets/season_ceremony_dialog.dart';

void main() {
  group('P30-02: SeasonCeremonyDialog Widget Tests', () {
    final championReport = SeasonCeremonyEngine.generateWrapupReport(
      seasonId: '2026-10',
      seasonTitleEn: 'October in Tashkent',
      seasonTitleUz: 'Toshkentda Oktyabr',
      seasonTitleRu: 'Октябрь в Ташкенте',
      totalSeasonXp: 1500,
      totalPlacesVisited: 22,
      topDistrict: 'Mirabad',
      districtRank: 1,
      cityRank: 1,
    );

    final podiumReport = SeasonCeremonyEngine.generateWrapupReport(
      seasonId: '2026-10',
      totalSeasonXp: 600,
      totalPlacesVisited: 10,
      topDistrict: 'Chilanzar',
      districtRank: 3,
      cityRank: 7,
    );

    testWidgets('renders season ceremony dialog for district champion', (tester) async {
      bool claimed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonCeremonyDialog(
              report: championReport,
              languageCode: 'en',
              onClaimCelebration: () {
                claimed = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('season_ceremony_dialog')), findsOneWidget);
      expect(find.text('SEASON WRAP-UP · 2026-10'), findsOneWidget);
      expect(find.text('Congratulations! You are the Mirabad Champion!'), findsOneWidget);
      expect(find.text('District Champion Crown'), findsOneWidget);
      expect(find.text('1500 XP'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('Mirabad (#1)'), findsOneWidget);
      expect(find.byKey(const Key('crown_awarded_banner')), findsOneWidget);

      final claimBtn = find.byKey(const Key('claim_ceremony_btn'));
      expect(claimBtn, findsOneWidget);
      await tester.tap(claimBtn);
      await tester.pumpAndSettle();

      expect(claimed, isTrue);
    });

    testWidgets('renders podium report without crown banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonCeremonyDialog(
              report: podiumReport,
              languageCode: 'en',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You placed #3 in Chilanzar!'), findsOneWidget);
      expect(find.text('Silver Podium Laurel'), findsOneWidget);
      expect(find.byKey(const Key('crown_awarded_banner')), findsNothing);
    });

    testWidgets('renders Uzbek and Russian localizations correctly', (tester) async {
      // Uzbek
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonCeremonyDialog(
              report: championReport,
              languageCode: 'uz',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MAVSUM YAKUNI · 2026-10'), findsOneWidget);
      expect(find.text('Tabriklaymiz! Siz Mirabad Tuman Chempionisiz!'), findsOneWidget);
      expect(find.text('Tuman Chempioni Toji'), findsOneWidget);
      expect(find.text('+1 Shahar Toji berildi!'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonCeremonyDialog(
              report: championReport,
              languageCode: 'ru',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ИТОГИ СЕЗОНА · 2026-10'), findsOneWidget);
      expect(find.text('Поздравляем! Вы Чемпион Района Mirabad!'), findsOneWidget);
      expect(find.text('Корона Чемпиона Района'), findsOneWidget);
      expect(find.text('+1 Городская Корона вручена!'), findsOneWidget);
    });
  });
}
