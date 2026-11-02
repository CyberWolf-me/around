import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  GroupCrawlRoomViewer,
  calculateWebSquadProgress,
  WebGroupCrawlSession,
  WebCrawlStop,
} from '../components/GroupCrawlRoomViewer';

describe('P26-03: GroupCrawlRoomViewer Component & Squad Progress Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const testStops: WebCrawlStop[] = [
    { placeId: 'place_breadly', name: 'Breadly Bakery', nearestSubway: 'Oybek' },
    { placeId: 'place_socials', name: 'Socials Cafe', nearestSubway: 'Oybek' },
    { placeId: 'place_ekler', name: 'Ekler Patisserie', nearestSubway: 'Kosmonavtlar' },
  ];

  const testSession: WebGroupCrawlSession = {
    sessionCode: 'CR-MRB-77',
    routeId: 'mirabad_coffee_crawl',
    routeTitle: 'Mirabad Specialty Coffee Crawl',
    squadBonusXp: 200,
    participants: [
      {
        userId: 'kamila',
        name: 'Kamila',
        avatarInitials: 'KR',
        currentPlaceId: 'place_breadly',
        visitedStopIds: ['place_breadly'],
        isHost: true,
      },
      {
        userId: 'bekzod',
        name: 'Bekzod',
        avatarInitials: 'BA',
        currentPlaceId: 'place_breadly',
        visitedStopIds: ['place_breadly'],
        isHost: false,
      },
    ],
  };

  it('calculateWebSquadProgress computes partial squad progress and active visitors', () => {
    const progress = calculateWebSquadProgress(testSession, testStops);

    expect(progress.totalStops).toBe(3);
    expect(progress.groupCoveredStops).toBe(1);
    expect(progress.percentage).toBe(33);
    expect(progress.isSquadComplete).toBe(false);
    expect(progress.stopVisitorsMap['place_breadly']).toEqual(['Kamila', 'Bekzod']);
  });

  it('calculateWebSquadProgress identifies 100% squad completion', () => {
    const completeSession: WebGroupCrawlSession = {
      ...testSession,
      participants: [
        {
          userId: 'kamila',
          name: 'Kamila',
          avatarInitials: 'KR',
          currentPlaceId: 'place_ekler',
          visitedStopIds: ['place_breadly', 'place_socials', 'place_ekler'],
          isHost: true,
        },
        {
          userId: 'bekzod',
          name: 'Bekzod',
          avatarInitials: 'BA',
          currentPlaceId: 'place_ekler',
          visitedStopIds: ['place_breadly', 'place_socials', 'place_ekler'],
          isHost: false,
        },
      ],
    };

    const progress = calculateWebSquadProgress(completeSession, testStops);
    expect(progress.groupCoveredStops).toBe(3);
    expect(progress.percentage).toBe(100);
    expect(progress.isSquadComplete).toBe(true);
  });

  it('renders GroupCrawlRoomViewer to static markup with session code and stop radar', () => {
    const html = renderToStaticMarkup(
      React.createElement(GroupCrawlRoomViewer, {
        session: testSession,
        stops: testStops,
        currentUserId: 'bekzod',
        language: 'en',
      })
    );

    expect(html).toContain('SQUAD CRAWL LIVE RADAR');
    expect(html).toContain('CR-MRB-77');
    expect(html).toContain('+200 XP Squad');
    expect(html).toContain('Mirabad Specialty Coffee Crawl');
    expect(html).toContain('33%');
    expect(html).toContain('Breadly Bakery');
    expect(html).toContain('Socials Cafe');
    expect(html).toContain('Ekler Patisserie');
    expect(html).toContain('Kamila');
    expect(html).toContain('Bekzod');
  });

  it('renders Uzbek and Russian localizations in GroupCrawlRoomViewer', () => {
    const htmlUz = renderToStaticMarkup(
      React.createElement(GroupCrawlRoomViewer, {
        session: testSession,
        stops: testStops,
        language: 'uz',
      })
    );
    expect(htmlUz).toContain('GURUH SAYRI JONLI MAYDONI');
    expect(htmlUz).toContain('Belgilanish');

    const htmlRu = renderToStaticMarkup(
      React.createElement(GroupCrawlRoomViewer, {
        session: testSession,
        stops: testStops,
        language: 'ru',
      })
    );
    expect(htmlRu).toContain('ГРУППОВОЙ МАРШРУТ ОНЛАЙН');
    expect(htmlRu).toContain('Отметиться');
  });
});
