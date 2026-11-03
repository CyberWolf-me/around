import 'package:flutter/material.dart';
import '../../data/models/place_model.dart';
import '../constants/app_colors.dart';

/// The four canonical urban rhythms of Tashkent city life.
enum AtmosphereMode {
  morningBrew,
  afternoonFocus,
  goldenHour,
  lateNightVinyl,
}

/// Metadata and visual attributes for a Tashkent urban rhythm.
class AtmosphereInfo {
  final AtmosphereMode mode;
  final String title;
  final String tagline;
  final String timeRange;
  final IconData icon;
  final Color accentColor;
  final Color bgTint;
  final List<String> recommendedCategories;
  final List<String> matchingTags;

  const AtmosphereInfo({
    required this.mode,
    required this.title,
    required this.tagline,
    required this.timeRange,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    required this.recommendedCategories,
    required this.matchingTags,
  });
}

/// Service that classifies Tashkent local time into distinct urban rhythms
/// and provides contextual discovery filtering for venues.
class AtmosphereService {
  /// Evaluates the active atmosphere mode for the provided time (defaults to local now).
  static AtmosphereMode getModeForHour(int hour) {
    if (hour >= 6 && hour < 12) {
      return AtmosphereMode.morningBrew;
    } else if (hour >= 12 && hour < 17) {
      return AtmosphereMode.afternoonFocus;
    } else if (hour >= 17 && hour < 21) {
      return AtmosphereMode.goldenHour;
    } else {
      return AtmosphereMode.lateNightVinyl;
    }
  }

  /// Returns the current atmosphere mode based on system time.
  static AtmosphereMode getCurrentMode([DateTime? now]) {
    final time = now ?? DateTime.now();
    return getModeForHour(time.hour);
  }

  /// Returns full metadata and styling for an atmosphere mode.
  static AtmosphereInfo getInfo(AtmosphereMode mode) {
    switch (mode) {
      case AtmosphereMode.morningBrew:
        return const AtmosphereInfo(
          mode: AtmosphereMode.morningBrew,
          title: 'Morning Brew',
          tagline: 'Fresh sourdough, flat whites & sunny terraces',
          timeRange: '6:00 AM – 12:00 PM',
          icon: Icons.coffee_rounded,
          accentColor: AppColors.orange,
          bgTint: AppColors.orangeSubtle,
          recommendedCategories: ['Café', 'Bakery', 'Coffee', 'All'],
          matchingTags: ['espresso', 'flat white', 'cardamom bun', 'sourdough', 'breakfast', 'terrace', 'bakery', 'coffee'],
        );
      case AtmosphereMode.afternoonFocus:
        return const AtmosphereInfo(
          mode: AtmosphereMode.afternoonFocus,
          title: 'Afternoon Focus',
          tagline: 'Quiet study nooks, tea libraries & fast Wi-Fi',
          timeRange: '12:00 PM – 5:00 PM',
          icon: Icons.laptop_mac_rounded,
          accentColor: AppColors.cobalt,
          bgTint: AppColors.cobaltSubtle,
          recommendedCategories: ['Study', 'Bookshop', 'Café', 'All'],
          matchingTags: ['quiet study', 'tea library', 'power sockets', 'wi-fi', 'wedding plov', 'reading', 'tea selection'],
        );
      case AtmosphereMode.goldenHour:
        return const AtmosphereInfo(
          mode: AtmosphereMode.goldenHour,
          title: 'Golden Hour',
          tagline: 'Sunset promenades, shaded parks & dinner',
          timeRange: '5:00 PM – 9:00 PM',
          icon: Icons.wb_twilight_rounded,
          accentColor: AppColors.butter,
          bgTint: AppColors.butterSubtle,
          recommendedCategories: ['Wine Bar', 'Modern Uzbek', 'Ramen', 'All'],
          matchingTags: ['sunset', 'lake', 'wine bar', 'date spot', 'dinner', 'promenade', 'terrace', 'shaded walks'],
        );
      case AtmosphereMode.lateNightVinyl:
        return const AtmosphereInfo(
          mode: AtmosphereMode.lateNightVinyl,
          title: 'Late Night Vinyl',
          tagline: 'Analog vinyl listening, craft drinks & night bites',
          timeRange: '9:00 PM – 6:00 AM',
          icon: Icons.album_rounded,
          accentColor: AppColors.ink,
          bgTint: AppColors.paper2,
          recommendedCategories: ['Records', 'Wine Bar', 'Ramen', 'All'],
          matchingTags: ['vinyl', 'cocktails', 'late night', 'music', 'analog', 'wine', 'bar', 'ramen'],
        );
    }
  }

  /// Returns current atmosphere metadata.
  static AtmosphereInfo getCurrentInfo([DateTime? now]) {
    return getInfo(getCurrentMode(now));
  }

  /// Checks if a venue matches the given atmosphere mode.
  static bool matchesAtmosphere(PlaceModel place, AtmosphereMode mode) {
    final info = getInfo(mode);
    final placeCategory = place.category.toLowerCase();
    final placeTags = place.tags.map((t) => t.toLowerCase()).toList();

    // 1. Check category match
    for (final cat in info.recommendedCategories) {
      if (cat != 'All' && placeCategory.contains(cat.toLowerCase())) {
        return true;
      }
    }

    // 2. Check tag match
    for (final tag in info.matchingTags) {
      if (placeTags.contains(tag) || placeCategory.contains(tag)) {
        return true;
      }
    }

    // 3. Check description / status line
    final desc = place.description.toLowerCase();
    final status = place.statusLine.toLowerCase();
    for (final tag in info.matchingTags) {
      if (desc.contains(tag) || status.contains(tag)) {
        return true;
      }
    }

    return false;
  }

  /// Filters a list of places according to the active atmosphere mode.
  static List<PlaceModel> filterPlaces(List<PlaceModel> places, AtmosphereMode mode) {
    final matched = places.where((p) => matchesAtmosphere(p, mode)).toList();
    // Fall back to all places if no exact match exists in smaller subsets
    return matched.isNotEmpty ? matched : places;
  }
}
