import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  SeasonHallOfFame,
  filterHallOfFameEntries,
  WebHallOfFameEntry,
} from '../components/SeasonHallOfFame';

describe('P30-03: SeasonHallOfFame Web Component & Filtering Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const testEntries: WebHallOfFameEntry[] = [
    {
      userId: 'user_kamila',
      username: 'kamila_tashkent',
      displayName: 'Kamila Rahimova',
      district: 'Mirabad',
      seasonId: '2026-10',
      rank: 1,
      seasonXp: 1850,
      placesCount: 24,
      laurel: 'champion',
    },
    {
      userId: 'user_bekzod',
      username: 'bekzod_art',
      displayName: 'Bekzod Aliev',
      district: 'Mirabad',
      seasonId: '2026-10',
      rank: 2,
      seasonXp: 1420,
      placesCount: 19,
      laurel: 'podium',
    },
    {
      userId: 'user_jasur',
      username: 'jasur_coffee',
      displayName: 'Jasur Umarov',
      district: 'Mirabad',
      seasonId: '2026-10',
      rank: 3,
      seasonXp: 1100,
      placesCount: 15,
      laurel: 'podium',
    },
    {
      userId: 'user_dilnoza',
      username: 'dilnoza_m',
      displayName: 'Dilnoza Karimova',
      district: 'Mirabad',
      seasonId: '2026-10',
      rank: 4,
      seasonXp: 850,
      placesCount: 12,
      laurel: 'topTen',
    },
    {
      userId: 'user_sardor',
      username: 'sardor_yakkasaray',
      displayName: 'Sardor Qodirov',
      district: 'Yakkasaray',
      seasonId: '2026-09',
      rank: 1,
      seasonXp: 1200,
      placesCount: 16,
      laurel: 'champion',
    },
  ];

  it('filterHallOfFameEntries filters by seasonId and district and sorts by rank', () => {
    // Mirabad 2026-10
    const filtered = filterHallOfFameEntries(testEntries, '2026-10', 'Mirabad');
    expect(filtered.length).toBe(4);
    expect(filtered[0].username).toBe('kamila_tashkent');
    expect(filtered[1].username).toBe('bekzod_art');
    expect(filtered[2].username).toBe('jasur_coffee');
    expect(filtered[3].username).toBe('dilnoza_m');

    // All districts 2026-10
    const allDistricts = filterHallOfFameEntries(testEntries, '2026-10', 'all');
    expect(allDistricts.length).toBe(4);

    // Yakkasaray 2026-09
    const yakkasaray = filterHallOfFameEntries(testEntries, '2026-09', 'Yakkasaray');
    expect(yakkasaray.length).toBe(1);
    expect(yakkasaray[0].displayName).toBe('Sardor Qodirov');
  });

  it('renders SeasonHallOfFame with header, podium cards, and runner-ups', () => {
    const html = renderToStaticMarkup(
      React.createElement(SeasonHallOfFame, {
        entries: testEntries,
        language: 'en',
      })
    );

    expect(html).toContain('Tashkent Hall of Fame');
    expect(html).toContain('Historical season champions');
    expect(html).toContain('Kamila Rahimova');
    expect(html).toContain('@kamila_tashkent');
    expect(html).toContain('1850 XP');
    expect(html).toContain('Bekzod Aliev');
    expect(html).toContain('Jasur Umarov');
    expect(html).toContain('Dilnoza Karimova');
    expect(html).toContain('#4');
  });

  it('renders empty state when no entries match filter', () => {
    const html = renderToStaticMarkup(
      React.createElement(SeasonHallOfFame, {
        entries: [],
        language: 'en',
      })
    );

    expect(html).toContain('No entries found for selected filter');
  });

  it('supports Uzbek and Russian localizations correctly', () => {
    const uzHtml = renderToStaticMarkup(
      React.createElement(SeasonHallOfFame, {
        entries: testEntries,
        language: 'uz',
      })
    );
    expect(uzHtml).toContain('Toshkent Shon-Sharaf Zali');
    expect(uzHtml).toContain('Barcha Tumanlar');

    const ruHtml = renderToStaticMarkup(
      React.createElement(SeasonHallOfFame, {
        entries: testEntries,
        language: 'ru',
      })
    );
    expect(ruHtml).toContain('Зал Славы Ташкента');
    expect(ruHtml).toContain('Все Районы');
  });
});
