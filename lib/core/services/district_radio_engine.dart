import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a broadcast radio station rooted in a Tashkent district.
class RadioStation {
  final String id;
  final double frequencyMhz;
  final String callsign;
  final String title;
  final String district;
  final String genreDescription;
  final String accentColorHex;
  final String streamUrl;
  final int baseListeners;
  final String currentTrack;
  final String curatorName;

  const RadioStation({
    required this.id,
    required this.frequencyMhz,
    required this.callsign,
    required this.title,
    required this.district,
    required this.genreDescription,
    required this.accentColorHex,
    required this.streamUrl,
    required this.baseListeners,
    required this.currentTrack,
    required this.curatorName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'frequency_mhz': frequencyMhz,
    'callsign': callsign,
    'title': title,
    'district': district,
    'genre_description': genreDescription,
    'accent_color_hex': accentColorHex,
    'stream_url': streamUrl,
    'base_listeners': baseListeners,
    'current_track': currentTrack,
    'curator_name': curatorName,
  };

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] as String? ?? '',
      frequencyMhz: (json['frequency_mhz'] as num?)?.toDouble() ?? 88.0,
      callsign: json['callsign'] as String? ?? 'ARND',
      title: json['title'] as String? ?? 'District Radio',
      district: json['district'] as String? ?? 'Tashkent',
      genreDescription: json['genre_description'] as String? ?? 'Ambient',
      accentColorHex: json['accent_color_hex'] as String? ?? '#FF4800',
      streamUrl: json['stream_url'] as String? ?? '',
      baseListeners: (json['base_listeners'] as num?)?.toInt() ?? 100,
      currentTrack: json['current_track'] as String? ?? 'Atmosphere Stream',
      curatorName: json['curator_name'] as String? ?? 'Around Audio',
    );
  }
}

/// Evaluation of tuning dial reception quality and lock-on.
class TuningResult {
  final double dialFrequency;
  final RadioStation? lockedStation;
  final double signalStrength; // 0.0 to 1.0
  final bool isClearReception;
  final double staticNoiseVolume; // 0.0 to 1.0

  const TuningResult({
    required this.dialFrequency,
    this.lockedStation,
    required this.signalStrength,
    required this.isClearReception,
    required this.staticNoiseVolume,
  });
}

/// Core engine for district radio station tuning, frequency drift, and session tracking.
class DistrictRadioEngine {
  /// Default catalog of curated Tashkent district field-recording stations.
  static const List<RadioStation> defaultStations = [
    RadioStation(
      id: 'station-chorsu-fm',
      frequencyMhz: 88.4,
      callsign: 'CHRS 88.4',
      title: 'Old City Chorsu Echoes',
      district: 'Shaykhontohur',
      genreDescription: 'Clay ovens, spice merchants & morning adhan reverberation',
      accentColorHex: '#2563EB', // Cobalt
      streamUrl: 'https://around.tashkent.app/radio/chorsu_ambient.aac',
      baseListeners: 340,
      currentTrack: 'Kaffal Shashi Courtyard Birds & Copper Chimes',
      curatorName: 'Akrom Chorsui',
    ),
    RadioStation(
      id: 'station-mirabad-beat',
      frequencyMhz: 94.2,
      callsign: 'MRBD 94.2',
      title: 'Mirabad Modern Beat',
      district: 'Mirabad',
      genreDescription: 'Specialty espresso hiss, vinyl crackle & evening lo-fi beats',
      accentColorHex: '#FF4800', // Around Orange
      streamUrl: 'https://around.tashkent.app/radio/mirabad_lofi.aac',
      baseListeners: 520,
      currentTrack: 'Shevchenko Rain & Ceramic Portafilter Knocks',
      curatorName: 'DJ Rustam Mirabad',
    ),
    RadioStation(
      id: 'station-yunusabad-rain',
      frequencyMhz: 101.6,
      callsign: 'YNSB 101.6',
      title: 'Yunusabad Night Rain',
      district: 'Yunusabad',
      genreDescription: 'TV tower wind chimes, nocturnal tram hum & autumn rain',
      accentColorHex: '#059669', // Emerald
      streamUrl: 'https://around.tashkent.app/radio/yunusabad_rain.aac',
      baseListeners: 290,
      currentTrack: 'Amir Timur Avenue Tram Tracks & Deep Drizzle',
      curatorName: 'Nargiza S.',
    ),
    RadioStation(
      id: 'station-yakkasaray-breeze',
      frequencyMhz: 107.5,
      callsign: 'YKKS 107.5',
      title: 'Yakkasaray Park Breeze',
      district: 'Yakkasaray',
      genreDescription: 'Ankhor canal water ripple, plane trees & acoustic dombra',
      accentColorHex: '#A259FF', // Violet
      streamUrl: 'https://around.tashkent.app/radio/yakkasaray_breeze.aac',
      baseListeners: 215,
      currentTrack: 'Ankhor Embankment Twilight & Willow Leaves',
      curatorName: 'Otabek Dombra Master',
    ),
  ];

  /// Returns all available district radio stations ordered by frequency.
  List<RadioStation> getAllStations() => defaultStations;

  /// Retrieves station by identifier.
  RadioStation? getStationById(String id) {
    for (final s in defaultStations) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Calculates tuning reception quality at a given dial frequency (MHz).
  TuningResult tuneToFrequency(double dialFrequencyMhz) {
    const double maxToleranceMhz = 1.0;
    RadioStation? closest;
    double minDiff = double.infinity;

    for (final s in defaultStations) {
      final diff = (s.frequencyMhz - dialFrequencyMhz).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }

    if (closest == null || minDiff > maxToleranceMhz) {
      return TuningResult(
        dialFrequency: dialFrequencyMhz,
        lockedStation: null,
        signalStrength: 0.0,
        isClearReception: false,
        staticNoiseVolume: 1.0,
      );
    }

    // Signal strength decreases linearly from 1.0 at center to 0.0 at maxTolerance
    final double strength = (1.0 - (minDiff / maxToleranceMhz)).clamp(0.0, 1.0);
    final bool isClear = strength >= 0.75;
    final double staticVolume = (1.0 - strength).clamp(0.0, 1.0);

    return TuningResult(
      dialFrequency: dialFrequencyMhz,
      lockedStation: closest,
      signalStrength: double.parse(strength.toStringAsFixed(2)),
      isClearReception: isClear,
      staticNoiseVolume: double.parse(staticVolume.toStringAsFixed(2)),
    );
  }

  /// Finds the closest station to the current dial position.
  RadioStation findClosestStation(double dialFrequencyMhz) {
    RadioStation closest = defaultStations.first;
    double minDiff = (closest.frequencyMhz - dialFrequencyMhz).abs();

    for (final s in defaultStations) {
      final diff = (s.frequencyMhz - dialFrequencyMhz).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return closest;
  }

  /// Formats frequency label cleanly (e.g. "88.4 MHz").
  String formatFrequency(double frequencyMhz) {
    return '${frequencyMhz.toStringAsFixed(1)} MHz';
  }

  /// Calculates dynamic live listeners based on hour of day.
  int calculateLiveListeners(RadioStation station, {DateTime? time}) {
    final now = time ?? DateTime.now();
    final hour = now.hour;

    // Peak listening during evening chill (18:00 - 23:00)
    double timeMultiplier;
    if (hour >= 18 && hour <= 23) {
      timeMultiplier = 1.6;
    } else if (hour >= 8 && hour <= 12) {
      timeMultiplier = 1.3;
    } else if (hour >= 1 && hour <= 6) {
      timeMultiplier = 0.5;
    } else {
      timeMultiplier = 1.0;
    }

    // Add deterministic variance
    final variance = math.sin(hour * 0.5) * 20;
    return math.max(20, (station.baseListeners * timeMultiplier + variance).round());
  }

  /// Formats listening session progress label.
  String formatSessionProgressLabel(int durationSeconds, String languageCode) {
    final minutes = durationSeconds ~/ 60;
    final remainingMinutes = math.max(0, 10 - minutes);

    if (durationSeconds >= 600) {
      switch (languageCode) {
        case 'uz':
          return '10 daqiqa tinglandi! +25 XP mukofoti olindi';
        case 'ru':
          return '10 минут прослушано! Получено +25 XP';
        case 'en':
        default:
          return '10 minutes tuned in! Earned +25 XP';
      }
    }

    switch (languageCode) {
      case 'uz':
        return '+25 XP olish uchun yana $remainingMinutes daqiqa tinglang';
      case 'ru':
        return 'Слушайте еще $remainingMinutes мин до +25 XP';
      case 'en':
      default:
        return 'Listen $remainingMinutes more mins for +25 XP';
    }
  }
}

/// Riverpod provider for DistrictRadioEngine.
final districtRadioEngineProvider = Provider<DistrictRadioEngine>((ref) {
  return DistrictRadioEngine();
});
