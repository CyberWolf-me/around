import { describe, it, expect } from 'vitest';
import {
  calculateCrossBraceStringTension,
  formatPuppetPriceUzs,
  calculateTotalBookingPrice,
  getWoodHardnessDescription,
  filterStagesByPuppetFormat,
  TASHKENT_PUPPET_STAGES,
} from '../components/WebPuppetTheaterStage';

describe('WebPuppetTheaterStage Domain & Helper Tests', () => {
  it('calculates string tension accurately across cross-brace tilt angles', () => {
    // Neutral tilt
    const neutralEven = calculateCrossBraceStringTension(0, 0);
    const neutralOdd = calculateCrossBraceStringTension(1, 0);
    expect(neutralEven).toBe(0.5);
    expect(neutralOdd).toBe(0.5);

    // Max positive tilt (+45 deg)
    const posEven = calculateCrossBraceStringTension(0, 45);
    const posOdd = calculateCrossBraceStringTension(1, 45);
    expect(posEven).toBe(1.0);
    expect(posOdd).toBe(0.0);

    // Max negative tilt (-45 deg)
    const negEven = calculateCrossBraceStringTension(0, -45);
    const negOdd = calculateCrossBraceStringTension(1, -45);
    expect(negEven).toBe(0.0);
    expect(negOdd).toBe(1.0);

    // Clamping beyond 45 deg
    const clampedOver = calculateCrossBraceStringTension(0, 90);
    expect(clampedOver).toBe(1.0);
  });

  it('formats Uzbek Sum prices with comma separators', () => {
    expect(formatPuppetPriceUzs(35000)).toBe('35,000 UZS');
    expect(formatPuppetPriceUzs(50000)).toBe('50,000 UZS');
    expect(formatPuppetPriceUzs(120000)).toBe('120,000 UZS');
  });

  it('calculates total booking price with safe minimum seat bounds', () => {
    expect(calculateTotalBookingPrice(35000, 1)).toBe(35000);
    expect(calculateTotalBookingPrice(35000, 3)).toBe(105000);
    expect(calculateTotalBookingPrice(50000, 0)).toBe(50000); // minimum 1 seat
  });

  it('returns appropriate wood hardness specifications and descriptions', () => {
    const chinor = getWoodHardnessDescription('chinor');
    expect(chinor.name).toContain('Chinor');
    expect(chinor.hardnessMohs).toBe(3.5);

    const walnut = getWoodHardnessDescription('walnut');
    expect(walnut.name).toContain('Walnut');
    expect(walnut.hardnessMohs).toBe(4.0);

    const apricot = getWoodHardnessDescription('apricot');
    expect(apricot.name).toContain('Apricot');
    expect(apricot.hardnessMohs).toBe(4.5);
  });

  it('filters puppet stages by puppetry format correctly', () => {
    const gloveStages = filterStagesByPuppetFormat(TASHKENT_PUPPET_STAGES, 'chodir_jamol');
    expect(gloveStages.length).toBeGreaterThanOrEqual(2);

    const marionetteStages = filterStagesByPuppetFormat(TASHKENT_PUPPET_STAGES, 'chodir_xayol');
    expect(marionetteStages.length).toBeGreaterThanOrEqual(2);
  });

  it('validates Tashkent puppet stage repository fixtures', () => {
    expect(TASHKENT_PUPPET_STAGES.length).toBe(3);
    const stateTheater = TASHKENT_PUPPET_STAGES[0];
    expect(stateTheater.id).toBe('theater-state-puppet-kosmonavtlar');
    expect(stateTheater.foundedYear).toBe(1939);
    expect(stateTheater.availableSeats).toBe(48);
    expect(stateTheater.repertoire.length).toBe(2);
    expect(stateTheater.signatureFigures.length).toBe(2);
  });
});
