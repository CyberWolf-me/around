import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/features/plans/widgets/group_meetup_coordination_sheet.dart';

void main() {
  group('P22-02: GroupMeetupCoordinationSheet Widget Tests', () {
    testWidgets('renders venue name, occasion input, curator stepper, and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupMeetupCoordinationSheet(
              venueName: 'Breadly Bakery & Café',
              venueSlug: 'breadly',
              venueLatitude: 41.2995,
              venueLongitude: 69.2810,
              initialOccasion: 'Morning Espresso & Croissant',
              initialMaxParticipants: 4,
            ),
          ),
        ),
      );

      expect(find.text('GROUP COFFEE MEETUP'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('Morning Espresso & Croissant'), findsOneWidget);
      expect(find.text('4 curators'), findsOneWidget);
      expect(find.text('Share to Telegram'), findsOneWidget);
      expect(find.text('Save Meetup to Plans'), findsOneWidget);
    });

    testWidgets('stepper increments and decrements participant count within bounds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroupMeetupCoordinationSheet(
              venueName: 'B&B Coffee House',
              venueSlug: 'bnb',
              initialMaxParticipants: 3,
            ),
          ),
        ),
      );

      expect(find.text('3 curators'), findsOneWidget);

      // Increment
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('4 curators'), findsOneWidget);

      // Decrement twice
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('3 curators'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('2 curators'), findsOneWidget);

      // Attempt decrement below minimum bound (2)
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('2 curators'), findsOneWidget); // clamped to 2
    });

    testWidgets('triggers onLaunchOverride when Share to Telegram is tapped', (tester) async {
      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupMeetupCoordinationSheet(
              venueName: 'Ecorn Patisserie',
              venueSlug: 'ecorn',
              initialOccasion: 'Afternoon Tea',
              onLaunchOverride: (url) => launchedUrl = url,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Share to Telegram'));
      await tester.pumpAndSettle();

      expect(launchedUrl, isNotNull);
      expect(launchedUrl, contains('t.me/share/url'));
      expect(launchedUrl, contains('ecorn'));
    });

    testWidgets('triggers onPlanCreated callback when Save Meetup to Plans is tapped', (tester) async {
      String? savedOccasion;
      int? savedLimit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupMeetupCoordinationSheet(
              venueName: 'Socials Cafe',
              venueSlug: 'socials',
              initialOccasion: 'Work Session',
              initialMaxParticipants: 5,
              onPlanCreated: (occ, dt, limit) {
                savedOccasion = occ;
                savedLimit = limit;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save Meetup to Plans'));
      await tester.pumpAndSettle();

      expect(savedOccasion, equals('Work Session'));
      expect(savedLimit, equals(5));
    });

    test('buildGroupInviteMessage produces accurate trilingual copy', () {
      final uzMsg = GroupMeetupCoordinationSheet.buildGroupInviteMessage(
        occasion: 'Kofe uchrashuvi',
        venueName: 'Breadly Bakery',
        timeFormatted: 'Nov 4, 11:00',
        maxParticipants: 4,
        venueSlug: 'breadly',
        metroBeacon: '🚇 Oybek • 350m',
        lang: 'uz',
      );
      expect(uzMsg, contains('Toshkent Do‘stlar Uchrashuvi: Kofe uchrashuvi'));
      expect(uzMsg, contains('Around orqali tasdiqlang'));

      final ruMsg = GroupMeetupCoordinationSheet.buildGroupInviteMessage(
        occasion: 'Встреча за кофе',
        venueName: 'Breadly Bakery',
        timeFormatted: 'Nov 4, 11:00',
        maxParticipants: 4,
        venueSlug: 'breadly',
        lang: 'ru',
      );
      expect(ruMsg, contains('Встреча друзей в Ташкенте: Встреча за кофе'));
      expect(ruMsg, contains('Подтвердить в Around'));

      final enMsg = GroupMeetupCoordinationSheet.buildGroupInviteMessage(
        occasion: 'Coffee Meetup',
        venueName: 'Breadly Bakery',
        timeFormatted: 'Nov 4, 11:00',
        maxParticipants: 4,
        venueSlug: 'breadly',
        lang: 'en',
      );
      expect(enMsg, contains('Tashkent Friends Meetup: Coffee Meetup'));
      expect(enMsg, contains('RSVP on Around'));
    });
  });
}
