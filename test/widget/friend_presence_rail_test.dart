import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/feed/widgets/friend_presence_rail.dart';
import 'package:around_app/data/models/post_model.dart';

void main() {
  group('P17-01: FriendPresenceRail Widget Tests', () {
    PostModel createTestDrop({
      required String id,
      required String authorId,
      required String placeId,
      required String placeName,
      required String district,
      required DateTime createdAt,
    }) {
      return PostModel(
        id: id,
        authorId: authorId,
        authorName: 'User $authorId',
        authorUsername: 'user_$authorId',
        placeId: placeId,
        placeName: placeName,
        placeCategory: 'Cafe',
        placeAddress: '$district, Tashkent',
        note: 'Fresh morning brew at $placeName',
        audience: PostAudience.friends,
        createdAt: createdAt,
      );
    }

    testWidgets('renders active friend avatar, district pill, and opens details sheet on tap',
        (tester) async {
      final now = DateTime.now();

      final drops = [
        createTestDrop(
          id: 'drop_kamila',
          authorId: 'kamila',
          placeId: 'place_breadly',
          placeName: 'Breadly Bakery',
          district: 'Mirabad',
          createdAt: now.subtract(const Duration(minutes: 10)), // justNow online
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FriendPresenceRail(
                overrideFriends: const ['kamila'],
                overrideDrops: drops,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header presence
      expect(find.textContaining('FRIENDS AROUND TASHKENT'), findsOneWidget);

      // Verify Kamila's first name is rendered
      expect(find.text('Kamila'), findsOneWidget);

      // Verify district chip
      expect(find.text('Mirabad'), findsOneWidget);

      // Tap on Kamila's avatar to open bottom sheet
      await tester.tap(find.text('Kamila'));
      await tester.pumpAndSettle();

      // Verify bottom sheet content
      expect(find.text('Kamila Rahimova'), findsOneWidget);
      expect(find.text('@kamilar'), findsOneWidget);
      expect(find.text('Breadly Bakery'), findsOneWidget);
      expect(find.text('Fresh morning brew at Breadly Bakery'), findsOneWidget);
    });

    testWidgets('returns empty widget when no friends are followed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FriendPresenceRail(
                overrideFriends: [],
                overrideDrops: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('FRIENDS AROUND TASHKENT'), findsNothing);
    });
  });
}
