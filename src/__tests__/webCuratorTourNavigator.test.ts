import { describe, it, expect } from 'vitest';
import {
  formatTourDuration,
  calculateTourProgressPct,
  getChapterHeader,
  WebCuratorTour,
} from '../components/WebCuratorTourNavigator';

describe('P40-03: WebCuratorTourNavigator Component & Utilities', () => {
  const sampleTour: WebCuratorTour = {
    id: 't-modernism',
    title: 'Tashkent Modernism Audio Crawl',
    curatorName: 'Aziza Tursunova',
    district: 'Central',
    chapters: [
      {
        id: 'c-1',
        chapterIndex: 1,
        title: 'Cosmic Mosaic Portal',
        venueName: 'Kosmonavtlar Metro',
        durationSeconds: 150,
        transcriptSnippet: 'Cobalt glazed medallion honoring space pioneers.',
      },
      {
        id: 'c-2',
        chapterIndex: 2,
        title: 'Geodesic Blue Dome',
        venueName: 'Chorsu Dome',
        durationSeconds: 210,
        transcriptSnippet: 'Seismic engineering of concrete cupolas.',
      },
    ],
  };

  it('formats chapter audio duration accurately', () => {
    expect(formatTourDuration(0)).toBe('0:00');
    expect(formatTourDuration(45)).toBe('0:45');
    expect(formatTourDuration(150)).toBe('2:30');
    expect(formatTourDuration(210)).toBe('3:30');
  });

  it('calculates tour progress percentage accurately', () => {
    expect(calculateTourProgressPct(2, 0)).toBe(0);
    expect(calculateTourProgressPct(2, 1)).toBe(50);
    expect(calculateTourProgressPct(2, 2)).toBe(100);
    expect(calculateTourProgressPct(0, 0)).toBe(0);
  });

  it('formats localized chapter headers across Uzbek, Russian, and English', () => {
    expect(getChapterHeader(1, 2, 'en')).toBe('Chapter 1 of 2');
    expect(getChapterHeader(1, 2, 'uz')).toBe('2 tadan 1-bob');
    expect(getChapterHeader(1, 2, 'ru')).toBe('Глава 1 из 2');
  });

  it('validates tour structure and chapter sequencing', () => {
    expect(sampleTour.chapters.length).toBe(2);
    expect(sampleTour.chapters[0].chapterIndex).toBe(1);
    expect(sampleTour.chapters[1].chapterIndex).toBe(2);
    expect(sampleTour.chapters[0].durationSeconds).toBeGreaterThan(0);
  });
});
