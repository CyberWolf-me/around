import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  SeasonTrophyShowcase,
  calculateWebSeasonMetrics,
  WebCuratorSeason,
} from '../components/SeasonTrophyShowcase';

describe('P28-03: SeasonTrophyShowcase Web Component & Season Metrics Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const testSeason: WebCuratorSeason = {
    seasonId: '2026-11',
    titleEn: 'Autumn in Tashkent',
    titleUz: 'Toshkentda Kuz',
    titleRu: 'Осень в Ташкенте',
    startDate: '2026-11-01',
    endDate: '2026-11-30',
    daysRemaining: 27,
    challenges: [
      {
        id: 'district_explorer',
        titleEn: 'District Pioneer',
        titleUz: 'Tuman Kashfiyotchisi',
        titleRu: 'Первопроходец Районов',
        descriptionEn: 'Discover 3 districts',
        descriptionUz: '3 ta tumanni kashf eting',
        descriptionRu: 'Посетите 3 района',
        icon: '🧭',
        targetCount: 3,
        currentCount: 3,
        xpReward: 200,
      },
      {
        id: 'metro_nomad',
        titleEn: 'Metro Line Nomad',
        titleUz: 'Metro Sayyohi',
        titleRu: 'Кочевник Метрополитена',
        descriptionEn: 'Check in near 3 subway stops',
        descriptionUz: '3 ta metro bekatida boling',
        descriptionRu: 'Отметьтесь около 3 станций',
        icon: '🚇',
        targetCount: 3,
        currentCount: 1,
        xpReward: 150,
      },
      {
        id: 'weekend_rhythm',
        titleEn: 'Weekend Taste Scout',
        titleUz: 'Dam Olish Skauti',
        titleRu: 'Скаут Выходного Дня',
        descriptionEn: 'Drop 2 weekend memories',
        descriptionUz: '2 ta dam olish xotirasi',
        descriptionRu: '2 заметки в выходные',
        icon: '☕',
        targetCount: 2,
        currentCount: 0,
        xpReward: 150,
      },
    ],
  };

  it('calculateWebSeasonMetrics calculates progress, XP, and bronze tier for 1 challenge', () => {
    const metrics = calculateWebSeasonMetrics(testSeason);

    expect(metrics.totalCount).toBe(3);
    expect(metrics.completedCount).toBe(1);
    expect(metrics.overallPercentage).toBe(33);
    expect(metrics.totalXpAvailable).toBe(500);
    expect(metrics.totalXpEarned).toBe(200);
    expect(metrics.earnedTier).toBe('bronze');
  });

  it('calculateWebSeasonMetrics awards gold tier when all 3 challenges completed', () => {
    const allCompletedSeason: WebCuratorSeason = {
      ...testSeason,
      challenges: testSeason.challenges.map((c) => ({ ...c, currentCount: c.targetCount })),
    };

    const metrics = calculateWebSeasonMetrics(allCompletedSeason);
    expect(metrics.completedCount).toBe(3);
    expect(metrics.earnedTier).toBe('gold');
    expect(metrics.totalXpEarned).toBe(500);
  });

  it('calculateWebSeasonMetrics awards no tier when 0 challenges completed', () => {
    const zeroSeason: WebCuratorSeason = {
      ...testSeason,
      challenges: testSeason.challenges.map((c) => ({ ...c, currentCount: 0 })),
    };

    const metrics = calculateWebSeasonMetrics(zeroSeason);
    expect(metrics.completedCount).toBe(0);
    expect(metrics.earnedTier).toBeNull();
  });

  it('renders SeasonTrophyShowcase with season header, days left, and trophy shelf', () => {
    const html = renderToStaticMarkup(
      React.createElement(SeasonTrophyShowcase, {
        season: testSeason,
        language: 'en',
      })
    );

    expect(html).toContain('Autumn in Tashkent');
    expect(html).toContain('2026-11');
    expect(html).toContain('27 days left');
    expect(html).toContain('Seasonal Trophy Shelf');
    expect(html).toContain('BRONZE');
    expect(html).toContain('SILVER');
    expect(html).toContain('GOLD');
    expect(html).toContain('District Pioneer');
    expect(html).toContain('+200 XP');
    expect(html).toContain('+150 XP');
    expect(html).toContain('Claim Trophy');
  });

  it('supports Uzbek and Russian localizations cleanly', () => {
    const uzHtml = renderToStaticMarkup(
      React.createElement(SeasonTrophyShowcase, {
        season: testSeason,
        language: 'uz',
      })
    );
    expect(uzHtml).toContain('Toshkentda Kuz');
    expect(uzHtml).toContain('27 kun qoldi');
    expect(uzHtml).toContain('Mavsumiy Kuboklar');
    expect(uzHtml).toContain('Tuman Kashfiyotchisi');

    const ruHtml = renderToStaticMarkup(
      React.createElement(SeasonTrophyShowcase, {
        season: testSeason,
        language: 'ru',
      })
    );
    expect(ruHtml).toContain('Осень в Ташкенте');
    expect(ruHtml).toContain('Осталось 27 дн.');
    expect(ruHtml).toContain('Сезонные Трофеи');
    expect(ruHtml).toContain('Первопроходец Районов');
  });
});
