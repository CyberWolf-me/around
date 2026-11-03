import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebSoundscapePreset =
  | 'espressoMurmur'
  | 'orientalBazaar'
  | 'courtyardFountain'
  | 'jazzLounge'
  | 'quietLibrary';

export interface WebSoundscapeConfig {
  preset: WebSoundscapePreset;
  id: string;
  emoji: string;
  defaultVolume: number;
  frequencyHz: number;
  title: string;
  description: string;
}

export function getWebSoundscapeConfig(
  preset: WebSoundscapePreset,
  locale = 'en',
): WebSoundscapeConfig {
  const lang = locale.toLowerCase();

  switch (preset) {
    case 'espressoMurmur':
      return {
        preset,
        id: 'espresso_murmur',
        emoji: '☕',
        defaultVolume: 0.65,
        frequencyHz: 220,
        title: lang.startsWith('uz')
          ? 'Qahvaxona Shovqini'
          : lang.startsWith('ru')
          ? 'Кофейный Гул'
          : 'Espresso Murmur',
        description: lang.startsWith('uz')
          ? 'Mayin qahva tuyish va chashkalar jaranggi'
          : lang.startsWith('ru')
          ? 'Мягкий помол кофе и звон чашек'
          : 'Gentle coffee grinding and cups clinking',
      };

    case 'orientalBazaar':
      return {
        preset,
        id: 'oriental_bazaar',
        emoji: '🕌',
        defaultVolume: 0.6,
        frequencyHz: 260,
        title: lang.startsWith('uz')
          ? 'Sharq Bozorining Havosi'
          : lang.startsWith('ru')
          ? 'Восточный Базар'
          : 'Oriental Bazaar',
        description: lang.startsWith('uz')
          ? 'Choy quyilishi va samovar nafasi'
          : lang.startsWith('ru')
          ? 'Чай из самовара и шум базара'
          : 'Samovar tea pouring and bazaar warmth',
      };

    case 'courtyardFountain':
      return {
        preset,
        id: 'courtyard_fountain',
        emoji: '⛲',
        defaultVolume: 0.5,
        frequencyHz: 330,
        title: lang.startsWith('uz')
          ? 'Hovli Favvorasi'
          : lang.startsWith('ru')
          ? 'Дворовый Фонтан'
          : 'Courtyard Fountain',
        description: lang.startsWith('uz')
          ? 'Shildiragan suv tomchilari va mayin shabada'
          : lang.startsWith('ru')
          ? 'Журчание воды и вечерний бриз'
          : 'Trickling water fountain and gentle breeze',
      };

    case 'jazzLounge':
      return {
        preset,
        id: 'jazz_lounge',
        emoji: '🎷',
        defaultVolume: 0.7,
        frequencyHz: 180,
        title: lang.startsWith('uz')
          ? 'Kechki Jaz Ohanglari'
          : lang.startsWith('ru')
          ? 'Джазовый Лаунж'
          : 'Jazz Lounge',
        description: lang.startsWith('uz')
          ? 'Mayin kontrabas va sokin vinil crackle'
          : lang.startsWith('ru')
          ? 'Бархатный контрабас и треск винила'
          : 'Smooth upright bass and vinyl crackle',
      };

    case 'quietLibrary':
      return {
        preset,
        id: 'quiet_library',
        emoji: '📖',
        defaultVolume: 0.4,
        frequencyHz: 440,
        title: lang.startsWith('uz')
          ? 'Sokin Kutubxona'
          : lang.startsWith('ru')
          ? 'Тихая Библиотека'
          : 'Quiet Library',
        description: lang.startsWith('uz')
          ? 'Kitob varoqlash ovozi va chuqur diqqat'
          : lang.startsWith('ru')
          ? 'Шелест книжных страниц и концентрация'
          : 'Gentle page turns and deep focus',
      };
  }
}

export function recommendWebSoundscape(
  category: string,
  hourOfDay?: number,
): WebSoundscapePreset {
  const cat = category.trim().toLowerCase();
  const hour = hourOfDay ?? new Date().getHours();

  if (cat.includes('bar') || cat.includes('pub') || cat.includes('speakeasy')) {
    return 'jazzLounge';
  }
  if (cat.includes('book') || cat.includes('library') || cat.includes('work') || cat.includes('study')) {
    return 'quietLibrary';
  }
  if (cat.includes('park') || cat.includes('garden') || cat.includes('fountain') || cat.includes('courtyard')) {
    return 'courtyardFountain';
  }
  if (cat.includes('bazaar') || cat.includes('market') || cat.includes('plov') || cat.includes('heritage')) {
    return 'orientalBazaar';
  }
  if (hour >= 20 || hour < 5) {
    return 'jazzLounge';
  }
  return 'espressoMurmur';
}

export interface WebSoundscapeControllerProps {
  initialPreset?: WebSoundscapePreset;
  locale?: string;
  onStateChange?: (
    preset: WebSoundscapePreset,
    isPlaying: boolean,
    volume: number,
  ) => void;
}

export const WebSoundscapeController: React.FC<WebSoundscapeControllerProps> = ({
  initialPreset = 'espressoMurmur',
  locale = 'en',
  onStateChange,
}) => {
  const [currentPreset, setCurrentPreset] = useState<WebSoundscapePreset>(initialPreset);
  const [isPlaying, setIsPlaying] = useState(false);
  const config = getWebSoundscapeConfig(currentPreset, locale);
  const [volume, setVolume] = useState<number>(config.defaultVolume);

  const togglePlay = () => {
    const nextState = !isPlaying;
    setIsPlaying(nextState);
    playSoundWithHaptic('select');
    if (onStateChange) {
      onStateChange(currentPreset, nextState, volume);
    }
  };

  const handleSelectPreset = (p: WebSoundscapePreset) => {
    if (p === currentPreset) return;
    const newConfig = getWebSoundscapeConfig(p, locale);
    setCurrentPreset(p);
    setVolume(newConfig.defaultVolume);
    playSoundWithHaptic('select');
    if (onStateChange) {
      onStateChange(p, isPlaying, newConfig.defaultVolume);
    }
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const nextVol = Math.max(0, Math.min(1, parseFloat(e.target.value)));
    setVolume(nextVol);
    if (onStateChange) {
      onStateChange(currentPreset, isPlaying, nextVol);
    }
  };

  const allPresets: WebSoundscapePreset[] = [
    'espressoMurmur',
    'orientalBazaar',
    'courtyardFountain',
    'jazzLounge',
    'quietLibrary',
  ];

  return (
    <div className="w-full max-w-lg mx-auto p-5 rounded-2xl bg-white dark:bg-stone-900 border border-stone-200 dark:border-stone-800 shadow-md">
      {/* Header */}
      <div className="flex items-center justify-between gap-3 pb-3 border-b border-stone-100 dark:border-stone-800">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-orange-50 dark:bg-orange-950/40 border border-orange-200 dark:border-orange-800/60 flex items-center justify-center text-xl shrink-0">
            {config.emoji}
          </div>
          <div>
            <h2 className="text-sm font-black text-stone-900 dark:text-stone-100">
              {config.title}
            </h2>
            <p className="text-[11px] font-medium text-stone-500 dark:text-stone-400 truncate max-w-[220px]">
              {config.description}
            </p>
          </div>
        </div>

        {/* Play/Pause Button */}
        <button
          data-testid="web-soundscape-toggle-btn"
          onClick={togglePlay}
          className={`w-9 h-9 rounded-full flex items-center justify-center font-black transition-all ${
            isPlaying
              ? 'bg-orange-500 text-white shadow-md shadow-orange-500/20'
              : 'bg-stone-100 dark:bg-stone-800 text-stone-800 dark:text-stone-200 hover:bg-stone-200'
          }`}
        >
          {isPlaying ? '⏸' : '▶'}
        </button>
      </div>

      {/* Waveform Equalizer */}
      <div className="flex items-end justify-center gap-1.5 h-7 my-3">
        {[8, 16, 10, 22, 14, 18, 9].map((height, i) => (
          <div
            key={i}
            className={`w-1 rounded-full transition-all duration-300 ${
              isPlaying
                ? 'bg-orange-500'
                : 'bg-stone-200 dark:bg-stone-700'
            }`}
            style={{ height: isPlaying ? `${height}px` : '6px' }}
          />
        ))}
      </div>

      {/* Preset Chips */}
      <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
        {allPresets.map((p) => {
          const pCfg = getWebSoundscapeConfig(p, locale);
          const isSelected = p === currentPreset;

          return (
            <button
              key={p}
              data-testid={`web-preset-chip-${pCfg.id}`}
              onClick={() => handleSelectPreset(p)}
              className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-bold shrink-0 transition-colors ${
                isSelected
                  ? 'bg-orange-50 dark:bg-orange-950/40 border border-orange-300 dark:border-orange-700 text-orange-600 dark:text-orange-400'
                  : 'bg-stone-50 dark:bg-stone-800/80 border border-stone-200 dark:border-stone-700 text-stone-600 dark:text-stone-300 hover:bg-stone-100'
              }`}
            >
              <span>{pCfg.emoji}</span>
              <span>{pCfg.title}</span>
            </button>
          );
        })}
      </div>

      {/* Volume Slider */}
      <div className="mt-4 flex items-center gap-3 pt-3 border-t border-stone-100 dark:border-stone-800">
        <span className="text-xs text-stone-400">🔈</span>
        <input
          data-testid="web-soundscape-volume-input"
          type="range"
          min="0"
          max="1"
          step="0.05"
          value={volume}
          onChange={handleVolumeChange}
          className="flex-1 accent-orange-500 h-1.5 bg-stone-100 dark:bg-stone-800 rounded-lg cursor-pointer"
        />
        <span className="text-xs text-stone-400">🔊</span>
      </div>
    </div>
  );
};
