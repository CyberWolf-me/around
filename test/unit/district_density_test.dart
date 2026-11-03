import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:around_app/data/repositories/places_repository.dart';
import 'package:around_app/features/places/widgets/district_density_overlay.dart';

void main() {
  group('P13-02: District Density Engine & Spatial Privacy Tests', () {
    test('DistrictDensityModel serialization and defaults', () {
      final sample = {
        'district': 'Mirabad',
        'drop_count': 42,
        'active_venues_count': 12,
        'centroid_lat': 41.3060,
        'centroid_lng': 69.2815,
        'relative_density': 0.88,
      };

      final model = DistrictDensityModel.fromJson(sample);
      expect(model.district, 'Mirabad');
      expect(model.dropCount, 42);
      expect(model.activeVenuesCount, 12);
      expect(model.centroidLat, 41.3060);
      expect(model.centroidLng, 69.2815);
      expect(model.relativeDensity, 0.88);

      final json = model.toJson();
      expect(json['district'], 'Mirabad');
      expect(json['drop_count'], 42);
      expect(json['active_venues_count'], 12);
      expect(json['centroid_lat'], 41.3060);
      expect(json['centroid_lng'], 69.2815);
    });

    test('DistrictDensityModel handles empty and null json gracefully', () {
      final fallback = DistrictDensityModel.fromJson({});
      expect(fallback.district, 'Tashkent');
      expect(fallback.dropCount, 0);
      expect(fallback.activeVenuesCount, 0);
      expect(fallback.centroidLat, closeTo(41.31, 0.05));
      expect(fallback.centroidLng, closeTo(69.28, 0.05));
      expect(fallback.relativeDensity, 0.0);
    });

    test('PlacesRepository getDistrictActivityDensity calculates spatial centroids and privacy guarantee', () async {
      final repo = PlacesRepository();
      final densities = await repo.getDistrictActivityDensity(windowDays: 7);

      expect(densities.isNotEmpty, isTrue);

      // Verify Mirabad or top district has highest drop counts
      expect(densities.first.dropCount, greaterThanOrEqualTo(densities.last.dropCount));

      // Privacy Invariant: zero individual user IDs or private coordinates
      for (final item in densities) {
        expect(item.district.isNotEmpty, isTrue);
        expect(item.activeVenuesCount, greaterThan(0));
        expect(item.dropCount, greaterThanOrEqualTo(0));
        expect(item.relativeDensity, inInclusiveRange(0.0, 1.0));

        // Tashkent coordinate boundary checks
        expect(item.centroidLat, inInclusiveRange(41.20, 41.40));
        expect(item.centroidLng, inInclusiveRange(69.15, 69.40));

        // Verify JSON representation does NOT leak user fields
        final json = item.toJson();
        expect(json.containsKey('user_id'), isFalse);
        expect(json.containsKey('author_id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      }
    });

    test('SQL migration 00013 exists and defines secure RPC get_district_activity_density', () {
      final migrationFile = File('supabase/migrations/00013_district_activity_density.sql');
      expect(migrationFile.existsSync(), isTrue, reason: 'Migration 00013 must exist');

      final content = migrationFile.readAsStringSync();
      expect(content, contains('CREATE OR REPLACE FUNCTION public.get_district_activity_density'));
      expect(content, contains('SECURITY DEFINER'));
      expect(content, contains('SET search_path = public, extensions'));
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.get_district_activity_density(integer) TO anon;'));
      expect(content, contains('GRANT EXECUTE ON FUNCTION public.get_district_activity_density(integer) TO authenticated;'));
      // Ensure no user_id column is selected or returned
      expect(content, isNot(contains('user_id')));
      expect(content, isNot(contains('author_id')));
    });

    testWidgets('DistrictDensityOverlay renders district chips and handles selection', (tester) async {
      final testDistricts = [
        const DistrictDensityModel(
          district: 'Mirabad',
          dropCount: 42,
          activeVenuesCount: 15,
          centroidLat: 41.3060,
          centroidLng: 69.2815,
          relativeDensity: 1.0,
        ),
        const DistrictDensityModel(
          district: 'Yakkasaray',
          dropCount: 28,
          activeVenuesCount: 10,
          centroidLat: 41.2885,
          centroidLng: 69.2580,
          relativeDensity: 0.67,
        ),
      ];

      DistrictDensityModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DistrictDensityOverlay(
              districts: testDistricts,
              selectedDistrict: 'Mirabad',
              onDistrictTap: (d) => selected = d,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('district_density_overlay')), findsOneWidget);
      expect(find.text('Tashkent Live Density'), findsOneWidget);
      expect(find.text('🔒 Zero GPS Tracking'), findsOneWidget);
      expect(find.text('Mirabad'), findsOneWidget);
      expect(find.text('Yakkasaray'), findsOneWidget);
      expect(find.text('42 drops · 15 spots'), findsOneWidget);

      // Tap Yakkasaray chip
      await tester.tap(find.byKey(const Key('district_chip_Yakkasaray')));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected?.district, 'Yakkasaray');
    });
  });
}
