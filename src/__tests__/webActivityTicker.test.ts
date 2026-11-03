import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  WebActivityTicker,
  getWebActivityEmoji,
  formatWebRelativeTime,
  formatWebEventTitle,
  WebActivityEvent,
} from '../components/WebActivityTicker';

describe('P34-03: WebActivityTicker Web Component & Helpers Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const fixedNow = new Date('2026-11-03T14:00:00Z');

  const mockEvents: WebActivityEvent[] = [
    {
      id: 'e1',
      type: 'dropCreated',
      userId: 'u1',
      username: '@kamila',
      userFullName: 'Kamila K',
      district: 'Mirabad',
      placeName: 'Breadly Bakery',
      timestamp: '2026-11-03T13:58:00Z', // 2m ago
    },
    {
      id: 'e2',
      type: 'routeCompleted',
      userId: 'u2',
      username: '@jasur',
      userFullName: 'Jasur A',
      district: 'Chilanzar',
      routeName: 'Chorsu Heritage Route',
      xpAwarded: 50,
      timestamp: '2026-11-03T13:30:00Z', // 30m ago
    },
    {
      id: 'e3',
      type: 'crownOvertake',
      userId: 'u3',
      username: '@nodir',
      userFullName: 'Nodir U',
      district: 'Mirabad',
      timestamp: '2026-11-03T11:00:00Z', // 3h ago
    },
  ];

  it('maps activity types to distinct emojis', () => {
    expect(getWebActivityEmoji('dropCreated')).toBe('📸');
    expect(getWebActivityEmoji('routeCompleted')).toBe('🚶');
    expect(getWebActivityEmoji('crownOvertake')).toBe('👑');
    expect(getWebActivityEmoji('badgeUnlocked')).toBe('🎖️');
    expect(getWebActivityEmoji('placeVisited')).toBe('📍');
  });

  it('formats relative timestamps accurately across EN, UZ, and RU', () => {
    // Just now (< 45s)
    const justNowIso = new Date('2026-11-03T13:59:40Z').toISOString();
    expect(formatWebRelativeTime(justNowIso, 'en', fixedNow)).toBe('Just now');
    expect(formatWebRelativeTime(justNowIso, 'uz', fixedNow)).toBe('Hozirgina');
    expect(formatWebRelativeTime(justNowIso, 'ru', fixedNow)).toBe('Только что');

    // 15m ago
    const minsIso = new Date('2026-11-03T13:45:00Z').toISOString();
    expect(formatWebRelativeTime(minsIso, 'en', fixedNow)).toBe('15m ago');
    expect(formatWebRelativeTime(minsIso, 'uz', fixedNow)).toBe('15 daq. oldin');
    expect(formatWebRelativeTime(minsIso, 'ru', fixedNow)).toBe('15 мин. назад');

    // 4h ago
    const hoursIso = new Date('2026-11-03T10:00:00Z').toISOString();
    expect(formatWebRelativeTime(hoursIso, 'en', fixedNow)).toBe('4h ago');
    expect(formatWebRelativeTime(hoursIso, 'uz', fixedNow)).toBe('4 soat oldin');
    expect(formatWebRelativeTime(hoursIso, 'ru', fixedNow)).toBe('4 ч. назад');

    // Yesterday
    const yesterdayIso = new Date('2026-11-02T10:00:00Z').toISOString();
    expect(formatWebRelativeTime(yesterdayIso, 'en', fixedNow)).toBe('Yesterday');
    expect(formatWebRelativeTime(yesterdayIso, 'uz', fixedNow)).toBe('Kecha');
    expect(formatWebRelativeTime(yesterdayIso, 'ru', fixedNow)).toBe('Вчера');
  });

  it('formats localized event descriptions cleanly', () => {
    // Drop created
    expect(formatWebEventTitle(mockEvents[0], 'en')).toBe(
      '@kamila shared a new Drop at Breadly Bakery',
    );
    expect(formatWebEventTitle(mockEvents[0], 'uz')).toBe(
      '@kamila Breadly Bakery da yangi Drop qoldirdi',
    );
    expect(formatWebEventTitle(mockEvents[0], 'ru')).toBe(
      '@kamila оставил(а) новый Дроп в Breadly Bakery',
    );

    // Route completed
    expect(formatWebEventTitle(mockEvents[1], 'en')).toBe(
      '@jasur completed "Chorsu Heritage Route" (+50 XP)',
    );

    // Crown overtake
    expect(formatWebEventTitle(mockEvents[2], 'en')).toBe(
      '@nodir took the #1 Crown in Mirabad!',
    );
  });

  it('renders static markup for empty state cleanly', () => {
    const htmlEn = renderToStaticMarkup(
      React.createElement(WebActivityTicker, {
        events: [],
        locale: 'en',
      }),
    );
    expect(htmlEn).toContain('LIVE');
    expect(htmlEn).toContain('Quiet across Tashkent');

    const htmlUz = renderToStaticMarkup(
      React.createElement(WebActivityTicker, {
        events: [],
        locale: 'uz',
      }),
    );
    expect(htmlUz).toContain('JONLI');
    expect(htmlUz).toContain('Toshkentda hozircha sokin');
  });

  it('renders populated ticker events and respects district filtering', () => {
    // Unfiltered: all 3 events
    const htmlAll = renderToStaticMarkup(
      React.createElement(WebActivityTicker, {
        events: mockEvents,
        locale: 'en',
      }),
    );
    expect(htmlAll).toContain('@kamila');
    expect(htmlAll).toContain('@jasur');
    expect(htmlAll).toContain('@nodir');

    // Filtered by Mirabad: only kamila and nodir
    const htmlMirabad = renderToStaticMarkup(
      React.createElement(WebActivityTicker, {
        events: mockEvents,
        districtFilter: 'Mirabad',
        locale: 'en',
      }),
    );
    expect(htmlMirabad).toContain('@kamila');
    expect(htmlMirabad).not.toContain('@jasur');
    expect(htmlMirabad).toContain('@nodir');
  });
});
