import { describe, it, expect } from 'vitest';
import {
  parseRoute,
  buildInviteUrl,
  buildPassportUrl,
  buildPlaceUrl,
  buildTelegramShareUrl,
} from '../router';

describe('Web Companion Router & Deep Link Bridge (P12-09)', () => {
  it('parses invite URLs correctly', () => {
    const route = parseRoute('/invite/TASH50');
    expect(route.type).toBe('invite');
    expect(route.params.code).toBe('TASH50');

    const routeToken = parseRoute('/invite/inv_custom_token_123');
    expect(routeToken.type).toBe('invite');
    expect(routeToken.params.code).toBe('inv_custom_token_123');
  });

  it('parses taste passport URLs across legacy and canonical paths', () => {
    const route1 = parseRoute('/passport/dilshod_b');
    expect(route1.type).toBe('passport');
    expect(route1.params.username).toBe('dilshod_b');

    const route2 = parseRoute('/u/kamila_r/passport');
    expect(route2.type).toBe('passport');
    expect(route2.params.username).toBe('kamila_r');
  });

  it('parses place detail URLs', () => {
    const route1 = parseRoute('/places/breadly-bakery-cafe');
    expect(route1.type).toBe('place');
    expect(route1.params.id).toBe('breadly-bakery-cafe');

    const route2 = parseRoute('/p/steam-bar-lounge');
    expect(route2.type).toBe('place');
    expect(route2.params.id).toBe('steam-bar-lounge');
  });

  it('falls back to home route for root or unmatched paths', () => {
    expect(parseRoute('/').type).toBe('home');
    expect(parseRoute('').type).toBe('home');
    expect(parseRoute('/feed').type).toBe('home');
  });

  it('builds canonical deep links and Telegram share URLs accurately', () => {
    expect(buildInviteUrl('TASH50')).toBe('https://around.tashkent.app/invite/TASH50');
    expect(buildPassportUrl('dilshod_b')).toBe('https://around.tashkent.app/u/dilshod_b/passport');
    expect(buildPlaceUrl('breadly')).toBe('https://around.tashkent.app/places/breadly');

    const tgShare = buildTelegramShareUrl('https://around.tashkent.app/invite/TASH50', 'Join Around!');
    expect(tgShare).toContain('t.me/share/url');
    expect(tgShare).toContain('url=https%3A%2F%2Faround.tashkent.app%2Finvite%2FTASH50');
    expect(tgShare).toContain('text=Join%20Around!');
  });
});
