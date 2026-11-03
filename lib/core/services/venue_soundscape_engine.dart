import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Core ambient soundscape presets for Tashkent venues.
enum VenueSoundscapePreset {
  espressoMurmur,
  orientalBazaar,
  courtyardFountain,
  jazzLounge,
  quietLibrary,
}

/// Metadata configuration for an ambient soundscape preset.
class SoundscapePresetConfig {
  final VenueSoundscapePreset preset;
  final String id;
  final String emoji;
  final double defaultVolume;
  final int loopDurationSeconds;

  const SoundscapePresetConfig({
    required this.preset,
    required this.id,
    required this.emoji,
    required this.defaultVolume,
    required this.loopDurationSeconds,
  });

  String localizedTitle({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (preset) {
      case VenueSoundscapePreset.espressoMurmur:
        if (lang.startsWith('uz')) return 'Qahvaxona Shovqini';
        if (lang.startsWith('ru')) return 'Кофейный Гул';
        return 'Espresso Murmur';

      case VenueSoundscapePreset.orientalBazaar:
        if (lang.startsWith('uz')) return 'Sharq Bozorining Havosi';
        if (lang.startsWith('ru')) return 'Восточный Базар';
        return 'Oriental Bazaar';

      case VenueSoundscapePreset.courtyardFountain:
        if (lang.startsWith('uz')) return 'Hovli Favvorasi';
        if (lang.startsWith('ru')) return 'Дворовый Фонтан';
        return 'Courtyard Fountain';

      case VenueSoundscapePreset.jazzLounge:
        if (lang.startsWith('uz')) return 'Kechki Jaz Ohanglari';
        if (lang.startsWith('ru')) return 'Джазовый Лаунж';
        return 'Jazz Lounge';

      case VenueSoundscapePreset.quietLibrary:
        if (lang.startsWith('uz')) return 'Sokin Kutubxona';
        if (lang.startsWith('ru')) return 'Тихая Библиотека';
        return 'Quiet Library';
    }
  }

  String localizedDescription({String locale = 'en'}) {
    final lang = locale.toLowerCase();
    switch (preset) {
      case VenueSoundscapePreset.espressoMurmur:
        if (lang.startsWith('uz')) return 'Mayin qahva tuyish, chashkalar jaranggi va xushfe\'l suhbatlar';
        if (lang.startsWith('ru')) return 'Мягкий помол кофе, звон чашек и приглушенные разговоры';
        return 'Gentle coffee grinding, cups clinking, and low friendly chatter';

      case VenueSoundscapePreset.orientalBazaar:
        if (lang.startsWith('uz')) return 'Choynakdan choy quyilishi, chorsu shovqini va samovar nafasi';
        if (lang.startsWith('ru')) return 'Чай из самовара, шум Чорсу и оживленная восточная атмосфера';
        return 'Samovar tea pouring, distant merchant calls, and bazaar warmth';

      case VenueSoundscapePreset.courtyardFountain:
        if (lang.startsWith('uz')) return 'Shildiragan suv tomchilari, qushlar sayrashi va mayin shabada';
        if (lang.startsWith('ru')) return 'Журчание воды, шелест листвы и вечернее пение птиц';
        return 'Trickling water fountain, rustling leaves, and evening breeze';

      case VenueSoundscapePreset.jazzLounge:
        if (lang.startsWith('uz')) return 'Mayin kontrabas sadolari va sokin vinil shildirashi';
        if (lang.startsWith('ru')) return 'Бархатный контрабас и теплое потрескивание винила';
        return 'Smooth upright bass, muted trumpets, and warm vinyl crackle';

      case VenueSoundscapePreset.quietLibrary:
        if (lang.startsWith('uz')) return 'Kitob varoqlash ovozi va derazadagi mayin yomg\'ir';
        if (lang.startsWith('ru')) return 'Шелест книжных страниц и капли дождя по стеклу';
        return 'Gentle turning of book pages, rain on glass, and deep focus';
    }
  }
}

/// Algorithm engine for recommending and managing venue atmosphere soundscapes.
class VenueSoundscapeEngine {
  static const Map<VenueSoundscapePreset, SoundscapePresetConfig> _configs = {
    VenueSoundscapePreset.espressoMurmur: SoundscapePresetConfig(
      preset: VenueSoundscapePreset.espressoMurmur,
      id: 'espresso_murmur',
      emoji: '☕',
      defaultVolume: 0.65,
      loopDurationSeconds: 45,
    ),
    VenueSoundscapePreset.orientalBazaar: SoundscapePresetConfig(
      preset: VenueSoundscapePreset.orientalBazaar,
      id: 'oriental_bazaar',
      emoji: '🕌',
      defaultVolume: 0.60,
      loopDurationSeconds: 60,
    ),
    VenueSoundscapePreset.courtyardFountain: SoundscapePresetConfig(
      preset: VenueSoundscapePreset.courtyardFountain,
      id: 'courtyard_fountain',
      emoji: '⛲',
      defaultVolume: 0.50,
      loopDurationSeconds: 30,
    ),
    VenueSoundscapePreset.jazzLounge: SoundscapePresetConfig(
      preset: VenueSoundscapePreset.jazzLounge,
      id: 'jazz_lounge',
      emoji: '🎷',
      defaultVolume: 0.70,
      loopDurationSeconds: 50,
    ),
    VenueSoundscapePreset.quietLibrary: SoundscapePresetConfig(
      preset: VenueSoundscapePreset.quietLibrary,
      id: 'quiet_library',
      emoji: '📖',
      defaultVolume: 0.40,
      loopDurationSeconds: 40,
    ),
  };

  /// Retrieves configuration metadata for a preset.
  SoundscapePresetConfig getConfig(VenueSoundscapePreset preset) {
    return _configs[preset] ?? _configs[VenueSoundscapePreset.espressoMurmur]!;
  }

  /// Recommends best-fitting ambient preset for a venue category and optional time of day.
  VenueSoundscapePreset recommendPreset({
    required String venueCategory,
    int? hourOfDay,
  }) {
    final cat = venueCategory.trim().toLowerCase();
    final hour = hourOfDay ?? DateTime.now().hour;

    // Evening / Night Speakeasy / Bar
    if (cat.contains('bar') || cat.contains('night') || cat.contains('pub') || cat.contains('speakeasy')) {
      return VenueSoundscapePreset.jazzLounge;
    }

    // Co-working / Library / Books
    if (cat.contains('book') || cat.contains('work') || cat.contains('library') || cat.contains('study') || cat.contains('museum')) {
      return VenueSoundscapePreset.quietLibrary;
    }

    // Parks / Courtyards / Nature
    if (cat.contains('park') || cat.contains('courtyard') || cat.contains('garden') || cat.contains('outdoor') || cat.contains('fountain')) {
      return VenueSoundscapePreset.courtyardFountain;
    }

    // Traditional Bazaar / Market / Street Food
    if (cat.contains('bazaar') || cat.contains('market') || cat.contains('plov') || cat.contains('heritage') || cat.contains('street')) {
      return VenueSoundscapePreset.orientalBazaar;
    }

    // If it's late night (after 20:00), default to jazz lounge
    if (hour >= 20 || hour < 5) {
      return VenueSoundscapePreset.jazzLounge;
    }

    // Default: Cafe / Espresso Murmur
    return VenueSoundscapePreset.espressoMurmur;
  }

  /// Clamps volume multiplier cleanly between 0.0 and 1.0.
  double clampVolume(double volume) {
    return volume.clamp(0.0, 1.0);
  }
}

final venueSoundscapeEngineProvider = Provider<VenueSoundscapeEngine>((ref) {
  return VenueSoundscapeEngine();
});
