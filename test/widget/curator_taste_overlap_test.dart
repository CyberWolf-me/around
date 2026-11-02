import 'package:around_app/core/services/curator_recommendation_engine.dart';
import 'package:around_app/features/profile/widgets/curator_taste_overlap_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P20-01: CuratorTasteOverlapCard Widget Tests', () {
    const candidateCurator = CuratorTasteProfile(
      userId: 'user_kamila',
      username: 'kamila_r',
      fullName: 'Kamila Rahimova',
      neighborhood: 'Mirabad',
      droppedPlaceIds: {'breadly', 'tims'},
      preferredTags: {'Coffee', 'Pastry'},
      activeDistricts: {'Mirabad'},
    );

    testWidgets('renders high match badge, shared places and tags', (tester) async {
      const match = TasteOverlapMatch(
        curator: candidateCurator,
        similarityScore: 0.85,
        compatibilityPercent: 85,
        sharedPlaces: ['breadly', 'tims'],
        sharedTags: ['Coffee', 'Pastry'],
        sharedDistricts: ['Mirabad'],
        primaryHighlightEn: '2 shared favorite spots in Mirabad',
        primaryHighlightUz: 'Mirabad tumanida 2 ta umumiy sevimli joy',
        primaryHighlightRu: '2 общих места в районе Mirabad',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTasteOverlapCard(
                match: match,
                languageCode: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('TASTE COMPATIBILITY'), findsOneWidget);
      expect(find.text('85% MATCH'), findsOneWidget);
      expect(find.text('2 shared favorite spots in Mirabad'), findsOneWidget);
      expect(find.text('breadly'), findsOneWidget);
      expect(find.text('#Coffee'), findsOneWidget);
    });

    testWidgets('renders Uzbek and Russian localized highlights accurately', (tester) async {
      const match = TasteOverlapMatch(
        curator: candidateCurator,
        similarityScore: 0.70,
        compatibilityPercent: 70,
        sharedPlaces: ['breadly'],
        sharedTags: ['Coffee'],
        sharedDistricts: ['Mirabad'],
        primaryHighlightEn: '1 shared favorite spot in Mirabad',
        primaryHighlightUz: 'Mirabad tumanida 1 ta umumiy sevimli joy',
        primaryHighlightRu: '1 общее место в районе Mirabad',
      );

      // Uzbek
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTasteOverlapCard(
                match: match,
                languageCode: 'uz',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mirabad tumanida 1 ta umumiy sevimli joy'), findsOneWidget);

      // Russian
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTasteOverlapCard(
                match: match,
                languageCode: 'ru',
              ),
            ),
          ),
        ),
      );

      expect(find.text('1 общее место в районе Mirabad'), findsOneWidget);
    });

    testWidgets('renders discovery prompt for disjoint taste profiles', (tester) async {
      const match = TasteOverlapMatch(
        curator: candidateCurator,
        similarityScore: 0.0,
        compatibilityPercent: 0,
        sharedPlaces: [],
        sharedTags: [],
        sharedDistricts: [],
        primaryHighlightEn: 'Fresh taste perspective to discover',
        primaryHighlightUz: 'Kashf qilish uchun yangi did nigohi',
        primaryHighlightRu: 'Свежий взгляд на городские места',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorTasteOverlapCard(
                match: match,
                languageCode: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('0% MATCH'), findsOneWidget);
      expect(find.text('Fresh taste perspective to discover'), findsOneWidget);
      expect(find.textContaining('Explore their profile to discover new neighborhood spots'), findsOneWidget);
    });
  });
}
