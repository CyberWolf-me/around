import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/explore/widgets/district_coverage_card.dart';
import 'package:around_app/core/services/personal_coverage_engine.dart';

const mirabad = DistrictCoverage(
  district: 'Mirabad',
  visitedCount: 7,
  totalPlaces: 10,
  coverageFraction: 0.7,
  coveragePercent: 70,
  statusLevel: 'mastered',
);

const central = DistrictCoverage(
  district: 'Central Tashkent',
  visitedCount: 2,
  totalPlaces: 10,
  coverageFraction: 0.2,
  coveragePercent: 20,
  statusLevel: 'discovering',
);

const yakkasaray = DistrictCoverage(
  district: 'Yakkasaray',
  visitedCount: 0,
  totalPlaces: 8,
  coverageFraction: 0.0,
  coveragePercent: 0,
  statusLevel: 'unexplored',
);

const testDistricts = {
  'Mirabad': mirabad,
  'Central Tashkent': central,
  'Yakkasaray': yakkasaray,
};

const testReport = CityCoverageReport(
  totalVisited: 9,
  totalPlaces: 28,
  overallFraction: 0.32,
  overallPercentage: 32,
  districts: testDistricts,
  leastExploredDistrict: yakkasaray,
  mostExploredDistrict: mirabad,
  recommendedPlaceId: 'place_bnb',
  recommendedPlaceName: 'B&B Coffee House',
  recommendedDistrict: 'Yakkasaray',
);

void main() {
  group('P24-02: DistrictCoverageCard Widget Tests', () {

    testWidgets('renders exploration header, city score, and district progress bars', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistrictCoverageCard(
              customReport: testReport,
              languageCode: 'en',
            ),
          ),
        ),
      );

      expect(find.text('TASHKENT EXPLORATION HEAT'), findsOneWidget);
      expect(find.text('32% of Tashkent Explored'), findsOneWidget);
      expect(find.text('32%'), findsOneWidget);
      expect(find.text('Mirabad'), findsOneWidget);
      expect(find.text('Central Tashkent'), findsOneWidget);
      expect(find.text('Yakkasaray'), findsOneWidget);
      expect(find.text('7/10 (70%)'), findsOneWidget);
      expect(find.text('B&B Coffee House'), findsOneWidget);
    });

    testWidgets('triggers onSelectDistrict callback when district row is tapped', (tester) async {
      String? selectedDistrict;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistrictCoverageCard(
              customReport: testReport,
              onSelectDistrict: (d) => selectedDistrict = d,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('district_row_mirabad')));
      await tester.pumpAndSettle();

      expect(selectedDistrict, equals('Mirabad'));
    });

    testWidgets('triggers onTapRecommendation callback when View Spot is tapped', (tester) async {
      String? viewedPlaceId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistrictCoverageCard(
              customReport: testReport,
              onTapRecommendation: (id) => viewedPlaceId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.text('View Spot'));
      await tester.pumpAndSettle();

      expect(viewedPlaceId, equals('place_bnb'));
    });

    testWidgets('supports Uzbek and Russian localizations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistrictCoverageCard(
              customReport: testReport,
              languageCode: 'uz',
            ),
          ),
        ),
      );
      expect(find.text('Toshkentning 32% qismi kashf etildi'), findsOneWidget);
      expect(find.text('👑 O‘zlashtirilgan'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DistrictCoverageCard(
              customReport: testReport,
              languageCode: 'ru',
            ),
          ),
        ),
      );
      expect(find.text('Исследовано 32% Ташкента'), findsOneWidget);
      expect(find.text('👑 Освоено'), findsOneWidget);
    });
  });
}
