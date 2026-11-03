import { describe, it, expect } from 'vitest';
import {
  calculateFlightMetrics,
  getAllFlavorNotes,
  getFlightCertificateLabel,
  WebTastingFlight,
} from '../components/WebTastingFlightSampler';

describe('WebTastingFlightSampler Helper Tests', () => {
  const mockFlight: WebTastingFlight = {
    id: 'flight-coffee',
    title: 'Tashkent Third-Wave Roastery Flight',
    curatorTitle: 'Specialty Coffee Cupping Certificate',
    category: 'Coffee',
    accentColor: '#A259FF',
    requiredStops: 2,
    stops: [
      {
        id: 'stop-breadly',
        venueName: 'Breadly Bakery & Roastery',
        district: 'Mirabad',
        itemTitle: 'Ethiopia Sidama Natural Pour-Over',
        flavorNotes: ['Bergamot', 'Dried Peach', 'Wild Jasmine'],
        originStory: 'Slow-drip V60 extracted at 92°C.',
        servingTemp: '92°C V60',
      },
      {
        id: 'stop-bb',
        venueName: 'B&B Coffee House',
        district: 'Yakkasaray',
        itemTitle: 'Colombia Anaerobic Filter',
        flavorNotes: ['Red Currant', 'Dark Cacao', 'Bergamot'], // Bergamot overlaps
        originStory: '72-hour extended maceration.',
        servingTemp: 'Aeropress',
      },
    ],
  };

  it('calculates flight metrics accurately for empty, partial, and completed logs', () => {
    // Empty
    const emptyMetrics = calculateFlightMetrics(mockFlight, {});
    expect(emptyMetrics.completedCount).toBe(0);
    expect(emptyMetrics.percentage).toBe(0);
    expect(emptyMetrics.averageScore).toBe(0);
    expect(emptyMetrics.isCompleted).toBe(false);

    // 1 log
    const partialMetrics = calculateFlightMetrics(mockFlight, {
      'stop-breadly': {
        stopId: 'stop-breadly',
        rating: 9.0,
        flavorNotes: ['Bergamot'],
      },
    });
    expect(partialMetrics.completedCount).toBe(1);
    expect(partialMetrics.percentage).toBe(50);
    expect(partialMetrics.averageScore).toBe(9.0);
    expect(partialMetrics.isCompleted).toBe(false);

    // 2 logs (full completion)
    const fullMetrics = calculateFlightMetrics(mockFlight, {
      'stop-breadly': {
        stopId: 'stop-breadly',
        rating: 9.2,
        flavorNotes: ['Bergamot'],
      },
      'stop-bb': {
        stopId: 'stop-bb',
        rating: 8.8,
        flavorNotes: ['Dark Cacao'],
      },
    });
    expect(fullMetrics.completedCount).toBe(2);
    expect(fullMetrics.percentage).toBe(100);
    expect(fullMetrics.averageScore).toBe(9.0);
    expect(fullMetrics.isCompleted).toBe(true);
  });

  it('deduplicates all flavor notes across flight stops', () => {
    const notes = getAllFlavorNotes(mockFlight);
    expect(notes).toContain('Bergamot');
    expect(notes).toContain('Dried Peach');
    expect(notes).toContain('Wild Jasmine');
    expect(notes).toContain('Red Currant');
    expect(notes).toContain('Dark Cacao');
    // Ensure Bergamot is only counted once
    expect(notes.filter((n) => n === 'Bergamot').length).toBe(1);
    expect(notes.length).toBe(5);
  });

  it('formats cupping certificate label with trilingual support', () => {
    // Unlocked
    expect(getFlightCertificateLabel(true, 'en')).toBe('Cupping Certificate Unlocked! (+50 XP)');
    expect(getFlightCertificateLabel(true, 'uz')).toBe('Sertifikat ochildi! (+50 XP)');
    expect(getFlightCertificateLabel(true, 'ru')).toBe('Сертификат открыт! (+50 XP)');

    // In Progress
    expect(getFlightCertificateLabel(false, 'en')).toBe('Cupping In Progress');
    expect(getFlightCertificateLabel(false, 'uz')).toBe('Tasting davom etmoqda');
    expect(getFlightCertificateLabel(false, 'ru')).toBe('Дегустация в процессе');
  });
});
