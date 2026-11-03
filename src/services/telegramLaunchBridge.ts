/**
 * Telegram Mini App Launch Router & Deep Link Bridge (`P29-03`).
 * Extracts start_param from window.Telegram.WebApp or URL search queries
 * and resolves corresponding web routes and referral telemetry.
 */

export type WebLaunchType = 'route' | 'postcard' | 'season' | 'crawl' | 'referral' | 'home';

export interface WebLaunchTarget {
  type: WebLaunchType;
  rawPayload: string;
  resourceId: string;
  referrerId?: string;
  routePath: string;
  isValid: boolean;
}

export function extractTelegramStartParam(
  searchString?: string,
  mockInitData?: { start_param?: string }
): string | null {
  // 1. Check explicit mock or Telegram WebApp object
  if (mockInitData?.start_param) {
    return mockInitData.start_param.trim();
  }

  try {
    const tg = typeof window !== 'undefined' ? (window as unknown as { Telegram?: { WebApp?: { initDataUnsafe?: { start_param?: string } } } })?.Telegram?.WebApp : undefined;
    if (tg?.initDataUnsafe?.start_param) {
      return tg.initDataUnsafe.start_param.trim();
    }
  } catch {
    // Ignore in non-browser or sandboxed environments
  }

  // 2. Fall back to URL search query parameters (?startapp= or ?tgWebAppStartParam= or ?start=)
  const query = searchString ?? (typeof window !== 'undefined' ? window.location?.search : '');
  if (!query) return null;

  const params = new URLSearchParams(query);
  const candidate = params.get('startapp') || params.get('tgWebAppStartParam') || params.get('start');
  return candidate ? candidate.trim() : null;
}

export function resolveWebLaunchTarget(startParam: string | null | undefined): WebLaunchTarget {
  if (!startParam || !startParam.trim()) {
    return {
      type: 'home',
      rawPayload: '',
      resourceId: '',
      routePath: '/',
      isValid: false,
    };
  }

  const raw = startParam.trim();
  let payload = raw;
  let referrerId: string | undefined;

  // Extract optional referral suffix: "__ref_<curator>"
  if (payload.includes('__ref_')) {
    const parts = payload.split('__ref_');
    payload = parts[0];
    if (parts.length > 1 && parts[1].trim()) {
      referrerId = parts[1].trim();
    }
  }

  if (payload.startsWith('route_')) {
    const id = payload.substring('route_'.length).trim();
    return {
      type: 'route',
      rawPayload: raw,
      resourceId: id,
      referrerId,
      routePath: id ? `/routes/${id}` : '/',
      isValid: Boolean(id),
    };
  }

  if (payload.startsWith('postcard_')) {
    const id = payload.substring('postcard_'.length).trim();
    return {
      type: 'postcard',
      rawPayload: raw,
      resourceId: id,
      referrerId,
      routePath: id ? `/postcards/${id}` : '/',
      isValid: Boolean(id),
    };
  }

  if (payload.startsWith('season_')) {
    const id = payload.substring('season_'.length).trim();
    return {
      type: 'season',
      rawPayload: raw,
      resourceId: id,
      referrerId,
      routePath: id ? `/seasons/${id}` : '/',
      isValid: Boolean(id),
    };
  }

  if (payload.startsWith('crawl_')) {
    const id = payload.substring('crawl_'.length).trim();
    return {
      type: 'crawl',
      rawPayload: raw,
      resourceId: id,
      referrerId,
      routePath: id ? `/crawl/${id}` : '/',
      isValid: Boolean(id),
    };
  }

  if (payload.startsWith('ref_')) {
    const id = payload.substring('ref_'.length).trim();
    return {
      type: 'referral',
      rawPayload: raw,
      resourceId: id,
      referrerId: id,
      routePath: '/',
      isValid: Boolean(id),
    };
  }

  return {
    type: 'home',
    rawPayload: raw,
    resourceId: raw,
    referrerId,
    routePath: '/',
    isValid: false,
  };
}

export function buildCanonicalTelegramBotUrl(
  type: 'route' | 'postcard' | 'season' | 'crawl' | 'referral',
  resourceId: string,
  referrerId?: string
): string {
  const cleanId = resourceId.trim();
  let param: string;

  if (type === 'referral') {
    param = `ref_${cleanId}`;
  } else {
    param = `${type}_${cleanId}`;
    if (referrerId && referrerId.trim()) {
      param += `__ref_${referrerId.trim()}`;
    }
  }

  return `https://t.me/around_tashkent_bot/app?startapp=${encodeURIComponent(param)}`;
}
