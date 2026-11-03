import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/models/place_model.dart';
import 'package:around_app/data/models/post_model.dart';
import 'package:around_app/features/places/widgets/story_card_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P14-03: Viral Story & Passport Card Visual Exporter Tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    const testPlace = PlaceModel(
      id: 'place_breadly',
      slug: 'breadly-bakery',
      name: 'Breadly Bakery & Café',
      category: 'Specialty Coffee · Bakery',
      streetAddress: '24 Mirobod Street',
      district: 'Mirabad',
      city: 'Tashkent',
      latitude: 41.3002,
      longitude: 69.2715,
      distanceMeters: 250,
      walkTimeMinutes: 3,
      priceTier: r'$$',
      hours: '8:00 AM – 11:00 PM',
      statusLine: 'Open now · Artisan croissants',
      description: 'Cozy Tashkent café.',
      heroImageUrl: 'assets/cafe-bw.jpg',
      ratingAvg: 4.8,
      ratingCount: 320,
      tags: ['coffee', 'croissant'],
      photos: ['assets/cafe-bw.jpg'],
    );

    final testDrop = PostModel(
      id: 'drop_1',
      authorId: 'kamila_r',
      authorName: 'Kamila Rustamova',
      authorUsername: 'kamila_r',
      authorAvatar: 'KR',
      placeId: 'place_breadly',
      placeName: 'Breadly Bakery & Café',
      placeCategory: 'Specialty Coffee',
      placeAddress: '24 Mirobod Street',
      note: 'Best almond croissants and quiet morning light in Tashkent.',
      rating: 5,
      audience: PostAudience.friends,
      size: PostSize.hero,
      tags: const ['coffee'],
      createdAt: DateTime.now(),
    );

    testWidgets('StoryCardExporter renders 9:16 story preview with metadata and actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool exportCalled = false;
      String? copiedLink;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryCardExporter(
              place: testPlace,
              drop: testDrop,
              onExport: () => exportCalled = true,
              onCopyLink: (link) => copiedLink = link,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('story_card_exporter_frame')), findsOneWidget);
      expect(find.byKey(const Key('story_canvas')), findsOneWidget);
      expect(find.text('AROUND'), findsOneWidget);
      expect(find.text('📍 Mirabad'), findsOneWidget);
      expect(find.text('Breadly Bakery & Café'), findsOneWidget);
      expect(find.text('4.8★ (320 reviews)'), findsOneWidget);
      expect(find.text('@kamila_r'), findsOneWidget);
      expect(find.text('"Best almond croissants and quiet morning light in Tashkent."'), findsOneWidget);
      expect(find.text('around.tashkent.app/places/breadly-bakery'), findsOneWidget);

      // Tap Copy Link
      final copyBtn = find.byKey(const Key('btn_copy_story_link'));
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(copiedLink, 'https://around.tashkent.app/places/breadly-bakery');

      // Tap Share Story
      final exportBtn = find.byKey(const Key('btn_export_story_card'));
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });
  });
}
