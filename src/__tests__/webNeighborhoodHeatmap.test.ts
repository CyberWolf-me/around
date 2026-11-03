import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  WebNeighborhoodHeatmap,
  getWebClusterIntensity,
  getWebClusterColor,
  getWebClusterEmoji,
  formatWebClusterSummary,
  WebNeighborhoodCluster,
} from '../components/WebNeighborhoodHeatmap';

describe('P37-03: WebNeighborhoodHeatmap Component & Helpers Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  const mockClusters: WebNeighborhoodCluster[] = [
    {
      id: 'c-breadly',
      district: 'Mirabad',
      centroidLat: 41.3111,
      centroidLng: 69.2405,
      dropsCount: 8,
      intensity: 'buzzing',
      primaryVenueName: 'Breadly Bakery',
      venueNames: ['Breadly Bakery', 'Ecocafe'],
    },
    {
      id: 'c-chorsu',
      district: 'Shaikhontokhur',
      centroidLat: 41.3275,
      centroidLng: 69.234,
      dropsCount: 14,
      intensity: 'peak',
      primaryVenueName: 'Chorsu Bazaar',
      venueNames: ['Chorsu Bazaar', 'Kukeldash'],
    },
    {
      id: 'c-park',
      district: 'Yakkasaray',
      centroidLat: 41.305,
      centroidLng: 69.25,
      dropsCount: 2,
      intensity: 'serene',
      primaryVenueName: 'Courtyard Park',
      venueNames: ['Courtyard Park'],
    },
  ];

  it('evaluates cluster intensity levels accurately', () => {
    expect(getWebClusterIntensity(1)).toBe('serene');
    expect(getWebClusterIntensity(2)).toBe('serene');
    expect(getWebClusterIntensity(3)).toBe('lively');
    expect(getWebClusterIntensity(5)).toBe('lively');
    expect(getWebClusterIntensity(6)).toBe('buzzing');
    expect(getWebClusterIntensity(10)).toBe('buzzing');
    expect(getWebClusterIntensity(11)).toBe('peak');
    expect(getWebClusterIntensity(20)).toBe('peak');
  });

  it('maps intensities to color codes and emojis', () => {
    expect(getWebClusterColor('serene')).toBe('#10b981');
    expect(getWebClusterColor('peak')).toBe('#ef4444');

    expect(getWebClusterEmoji('serene')).toBe('🍃');
    expect(getWebClusterEmoji('lively')).toBe('✨');
    expect(getWebClusterEmoji('buzzing')).toBe('🔥');
    expect(getWebClusterEmoji('peak')).toBe('⚡');
  });

  it('formats localized summaries across EN, UZ, and RU', () => {
    const cluster = mockClusters[0];

    expect(formatWebClusterSummary(cluster, 'en')).toBe(
      '8 drops across Breadly Bakery & nearby',
    );
    expect(formatWebClusterSummary(cluster, 'uz')).toBe(
      'Breadly Bakery va yaqinida 8 ta drop',
    );
    expect(formatWebClusterSummary(cluster, 'ru')).toBe(
      '8 дроп(ов) в районе Breadly Bakery и рядом',
    );
  });

  it('renders static markup for empty state cleanly', () => {
    const html = renderToStaticMarkup(
      React.createElement(WebNeighborhoodHeatmap, {
        clusters: [],
        selectedDistrict: 'Chilanzar',
        locale: 'en',
      }),
    );

    expect(html).toContain('Neighborhood Heatmap');
    expect(html).toContain('No activity clusters in this district');
  });

  it('renders populated cluster cards and respects district filter', () => {
    // Unfiltered: all 3 clusters
    const htmlAll = renderToStaticMarkup(
      React.createElement(WebNeighborhoodHeatmap, {
        clusters: mockClusters,
        selectedDistrict: 'all',
        locale: 'en',
      }),
    );

    expect(htmlAll).toContain('Breadly Bakery');
    expect(htmlAll).toContain('Chorsu Bazaar');
    expect(htmlAll).toContain('Courtyard Park');
    expect(htmlAll).toContain('3 active clusters');

    // Filtered by Mirabad: only Breadly
    const htmlMirabad = renderToStaticMarkup(
      React.createElement(WebNeighborhoodHeatmap, {
        clusters: mockClusters,
        selectedDistrict: 'Mirabad',
        locale: 'en',
      }),
    );

    expect(htmlMirabad).toContain('Breadly Bakery');
    expect(htmlMirabad).not.toContain('Chorsu Bazaar');
    expect(htmlMirabad).toContain('1 active clusters');
  });
});
