import { describe, it, expect } from 'vitest';
import {
  formatSoundDuration,
  formatSoundProgress,
  getSoundBiteCategoryLabel,
  WebPlaceSoundBite,
} from '../components/WebSoundBitePlayer';

describe('P38-03: WebSoundBitePlayer Component & Utilities', () => {
  const sampleSoundBite: WebPlaceSoundBite = {
    id: 'sb-web-1',
    placeId: 'pl-breadly',
    placeName: 'Breadly Bakery & Café',
    district: 'Mirabad',
    authorName: 'Kamila Karimova',
    durationSeconds: 24,
    waveformAmplitudes: [0.2, 0.4, 0.8, 0.6, 0.9, 0.5, 0.3, 0.7],
    transcriptionSnippet: 'The aroma of freshly baked sourdough at 8:30 AM is unreal.',
    categoryTag: 'barista_tip',
    likesCount: 18,
  };

  it('formats audio duration accurately', () => {
    expect(formatSoundDuration(0)).toBe('0:00');
    expect(formatSoundDuration(9)).toBe('0:09');
    expect(formatSoundDuration(24)).toBe('0:24');
    expect(formatSoundDuration(75)).toBe('1:15');
  });

  it('formats current and total timeline progress', () => {
    expect(formatSoundProgress(12, 24)).toBe('0:12 / 0:24');
    expect(formatSoundProgress(0, 45)).toBe('0:00 / 0:45');
    expect(formatSoundProgress(45, 45)).toBe('0:45 / 0:45');
  });

  it('localizes sound bite category across Uzbek, Russian, and English', () => {
    expect(getSoundBiteCategoryLabel('barista_tip', 'en')).toBe('Barista Tip');
    expect(getSoundBiteCategoryLabel('barista_tip', 'uz')).toBe('Barista Tavsiyasi');
    expect(getSoundBiteCategoryLabel('barista_tip', 'ru')).toBe('Совет бариста');

    expect(getSoundBiteCategoryLabel('history', 'uz')).toBe('Tarixiy Xotira');
    expect(getSoundBiteCategoryLabel('whisper', 'ru')).toBe('Шепот дворика');
    expect(getSoundBiteCategoryLabel('ambient', 'en')).toBe('Atmosphere Note');
  });

  it('validates sound bite data integrity and amplitude bounds', () => {
    expect(sampleSoundBite.durationSeconds).toBeGreaterThan(0);
    expect(sampleSoundBite.durationSeconds).toBeLessThanOrEqual(45);
    expect(sampleSoundBite.waveformAmplitudes.length).toBe(8);

    for (const amp of sampleSoundBite.waveformAmplitudes) {
      expect(amp).toBeGreaterThanOrEqual(0);
      expect(amp).toBeLessThanOrEqual(1.0);
    }
  });

  it('calculates seeker fraction within valid range', () => {
    const barsCount = sampleSoundBite.waveformAmplitudes.length;
    const testIndices = [0, 3, 7];

    testIndices.forEach((idx) => {
      const fraction = (idx + 1) / barsCount;
      expect(fraction).toBeGreaterThan(0);
      expect(fraction).toBeLessThanOrEqual(1);
    });
  });
});
