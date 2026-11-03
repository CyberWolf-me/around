import { describe, it, expect } from 'vitest';
import {
  extractTelegramStartParam,
  resolveWebLaunchTarget,
  buildCanonicalTelegramBotUrl,
} from '../services/telegramLaunchBridge';

describe('P29-03: telegramLaunchBridge Unit Tests', () => {
  it('extractTelegramStartParam extracts from mock initData and query params', () => {
    // 1. From initData
    expect(extractTelegramStartParam('', { start_param: 'route_mirabad_coffee_crawl' })).toBe(
      'route_mirabad_coffee_crawl'
    );

    // 2. From ?startapp=
    expect(extractTelegramStartParam('?startapp=postcard_REC-MIR-2026-774')).toBe(
      'postcard_REC-MIR-2026-774'
    );

    // 3. From ?tgWebAppStartParam=
    expect(extractTelegramStartParam('?tgWebAppStartParam=season_2026-11')).toBe('season_2026-11');

    // 4. From ?start=
    expect(extractTelegramStartParam('?start=ref_kamila')).toBe('ref_kamila');

    // 5. Empty
    expect(extractTelegramStartParam('')).toBeNull();
    expect(extractTelegramStartParam('?other=123')).toBeNull();
  });

  it('resolveWebLaunchTarget parses route, postcard, season, and crawl targets', () => {
    const route = resolveWebLaunchTarget('route_mirabad_coffee_crawl');
    expect(route.type).toBe('route');
    expect(route.resourceId).toBe('mirabad_coffee_crawl');
    expect(route.routePath).toBe('/routes/mirabad_coffee_crawl');
    expect(route.isValid).toBe(true);

    const postcard = resolveWebLaunchTarget('postcard_REC-MIR-2026-774');
    expect(postcard.type).toBe('postcard');
    expect(postcard.resourceId).toBe('REC-MIR-2026-774');
    expect(postcard.routePath).toBe('/postcards/REC-MIR-2026-774');
    expect(postcard.isValid).toBe(true);

    const season = resolveWebLaunchTarget('season_2026-11');
    expect(season.type).toBe('season');
    expect(season.resourceId).toBe('2026-11');
    expect(season.routePath).toBe('/seasons/2026-11');

    const crawl = resolveWebLaunchTarget('crawl_CR-MRB-77');
    expect(crawl.type).toBe('crawl');
    expect(crawl.resourceId).toBe('CR-MRB-77');
    expect(crawl.routePath).toBe('/crawl/CR-MRB-77');
  });

  it('resolveWebLaunchTarget parses composite payloads with referral attribution', () => {
    const target = resolveWebLaunchTarget('route_mirabad_coffee_crawl__ref_kamila_tashkent');
    expect(target.type).toBe('route');
    expect(target.resourceId).toBe('mirabad_coffee_crawl');
    expect(target.referrerId).toBe('kamila_tashkent');
    expect(target.routePath).toBe('/routes/mirabad_coffee_crawl');

    const refOnly = resolveWebLaunchTarget('ref_bekzod');
    expect(refOnly.type).toBe('referral');
    expect(refOnly.referrerId).toBe('bekzod');
    expect(refOnly.routePath).toBe('/');
  });

  it('resolveWebLaunchTarget handles empty or malformed strings gracefully', () => {
    const empty = resolveWebLaunchTarget(null);
    expect(empty.type).toBe('home');
    expect(empty.routePath).toBe('/');
    expect(empty.isValid).toBe(false);

    const unknown = resolveWebLaunchTarget('unrecognized_payload');
    expect(unknown.type).toBe('home');
    expect(unknown.routePath).toBe('/');
    expect(unknown.isValid).toBe(false);
  });

  it('buildCanonicalTelegramBotUrl constructs formatted bot URLs', () => {
    const url1 = buildCanonicalTelegramBotUrl('route', 'mirabad_coffee_crawl');
    expect(url1).toBe('https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl');

    const url2 = buildCanonicalTelegramBotUrl('route', 'mirabad_coffee_crawl', 'kamila');
    expect(url2).toBe(
      'https://t.me/around_tashkent_bot/app?startapp=route_mirabad_coffee_crawl__ref_kamila'
    );

    const url3 = buildCanonicalTelegramBotUrl('referral', 'kamila');
    expect(url3).toBe('https://t.me/around_tashkent_bot/app?startapp=ref_kamila');
  });
});
