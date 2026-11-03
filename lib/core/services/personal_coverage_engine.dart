import '../../data/models/place_model.dart' show PlaceModel;
import '../../data/repositories/places_repository.dart';

/// Exploration status of a specific Tashkent urban district.
class DistrictCoverage {
  final String district;
  final int visitedCount;
  final int totalPlaces;
  final double coverageFraction;
  final int coveragePercent;
  final String statusLevel; // 'unexplored' | 'discovering' | 'mastered'

  const DistrictCoverage({
    required this.district,
    required this.visitedCount,
    required this.totalPlaces,
    required this.coverageFraction,
    required this.coveragePercent,
    required this.statusLevel,
  });

  String localizedStatus(String lang) {
    switch (statusLevel) {
      case 'mastered':
        switch (lang.toLowerCase()) {
          case 'uz':
            return '👑 O‘zlashtirilgan';
          case 'ru':
            return '👑 Освоено';
          case 'en':
          default:
            return '👑 Mastered';
        }
      case 'discovering':
        switch (lang.toLowerCase()) {
          case 'uz':
            return '🧭 Kashf etilmoqda';
          case 'ru':
            return '🧭 В процессе';
          case 'en':
          default:
            return '🧭 Discovering';
        }
      case 'unexplored':
      default:
        switch (lang.toLowerCase()) {
          case 'uz':
            return '🌱 Kashf etilmagan';
          case 'ru':
            return '🌱 Не исследовано';
          case 'en':
          default:
            return '🌱 Unexplored';
        }
    }
  }
}

/// Comprehensive personal exploration report across all Tashkent districts.
class CityCoverageReport {
  final int totalVisited;
  final int totalPlaces;
  final double overallFraction;
  final int overallPercentage;
  final Map<String, DistrictCoverage> districts;
  final DistrictCoverage? leastExploredDistrict;
  final DistrictCoverage? mostExploredDistrict;
  final String? recommendedPlaceId;
  final String? recommendedPlaceName;
  final String? recommendedDistrict;

  const CityCoverageReport({
    required this.totalVisited,
    required this.totalPlaces,
    required this.overallFraction,
    required this.overallPercentage,
    required this.districts,
    required this.leastExploredDistrict,
    required this.mostExploredDistrict,
    this.recommendedPlaceId,
    this.recommendedPlaceName,
    this.recommendedDistrict,
  });

  String formattedCityScore(String lang) {
    switch (lang.toLowerCase()) {
      case 'uz':
        return 'Toshkentning $overallPercentage% qismi kashf etildi';
      case 'ru':
        return 'Исследовано $overallPercentage% Ташкента';
      case 'en':
      default:
        return '$overallPercentage% of Tashkent Explored';
    }
  }
}

/// Curator City District Coverage Engine (`P24-01`).
/// Computes personal city exploration heat and coverage percentages across Tashkent.
class PersonalCoverageEngine {
  static const List<String> canonicalDistricts = [
    'Mirabad',
    'Central Tashkent',
    'Yakkasaray',
    'Old City',
    'Yunusabad',
  ];

  /// Calculates personal district and city-wide exploration coverage.
  static CityCoverageReport calculateCoverage({
    required Set<String> visitedPlaceIds,
    List<PlaceModel>? catalogPlaces,
  }) {
    final places = catalogPlaces ?? PlacesRepository().getAllPlaces();
    final resolvedVisited = visitedPlaceIds.map(PlacesRepository.resolveCanonicalId).toSet();

    // Group catalog by district
    final Map<String, List<PlaceModel>> districtPlaces = {};
    for (final d in canonicalDistricts) {
      districtPlaces[d] = [];
    }

    for (final place in places) {
      final matchedDistrict = _normalizeDistrict(place.district);
      if (districtPlaces.containsKey(matchedDistrict)) {
        districtPlaces[matchedDistrict]!.add(place);
      } else {
        districtPlaces['Central Tashkent']!.add(place);
      }
    }

    final Map<String, DistrictCoverage> districtCoverageMap = {};
    int grandTotalVisited = 0;
    int grandTotalPlaces = 0;

    for (final entry in districtPlaces.entries) {
      final district = entry.key;
      final districtList = entry.value;
      final totalInDistrict = districtList.length;

      final visitedInDistrict = districtList
          .where((p) => resolvedVisited.contains(p.id) || resolvedVisited.contains(p.slug))
          .length;

      grandTotalVisited += visitedInDistrict;
      grandTotalPlaces += totalInDistrict;

      final fraction = totalInDistrict > 0 ? (visitedInDistrict / totalInDistrict).clamp(0.0, 1.0) : 0.0;
      final percent = (fraction * 100).round();

      String status;
      if (percent >= 70) {
        status = 'mastered';
      } else if (percent > 0) {
        status = 'discovering';
      } else {
        status = 'unexplored';
      }

      districtCoverageMap[district] = DistrictCoverage(
        district: district,
        visitedCount: visitedInDistrict,
        totalPlaces: totalInDistrict,
        coverageFraction: fraction,
        coveragePercent: percent,
        statusLevel: status,
      );
    }

    final overallFraction = grandTotalPlaces > 0
        ? (grandTotalVisited / grandTotalPlaces).clamp(0.0, 1.0)
        : 0.0;
    final overallPercent = (overallFraction * 100).round();

    // Find most and least explored among districts with catalog venues
    final districtsWithVenues = districtCoverageMap.values.where((d) => d.totalPlaces > 0).toList()
      ..sort((a, b) => a.coverageFraction.compareTo(b.coverageFraction));

    final least = districtsWithVenues.isNotEmpty ? districtsWithVenues.first : null;
    final most = districtsWithVenues.isNotEmpty ? districtsWithVenues.last : null;

    // Pick recommended next place from lowest-coverage district with unvisited places
    String? recPlaceId;
    String? recPlaceName;
    String? recDistrict;

    for (final candidate in districtsWithVenues) {
      final unvisited = districtPlaces[candidate.district]!
          .where((p) => !resolvedVisited.contains(p.id) && !resolvedVisited.contains(p.slug))
          .toList();

      if (unvisited.isNotEmpty) {
        final rec = unvisited.first;
        recPlaceId = rec.id;
        recPlaceName = rec.name;
        recDistrict = candidate.district;
        break;
      }
    }

    return CityCoverageReport(
      totalVisited: grandTotalVisited,
      totalPlaces: grandTotalPlaces,
      overallFraction: overallFraction,
      overallPercentage: overallPercent,
      districts: districtCoverageMap,
      leastExploredDistrict: least,
      mostExploredDistrict: most,
      recommendedPlaceId: recPlaceId,
      recommendedPlaceName: recPlaceName,
      recommendedDistrict: recDistrict,
    );
  }

  static String _normalizeDistrict(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('mira') || lower.contains('miro')) return 'Mirabad';
    if (lower.contains('yakka') || lower.contains('rustaveli')) return 'Yakkasaray';
    if (lower.contains('chorsu') || lower.contains('old') || lower.contains('eski')) return 'Old City';
    if (lower.contains('yunus') || lower.contains('minor')) return 'Yunusabad';
    return 'Central Tashkent';
  }
}
