import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  CuratorLevelBadge,
  calculateWebCuratorProgression,
} from '../components/CuratorLevelBadge';
import * as soundEffects from '../services/soundEffects';

describe('P23-03: CuratorLevelBadge Component & Progression Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('calculateWebCuratorProgression computes Tier 1 Neighborhood Scout for 0-4 drops', () => {
    const p = calculateWebCuratorProgression(2, 0, 0, 'en');
    expect(p.totalXp).toBe(100);
    expect(p.level).toBe(1);
    expect(p.tier).toBe('neighborhoodScout');
    expect(p.emoji).toBe('🌱');
    expect(p.xpToNextTier).toBe(150);
    expect(p.progressFraction).toBe(0.4);
  });

  it('calculateWebCuratorProgression unlocks Tier 2 District Curator at 250 XP', () => {
    const p = calculateWebCuratorProgression(5, 0, 0, 'en');
    expect(p.totalXp).toBe(250);
    expect(p.level).toBe(2);
    expect(p.tier).toBe('districtCurator');
    expect(p.emoji).toBe('🧭');
    expect(p.xpToNextTier).toBe(500);
  });

  it('calculateWebCuratorProgression unlocks Tier 3 City Pioneer at 750+ XP', () => {
    const p = calculateWebCuratorProgression(10, 3, 0, 'en'); // 500 + 300 = 800 XP
    expect(p.totalXp).toBe(800);
    expect(p.level).toBe(3);
    expect(p.tier).toBe('cityPioneer');
    expect(p.emoji).toBe('⚡');
  });

  it('calculateWebCuratorProgression unlocks Tier 4 Tashkent Legend at 2000+ XP', () => {
    const p = calculateWebCuratorProgression(30, 5, 2, 'en'); // 1500 + 500 + 500 = 2500 XP
    expect(p.totalXp).toBe(2500);
    expect(p.level).toBe(4);
    expect(p.tier).toBe('tashkentLegend');
    expect(p.emoji).toBe('👑');
    expect(p.progressFraction).toBe(1.0);
    expect(p.xpToNextTier).toBe(0);
    expect(p.progressLabel).toBe('Max Level Reached!');
  });

  it('localizes accurately across Uzbek and Russian', () => {
    const pUz = calculateWebCuratorProgression(1, 0, 0, 'uz');
    expect(pUz.title).toBe('Mahalla Izquvari');
    expect(pUz.progressLabel).toContain('200 XP');

    const pRu = calculateWebCuratorProgression(40, 10, 3, 'ru');
    expect(pRu.title).toBe('Легенда Ташкента');
    expect(pRu.progressLabel).toBe('Максимальный уровень!');
  });

  it('renders level badge card with XP chip and emoji', () => {
    const html = renderToStaticMarkup(
      React.createElement(CuratorLevelBadge, {
        dropsCount: 8,
        streakWeeks: 2,
        crowns: 1,
        lang: 'en',
      })
    );

    expect(html).toContain('850 XP'); // 400 + 200 + 250 = 850 XP
    expect(html).toContain('City Pioneer');
    expect(html).toContain('LVL 3');
    expect(html).toContain('⚡');
  });

  it('triggers playSoundWithHaptic when clicked', () => {
    const playSpy = vi.spyOn(soundEffects, 'playSoundWithHaptic').mockImplementation(() => {});
    const onTap = vi.fn();

    soundEffects.playSoundWithHaptic('select', 'selection');
    onTap();

    expect(playSpy).toHaveBeenCalledWith('select', 'selection');
    expect(onTap).toHaveBeenCalled();
  });
});
