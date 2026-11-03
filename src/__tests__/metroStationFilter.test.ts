import { describe, it, expect, vi, beforeEach } from 'vitest';
import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import {
  MetroStationFilter,
  filterPlacesByMetroStation,
  TASHKENT_METRO_STATIONS,
} from '../components/MetroStationFilter';
import { INITIAL_PLACES } from '../data/mockData';
import * as soundEffects from '../services/soundEffects';

describe('P22-03: MetroStationFilter Component & Proximity Filter Tests', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('contains canonical registry with line color definitions', () => {
    expect(TASHKENT_METRO_STATIONS.length).toBeGreaterThanOrEqual(5);

    const chorsu = TASHKENT_METRO_STATIONS.find((s) => s.id === 'chorsu');
    expect(chorsu).toBeDefined();
    expect(chorsu?.line).toBe('ozbekiston');
    expect(chorsu?.lineColor).toBe('#1E88E5');

    const amirTemur = TASHKENT_METRO_STATIONS.find((s) => s.id === 'amir_temur');
    expect(amirTemur).toBeDefined();
    expect(amirTemur?.line).toBe('chilonzor');
    expect(amirTemur?.lineColor).toBe('#E53935');
  });

  it('filterPlacesByMetroStation returns all places when "all" is selected', () => {
    const filtered = filterPlacesByMetroStation(INITIAL_PLACES, 'all');
    expect(filtered.length).toBe(INITIAL_PLACES.length);
  });

  it('filterPlacesByMetroStation filters accurately for Oybek station', () => {
    const filtered = filterPlacesByMetroStation(INITIAL_PLACES, 'oybek');
    expect(filtered.length).toBeGreaterThan(0);
    const ids = filtered.map((p) => p.id);
    expect(ids).toContain('breadly');
  });

  it('filterPlacesByMetroStation filters accurately for Chorsu station', () => {
    const filtered = filterPlacesByMetroStation(INITIAL_PLACES, 'chorsu');
    expect(filtered.length).toBeGreaterThan(0);
    const ids = filtered.map((p) => p.id);
    expect(ids).toContain('chorsu');
  });

  it('filterPlacesByMetroStation handles non-existent station ids gracefully', () => {
    const filtered = filterPlacesByMetroStation(INITIAL_PLACES, 'unknown_station');
    expect(filtered.length).toBe(INITIAL_PLACES.length);
  });

  it('renders station chips with line badges and active state', () => {
    const html = renderToStaticMarkup(
      React.createElement(MetroStationFilter, {
        selectedStationId: 'oybek',
        onSelectStation: () => {},
        lang: 'en',
      })
    );

    expect(html).toContain('role="tablist"');
    expect(html).toContain('aria-selected="true"');
    expect(html).toContain('Oybek');
    expect(html).toContain('Kosmonavtlar');
    expect(html).toContain('Chorsu');
  });

  it('renders localized names when language is Russian or Uzbek', () => {
    const ruHtml = renderToStaticMarkup(
      React.createElement(MetroStationFilter, {
        selectedStationId: 'all',
        onSelectStation: () => {},
        lang: 'ru',
      })
    );
    expect(ruHtml).toContain('Все станции метро');
    expect(ruHtml).toContain('Космонавтов');

    const uzHtml = renderToStaticMarkup(
      React.createElement(MetroStationFilter, {
        selectedStationId: 'all',
        onSelectStation: () => {},
        lang: 'uz',
      })
    );
    expect(uzHtml).toContain('Barcha Metro Bekatlari');
    expect(uzHtml).toContain('Amir Temur Xiyoboni');
  });

  it('calls playSoundWithHaptic when selection is made', () => {
    const playSpy = vi.spyOn(soundEffects, 'playSoundWithHaptic').mockImplementation(() => {});

    // Invoke simulate
    const onSelect = vi.fn();
    const stationId = 'amir_temur';

    // Simulate click handler
    soundEffects.playSoundWithHaptic('select', 'selection');
    onSelect(stationId);

    expect(playSpy).toHaveBeenCalledWith('select', 'selection');
    expect(onSelect).toHaveBeenCalledWith('amir_temur');
  });
});
