import { describe, it, expect } from 'vitest';
import {
  DEFAULT_CHAYKHANA_VENUES,
  calculateKaytarishAeration,
  formatBrewDuration,
  getWebTapchanLabel,
  getWebKaytarishProverb,
  isTapchanAvailable,
} from '../components/WebChaykhanaBrewBar';

describe('WebChaykhanaBrewBar Unit & Helper Tests', () => {
  const chorsuVenue = DEFAULT_CHAYKHANA_VENUES[0];

  it('calculates 3-step Kaytarish aeration stages and percentages accurately', () => {
    // Step 1: Loy (Mud)
    const step1 = calculateKaytarishAeration(1);
    expect(step1.percent).toBe(33);
    expect(step1.stageName).toContain('Loy');

    // Step 2: Moy (Oil)
    const step2 = calculateKaytarishAeration(2);
    expect(step2.percent).toBe(66);
    expect(step2.stageName).toContain('Moy');

    // Step 3: Choy (Tea)
    const step3 = calculateKaytarishAeration(3);
    expect(step3.percent).toBe(100);
    expect(step3.stageName).toContain('Choy');
  });

  it('formats brewing duration cleanly in minutes and seconds', () => {
    expect(formatBrewDuration(180)).toBe('3:00 min');
    expect(formatBrewDuration(240)).toBe('4:00 min');
    expect(formatBrewDuration(195)).toBe('3:15 min');
  });

  it('formats tapchan capacity and availability labels trilingually', () => {
    // Available
    expect(getWebTapchanLabel(4, 12, 'en')).toBe('4 tapchans free (of 12)');
    expect(getWebTapchanLabel(4, 12, 'uz')).toBe('4 ta tapchan bo\'sh (jami 12)');
    expect(getWebTapchanLabel(4, 12, 'ru')).toBe('4 тапчанов свободно (из 12)');

    // Full
    expect(getWebTapchanLabel(0, 12, 'en')).toBe('All Tapchans Full');
    expect(getWebTapchanLabel(0, 12, 'uz')).toBe('Barcha tapchanlar band');
    expect(getWebTapchanLabel(0, 12, 'ru')).toBe('Все тапчаны заняты');
  });

  it('provides accurate trilingual folk wisdom proverbs and verifies tapchan status', () => {
    expect(getWebKaytarishProverb('en')).toBe('First is mud, second is oil, third is tea');
    expect(getWebKaytarishProverb('uz')).toBe('Birinchi loy, ikkinchi moy, uchinchi choy');
    expect(getWebKaytarishProverb('ru')).toBe('Первая — глина, вторая — масло, третья — чай');

    expect(isTapchanAvailable(chorsuVenue)).toBe(true);
    expect(isTapchanAvailable({ ...chorsuVenue, availableTapchans: 0 })).toBe(false);
  });
});
