import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  WebSoundscapeController,
  getWebSoundscapeConfig,
  recommendWebSoundscape,
  WebSoundscapePreset,
} from '../components/WebSoundscapeController';

describe('P36-03: WebSoundscapeController Component & Helpers Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const presets: WebSoundscapePreset[] = [
    'espressoMurmur',
    'orientalBazaar',
    'courtyardFountain',
    'jazzLounge',
    'quietLibrary',
  ];

  it('provides complete metadata for all 5 presets', () => {
    for (const p of presets) {
      const cfg = getWebSoundscapeConfig(p, 'en');
      expect(cfg.preset).toBe(p);
      expect(cfg.id).toBeDefined();
      expect(cfg.emoji).toBeDefined();
      expect(cfg.title).toBeDefined();
      expect(cfg.description).toBeDefined();
      expect(cfg.defaultVolume).toBeGreaterThan(0);
      expect(cfg.frequencyHz).toBeGreaterThan(0);
    }
  });

  it('formats localized preset titles in Uzbek and Russian', () => {
    const espressoUz = getWebSoundscapeConfig('espressoMurmur', 'uz');
    expect(espressoUz.title).toBe('Qahvaxona Shovqini');

    const fountainRu = getWebSoundscapeConfig('courtyardFountain', 'ru');
    expect(fountainRu.title).toBe('Дворовый Фонтан');

    const jazzEn = getWebSoundscapeConfig('jazzLounge', 'en');
    expect(jazzEn.title).toBe('Jazz Lounge');
  });

  it('recommends appropriate presets based on category and time of day', () => {
    expect(recommendWebSoundscape('Speakeasy Cocktail Bar', 21)).toBe('jazzLounge');
    expect(recommendWebSoundscape('Quiet Co-working Library', 14)).toBe('quietLibrary');
    expect(recommendWebSoundscape('Botanical Park & Fountain', 10)).toBe('courtyardFountain');
    expect(recommendWebSoundscape('Chorsu Plov Bazaar', 12)).toBe('orientalBazaar');
    expect(recommendWebSoundscape('Specialty Coffee', 9)).toBe('espressoMurmur');
    expect(recommendWebSoundscape('General Venue', 23)).toBe('jazzLounge'); // Late night
  });

  it('renders static markup for initial preset cleanly', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebSoundscapeController, {
        initialPreset: 'espressoMurmur',
        locale: 'en',
      }),
    );

    expect(html).toContain('Espresso Murmur');
    expect(html).toContain('☕');
    expect(html).toContain('Gentle coffee grinding');
    expect(html).toContain('web-soundscape-toggle-btn');
    expect(html).toContain('web-soundscape-volume-input');
  });

  it('contains chips for all 5 presets in static markup', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebSoundscapeController, {
        initialPreset: 'courtyardFountain',
        locale: 'en',
      }),
    );

    for (const p of presets) {
      const cfg = getWebSoundscapeConfig(p, 'en');
      expect(html).toContain(cfg.title);
    }
  });
});
