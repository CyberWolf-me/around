import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/features/feed/widgets/bento_card.dart';

void main() {
  group('BentoCard Widget Tests', () {
    testWidgets('Renders note card with author, text and place name', (WidgetTester tester) async {
      final post = PostModel(
        id: 'test-note-1',
        placeId: 'kettle',
        placeName: 'Kettle & Loaf',
        placeCategory: 'Bakery · Café',
        placeAddress: '14 Ledger Street',
        authorId: 'u1',
        authorName: 'Noor Haddad',
        authorUsername: 'noorh',
        authorAvatar: 'NH',
        note: 'The back room table by the window is perfect for morning reading.',
        mediaUrl: null,
        size: PostSize.note,
        audience: PostAudience.friends,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        tags: const ['quiet', 'espresso'],
      );

      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BentoCard(
                post: post,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify author first name and note and place name are rendered
      expect(find.text('Noor'), findsOneWidget);
      expect(find.text('“The back room table by the window is perfect for morning reading.”'), findsOneWidget);
      expect(find.text('Kettle & Loaf'), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(BentoCard));
      expect(tapped, isTrue);
    });

    testWidgets('Renders audience badge "Friends" for friends posts', (WidgetTester tester) async {
      final post = PostModel(
        id: 'test-note-friends',
        placeId: 'fern',
        placeName: 'The Fern Room',
        placeCategory: 'Study café',
        placeAddress: '2 Ostrander Avenue',
        authorId: 'u2',
        authorName: 'Teo Vasquez',
        authorUsername: 'teovas',
        authorAvatar: 'TV',
        note: 'Power sockets are plentiful at the communal oak table.',
        mediaUrl: null,
        size: PostSize.note,
        audience: PostAudience.friends,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BentoCard(
                post: post,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Friends'), findsOneWidget);
    });
  });
}
