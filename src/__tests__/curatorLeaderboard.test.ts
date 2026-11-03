import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import React from 'react';
import { renderToString } from 'react-dom/server';
import {
  CuratorLeaderboard,
  DISTRICT_TABS,
  CuratorLeaderboardEntry,
} from '../components/CuratorLeaderboard';
import * as soundEffects from '../services/soundEffects';

describe('P20-03: Web Companion District Crown Leaderboard & Local Legend Showcase', () => {
  beforeEach(() => {
    vi.spyOn(soundEffects, 'playSoundWithHaptic').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders all district tabs properly', () => {
    const html = renderToString(React.createElement(CuratorLeaderboard));
    
    for (const tab of DISTRICT_TABS) {
      expect(html).toContain(tab);
    }
  });

  it('renders overall leaderboard sorted by drops count descending when district is All', () => {
    const html = renderToString(
      React.createElement(CuratorLeaderboard, { initialDistrict: 'All' })
    );

    // Top curator across Tashkent should have the crown spotlight
    expect(html).toContain('Tashkent Legend');
    expect(html).toContain('Kamila Rahimova');
    expect(html).toContain('32 verified drops');
    expect(html).toContain('🔥 6 wk streak');
  });

  it('filters curators by Mirabad district and displays Mirabad Crown Holder', () => {
    const html = renderToString(
      React.createElement(CuratorLeaderboard, { initialDistrict: 'Mirabad' })
    );

    expect(html).toContain('Mirabad Crown Holder');
    expect(html).toContain('Kamila Rahimova');
    expect(html).toContain('Yusuf Okonjo');
    expect(html).toContain('Diyor Usmanov');

    // Yunusabad and Yakkasaray curators must not appear in Mirabad list
    expect(html).not.toContain('Aziza Tursunova');
    expect(html).not.toContain('Bekzod Alimov');
  });

  it('filters curators by Central Tashkent district', () => {
    const html = renderToString(
      React.createElement(CuratorLeaderboard, { initialDistrict: 'Central Tashkent' })
    );

    expect(html).toContain('Central Tashkent Crown Holder');
    expect(html).toContain('Madina Karimova');
    expect(html).toContain('Rustam Saidov');
    expect(html).not.toContain('Kamila Rahimova');
  });

  it('filters curators by Yakkasaray district', () => {
    const html = renderToString(
      React.createElement(CuratorLeaderboard, { initialDistrict: 'Yakkasaray' })
    );

    expect(html).toContain('Yakkasaray Crown Holder');
    expect(html).toContain('Bekzod Alimov');
    expect(html).toContain('18 drops');
    expect(html).not.toContain('Madina Karimova');
  });

  it('renders crown badges, drop counts, and discovery streak flairs accurately', () => {
    const customCurators: CuratorLeaderboardEntry[] = [
      {
        id: 'curator_1',
        name: 'Nilufar Saidova',
        handle: 'nilufar_s',
        district: 'Mirabad',
        dropsCount: 42,
        streakWeeks: 10,
        archetype: 'Specialty Connoisseur',
        avatarBg: '#FF5A1F',
        initials: 'NS',
      },
      {
        id: 'curator_2',
        name: 'Otabek Mirzayev',
        handle: 'otabek_m',
        district: 'Mirabad',
        dropsCount: 20,
        streakWeeks: 3,
        archetype: 'Urban Culturist',
        avatarBg: '#FFE07A',
        initials: 'OM',
      },
    ];

    const html = renderToString(
      React.createElement(CuratorLeaderboard, {
        curators: customCurators,
        initialDistrict: 'Mirabad',
      })
    );

    expect(html).toContain('Nilufar Saidova');
    expect(html).toContain('👑 Mirabad Crown Holder');
    expect(html).toContain('42 verified drops');
    expect(html).toContain('🔥 10 wk streak');
    expect(html).toContain('Otabek Mirzayev');
    expect(html).toContain('20 drops');
    expect(html).toContain('🔥 3w');
  });

  it('displays empty state when district has no matching curators', () => {
    const html = renderToString(
      React.createElement(CuratorLeaderboard, {
        curators: [],
        initialDistrict: 'Old City',
      })
    );

    expect(html).toContain('No curators found for Old City. Be the first to drop a spot!');
  });
});
