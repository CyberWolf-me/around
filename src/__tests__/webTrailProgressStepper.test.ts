import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  WebTrailProgressStepper,
  computeWebTrailProgress,
  formatWebTrailProgressTitle,
  WebRouteWaypoint,
} from '../components/WebTrailProgressStepper';

describe('P35-03: WebTrailProgressStepper Component & Helpers Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const mockWaypoints: WebRouteWaypoint[] = [
    {
      id: 'wp-1',
      routeId: 'rt-chorsu',
      placeId: 'pl-1',
      placeName: 'Chorsu Dome',
      orderIndex: 0,
      category: 'Heritage',
      hint: 'Blue dome bazaar',
      xpAwarded: 20,
    },
    {
      id: 'wp-2',
      routeId: 'rt-chorsu',
      placeId: 'pl-2',
      placeName: 'Kukeldash Madrasah',
      orderIndex: 1,
      category: 'Architecture',
      hint: 'Historic portal',
      xpAwarded: 25,
    },
    {
      id: 'wp-3',
      routeId: 'rt-chorsu',
      placeId: 'pl-3',
      placeName: 'Chaikhana Samarkand',
      orderIndex: 2,
      category: 'Tea House',
      hint: 'Green tea tapchan',
      xpAwarded: 15,
    },
  ];

  it('computes partial trail progress and next target checkpoint', () => {
    const summary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1']),
      50,
    );

    expect(summary.totalWaypointsCount).toBe(3);
    expect(summary.visitedWaypointsCount).toBe(1);
    expect(summary.completionPercentage).toBeCloseTo(0.333, 2);
    expect(summary.isCompleted).toBe(false);
    expect(summary.totalXpEarned).toBe(20);
    expect(summary.nextTargetWaypoint).toBeDefined();
    expect(summary.nextTargetWaypoint?.id).toBe('wp-2');
  });

  it('awards completion bonus when all checkpoints are visited', () => {
    const summary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1', 'pl-2', 'pl-3']),
      50,
    );

    expect(summary.visitedWaypointsCount).toBe(3);
    expect(summary.completionPercentage).toBe(1.0);
    expect(summary.isCompleted).toBe(true);
    expect(summary.nextTargetWaypoint).toBeUndefined();
    // 20 + 25 + 15 + 50 (bonus) = 110 XP
    expect(summary.totalXpEarned).toBe(110);
  });

  it('formats localized progress descriptions properly', () => {
    const partialSummary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1']),
    );

    expect(formatWebTrailProgressTitle(partialSummary, 'en')).toBe(
      '1 of 3 stops completed',
    );
    expect(formatWebTrailProgressTitle(partialSummary, 'uz')).toBe(
      '3 tadan 1 ta bekat bajarildi',
    );
    expect(formatWebTrailProgressTitle(partialSummary, 'ru')).toBe(
      'Пройдено 1 из 3 остановок',
    );

    const completedSummary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1', 'pl-2', 'pl-3']),
    );

    expect(formatWebTrailProgressTitle(completedSummary, 'en')).toBe(
      'Route completed! 🏆',
    );
    expect(formatWebTrailProgressTitle(completedSummary, 'uz')).toBe(
      'Marshrut yakunlandi! 🏆',
    );
    expect(formatWebTrailProgressTitle(completedSummary, 'ru')).toBe(
      'Маршрут пройден! 🏆',
    );
  });

  it('renders static markup for partial progress stepper', () => {
    const summary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1']),
    );

    const html = renderToStaticMarkup(
      React.createElement(WebTrailProgressStepper, {
        summary,
        locale: 'en',
      }),
    );

    expect(html).toContain('Chorsu Heritage Trail');
    expect(html).toContain('1 of 3 stops completed');
    expect(html).toContain('+20 XP');
    expect(html).toContain('Chorsu Dome');
    expect(html).toContain('Kukeldash Madrasah');
  });

  it('renders static markup for completed route with celebration callout', () => {
    const summary = computeWebTrailProgress(
      'rt-chorsu',
      'Chorsu Heritage Trail',
      'Shaikhontokhur',
      mockWaypoints,
      new Set(['pl-1', 'pl-2', 'pl-3']),
      50,
    );

    const html = renderToStaticMarkup(
      React.createElement(WebTrailProgressStepper, {
        summary,
        locale: 'en',
      }),
    );

    expect(html).toContain('Route completed! 🏆');
    expect(html).toContain('+110 XP');
    expect(html).toContain('Route Completed! +50 Bonus XP Awarded');
  });
});
