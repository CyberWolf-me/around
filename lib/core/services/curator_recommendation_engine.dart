import 'package:flutter_riverpod/flutter_riverpod.dart';

final curatorRecommendationEngineProvider = Provider<CuratorRecommendationEngine>((ref) {
  return const CuratorRecommendationEngine();
});

class CuratorTasteProfile {
  final String userId;
  final String username;
  final String fullName;
  final String neighborhood;
  final Set<String> savedPlaceIds;
  final Set<String> droppedPlaceIds;
  final Set<String> preferredTags;
  final Set<String> activeDistricts;
  final int streakWeeks;
  final String? avatarUrl;

  const CuratorTasteProfile({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.neighborhood,
    this.savedPlaceIds = const {},
    this.droppedPlaceIds = const {},
    this.preferredTags = const {},
    this.activeDistricts = const {},
    this.streakWeeks = 0,
    this.avatarUrl,
  });

  /// All places associated with this curator (drops + saves).
  Set<String> get allVenueIds => {...droppedPlaceIds, ...savedPlaceIds};
}

class TasteOverlapMatch {
  final CuratorTasteProfile curator;
  final double similarityScore; // 0.0 to 1.0
  final int compatibilityPercent; // 0 to 100
  final List<String> sharedPlaces;
  final List<String> sharedTags;
  final List<String> sharedDistricts;
  final String primaryHighlightUz;
  final String primaryHighlightRu;
  final String primaryHighlightEn;

  const TasteOverlapMatch({
    required this.curator,
    required this.similarityScore,
    required this.compatibilityPercent,
    required this.sharedPlaces,
    required this.sharedTags,
    required this.sharedDistricts,
    required this.primaryHighlightUz,
    required this.primaryHighlightRu,
    required this.primaryHighlightEn,
  });

  String getLocalizedHighlight(String lang) {
    if (lang == 'uz') return primaryHighlightUz;
    if (lang == 'ru') return primaryHighlightRu;
    return primaryHighlightEn;
  }
}

class CuratorRecommendationEngine {
  const CuratorRecommendationEngine();

  /// Calculates Jaccard similarity index between two string sets.
  static double jaccardIndex(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty && setB.isEmpty) return 0.0;
    final intersectionCount = setA.intersection(setB).length;
    final unionCount = setA.union(setB).length;
    if (unionCount == 0) return 0.0;
    return intersectionCount / unionCount;
  }

  /// Calculates composite taste compatibility score (0.0 to 1.0).
  double computeCompatibilityScore(CuratorTasteProfile me, CuratorTasteProfile other) {
    if (me.userId == other.userId) return 1.0;

    // Weightings: 45% places, 35% tags, 20% districts
    final placesScore = jaccardIndex(me.allVenueIds, other.allVenueIds);
    final tagsScore = jaccardIndex(me.preferredTags, other.preferredTags);
    final districtsScore = jaccardIndex(me.activeDistricts, other.activeDistricts);

    final composite = (placesScore * 0.45) + (tagsScore * 0.35) + (districtsScore * 0.20);
    return composite.clamp(0.0, 1.0);
  }

  /// Evaluates two profiles and generates localized overlap highlights.
  TasteOverlapMatch evaluateOverlap(CuratorTasteProfile me, CuratorTasteProfile other) {
    final score = computeCompatibilityScore(me, other);
    final percent = (score * 100).round();

    final sharedPlaces = me.allVenueIds.intersection(other.allVenueIds).toList()..sort();
    final sharedTags = me.preferredTags.intersection(other.preferredTags).toList()..sort();
    final sharedDistricts = me.activeDistricts.intersection(other.activeDistricts).toList()..sort();

    String enHighlight;
    String uzHighlight;
    String ruHighlight;

    if (sharedPlaces.isNotEmpty && sharedDistricts.isNotEmpty) {
      final district = sharedDistricts.first;
      final count = sharedPlaces.length;
      enHighlight = '$count shared favorite ${count == 1 ? "spot" : "spots"} in $district';
      uzHighlight = '$district tumanida $count ta umumiy sevimli joy';
      ruHighlight = '$count ${count == 1 ? "общее место" : "общих мест"} в районе $district';
    } else if (sharedTags.isNotEmpty && sharedDistricts.isNotEmpty) {
      final tag = sharedTags.first;
      final district = sharedDistricts.first;
      enHighlight = 'Both love $tag spots in $district';
      uzHighlight = 'Ikkalangiz ham $district tumanidagi $tag joylarini sevasiz';
      ruHighlight = 'Оба любят места $tag в районе $district';
    } else if (sharedPlaces.isNotEmpty) {
      final count = sharedPlaces.length;
      enHighlight = '$count shared favorite ${count == 1 ? "venue" : "venues"}';
      uzHighlight = '$count ta umumiy sevimli maskan';
      ruHighlight = '$count ${count == 1 ? "общее любимое место" : "общих любимых мест"}';
    } else if (sharedTags.isNotEmpty) {
      final tag = sharedTags.first;
      enHighlight = 'Shared passion for $tag';
      uzHighlight = '$tag bo‘yicha umumiy qiziqish';
      ruHighlight = 'Общий интерес к $tag';
    } else if (sharedDistricts.isNotEmpty) {
      final district = sharedDistricts.first;
      enHighlight = 'Both explore $district';
      uzHighlight = 'Ikkalangiz ham $district tumanini kashf qilasiz';
      ruHighlight = 'Оба исследуют район $district';
    } else {
      enHighlight = 'Fresh taste perspective to discover';
      uzHighlight = 'Kashf qilish uchun yangi did nigohi';
      ruHighlight = 'Свежий взгляд на городские места';
    }

    return TasteOverlapMatch(
      curator: other,
      similarityScore: score,
      compatibilityPercent: percent,
      sharedPlaces: sharedPlaces,
      sharedTags: sharedTags,
      sharedDistricts: sharedDistricts,
      primaryHighlightUz: uzHighlight,
      primaryHighlightRu: ruHighlight,
      primaryHighlightEn: enHighlight,
    );
  }

  /// Evaluates and ranks candidate curators by taste compatibility.
  List<TasteOverlapMatch> rankCurators({
    required CuratorTasteProfile targetCurator,
    required List<CuratorTasteProfile> candidates,
    double minSimilarity = 0.0,
    int limit = 10,
  }) {
    final matches = candidates
        .where((c) => c.userId != targetCurator.userId)
        .map((candidate) => evaluateOverlap(targetCurator, candidate))
        .where((match) => match.similarityScore >= minSimilarity)
        .toList();

    matches.sort((a, b) {
      final scoreComparison = b.similarityScore.compareTo(a.similarityScore);
      if (scoreComparison != 0) return scoreComparison;
      // Secondary sort: streak weeks then drops count
      final streakComparison = b.curator.streakWeeks.compareTo(a.curator.streakWeeks);
      if (streakComparison != 0) return streakComparison;
      return b.curator.droppedPlaceIds.length.compareTo(a.curator.droppedPlaceIds.length);
    });

    if (matches.length > limit) {
      return matches.sublist(0, limit);
    }
    return matches;
  }
}
