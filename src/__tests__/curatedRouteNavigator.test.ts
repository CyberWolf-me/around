import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  CuratedRouteNavigator,
  DEFAULT_WEB_ROUTES,
  getLocalizedRouteTitle,
  calculateWebRouteProgress,
} from '../components/CuratedRouteNavigator';

describe('P25-03: CuratedRouteNavigator Component & Route Calculation Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('DEFAULT_WEB_ROUTES contains at least 3 curated routes with transit stops', () => {
    expect(DEFAULT_WEB_ROUTES.length).toBeGreaterThanOrEqual(3);

    for (const r of DEFAULT_WEB_ROUTES) {
      expect(r.id).toBeTruthy();
      expect(r.title).toBeTruthy();
      expect(r.district).toBeTruthy();
      expect(r.stops.length).toBeGreaterThan(0);
      expect(r.totalMinutes).toBeGreaterThan(0);
      expect(r.distanceMeters).toBeGreaterThan(0);
      expect(r.startSubway).toBeTruthy();
      expect(r.endSubway).toBeTruthy();
    }
  });

  it('getLocalizedRouteTitle translates accurately across languages', () => {
    const route = DEFAULT_WEB_ROUTES[0]; // Mirabad Specialty Coffee Crawl

    expect(getLocalizedRouteTitle(route, 'uz')).toBe('Mirobod Qahva Sayri');
    expect(getLocalizedRouteTitle(route, 'ru')).toBe('Кофейный маршрут по Мирабаду');
    expect(getLocalizedRouteTitle(route, 'en')).toBe('Mirabad Specialty Coffee Crawl');
  });

  it('calculateWebRouteProgress computes 0%, partial, and completed progress', () => {
    const route = DEFAULT_WEB_ROUTES[0]; // 3 stops: breadly, socials, ekler

    // 0%
    const pZero = calculateWebRouteProgress(route, []);
    expect(pZero.completedStops).toBe(0);
    expect(pZero.percentage).toBe(0);
    expect(pZero.isCompleted).toBe(false);
    expect(pZero.nextPendingStop?.placeId).toBe('place_breadly');

    // Partial (1 stop = 33%)
    const pPartial = calculateWebRouteProgress(route, ['place_breadly']);
    expect(pPartial.completedStops).toBe(1);
    expect(pPartial.percentage).toBe(33);
    expect(pPartial.isCompleted).toBe(false);
    expect(pPartial.nextPendingStop?.placeId).toBe('place_socials');

    // Completed (3 stops = 100%)
    const pComplete = calculateWebRouteProgress(route, [
      'place_breadly',
      'place_socials',
      'place_ekler',
    ]);
    expect(pComplete.completedStops).toBe(3);
    expect(pComplete.percentage).toBe(100);
    expect(pComplete.isCompleted).toBe(true);
    expect(pComplete.nextPendingStop).toBeNull();
  });

  it('renders CuratedRouteNavigator component to static markup cleanly', () => {
    const route = DEFAULT_WEB_ROUTES[0];
    const html = renderToStaticMarkup(
      React.createElement(CuratedRouteNavigator, {
        route,
        visitedPlaceIds: ['place_breadly'],
        language: 'en',
      })
    );

    expect(html).toContain('CURATED TASHKENT WALKING CRAWLS');
    expect(html).toContain('Mirabad Specialty Coffee Crawl');
    expect(html).toContain('Breadly Bakery &amp; Café');
    expect(html).toContain('Socials Coffee Hub');
    expect(html).toContain('Ekler Patisserie');
    expect(html).toContain('+150 XP');
    expect(html).toContain('1/3 visited');
    expect(html).toContain('33%');
    expect(html).toContain('Start Crawl');
  });

  it('renders completed state in CuratedRouteNavigator', () => {
    const route = DEFAULT_WEB_ROUTES[0];
    const html = renderToStaticMarkup(
      React.createElement(CuratedRouteNavigator, {
        route,
        visitedPlaceIds: ['place_breadly', 'place_socials', 'place_ekler'],
        language: 'en',
      })
    );

    expect(html).toContain('3/3 visited');
    expect(html).toContain('100%');
    expect(html).toContain('Route Completed 🏆');
  });

  it('renders Uzbek and Russian localizations in CuratedRouteNavigator', () => {
    const htmlUz = renderToStaticMarkup(
      React.createElement(CuratedRouteNavigator, {
        language: 'uz',
      })
    );
    expect(htmlUz).toContain('TOSHKENTNING SARALANGAN SAYRLARI');
    expect(htmlUz).toContain('Sayrni Boshlash');

    const htmlRu = renderToStaticMarkup(
      React.createElement(CuratedRouteNavigator, {
        language: 'ru',
      })
    );
    expect(htmlRu).toContain('КУРИРОВАННЫЕ МАРШРУТЫ ТАШКЕНТА');
    expect(htmlRu).toContain('Начать маршрут');
  });
});
