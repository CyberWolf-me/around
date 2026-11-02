import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/deep_link_service.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/profile_model.dart';
import 'package:around_app/features/profile/widgets/taste_passport_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tashkent Taste Passport Tests (P11-01)', () {
    const testProfile = ProfileModel(
      id: 'test-curator-1',
      username: 'shakhlo_n',
      fullName: 'Shakhlo Nazarova',
      bio: 'Independent bookshops, world classics, and quiet reading nooks.',
      neighborhood: 'Yunusabad',
      dropsCount: 19,
      friendsCount: 8,
      savedCount: 12,
      hideVisitsHistory: true,
      defaultAudience: 'public',
      discoverableByFriends: true,
      quietHours: false,
      allowFriendRequests: false,
    );

    const testPlace1 = PlaceModel(
      id: 'kitobxon',
      canonicalUuid: '11111111-1111-4111-8111-111111111105',
      slug: 'kitobxon-book-cafe',
      name: 'Kitobxon Book Café',
      category: 'Quiet Reading · Tea Library',
      streetAddress: '15 Navoi Avenue',
      district: 'Shaykhontohur',
      city: 'Tashkent',
      latitude: 41.3195,
      longitude: 69.2482,
      distanceMeters: 620,
      walkTimeMinutes: 8,
      priceTier: r'$$',
      hours: '9:00 AM – 10:00 PM',
      statusLine: 'Open · Quiet study rooms available',
      description: 'Peaceful reading sanctuary.',
      heroImageUrl: 'assets/cafe-bw.jpg',
      ratingAvg: 4.8,
      ratingCount: 310,
      tags: ['quiet study', 'tea selection'],
      photos: ['assets/cafe-bw.jpg'],
    );

    const testPlace2 = PlaceModel(
      id: 'breadly',
      canonicalUuid: '11111111-1111-4111-8111-111111111101',
      slug: 'breadly-bakery-cafe',
      name: 'Breadly Bakery & Café',
      category: 'Bakery · Specialty Café',
      streetAddress: '24 Taras Shevchenko Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.2996,
      longitude: 69.2748,
      distanceMeters: 350,
      walkTimeMinutes: 4,
      priceTier: r'$$',
      hours: '8:00 AM – 10:00 PM',
      statusLine: 'Fresh cinnamon buns out of the oven',
      description: 'Artisanal sourdough bakery.',
      heroImageUrl: 'assets/cafe-light.jpg',
      ratingAvg: 4.8,
      ratingCount: 420,
      tags: ['cardamom bun', 'flat white'],
      photos: ['assets/cafe-light.jpg'],
    );

    test('DeepLinkService correctly formats passport URIs and resolves routes', () {
      final webUri = DeepLinkService.buildPassportUri('shakhlo_n', web: true);
      expect(webUri, equals('https://around.tashkent.app/passport/shakhlo_n'));

      final appUri = DeepLinkService.buildPassportUri('shakhlo_n', web: false);
      expect(appUri, equals('around://passport/shakhlo_n'));

      final customResolved = DeepLinkService.resolveRouteFromUri(Uri.parse('around://passport/shakhlo_n'));
      expect(customResolved, equals('/passport/shakhlo_n'));

      final webResolved = DeepLinkService.resolveRouteFromUri(Uri.parse('https://around.tashkent.app/passport/kamilar'));
      expect(webResolved, equals('/passport/kamilar'));

      final fallbackResolved = DeepLinkService.resolveRouteFromUri(Uri.parse('https://around.app/passport/diyor_u'));
      expect(fallbackResolved, equals('/passport/diyor_u'));
    });

    testWidgets('TastePassportCard renders curator details, stats, and top venues', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastePassportCard(
                profile: testProfile,
                topPlaces: [testPlace1, testPlace2],
                totalDrops: 19,
                totalSaved: 12,
              ),
            ),
          ),
        ),
      );

      // Verify Header & Title
      expect(find.text('TASHKENT TASTE PASSPORT'), findsOneWidget);
      expect(find.text('YUNUSABAD'), findsOneWidget);

      // Verify Curator Identity
      expect(find.text('Shakhlo Nazarova'), findsOneWidget);
      expect(find.text('@shakhlo_n · Local Curator'), findsOneWidget);

      // Verify Stats
      expect(find.text('19'), findsOneWidget);
      expect(find.text('Curated Drops'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Saved Gems'), findsOneWidget);

      // Verify Venues
      expect(find.text('Kitobxon Book Café'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('Shaykhontohur'), findsOneWidget);
      expect(find.text('Mirabad'), findsOneWidget);

      // Verify Action Button
      expect(find.text('Share Taste Passport'), findsOneWidget);
    });

    testWidgets('TastePassportCard handles empty venue list gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TastePassportCard(
                profile: testProfile,
                topPlaces: [],
                totalDrops: 0,
                totalSaved: 0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Save or drop recommendations to populate your top venues.'), findsOneWidget);
    });
  });
}
