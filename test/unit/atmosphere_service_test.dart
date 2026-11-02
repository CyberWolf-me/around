import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/core/services/atmosphere_service.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/features/explore/widgets/category_chips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AtmosphereService & Real-Time Rhythm Engine Tests (P11-03)', () {
    const breadlyPlace = PlaceModel(
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
      description: 'Artisanal sourdough bakery with morning flat whites.',
      heroImageUrl: 'assets/cafe-light.jpg',
      ratingAvg: 4.8,
      ratingCount: 420,
      tags: ['cardamom bun', 'flat white', 'espresso', 'sourdough'],
      photos: ['assets/cafe-light.jpg'],
    );

    const kitobxonPlace = PlaceModel(
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
      description: 'Quiet study tables, tea selection, and fast Wi-Fi.',
      heroImageUrl: 'assets/cafe-bw.jpg',
      ratingAvg: 4.8,
      ratingCount: 310,
      tags: ['quiet study', 'tea library', 'power sockets'],
      photos: ['assets/cafe-bw.jpg'],
    );

    const centralParkPlace = PlaceModel(
      id: 'centralpark',
      canonicalUuid: '11111111-1111-4111-8111-111111111106',
      slug: 'central-park-tashkent',
      name: 'Central Park',
      category: 'Park · Green Promenade',
      streetAddress: '21 Movaraunnahr Street',
      district: 'Mirzo Ulugbek',
      city: 'Tashkent',
      latitude: 41.3142,
      longitude: 69.2931,
      distanceMeters: 850,
      walkTimeMinutes: 11,
      priceTier: 'Free',
      hours: '6:00 AM – 11:00 PM',
      statusLine: 'Open · Sunset promenade',
      description: 'Centuries-old shaded sycamores and sunset lake strolls.',
      heroImageUrl: 'assets/window-girl.jpg',
      ratingAvg: 4.7,
      ratingCount: 654,
      tags: ['shaded walks', 'sunset', 'lake'],
      photos: ['assets/window-girl.jpg'],
    );

    const steamBarPlace = PlaceModel(
      id: 'steam',
      canonicalUuid: '11111111-1111-4111-8111-111111111107',
      slug: 'steam-bar-vinyl',
      name: 'Steam Vinyl & Cocktail Bar',
      category: 'Records · Wine Bar',
      streetAddress: '12 Rustaveli Street',
      district: 'Yakkasaray',
      city: 'Tashkent',
      latitude: 41.2910,
      longitude: 69.2612,
      distanceMeters: 920,
      walkTimeMinutes: 12,
      priceTier: r'$$$',
      hours: '6:00 PM – 2:00 AM',
      statusLine: 'Open · Analog vinyl sessions',
      description: 'Craft cocktails, analog vinyl DJ sets, and evening ramen.',
      heroImageUrl: 'assets/wine-tall.jpg',
      ratingAvg: 4.9,
      ratingCount: 512,
      tags: ['vinyl', 'cocktails', 'late night', 'analog'],
      photos: ['assets/wine-tall.jpg'],
    );

    test('getModeForHour correctly categorizes all 24 hours of Tashkent time', () {
      // Morning Brew: 6:00 - 11:59
      expect(AtmosphereService.getModeForHour(6), equals(AtmosphereMode.morningBrew));
      expect(AtmosphereService.getModeForHour(9), equals(AtmosphereMode.morningBrew));
      expect(AtmosphereService.getModeForHour(11), equals(AtmosphereMode.morningBrew));

      // Afternoon Focus: 12:00 - 16:59
      expect(AtmosphereService.getModeForHour(12), equals(AtmosphereMode.afternoonFocus));
      expect(AtmosphereService.getModeForHour(14), equals(AtmosphereMode.afternoonFocus));
      expect(AtmosphereService.getModeForHour(16), equals(AtmosphereMode.afternoonFocus));

      // Golden Hour: 17:00 - 20:59
      expect(AtmosphereService.getModeForHour(17), equals(AtmosphereMode.goldenHour));
      expect(AtmosphereService.getModeForHour(19), equals(AtmosphereMode.goldenHour));
      expect(AtmosphereService.getModeForHour(20), equals(AtmosphereMode.goldenHour));

      // Late Night Vinyl: 21:00 - 5:59
      expect(AtmosphereService.getModeForHour(21), equals(AtmosphereMode.lateNightVinyl));
      expect(AtmosphereService.getModeForHour(23), equals(AtmosphereMode.lateNightVinyl));
      expect(AtmosphereService.getModeForHour(2), equals(AtmosphereMode.lateNightVinyl));
      expect(AtmosphereService.getModeForHour(5), equals(AtmosphereMode.lateNightVinyl));
    });

    test('getInfo returns accurate metadata for each urban rhythm', () {
      final morning = AtmosphereService.getInfo(AtmosphereMode.morningBrew);
      expect(morning.title, equals('Morning Brew'));
      expect(morning.recommendedCategories, contains('Café'));

      final afternoon = AtmosphereService.getInfo(AtmosphereMode.afternoonFocus);
      expect(afternoon.title, equals('Afternoon Focus'));
      expect(afternoon.matchingTags, contains('quiet study'));

      final golden = AtmosphereService.getInfo(AtmosphereMode.goldenHour);
      expect(golden.title, equals('Golden Hour'));
      expect(golden.matchingTags, contains('sunset'));

      final vinyl = AtmosphereService.getInfo(AtmosphereMode.lateNightVinyl);
      expect(vinyl.title, equals('Late Night Vinyl'));
      expect(vinyl.matchingTags, contains('vinyl'));
    });

    test('matchesAtmosphere and filterPlaces correctly filter places by urban rhythm', () {
      final all = [breadlyPlace, kitobxonPlace, centralParkPlace, steamBarPlace];

      // Morning Brew
      expect(AtmosphereService.matchesAtmosphere(breadlyPlace, AtmosphereMode.morningBrew), isTrue);
      final morningFiltered = AtmosphereService.filterPlaces(all, AtmosphereMode.morningBrew);
      expect(morningFiltered, contains(breadlyPlace));

      // Afternoon Focus
      expect(AtmosphereService.matchesAtmosphere(kitobxonPlace, AtmosphereMode.afternoonFocus), isTrue);
      final afternoonFiltered = AtmosphereService.filterPlaces(all, AtmosphereMode.afternoonFocus);
      expect(afternoonFiltered, contains(kitobxonPlace));

      // Golden Hour
      expect(AtmosphereService.matchesAtmosphere(centralParkPlace, AtmosphereMode.goldenHour), isTrue);
      final goldenFiltered = AtmosphereService.filterPlaces(all, AtmosphereMode.goldenHour);
      expect(goldenFiltered, contains(centralParkPlace));

      // Late Night Vinyl
      expect(AtmosphereService.matchesAtmosphere(steamBarPlace, AtmosphereMode.lateNightVinyl), isTrue);
      final vinylFiltered = AtmosphereService.filterPlaces(all, AtmosphereMode.lateNightVinyl);
      expect(vinylFiltered, contains(steamBarPlace));
    });

    testWidgets('CategoryChips renders atmosphere pill and toggles selection', (tester) async {
      bool toggled = false;
      String selectedCat = 'All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChips(
              selectedCategory: selectedCat,
              atmosphereLabel: 'Morning Brew',
              isAtmosphereActive: false,
              onToggleAtmosphere: () => toggled = true,
              onSelected: (cat) => selectedCat = cat,
            ),
          ),
        ),
      );

      // Verify atmosphere pill exists
      expect(find.text('Morning Brew'), findsOneWidget);
      expect(find.text('Café'), findsOneWidget);

      // Tap atmosphere pill
      await tester.tap(find.text('Morning Brew'));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);
    });
  });
}
