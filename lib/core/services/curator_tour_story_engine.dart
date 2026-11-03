import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An individual narrative chapter tied to a specific venue stop.
class TourStopStory {
  final String id;
  final String tourId;
  final int chapterIndex;
  final String title;
  final String venueId;
  final String venueName;
  final double latitude;
  final double longitude;
  final double triggerRadiusMeters;
  final String audioUrl;
  final int durationSeconds;
  final String transcript;
  final String? curatorNotes;

  const TourStopStory({
    required this.id,
    required this.tourId,
    required this.chapterIndex,
    required this.title,
    required this.venueId,
    required this.venueName,
    required this.latitude,
    required this.longitude,
    this.triggerRadiusMeters = 50.0,
    required this.audioUrl,
    required this.durationSeconds,
    required this.transcript,
    this.curatorNotes,
  });

  String get formattedDuration {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    return '$mins:${secs < 10 ? '0' : ''}$secs';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tour_id': tourId,
    'chapter_index': chapterIndex,
    'title': title,
    'venue_id': venueId,
    'venue_name': venueName,
    'latitude': latitude,
    'longitude': longitude,
    'trigger_radius_meters': triggerRadiusMeters,
    'audio_url': audioUrl,
    'duration_seconds': durationSeconds,
    'transcript': transcript,
    if (curatorNotes != null) 'curator_notes': curatorNotes,
  };

  factory TourStopStory.fromJson(Map<String, dynamic> json) {
    return TourStopStory(
      id: json['id'] as String? ?? '',
      tourId: json['tour_id'] as String? ?? '',
      chapterIndex: (json['chapter_index'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Chapter',
      venueId: json['venue_id'] as String? ?? '',
      venueName: json['venue_name'] as String? ?? 'Venue',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 41.311081,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 69.240562,
      triggerRadiusMeters: (json['trigger_radius_meters'] as num?)?.toDouble() ?? 50.0,
      audioUrl: json['audio_url'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 60,
      transcript: json['transcript'] as String? ?? '',
      curatorNotes: json['curator_notes'] as String?,
    );
  }
}

/// A complete curated audio story tour across multiple venue chapters.
class CuratorTour {
  final String id;
  final String title;
  final String subtitle;
  final String curatorId;
  final String curatorName;
  final String? curatorAvatarUrl;
  final String district;
  final String? coverImageUrl;
  final List<TourStopStory> stops;
  final int estimatedWalkingMinutes;
  final int xpReward;

  const CuratorTour({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.curatorId,
    required this.curatorName,
    this.curatorAvatarUrl,
    required this.district,
    this.coverImageUrl,
    required this.stops,
    this.estimatedWalkingMinutes = 45,
    this.xpReward = 100,
  });

  int get totalDurationSeconds {
    return stops.fold(0, (acc, s) => acc + s.durationSeconds);
  }

  String get formattedTotalDuration {
    final mins = totalDurationSeconds ~/ 60;
    return '$mins min audio';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'curator_id': curatorId,
    'curator_name': curatorName,
    if (curatorAvatarUrl != null) 'curator_avatar_url': curatorAvatarUrl,
    'district': district,
    if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
    'stops': stops.map((s) => s.toJson()).toList(),
    'estimated_walking_minutes': estimatedWalkingMinutes,
    'xp_reward': xpReward,
  };

  factory CuratorTour.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List? ?? [];
    final parsedStops = rawStops
        .map((s) => TourStopStory.fromJson(s as Map<String, dynamic>))
        .toList();

    return CuratorTour(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Audio Tour',
      subtitle: json['subtitle'] as String? ?? '',
      curatorId: json['curator_id'] as String? ?? '',
      curatorName: json['curator_name'] as String? ?? 'Curator',
      curatorAvatarUrl: json['curator_avatar_url'] as String?,
      district: json['district'] as String? ?? 'Mirabad',
      coverImageUrl: json['cover_image_url'] as String?,
      stops: parsedStops,
      estimatedWalkingMinutes: (json['estimated_walking_minutes'] as num?)?.toInt() ?? 45,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 100,
    );
  }
}

/// Computational engine for tour chapter progression and geotargeted arrival triggers.
class CuratorTourStoryEngine {
  /// Calculates tour completion percentage [0.0, 100.0].
  double calculateTourProgress(CuratorTour tour, Set<String> completedStopIds) {
    if (tour.stops.isEmpty) return 0.0;
    final completedCount = tour.stops.where((s) => completedStopIds.contains(s.id)).length;
    final pct = (completedCount / tour.stops.length) * 100.0;
    return double.parse(pct.toStringAsFixed(1));
  }

  /// Returns true if all chapters in the tour have been completed.
  bool isTourCompleted(CuratorTour tour, Set<String> completedStopIds) {
    if (tour.stops.isEmpty) return false;
    return tour.stops.every((s) => completedStopIds.contains(s.id));
  }

  /// Finds the next uncompleted chapter stop in sequential order.
  TourStopStory? getNextChapter(CuratorTour tour, Set<String> completedStopIds) {
    for (final stop in tour.stops) {
      if (!completedStopIds.contains(stop.id)) {
        return stop;
      }
    }
    return null;
  }

  /// Calculates Haversine distance in meters between two GPS coordinates.
  double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Checks if the user is within the geotargeted trigger radius of the stop.
  bool isWithinTriggerRadius(double userLat, double userLng, TourStopStory stop) {
    final dist = calculateDistanceMeters(userLat, userLng, stop.latitude, stop.longitude);
    return dist <= stop.triggerRadiusMeters;
  }

  /// Formats trilingual chapter heading (e.g. "Chapter 2 of 4").
  String formatChapterProgress(int currentChapter, int totalChapters, {String locale = 'en'}) {
    final lang = locale.toLowerCase();
    if (lang.startsWith('uz')) {
      return '$totalChapters tadan $currentChapter-bob';
    } else if (lang.startsWith('ru')) {
      return 'Глава $currentChapter из $totalChapters';
    }
    return 'Chapter $currentChapter of $totalChapters';
  }

  /// Formats localized duration (e.g. "12 min audio").
  String localizedDuration(int totalSeconds, {String locale = 'en'}) {
    final mins = (totalSeconds / 60).ceil();
    final lang = locale.toLowerCase();
    if (lang.startsWith('uz')) {
      return '$mins daqiqalik audio sayohat';
    } else if (lang.startsWith('ru')) {
      return '$mins мин. аудиотур';
    }
    return '$mins min audio tour';
  }
}

final curatorTourStoryEngineProvider = Provider<CuratorTourStoryEngine>((ref) {
  return CuratorTourStoryEngine();
});
