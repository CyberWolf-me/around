import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/curator_postcard_engine.dart';
import 'package:around_app/features/explore/widgets/curator_postcard_card.dart';

void main() {
  group('P27-02: CuratorPostcardCard Widget Tests', () {
    final samplePostcard = CuratorPostcard(
      placeId: 'place_breadly',
      placeName: 'Breadly Bakery & Café',
      district: 'Mirabad',
      atmosphereTag: 'Morning Brew',
      verifiedSeal: 'AR-B742-1894',
      nearestSubway: 'Oybek',
      curatorName: 'Kamila',
      curatorHandle: 'kamilar',
      curatorTier: 'tashkentLegend',
      curatorXp: 2450,
      visitTimestamp: DateTime.now(),
      receiptNumber: 'REC-MIR-2026-884',
      theme: PostcardTheme.warmPaper,
      aspectRatio: PostcardAspectRatio.story9x16,
    );

    testWidgets('renders receipt card with venue details, verified seal, and curator block', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                languageCode: 'en',
              ),
            ),
          ),
        ),
      );

      expect(find.text('TASHKENT CULTURAL RECEIPT'), findsOneWidget);
      expect(find.text('REC-MIR-2026-884'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('MIRABAD · Morning Brew'), findsOneWidget);
      expect(find.text('AR-B742-1894'), findsOneWidget);
      expect(find.text('Oybek'), findsOneWidget);
      expect(find.text('VERIFIED VISIT'), findsOneWidget);
      expect(find.text('Kamila'), findsOneWidget);
      expect(find.text('@kamilar · tashkentLegend'), findsOneWidget);
      expect(find.text('2450 XP'), findsOneWidget);
      expect(find.text('Share to Telegram'), findsOneWidget);
    });

    testWidgets('triggers onChangeTheme when theme toggle is tapped', (tester) async {
      PostcardTheme? updatedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                onChangeTheme: (t) => updatedTheme = t,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('postcard_theme_toggle_btn')));
      await tester.pumpAndSettle();

      expect(updatedTheme, equals(PostcardTheme.darkCarbon));
    });

    testWidgets('triggers onChangeAspectRatio when ratio toggle is tapped', (tester) async {
      PostcardAspectRatio? updatedRatio;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                onChangeAspectRatio: (r) => updatedRatio = r,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('postcard_ratio_toggle_btn')));
      await tester.pumpAndSettle();

      expect(updatedRatio, equals(PostcardAspectRatio.square1x1));
    });

    testWidgets('triggers onShare when Share button is tapped', (tester) async {
      CuratorPostcard? sharedPostcard;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                onShare: (p) => sharedPostcard = p,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('postcard_share_telegram_btn')));
      await tester.pumpAndSettle();

      expect(sharedPostcard, isNotNull);
      expect(sharedPostcard?.placeId, equals('place_breadly'));
    });

    testWidgets('supports Uzbek and Russian localizations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                languageCode: 'uz',
              ),
            ),
          ),
        ),
      );
      expect(find.text('TOSHKENT MADANIY CHEKI & KARTA'), findsOneWidget);
      expect(find.text('Telegramga Ulashish'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CuratorPostcardCard(
                postcard: samplePostcard,
                languageCode: 'ru',
              ),
            ),
          ),
        ),
      );
      expect(find.text('ТАШКЕНТСКИЙ КУЛЬТУРНЫЙ ЧЕК'), findsOneWidget);
      expect(find.text('Поделиться в Telegram'), findsOneWidget);
    });
  });
}
