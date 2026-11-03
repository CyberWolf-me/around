import { describe, it, expect } from 'vitest';
import {
  DEFAULT_CRAFT_STUDIOS,
  calculateAvailableSeats,
  isMasterclassFull,
  formatWebPriceUzs,
  getWebReservationStatus,
  filterStudiosByDiscipline,
} from '../components/WebCraftStudioShowcase';

describe('WebCraftStudioShowcase Unit & Helper Tests', () => {
  const rishtanStudio = DEFAULT_CRAFT_STUDIOS[0];
  const availableClass = rishtanStudio.masterclasses[0]; // 6 max, 4 reserved -> 2 available
  const fullClass = rishtanStudio.masterclasses[1]; // 5 max, 5 reserved -> 0 available, full

  it('calculates available seats and full capacity state accurately', () => {
    expect(calculateAvailableSeats(availableClass)).toBe(2);
    expect(isMasterclassFull(availableClass)).toBe(false);

    expect(calculateAvailableSeats(fullClass)).toBe(0);
    expect(isMasterclassFull(fullClass)).toBe(true);
  });

  it('formats Uzbek Som currency with spaced thousands separators', () => {
    expect(formatWebPriceUzs(180000)).toBe('180 000 UZS');
    expect(formatWebPriceUzs(250000)).toBe('250 000 UZS');
    expect(formatWebPriceUzs(1500000)).toBe('1 500 000 UZS');
  });

  it('formats reservation status labels trilingually across reservation and capacity states', () => {
    // Reserved state
    expect(getWebReservationStatus(true, false, 'en')).toBe('Reserved (+40 XP)');
    expect(getWebReservationStatus(true, false, 'uz')).toBe('Band qilingan (+40 XP)');
    expect(getWebReservationStatus(true, false, 'ru')).toBe('Забронировано (+40 XP)');

    // Full state
    expect(getWebReservationStatus(false, true, 'en')).toBe('Fully Booked');
    expect(getWebReservationStatus(false, true, 'uz')).toBe('Barcha joylar band');
    expect(getWebReservationStatus(false, true, 'ru')).toBe('Все места заняты');

    // Available state
    expect(getWebReservationStatus(false, false, 'en')).toBe('Reserve Seat');
    expect(getWebReservationStatus(false, false, 'uz')).toBe('Joyni band qilish');
    expect(getWebReservationStatus(false, false, 'ru')).toBe('Забронировать место');
  });

  it('filters craft studios by discipline accurately', () => {
    const ceramics = filterStudiosByDiscipline(DEFAULT_CRAFT_STUDIOS, 'Ceramics');
    expect(ceramics.length).toBe(1);
    expect(ceramics[0].id).toBe('studio-rishtan-ceramics');

    const woodcarving = filterStudiosByDiscipline(DEFAULT_CRAFT_STUDIOS, 'woodcarving');
    expect(woodcarving.length).toBe(1);
    expect(woodcarving[0].id).toBe('studio-chorsu-woodcarving');

    const all = filterStudiosByDiscipline(DEFAULT_CRAFT_STUDIOS, 'all');
    expect(all.length).toBe(2);
  });
});
