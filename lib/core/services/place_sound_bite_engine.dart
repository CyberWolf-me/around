import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a short community audio impression or courtyard voice note.
class PlaceSoundBite {
  final String id;
  final String placeId;
  final String placeName;
  final String district;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String audioUrl;
  final int durationSeconds;
  final List<double> waveformAmplitudes;
  final String? transcriptionSnippet;
  final String categoryTag; // 'ambient', 'barista_tip', 'history', 'whisper'
  final int likesCount;
  final DateTime createdAt;

  const PlaceSoundBite({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.district,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.audioUrl,
    required this.durationSeconds,
    required this.waveformAmplitudes,
    this.transcriptionSnippet,
    this.categoryTag = 'ambient',
    this.likesCount = 0,
    required this.createdAt,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final sStr = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$sStr';
  }

  String localizedCategory({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (categoryTag.toLowerCase()) {
      case 'barista_tip':
        if (lang.startsWith('uz')) return 'Barista Tavsiyasi';
        if (lang.startsWith('ru')) return 'Совет бариста';
        return 'Barista Tip';
      case 'history':
        if (lang.startsWith('uz')) return 'Tarixiy Xotira';
        if (lang.startsWith('ru')) return 'История места';
        return 'Local History';
      case 'whisper':
        if (lang.startsWith('uz')) return 'Hovli Shiviri';
        if (lang.startsWith('ru')) return 'Шепот дворика';
        return 'Courtyard Whisper';
      case 'ambient':
      default:
        if (lang.startsWith('uz')) return 'Muhit Ovozi';
        if (lang.startsWith('ru')) return 'Атмосфера';
        return 'Atmosphere Note';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'place_id': placeId,
    'place_name': placeName,
    'district': district,
    'author_id': authorId,
    'author_name': authorName,
    if (authorAvatarUrl != null) 'author_avatar_url': authorAvatarUrl,
    'audio_url': audioUrl,
    'duration_seconds': durationSeconds,
    'waveform_amplitudes': waveformAmplitudes,
    if (transcriptionSnippet != null) 'transcription_snippet': transcriptionSnippet,
    'category_tag': categoryTag,
    'likes_count': likesCount,
    'created_at': createdAt.toIso8601String(),
  };

  factory PlaceSoundBite.fromJson(Map<String, dynamic> json) {
    final rawAmps = json['waveform_amplitudes'] as List? ?? [];
    final amps = rawAmps.map((a) => (a as num).toDouble()).toList();

    return PlaceSoundBite(
      id: json['id'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      placeName: json['place_name'] as String? ?? 'Spot',
      district: json['district'] as String? ?? 'Mirabad',
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Explorer',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      audioUrl: json['audio_url'] as String? ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 15,
      waveformAmplitudes: amps.isNotEmpty ? amps : const [0.3, 0.6, 0.9, 0.5, 0.4, 0.8],
      transcriptionSnippet: json['transcription_snippet'] as String?,
      categoryTag: json['category_tag'] as String? ?? 'ambient',
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Core audio waveform calculation and duration enforcement engine for sound bites.
class PlaceSoundBiteEngine {
  static const int maxDurationSeconds = 45;
  static const int minDurationSeconds = 2;
  static const int standardWaveformBars = 24;

  /// Validates whether recorded audio length meets Around constraints.
  bool validateDuration(int seconds) {
    return seconds >= minDurationSeconds && seconds <= maxDurationSeconds;
  }

  /// Normalizes and resamples raw amplitude numbers into normalized bars [0.05, 1.0].
  List<double> normalizeWaveform(
    List<num> rawAmplitudes, {
    int targetBars = standardWaveformBars,
  }) {
    if (rawAmplitudes.isEmpty) {
      return List<double>.filled(targetBars, 0.2);
    }

    // Find maximum amplitude to scale relative heights
    double maxVal = 0.001;
    for (final a in rawAmplitudes) {
      final val = a.toDouble().abs();
      if (val > maxVal) maxVal = val;
    }

    final normalized = <double>[];
    for (int i = 0; i < targetBars; i++) {
      // Map bar index to raw sample index linearly
      final sampleIndex = ((i / targetBars) * rawAmplitudes.length).floor();
      final clampedIndex = sampleIndex.clamp(0, rawAmplitudes.length - 1);
      final rawVal = rawAmplitudes[clampedIndex].toDouble().abs();
      
      // Calculate normalized height with aesthetic min height of 0.08
      final height = ((rawVal / maxVal) * 0.92) + 0.08;
      normalized.add(double.parse(height.clamp(0.08, 1.0).toStringAsFixed(2)));
    }

    return normalized;
  }

  /// Formats playback progress into formatted timeline string '0:12 / 0:34'.
  String formatProgress(double currentSeconds, int totalDuration) {
    final curSec = currentSeconds.floor();
    final curMin = curSec ~/ 60;
    final curRem = curSec % 60;
    final curStr = '$curMin:${curRem < 10 ? '0$curRem' : '$curRem'}';

    final totMin = totalDuration ~/ 60;
    final totRem = totalDuration % 60;
    final totStr = '$totMin:${totRem < 10 ? '0$totRem' : '$totRem'}';

    return '$curStr / $totStr';
  }

  /// Filters sound bites by place UUID or slug.
  List<PlaceSoundBite> filterByPlace(List<PlaceSoundBite> bites, String? placeId) {
    if (placeId == null || placeId.trim().isEmpty || placeId.toLowerCase() == 'all') {
      return bites;
    }
    final q = placeId.trim().toLowerCase();
    return bites.where((b) => b.placeId.toLowerCase() == q).toList();
  }

  /// Filters sound bites by district.
  List<PlaceSoundBite> filterByDistrict(List<PlaceSoundBite> bites, String? district) {
    if (district == null || district.trim().isEmpty || district.toLowerCase() == 'all') {
      return bites;
    }
    final q = district.trim().toLowerCase();
    return bites.where((b) => b.district.toLowerCase() == q).toList();
  }
}

final placeSoundBiteEngineProvider = Provider<PlaceSoundBiteEngine>((ref) {
  return PlaceSoundBiteEngine();
});
