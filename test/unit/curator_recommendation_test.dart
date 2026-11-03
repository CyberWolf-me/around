import 'package:around_app/core/services/curator_recommendation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P19-04: Curator Recommendation & Taste Overlap Engine Tests', () {
    const engine = CuratorRecommendationEngine();

    test('jaccardIndex handles identical, disjoint, empty, and partial sets', () {
      expect(CuratorRecommendationEngine.jaccardIndex({}, {}), 0.0);
      expect(CuratorRecommendationEngine.jaccardIndex({'a'}, {}), 0.0);
      expect(CuratorRecommendationEngine.jaccardIndex({'a', 'b'}, {'c', 'd'}), 0.0);
      expect(CuratorRecommendationEngine.jaccardIndex({'a', 'b'}, {'a', 'b'}), 1.0);
      expect(CuratorRecommendationEngine.jaccardIndex({'a', 'b'}, {'b', 'c'}), closeTo(1 / 3, 0.001));
    });

    test('computeCompatibilityScore calculates weighted multi-factor similarity', () {
      const me = CuratorTasteProfile(
        userId: 'user_me',
        username: 'aziz_k',
        fullName: 'Aziz Karimov',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly', 'tims'},
        savedPlaceIds: {'pie-republic'},
        preferredTags: {'Coffee', 'Pastry', 'Morning Brew'},
        activeDistricts: {'Mirabad'},
      );

      const twin = CuratorTasteProfile(
        userId: 'user_twin',
        username: 'twin_k',
        fullName: 'Twin Explorer',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly', 'tims'},
        savedPlaceIds: {'pie-republic'},
        preferredTags: {'Coffee', 'Pastry', 'Morning Brew'},
        activeDistricts: {'Mirabad'},
      );

      const disjoint = CuratorTasteProfile(
        userId: 'user_other',
        username: 'other_u',
        fullName: 'Other Explorer',
        neighborhood: 'Chilanzar',
        droppedPlaceIds: {'chorsu'},
        savedPlaceIds: {'besh-qozon-plov'},
        preferredTags: {'Heritage', 'Plov'},
        activeDistricts: {'Shaykhontohur'},
      );

      final twinScore = engine.computeCompatibilityScore(me, twin);
      expect(twinScore, 1.0);

      final disjointScore = engine.computeCompatibilityScore(me, disjoint);
      expect(disjointScore, 0.0);
    });

    test('evaluateOverlap produces accurate highlights and trilingual strings', () {
      const me = CuratorTasteProfile(
        userId: 'user_me',
        username: 'aziz_k',
        fullName: 'Aziz Karimov',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly'},
        savedPlaceIds: {'tims'},
        preferredTags: {'Coffee', 'Pastry'},
        activeDistricts: {'Mirabad'},
      );

      const peer = CuratorTasteProfile(
        userId: 'user_peer',
        username: 'kamila_r',
        fullName: 'Kamila Rahimova',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly'},
        savedPlaceIds: {'pie-republic'},
        preferredTags: {'Coffee', 'Vinyl'},
        activeDistricts: {'Mirabad'},
      );

      final match = engine.evaluateOverlap(me, peer);
      expect(match.curator.username, 'kamila_r');
      expect(match.sharedPlaces, ['breadly']);
      expect(match.sharedTags, ['Coffee']);
      expect(match.sharedDistricts, ['Mirabad']);
      expect(match.compatibilityPercent, greaterThan(30));

      expect(match.getLocalizedHighlight('en'), contains('1 shared favorite spot in Mirabad'));
      expect(match.getLocalizedHighlight('uz'), contains('Mirabad tumanida 1 ta umumiy sevimli joy'));
      expect(match.getLocalizedHighlight('ru'), contains('1 общее место в районе Mirabad'));
    });

    test('rankCurators excludes self, sorts descending, and breaks ties by streak', () {
      const me = CuratorTasteProfile(
        userId: 'user_me',
        username: 'aziz_k',
        fullName: 'Aziz Karimov',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly', 'tims'},
        preferredTags: {'Coffee', 'Pastry'},
        activeDistricts: {'Mirabad'},
      );

      const highMatch = CuratorTasteProfile(
        userId: 'user_high',
        username: 'high_curator',
        fullName: 'High Match',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly', 'tims'},
        preferredTags: {'Coffee', 'Pastry'},
        activeDistricts: {'Mirabad'},
        streakWeeks: 2,
      );

      const highMatchTieBreaker = CuratorTasteProfile(
        userId: 'user_high_veteran',
        username: 'veteran_curator',
        fullName: 'Veteran Match',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'breadly', 'tims'},
        preferredTags: {'Coffee', 'Pastry'},
        activeDistricts: {'Mirabad'},
        streakWeeks: 8,
      );

      const lowMatch = CuratorTasteProfile(
        userId: 'user_low',
        username: 'low_curator',
        fullName: 'Low Match',
        neighborhood: 'Mirabad',
        droppedPlaceIds: {'centralpark'},
        preferredTags: {'Outdoors'},
        activeDistricts: {'Central Tashkent'},
      );

      final candidates = [lowMatch, me, highMatch, highMatchTieBreaker];
      final ranked = engine.rankCurators(targetCurator: me, candidates: candidates);

      // Self must be filtered out
      expect(ranked.any((m) => m.curator.userId == 'user_me'), isFalse);
      expect(ranked.length, 3);

      // Veteran should come first due to higher streak tie-breaker
      expect(ranked[0].curator.userId, 'user_high_veteran');
      expect(ranked[1].curator.userId, 'user_high');
      expect(ranked[2].curator.userId, 'user_low');
    });
  });
}
