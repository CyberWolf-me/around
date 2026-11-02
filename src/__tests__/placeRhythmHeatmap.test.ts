import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { renderToString } from 'react-dom/server';
import {
  PlaceRhythmHeatmap,
  computeHourlyDistribution,
  getVibeTag,
  computePeakWindow,
} from '../components/PlaceRhythmHeatmap';
import * as soundEffects from '../services/soundEffects';

describe('P21-03: Web Companion Live Place Atmosphere Heatmap & Rhythm Tracker', () => {
  beforeEach(() => {
    vi.spyOn(soundEffects, 'playSoundWithHaptic').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('computeHourlyDistribution prioritizes morning hours for coffee venues', () => {
    const dist = computeHourlyDistribution('Specialty Coffee', ['Breakfast', 'Coffee']);
    expect(dist.length).toBe(24);

    // Morning hours should be significantly higher than midnight
    expect(dist[9]).toBeGreaterThan(dist[2]);
    expect(dist[9]).toBeGreaterThanOrEqual(0.9);
  });

  it('computeHourlyDistribution prioritizes evening hours for nightlife venues', () => {
    const dist = computeHourlyDistribution('Cocktail Bar', ['Nightlife', 'Cocktails']);
    expect(dist[21]).toBeGreaterThan(dist[10]);
    expect(dist[21]).toBeGreaterThanOrEqual(0.9);
  });

  it('getVibeTag assigns contextual atmosphere hashtags', () => {
    expect(getVibeTag(9, 'Café', ['Coffee'])).toBe('#MorningBrew');
    expect(getVibeTag(14, 'Café', ['WorkFriendly'])).toBe('#WorkFriendly');
    expect(getVibeTag(18, 'Café')).toBe('#GoldenHour');
    expect(getVibeTag(22, 'Bar')).toBe('#EveningBuzz');
    expect(getVibeTag(2, 'Bar')).toBe('#EveningBuzz');
    expect(getVibeTag(5, 'Café')).toBe('#QuietHours');
  });

  it('computePeakWindow determines the 3-hour window with highest energy', () => {
    const dist = computeHourlyDistribution('Bakery', ['Coffee']);
    const peak = computePeakWindow(dist);

    expect(peak.label).toBe('08:00 – 11:00');
    expect(peak.peakHour).toBe(9);
  });

  it('renders PlaceRhythmHeatmap component with peak window badge and all 24 hour bars', () => {
    const html = renderToString(
      React.createElement(PlaceRhythmHeatmap, {
        placeName: 'Breadly Bakery',
        category: 'Café',
        tags: ['Coffee', 'WorkFriendly'],
        currentHour: 9,
      })
    );

    expect(html).toContain('VENUE RHYTHM');
    expect(html).toContain('Atmosphere rhythm for Breadly Bakery');
    expect(html).toContain('PEAK 08:00 – 11:00');
    expect(html).toContain('09:00');
    expect(html).toContain('#MorningBrew');
    expect(html).toContain('95% Active Vibe');

    // Verify all 24 hour bar data-testids are present
    for (let h = 0; h < 24; h++) {
      expect(html).toContain(`data-testid="hour-bar-${h}"`);
    }
  });

  it('renders selected hour with custom initialSelectedHour', () => {
    const html = renderToString(
      React.createElement(PlaceRhythmHeatmap, {
        placeName: 'Steam Bar',
        category: 'Cocktail Bar',
        tags: ['Nightlife'],
        currentHour: 10,
        initialSelectedHour: 21,
      })
    );

    expect(html).toContain('Atmosphere rhythm for Steam Bar');
    expect(html).toContain('21:00');
    expect(html).toContain('#EveningBuzz');
  });
});
