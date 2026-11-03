import { describe, it, expect } from 'vitest';
import {
  DEFAULT_METRO_STATIONS,
  METRO_LINES,
  filterStationsByLine,
  calculateMetroExplorationProgress,
  getWebMetroStampStatus,
  calculateZoomScale,
} from '../components/WebMetroMosaicGallery';

describe('WebMetroMosaicGallery Unit & Helper Tests (P46-03)', () => {
  it('METRO_LINES contains all 4 canonical Tashkent metro lines with colors and opening years', () => {
    expect(METRO_LINES.length).toBe(4);
    const chilanzar = METRO_LINES.find((l) => l.id === 'chilanzar');
    expect(chilanzar).toBeDefined();
    expect(chilanzar?.color).toBe('#E53935');
    expect(chilanzar?.year).toBe(1977);

    const uzbekistan = METRO_LINES.find((l) => l.id === 'uzbekistan');
    expect(uzbekistan?.color).toBe('#1E88E5');
    expect(uzbekistan?.year).toBe(1984);

    const yunusabad = METRO_LINES.find((l) => l.id === 'yunusabad');
    expect(yunusabad?.color).toBe('#43A047');
    expect(yunusabad?.year).toBe(2001);

    const circle = METRO_LINES.find((l) => l.id === 'circle');
    expect(circle?.color).toBe('#FBC02D');
    expect(circle?.year).toBe(2020);
  });

  it('filterStationsByLine correctly filters by line or returns all stations', () => {
    const all = filterStationsByLine(DEFAULT_METRO_STATIONS, 'all');
    expect(all.length).toBe(DEFAULT_METRO_STATIONS.length);

    const chilanzarStations = filterStationsByLine(DEFAULT_METRO_STATIONS, 'chilanzar');
    expect(chilanzarStations.length).toBe(2);
    expect(chilanzarStations.every((s) => s.lineId === 'chilanzar')).toBe(true);

    const uzbekistanStations = filterStationsByLine(DEFAULT_METRO_STATIONS, 'uzbekistan');
    expect(uzbekistanStations.length).toBe(3);
    expect(uzbekistanStations.every((s) => s.lineId === 'uzbekistan')).toBe(true);

    const yunusabadStations = filterStationsByLine(DEFAULT_METRO_STATIONS, 'yunusabad');
    expect(yunusabadStations.length).toBe(1);
    expect(yunusabadStations[0].id).toBe('bodomzor');
  });

  it('calculateMetroExplorationProgress calculates visited count, percentage, and total XP accurately', () => {
    // 0 stations visited
    const prog0 = calculateMetroExplorationProgress(DEFAULT_METRO_STATIONS, []);
    expect(prog0.visitedCount).toBe(0);
    expect(prog0.totalCount).toBe(DEFAULT_METRO_STATIONS.length);
    expect(prog0.percentage).toBe(0);
    expect(prog0.totalXp).toBe(0);

    // 2 stations visited
    const prog2 = calculateMetroExplorationProgress(DEFAULT_METRO_STATIONS, [
      'kosmonavtlar',
      'alisher_navoiy',
    ]);
    expect(prog2.visitedCount).toBe(2);
    expect(prog2.totalCount).toBe(DEFAULT_METRO_STATIONS.length);
    expect(prog2.percentage).toBe(Math.round((2 / DEFAULT_METRO_STATIONS.length) * 100));
    expect(prog2.totalXp).toBe(60);

    // All stations visited
    const allIds = DEFAULT_METRO_STATIONS.map((s) => s.id);
    const progAll = calculateMetroExplorationProgress(DEFAULT_METRO_STATIONS, allIds);
    expect(progAll.visitedCount).toBe(DEFAULT_METRO_STATIONS.length);
    expect(progAll.percentage).toBe(100);
    expect(progAll.totalXp).toBe(DEFAULT_METRO_STATIONS.length * 30);
  });

  it('formats stamp status copy trilingually for both stamped and unstamped states', () => {
    // Stamped
    expect(getWebMetroStampStatus(true, 'en')).toBe('Stamp Collected (+30 XP)');
    expect(getWebMetroStampStatus(true, 'uz')).toBe("Shtamp yig'ilgan (+30 XP)");
    expect(getWebMetroStampStatus(true, 'ru')).toBe('Штамп получен (+30 XP)');

    // Unstamped
    expect(getWebMetroStampStatus(false, 'en')).toBe('Collect Stamp (+30 XP)');
    expect(getWebMetroStampStatus(false, 'uz')).toBe('Shtampni olish (+30 XP)');
    expect(getWebMetroStampStatus(false, 'ru')).toBe('Собрать штамп (+30 XP)');
  });

  it('calculateZoomScale cycles through zoom steps and resets', () => {
    expect(calculateZoomScale(1)).toBe(1.5);
    expect(calculateZoomScale(1.5)).toBe(2);
    expect(calculateZoomScale(2)).toBe(1);
    expect(calculateZoomScale(2.5)).toBe(1);
  });
});
