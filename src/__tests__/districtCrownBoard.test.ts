import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  DistrictCrownBoard,
  computeWebDistrictPodium,
  formatWebDistrictTitle,
  formatWebCuratorRankLabel,
  WebDistrictCurator,
  TASHKENT_DISTRICTS,
} from '../components/DistrictCrownBoard';

describe('P33-03: DistrictCrownBoard Component & Calculations Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const mockStandings: WebDistrictCurator[] = [
    {
      userId: 'u1',
      username: '@jasur_brew',
      fullName: 'Jasur Aliyev',
      rank: 0,
      district: 'Mirabad',
      seasonXp: 1250,
      placesCount: 8,
      crownsCount: 2,
    },
    {
      userId: 'u2',
      username: '@kamila_tashkent',
      fullName: 'Kamila Karimova',
      rank: 0,
      district: 'Mirabad',
      seasonXp: 980,
      placesCount: 6,
      crownsCount: 3, // higher crowns count -> should be #1!
    },
    {
      userId: 'u3',
      username: '@nodir_walks',
      fullName: 'Nodir Usmanov',
      rank: 0,
      district: 'Mirabad',
      seasonXp: 720,
      placesCount: 5,
      crownsCount: 0,
    },
    {
      userId: 'u4',
      username: '@diana_art',
      fullName: 'Diana Lee',
      rank: 0,
      district: 'Mirabad',
      seasonXp: 610,
      placesCount: 4,
      crownsCount: 0,
    },
  ];

  it('computes district podium rankings by crowns, season XP, and places visited', () => {
    const podium = computeWebDistrictPodium(mockStandings, 'Mirabad', '2026-11');

    expect(podium.totalCuratorsCount).toBe(4);
    // Kamila has 3 crowns -> #1 Champion
    expect(podium.champion).toBeDefined();
    expect(podium.champion?.username).toBe('@kamila_tashkent');
    expect(podium.champion?.rank).toBe(1);
    expect(podium.champion?.gapToLeaderXp).toBe(0);

    // Jasur has 2 crowns -> #2 Silver
    expect(podium.silver).toBeDefined();
    expect(podium.silver?.username).toBe('@jasur_brew');
    expect(podium.silver?.rank).toBe(2);

    // Nodir -> #3 Bronze
    expect(podium.bronze).toBeDefined();
    expect(podium.bronze?.username).toBe('@nodir_walks');
    expect(podium.bronze?.rank).toBe(3);

    // Diana -> Runner-up
    expect(podium.runnersUp).toHaveLength(1);
    expect(podium.runnersUp[0].username).toBe('@diana_art');
    expect(podium.runnersUp[0].rank).toBe(4);
  });

  it('handles empty standings without throwing', () => {
    const podium = computeWebDistrictPodium([], 'Chilanzar', '2026-11');
    expect(podium.totalCuratorsCount).toBe(0);
    expect(podium.champion).toBeUndefined();
    expect(podium.silver).toBeUndefined();
    expect(podium.bronze).toBeUndefined();
    expect(podium.runnersUp).toHaveLength(0);
  });

  it('formats localized district titles properly', () => {
    expect(formatWebDistrictTitle('Mirabad', 'en')).toBe('Mirabad District');
    expect(formatWebDistrictTitle('Yakkasaray', 'uz')).toBe('Yakkasaray tumani');
    expect(formatWebDistrictTitle('Chilanzar', 'ru')).toBe('Chilanzar район');
  });

  it('formats curator rank labels with honorific medals', () => {
    expect(formatWebCuratorRankLabel(1, 'en')).toBe('👑 Champion Crown');
    expect(formatWebCuratorRankLabel(2, 'uz')).toBe('🥈 Kumush Shon-Sharaf');
    expect(formatWebCuratorRankLabel(3, 'ru')).toBe('🥉 Бронзовый Лавр');
    expect(formatWebCuratorRankLabel(4, 'en')).toBe('#4');
  });

  it('renders static markup for empty district board with Open placeholders', () => {
    const html = renderToStaticMarkup(
      React.createElement(DistrictCrownBoard, {
        initialDistrict: 'Yunusabad',
        locale: 'en',
      }),
    );

    expect(html).toContain('Yunusabad District');
    expect(html).toContain('0 Curators');
    expect(html).toContain('Open');
    expect(html).toContain('#1');
    expect(html).toContain('#2');
    expect(html).toContain('#3');
  });

  it('renders static markup for populated board with podium and runners-up', () => {
    const html = renderToStaticMarkup(
      React.createElement(DistrictCrownBoard, {
        initialDistrict: 'Mirabad',
        standingsByDistrict: {
          Mirabad: mockStandings,
        },
        locale: 'en',
      }),
    );

    expect(html).toContain('Mirabad District');
    expect(html).toContain('4 Curators');
    expect(html).toContain('@kamila_tashkent');
    expect(html).toContain('@jasur_brew');
    expect(html).toContain('@nodir_walks');
    expect(html).toContain('Contenders &amp; Runners-up');
    expect(html).toContain('Diana Lee');
    expect(html).toContain('610 XP');
  });

  it('contains all 11 Tashkent districts in selector options', () => {
    const html = renderToStaticMarkup(
      React.createElement(DistrictCrownBoard, {
        initialDistrict: 'Mirabad',
      }),
    );

    for (const district of TASHKENT_DISTRICTS) {
      expect(html).toContain(district);
    }
  });
});
