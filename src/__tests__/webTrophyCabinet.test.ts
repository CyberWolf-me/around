import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  WebTrophyCabinet,
  calculateWebMasteryTier,
  formatWebMasteryTitle,
  calculateWebHonorScore,
  generateWebShareCopy,
  WebCuratorAccolades,
} from '../components/WebTrophyCabinet';

describe('P31-03: WebTrophyCabinet Web Component & Accolades Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const testAccolades: WebCuratorAccolades = {
    userId: 'usr-99',
    username: 'kamila_tashkent',
    crownsCount: 2,
    trophies: [
      {
        id: 't-1',
        seasonId: '2026-11',
        seasonTitle: 'Autumn in Tashkent',
        tier: 'gold',
        completedChallengesCount: 3,
        xpBonus: 150,
        earnedAt: '2026-11-02T10:00:00Z',
      },
      {
        id: 't-2',
        seasonId: '2026-10',
        seasonTitle: 'October Harvest',
        tier: 'silver',
        completedChallengesCount: 2,
        xpBonus: 75,
        earnedAt: '2026-10-31T18:00:00Z',
      },
    ],
    laurels: [
      {
        seasonId: '2026-10',
        district: 'Mirabad',
        rank: 1,
        laurel: 'champion',
      },
    ],
    totalCuratorXp: 950,
  };

  it('calculates mastery tiers accurately according to rule matrix', () => {
    expect(calculateWebMasteryTier(0, [])).toBe('scout');

    expect(
      calculateWebMasteryTier(0, [
        {
          id: '1',
          seasonId: '2026-10',
          seasonTitle: 'October',
          tier: 'bronze',
          completedChallengesCount: 1,
          xpBonus: 30,
          earnedAt: '2026-10-31',
        },
      ]),
    ).toBe('pioneer');

    expect(
      calculateWebMasteryTier(1, []),
    ).toBe('legend');

    expect(
      calculateWebMasteryTier(3, []),
    ).toBe('grandMaster');

    expect(
      calculateWebMasteryTier(1, [
        { id: '1', seasonId: 'a', seasonTitle: 'A', tier: 'gold', completedChallengesCount: 3, xpBonus: 100, earnedAt: '' },
        { id: '2', seasonId: 'b', seasonTitle: 'B', tier: 'gold', completedChallengesCount: 3, xpBonus: 100, earnedAt: '' },
      ]),
    ).toBe('grandMaster');
  });

  it('formats localized mastery titles across UZ, RU, and EN', () => {
    expect(formatWebMasteryTitle('grandMaster', 'en')).toBe('Grand Master Curator');
    expect(formatWebMasteryTitle('grandMaster', 'uz')).toBe('Katta Kurator Ustasi');
    expect(formatWebMasteryTitle('grandMaster', 'ru')).toBe('Гранд-Мастер Куратор');

    expect(formatWebMasteryTitle('legend', 'en')).toBe('Tashkent Legend');
    expect(formatWebMasteryTitle('pioneer', 'uz')).toBe('Tuman Kashfiyotchisi');
    expect(formatWebMasteryTitle('scout', 'ru')).toBe('Разведчик Махалли');
  });

  it('calculates accurate weighted honor scores', () => {
    // 2 crowns (2000) + 1 gold (500) + 1 silver (250) + 1 laurel (150) + 950/10 (95) = 3000 - 5 = 2995
    const score = calculateWebHonorScore(testAccolades);
    expect(score).toBe(2995);
  });

  it('generates social share copy containing user handle and URL', () => {
    const copyEn = generateWebShareCopy(testAccolades, 'en');
    expect(copyEn).toContain('Tashkent Legend — @kamila_tashkent');
    expect(copyEn).toContain('2 District Crowns • 2 Trophies');
    expect(copyEn).toContain('https://around.tashkent.app/passport/kamila_tashkent');

    const copyUz = generateWebShareCopy(testAccolades, 'uz');
    expect(copyUz).toContain('Toshkent Afsonasi');
    expect(copyUz).toContain("Toshkent ta'm pasporti");
  });

  it('renders WebTrophyCabinet component markup with crowns, trophies, and laurels', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebTrophyCabinet, {
        accolades: testAccolades,
        locale: 'en',
      }),
    );

    expect(html).toContain('Tashkent Legend');
    expect(html).toContain('Accolades Honor: 2995 pts');
    expect(html).toContain('Autumn in Tashkent');
    expect(html).toContain('October Harvest');
    expect(html).toContain('Mirabad #1');
    expect(html).toContain('Share Accolades');
  });

  it('renders empty trophies state cleanly when user has no trophies', () => {
    const emptyAccolades: WebCuratorAccolades = {
      userId: 'usr-empty',
      username: 'scout_user',
      crownsCount: 0,
      trophies: [],
      laurels: [],
      totalCuratorXp: 20,
    };

    const html = renderToStaticMarkup(
      React.createElement(WebTrophyCabinet, {
        accolades: emptyAccolades,
        locale: 'en',
      }),
    );

    expect(html).toContain('Neighborhood Scout');
    expect(html).toContain('No seasonal trophies yet.');
  });
});
