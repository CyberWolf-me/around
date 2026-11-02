import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  DistrictCoverageMeter,
  calculateWebDistrictCoverage,
  TASHKENT_CATALOG_PLACES,
  getStatusBadge,
} from '../components/DistrictCoverageMeter';

describe('P24-03: DistrictCoverageMeter Component & Calculation Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('calculateWebDistrictCoverage accurately aggregates 0 visits', () => {
    const summary = calculateWebDistrictCoverage([], TASHKENT_CATALOG_PLACES, 'en');

    expect(summary.totalVisited).toBe(0);
    expect(summary.totalPlaces).toBe(12);
    expect(summary.overallPercentage).toBe(0);
    expect(summary.overallFraction).toBe(0.0);
    expect(summary.districts.length).toBe(5);

    for (const d of summary.districts) {
      expect(d.visitedCount).toBe(0);
      expect(d.statusLevel).toBe('unexplored');
      expect(d.statusBadge).toBe('🌱 Unexplored');
    }

    expect(summary.leastExplored).not.toBeNull();
    expect(summary.recommendedSpot).not.toBeNull();
  });

  it('calculateWebDistrictCoverage computes mastered district when visits >= 60%', () => {
    // Mirabad has 3 places: place_breadly, place_socials, place_ekler
    const summary = calculateWebDistrictCoverage(
      ['place_breadly', 'place_socials'], // 2 out of 3 = 67%
      TASHKENT_CATALOG_PLACES,
      'en'
    );

    const mirabad = summary.districts.find((d) => d.district === 'Mirabad');
    expect(mirabad).toBeDefined();
    expect(mirabad?.visitedCount).toBe(2);
    expect(mirabad?.totalPlaces).toBe(3);
    expect(mirabad?.coveragePercent).toBe(67);
    expect(mirabad?.statusLevel).toBe('mastered');
    expect(mirabad?.statusBadge).toBe('👑 Mastered');

    expect(summary.mostExplored?.district).toBe('Mirabad');
  });

  it('correctly picks least explored district for recommended spot', () => {
    // Visit all Mirabad and Central Tashkent spots
    const summary = calculateWebDistrictCoverage(
      [
        'place_breadly',
        'place_socials',
        'place_ekler',
        'place_tims',
        'place_afsona',
        'place_dodo',
      ],
      TASHKENT_CATALOG_PLACES,
      'en'
    );

    // Least explored should be one of Yakkasaray, Old City, or Yunusabad (all 0%)
    expect(summary.leastExplored?.coveragePercent).toBe(0);
    expect(summary.recommendedSpot).not.toBeNull();
    expect(
      ['Yakkasaray', 'Old City', 'Yunusabad'].includes(
        summary.recommendedSpot!.district
      )
    ).toBe(true);
  });

  it('translates status badges and strings across Uzbek and Russian', () => {
    expect(getStatusBadge('mastered', 'uz')).toBe('👑 O‘zlashtirilgan');
    expect(getStatusBadge('discovering', 'uz')).toBe('🧭 O‘rganilmoqda');
    expect(getStatusBadge('unexplored', 'uz')).toBe('🌱 O‘rganilmagan');

    expect(getStatusBadge('mastered', 'ru')).toBe('👑 Освоено');
    expect(getStatusBadge('discovering', 'ru')).toBe('🧭 Исследуется');
    expect(getStatusBadge('unexplored', 'ru')).toBe('🌱 Не исследовано');

    const summaryUz = calculateWebDistrictCoverage(
      ['place_breadly'],
      TASHKENT_CATALOG_PLACES,
      'uz'
    );
    const mirabadUz = summaryUz.districts.find((d) => d.district === 'Mirabad');
    expect(mirabadUz?.statusBadge).toBe('🧭 O‘rganilmoqda');
  });

  it('renders DistrictCoverageMeter component to static markup cleanly', () => {
    const summary = calculateWebDistrictCoverage(
      ['place_breadly', 'place_socials'],
      TASHKENT_CATALOG_PLACES,
      'en'
    );

    const html = renderToStaticMarkup(
      React.createElement(DistrictCoverageMeter, {
        summary,
        selectedDistrict: 'Mirabad',
        language: 'en',
      })
    );

    expect(html).toContain('TASHKENT EXPLORATION HEAT');
    expect(html).toContain('Mirabad');
    expect(html).toContain('Central Tashkent');
    expect(html).toContain('Yakkasaray');
    expect(html).toContain('Old City');
    expect(html).toContain('Yunusabad');
    expect(html).toContain('17% of Tashkent Explored');
    expect(html).toContain('👑 Mastered');
    expect(html).toContain('Explore Spot');
  });

  it('renders Uzbek and Russian UI headers in DistrictCoverageMeter component', () => {
    const htmlUz = renderToStaticMarkup(
      React.createElement(DistrictCoverageMeter, {
        visitedPlaceIds: ['place_breadly'],
        language: 'uz',
      })
    );
    expect(htmlUz).toContain('TOSHKENT KASHFIYOT XARITASI');
    expect(htmlUz).toContain('Joyni Ko‘rish');

    const htmlRu = renderToStaticMarkup(
      React.createElement(DistrictCoverageMeter, {
        visitedPlaceIds: ['place_breadly'],
        language: 'ru',
      })
    );
    expect(htmlRu).toContain('ТЕПЛОВАЯ КАРТА ТАШКЕНТА');
    expect(htmlRu).toContain('Посмотреть');
  });
});
