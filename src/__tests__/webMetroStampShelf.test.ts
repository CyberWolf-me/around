import { describe, it, expect } from 'vitest';
import {
  calculateWebLineCompletion,
  getWebLineColor,
  getWebLineTitle,
  CANONICAL_WEB_METRO_STATIONS,
} from '../components/WebMetroStampShelf';

describe('P39-03: WebMetroStampShelf Component & Utilities', () => {
  it('contains canonical stations across all 3 lines', () => {
    expect(CANONICAL_WEB_METRO_STATIONS.length).toBe(12);

    const chilanzar = CANONICAL_WEB_METRO_STATIONS.filter((s) => s.line === 'chilanzar');
    const uzbekistan = CANONICAL_WEB_METRO_STATIONS.filter((s) => s.line === 'uzbekistan');
    const yunusabad = CANONICAL_WEB_METRO_STATIONS.filter((s) => s.line === 'yunusabad');

    expect(chilanzar.length).toBe(4);
    expect(uzbekistan.length).toBe(4);
    expect(yunusabad.length).toBe(4);
  });

  it('calculates line completion progress accurately', () => {
    const emptyResult = calculateWebLineCompletion('uzbekistan', []);
    expect(emptyResult.total).toBe(4);
    expect(emptyResult.count).toBe(0);
    expect(emptyResult.pct).toBe(0);

    const halfResult = calculateWebLineCompletion('uzbekistan', [
      'kosmonavtlar',
      'chorsu',
      'other_unrelated_id',
    ]);
    expect(halfResult.count).toBe(2);
    expect(halfResult.total).toBe(4);
    expect(halfResult.pct).toBe(50);

    const fullResult = calculateWebLineCompletion('uzbekistan', [
      'kosmonavtlar',
      'chorsu',
      'alisher_navoiy',
      'oybek',
    ]);
    expect(fullResult.count).toBe(4);
    expect(fullResult.pct).toBe(100);
  });

  it('provides distinct line theme colors', () => {
    expect(getWebLineColor('chilanzar')).toBe('#E53935');
    expect(getWebLineColor('uzbekistan')).toBe('#1E88E5');
    expect(getWebLineColor('yunusabad')).toBe('#43A047');
  });

  it('localizes line titles across Uzbek, Russian, and English', () => {
    expect(getWebLineTitle('chilanzar', 'en')).toBe('Chilanzar Line');
    expect(getWebLineTitle('chilanzar', 'uz')).toBe('Chilonzor yo‘li');
    expect(getWebLineTitle('chilanzar', 'ru')).toBe('Чиланзарская линия');

    expect(getWebLineTitle('uzbekistan', 'uz')).toBe('O‘zbekiston yo‘li');
    expect(getWebLineTitle('yunusabad', 'ru')).toBe('Юнусабадская линия');
  });

  it('validates station metadata integrity', () => {
    for (const station of CANONICAL_WEB_METRO_STATIONS) {
      expect(station.id).toBeTruthy();
      expect(station.name).toBeTruthy();
      expect(station.district).toBeTruthy();
      expect(station.motif).toBeTruthy();
      expect(station.colorHex).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});
