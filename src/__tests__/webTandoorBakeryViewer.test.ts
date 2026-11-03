import { describe, it, expect } from 'vitest';
import {
  CHEKICH_PATTERNS,
  DEFAULT_BREAD_VARIETIES,
  DEFAULT_TANDOOR_BAKERIES,
  calculateFreshnessTier,
  formatWebBreadPrice,
  calculateBatchTotalUzs,
  isHotBatchAvailable,
  getWebChekichPinLabel,
} from '../components/WebTandoorBakeryViewer';

describe('WebTandoorBakeryViewer Unit & Helper Tests (P48-03)', () => {
  it('CHEKICH_PATTERNS contains all 3 traditional patterns with pin counts', () => {
    expect(CHEKICH_PATTERNS.length).toBe(3);

    const sunburst = CHEKICH_PATTERNS.find((p) => p.id === 'sunburst');
    expect(sunburst).toBeDefined();
    expect(sunburst?.pinCount).toBe(36);

    const rosette = CHEKICH_PATTERNS.find((p) => p.id === 'rosette');
    expect(rosette?.pinCount).toBe(48);

    const octagon = CHEKICH_PATTERNS.find((p) => p.id === 'octagon');
    expect(octagon?.pinCount).toBe(64);
  });

  it('DEFAULT_BREAD_VARIETIES contains all 4 canonical breads with temperatures and prices', () => {
    expect(DEFAULT_BREAD_VARIETIES.length).toBe(4);

    const obiNon = DEFAULT_BREAD_VARIETIES.find((b) => b.id === 'obi_non');
    expect(obiNon?.priceUzs).toBe(4000);
    expect(obiNon?.tempCelsius).toBe(280);

    const patir = DEFAULT_BREAD_VARIETIES.find((b) => b.id === 'patir');
    expect(patir?.priceUzs).toBe(8000);
    expect(patir?.tempCelsius).toBe(300);

    const shirmoy = DEFAULT_BREAD_VARIETIES.find((b) => b.id === 'shirmoy');
    expect(shirmoy?.priceUzs).toBe(12000);
    expect(shirmoy?.tempCelsius).toBe(260);

    const jizzali = DEFAULT_BREAD_VARIETIES.find((b) => b.id === 'jizzali');
    expect(jizzali?.priceUzs).toBe(10000);
    expect(jizzali?.tempCelsius).toBe(290);
  });

  it('calculateFreshnessTier determines tier and isHot flag accurately', () => {
    // Under 15m
    const hot = calculateFreshnessTier(5);
    expect(hot.tier).toContain('Piping Hot');
    expect(hot.isHot).toBe(true);

    // 16 to 45m
    const warm = calculateFreshnessTier(25);
    expect(warm.tier).toContain('Warm & Fragrant');
    expect(warm.isHot).toBe(true);

    // Over 45m
    const ambient = calculateFreshnessTier(55);
    expect(ambient.tier).toContain('Ambient Fresh');
    expect(ambient.isHot).toBe(false);
  });

  it('formatWebBreadPrice formats prices with spaced thousands separators', () => {
    expect(formatWebBreadPrice(4000)).toBe('4 000 UZS');
    expect(formatWebBreadPrice(8000)).toBe('8 000 UZS');
    expect(formatWebBreadPrice(12000)).toBe('12 000 UZS');
    expect(formatWebBreadPrice(32000)).toBe('32 000 UZS');
  });

  it('calculateBatchTotalUzs computes batch cost across multiple loaves', () => {
    expect(calculateBatchTotalUzs(4000, 2)).toBe(8000);
    expect(calculateBatchTotalUzs(8000, 3)).toBe(24000);
    expect(calculateBatchTotalUzs(12000, 4)).toBe(48000);
    expect(calculateBatchTotalUzs(4000, 0)).toBe(4000); // Minimum 1 loaf
  });

  it('isHotBatchAvailable and getWebChekichPinLabel work as expected', () => {
    const chorsu = DEFAULT_TANDOOR_BAKERIES[0];
    expect(isHotBatchAvailable(chorsu)).toBe(true);

    const emptyBakery = { ...chorsu, hotLoavesCount: 0 };
    expect(isHotBatchAvailable(emptyBakery)).toBe(false);

    expect(getWebChekichPinLabel('sunburst')).toContain('36 steel pins');
    expect(getWebChekichPinLabel('rosette')).toContain('48 steel pins');
    expect(getWebChekichPinLabel('octagon')).toContain('64 steel pins');
  });
});
