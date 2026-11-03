import { describe, it, expect } from 'vitest';
import {
  PAPER_CRAFT_STAGES,
  CALLIGRAPHY_SCRIPTS,
  DEFAULT_SILK_ATELIERS,
  calculatePaperSmoothness,
  formatWebAtelierPrice,
  isAtelierSeatAvailable,
  getWebScriptProverb,
  calculateCumulativeHours,
} from '../components/WebSilkPaperWorkshop';

describe('WebSilkPaperWorkshop Unit & Helper Tests (P47-03)', () => {
  it('PAPER_CRAFT_STAGES contains all 4 traditional crafting steps and calculates total hours', () => {
    expect(PAPER_CRAFT_STAGES.length).toBe(4);

    expect(PAPER_CRAFT_STAGES[0].name).toContain('Soaking & Peeling');
    expect(PAPER_CRAFT_STAGES[0].durationHours).toBe(12);

    expect(PAPER_CRAFT_STAGES[1].name).toContain('Watermill Wooden Mashing');
    expect(PAPER_CRAFT_STAGES[1].durationHours).toBe(8);

    expect(PAPER_CRAFT_STAGES[2].name).toContain('Silk Sieve Framing');
    expect(PAPER_CRAFT_STAGES[2].durationHours).toBe(24);

    expect(PAPER_CRAFT_STAGES[3].name).toContain('Agate Stone Mirror Burnishing');
    expect(PAPER_CRAFT_STAGES[3].durationHours).toBe(1);

    expect(calculateCumulativeHours(PAPER_CRAFT_STAGES)).toBe(45);
  });

  it('calculatePaperSmoothness calculates percent and luster grades accurately', () => {
    // 0 passes
    const zero = calculatePaperSmoothness(0);
    expect(zero.percent).toBe(0);
    expect(zero.grade).toBe('Raw Matte Parchment');

    // 15 passes (50%)
    const mid = calculatePaperSmoothness(15);
    expect(mid.percent).toBe(50);
    expect(mid.grade).toBe('Semi-Smooth Calligraphy Surface');

    // 25 passes (83%)
    const high = calculatePaperSmoothness(25);
    expect(high.percent).toBe(83);
    expect(high.grade).toBe('Lustrous Silk Vellum');

    // 30+ passes (100%)
    const mirror = calculatePaperSmoothness(30);
    expect(mirror.percent).toBe(100);
    expect(mirror.grade).toBe('Mirror Glass Sheen (Imperial Grade)');
  });

  it('formatWebAtelierPrice formats Uzbek Som with spaced thousands separators', () => {
    expect(formatWebAtelierPrice(150000)).toBe('150 000 UZS');
    expect(formatWebAtelierPrice(180000)).toBe('180 000 UZS');
    expect(formatWebAtelierPrice(140000)).toBe('140 000 UZS');
  });

  it('isAtelierSeatAvailable evaluates seat inventory properly', () => {
    const chorsu = DEFAULT_SILK_ATELIERS[0];
    expect(isAtelierSeatAvailable(chorsu)).toBe(true);

    const fullAtelier = { ...chorsu, availableSeats: 0 };
    expect(isAtelierSeatAvailable(fullAtelier)).toBe(false);
  });

  it('CALLIGRAPHY_SCRIPTS and getWebScriptProverb return valid translations', () => {
    expect(CALLIGRAPHY_SCRIPTS.length).toBe(4);

    const nastaliqEn = getWebScriptProverb('nastaliq', 'en');
    expect(nastaliqEn).toContain('Make thy heart the reed pen');

    const nastaliqUz = getWebScriptProverb('nastaliq', 'uz');
    expect(nastaliqUz).toContain('Qalbingni qalam qil');

    const thuluthEn = getWebScriptProverb('thuluth', 'en');
    expect(thuluthEn).toContain('Seek knowledge');
  });
});
