import { describe, it, expect } from 'vitest';
import {
  DEFAULT_RADIO_STATIONS,
  calculateWebLiveListeners,
  tuneFrequency,
  formatRadioFrequency,
  getRadioReceptionLabel,
  formatRadioSessionProgress,
} from '../components/WebDistrictRadioTuner';

describe('WebDistrictRadioTuner Unit & Logic Tests', () => {
  const chorsuStation = DEFAULT_RADIO_STATIONS[0]; // 88.4 MHz, base 340

  it('accurately tunes into station with high signal strength and clear reception', () => {
    // Exact center frequency
    const exactResult = tuneFrequency(88.4, DEFAULT_RADIO_STATIONS, 12);
    expect(exactResult.lockedStation?.id).toBe('station-chorsu-fm');
    expect(exactResult.signalStrength).toBe(1.0);
    expect(exactResult.isClearReception).toBe(true);
    expect(exactResult.staticVolume).toBe(0.0);
    expect(exactResult.liveListeners).toBeGreaterThan(0);

    // Near center (88.5 MHz -> 0.1 MHz delta -> 0.9 strength)
    const nearResult = tuneFrequency(88.5, DEFAULT_RADIO_STATIONS, 12);
    expect(nearResult.lockedStation?.id).toBe('station-chorsu-fm');
    expect(nearResult.signalStrength).toBe(0.9);
    expect(nearResult.isClearReception).toBe(true);
    expect(nearResult.staticVolume).toBe(0.1);

    // Far delta (89.2 MHz -> 0.8 MHz delta -> 0.2 strength -> weak/no clear lock)
    const weakResult = tuneFrequency(89.2, DEFAULT_RADIO_STATIONS, 12);
    expect(weakResult.signalStrength).toBe(0.2);
    expect(weakResult.isClearReception).toBe(false);
    expect(weakResult.staticVolume).toBe(0.8);

    // Out of range (91.0 MHz -> delta > 1.0 -> static noise)
    const staticResult = tuneFrequency(91.0, DEFAULT_RADIO_STATIONS, 12);
    expect(staticResult.lockedStation).toBeNull();
    expect(staticResult.signalStrength).toBe(0);
    expect(staticResult.isClearReception).toBe(false);
    expect(staticResult.staticVolume).toBe(1.0);
  });

  it('calculates dynamic web live listeners across hours of the day', () => {
    // Evening peak (20:00)
    const eveningListeners = calculateWebLiveListeners(chorsuStation, 20);
    // Morning tea (10:00)
    const morningListeners = calculateWebLiveListeners(chorsuStation, 10);
    // Late night (03:00)
    const nightListeners = calculateWebLiveListeners(chorsuStation, 3);

    expect(eveningListeners).toBeGreaterThan(morningListeners);
    expect(morningListeners).toBeGreaterThan(nightListeners);
    expect(nightListeners).toBeGreaterThanOrEqual(20);
  });

  it('formats radio frequency and reception labels in English, Uzbek, and Russian', () => {
    expect(formatRadioFrequency(88.4)).toBe('88.4 MHz');
    expect(formatRadioFrequency(101.6)).toBe('101.6 MHz');

    // Clear signal
    expect(getRadioReceptionLabel(0.9, 'en')).toBe('Clear Signal');
    expect(getRadioReceptionLabel(0.9, 'uz')).toBe('Aniq signal');
    expect(getRadioReceptionLabel(0.9, 'ru')).toBe('Четкий сигнал');

    // Weak signal
    expect(getRadioReceptionLabel(0.5, 'en')).toBe('Weak Signal');
    expect(getRadioReceptionLabel(0.5, 'uz')).toBe('Zaif signal');
    expect(getRadioReceptionLabel(0.5, 'ru')).toBe('Слабый сигнал');

    // Static noise
    expect(getRadioReceptionLabel(0.1, 'en')).toBe('Static Noise');
    expect(getRadioReceptionLabel(0.1, 'uz')).toBe('Statik shovqin');
    expect(getRadioReceptionLabel(0.1, 'ru')).toBe('Статический шум');
  });

  it('formats session progress labels across locales and completion thresholds', () => {
    // In progress (3 minutes)
    expect(formatRadioSessionProgress(3, 'en')).toBe('Listen 7 more mins for +25 XP');
    expect(formatRadioSessionProgress(3, 'uz')).toBe('+25 XP olish uchun yana 7 daqiqa tinglang');
    expect(formatRadioSessionProgress(3, 'ru')).toBe('Слушайте еще 7 мин до +25 XP');

    // Completed (10 minutes)
    expect(formatRadioSessionProgress(10, 'en')).toBe('10 minutes tuned in! Earned +25 XP');
    expect(formatRadioSessionProgress(12, 'uz')).toBe('10 daqiqa tinglandi! +25 XP berildi');
    expect(formatRadioSessionProgress(15, 'ru')).toBe('10 минут прослушано! +25 XP получено');
  });
});
