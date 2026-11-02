import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  isTelegramWebAppAvailable,
  getTelegramWebApp,
  getTelegramStartParam,
  getTelegramUser,
  applyTelegramTheme,
  parseTelegramStartParam,
  triggerTelegramHaptic,
  initTelegramWebApp,
} from '../services/telegramWebApp';
import { resolveInitialRoute } from '../router';

describe('P13-03: Telegram WebApp (TWA) Mini App Bridge & Direct Invite Injection', () => {
  let mockWindow: any;
  let mockDoc: any;
  const originalWindow = (globalThis as any).window;
  const originalDoc = (globalThis as any).document;

  beforeEach(() => {
    mockDoc = {
      documentElement: {
        style: {
          _props: {} as Record<string, string>,
          setProperty(name: string, val: string) {
            this._props[name] = val;
          },
          getPropertyValue(name: string) {
            return this._props[name] || '';
          },
        },
        _attrs: {} as Record<string, string>,
        setAttribute(name: string, val: string) {
          this._attrs[name] = val;
        },
        getAttribute(name: string) {
          return this._attrs[name] || null;
        },
      },
    };

    mockWindow = {
      location: {
        pathname: '/',
        search: '',
      },
      history: {
        replaceState(_state: any, _title: string, url: string) {
          const parts = url.split('?');
          mockWindow.location.pathname = parts[0] || '/';
          mockWindow.location.search = parts[1] ? `?${parts[1]}` : '';
        },
      },
      Telegram: undefined,
    };

    (globalThis as any).window = mockWindow;
    (globalThis as any).document = mockDoc;
  });

  afterEach(() => {
    (globalThis as any).window = originalWindow;
    (globalThis as any).document = originalDoc;
    vi.restoreAllMocks();
  });

  it('detects Telegram WebApp availability correctly', () => {
    expect(isTelegramWebAppAvailable()).toBe(false);
    expect(getTelegramWebApp()).toBeNull();

    mockWindow.Telegram = {
      WebApp: {
        ready: vi.fn(),
        expand: vi.fn(),
        close: vi.fn(),
      },
    };

    expect(isTelegramWebAppAvailable()).toBe(true);
    expect(getTelegramWebApp()).toBeDefined();
  });

  it('extracts start_param from window.Telegram.WebApp.initDataUnsafe', () => {
    mockWindow.Telegram = {
      WebApp: {
        ready: vi.fn(),
        expand: vi.fn(),
        close: vi.fn(),
        initDataUnsafe: {
          start_param: 'inv_vip_tashkent_2026',
        },
      },
    };

    expect(getTelegramStartParam()).toBe('inv_vip_tashkent_2026');
  });

  it('falls back to URL query parameters when Telegram WebApp is not present', () => {
    mockWindow.history.replaceState({}, '', '/?startapp=tashkent_beta_cohort');
    expect(getTelegramStartParam()).toBe('tashkent_beta_cohort');

    mockWindow.history.replaceState({}, '', '/?tgWebAppStartParam=inv_friend_camila');
    expect(getTelegramStartParam()).toBe('inv_friend_camila');

    mockWindow.history.replaceState({}, '', '/?start_param=place_breadly');
    expect(getTelegramStartParam()).toBe('place_breadly');
  });

  it('extracts Telegram user profile data safely', () => {
    expect(getTelegramUser()).toBeNull();

    mockWindow.Telegram = {
      WebApp: {
        ready: vi.fn(),
        expand: vi.fn(),
        close: vi.fn(),
        initDataUnsafe: {
          user: {
            id: 998901234,
            first_name: 'Aziz',
            last_name: 'Karimov',
            username: 'aziz_tashkent',
            language_code: 'uz',
          },
        },
      },
    };

    const user = getTelegramUser();
    expect(user).not.toBeNull();
    expect(user?.id).toBe(998901234);
    expect(user?.username).toBe('aziz_tashkent');
    expect(user?.language_code).toBe('uz');
  });

  it('synchronizes Telegram theme parameters with document CSS custom properties', () => {
    mockWindow.Telegram = {
      WebApp: {
        ready: vi.fn(),
        expand: vi.fn(),
        close: vi.fn(),
        colorScheme: 'dark',
        themeParams: {
          bg_color: '#1a1816',
          text_color: '#faf7f2',
          hint_color: '#8f887f',
          link_color: '#ff4800',
          button_color: '#ff4800',
          button_text_color: '#ffffff',
          secondary_bg_color: '#24201c',
        },
      },
    };

    applyTelegramTheme(mockDoc as any);

    expect(mockDoc.documentElement.getAttribute('data-theme')).toBe('dark');
    expect(mockDoc.documentElement.style.getPropertyValue('--tg-theme-bg-color')).toBe('#1a1816');
    expect(mockDoc.documentElement.style.getPropertyValue('--tg-theme-text-color')).toBe('#faf7f2');
    expect(mockDoc.documentElement.style.getPropertyValue('--tg-theme-button-color')).toBe('#ff4800');
  });

  it('correctly parses Telegram start_param variants', () => {
    expect(parseTelegramStartParam('inv_camila_coffee')).toEqual({
      type: 'invite',
      value: 'inv_camila_coffee',
    });

    expect(parseTelegramStartParam('place_breadly-bakery')).toEqual({
      type: 'place',
      value: 'breadly-bakery',
    });

    expect(parseTelegramStartParam('p_canti-wine')).toEqual({
      type: 'place',
      value: 'canti-wine',
    });

    expect(parseTelegramStartParam('pass_jasur')).toEqual({
      type: 'passport',
      value: 'jasur',
    });

    expect(parseTelegramStartParam('u_nodira')).toEqual({
      type: 'passport',
      value: 'nodira',
    });

    expect(parseTelegramStartParam('VIP-COFFEE-2026')).toEqual({
      type: 'invite',
      value: 'VIP-COFFEE-2026',
    });
  });

  it('triggers haptic feedback via Telegram HapticFeedback without throwing', () => {
    const impactMock = vi.fn();
    const notificationMock = vi.fn();
    const selectionMock = vi.fn();

    mockWindow.Telegram = {
      WebApp: {
        ready: vi.fn(),
        expand: vi.fn(),
        close: vi.fn(),
        HapticFeedback: {
          impactOccurred: impactMock,
          notificationOccurred: notificationMock,
          selectionChanged: selectionMock,
        },
      },
    };

    expect(triggerTelegramHaptic('light')).toBe(true);
    expect(impactMock).toHaveBeenCalledWith('light');

    expect(triggerTelegramHaptic('selection')).toBe(true);
    expect(selectionMock).toHaveBeenCalled();

    expect(triggerTelegramHaptic('success')).toBe(true);
    expect(notificationMock).toHaveBeenCalledWith('success');
  });

  it('initializes Telegram WebApp lifecycle', () => {
    const readyMock = vi.fn();
    const expandMock = vi.fn();

    mockWindow.Telegram = {
      WebApp: {
        ready: readyMock,
        expand: expandMock,
        close: vi.fn(),
        initDataUnsafe: {
          start_param: 'inv_seed_alpha',
        },
      },
    };

    const twa = initTelegramWebApp();
    expect(twa.isAvailable).toBe(true);
    expect(twa.startParam).toBe('inv_seed_alpha');
    expect(readyMock).toHaveBeenCalled();
    expect(expandMock).toHaveBeenCalled();
  });

  it('resolves initial route with start_param priority', () => {
    const inviteRoute = resolveInitialRoute('/', 'inv_vip_code');
    expect(inviteRoute.type).toBe('invite');
    expect(inviteRoute.params.code).toBe('inv_vip_code');

    const placeRoute = resolveInitialRoute('/', 'place_breadly');
    expect(placeRoute.type).toBe('place');
    expect(placeRoute.params.id).toBe('breadly');

    const passportRoute = resolveInitialRoute('/', 'pass_kamila');
    expect(passportRoute.type).toBe('passport');
    expect(passportRoute.params.username).toBe('kamila');

    // Without start_param, uses standard pathname
    const homeRoute = resolveInitialRoute('/');
    expect(homeRoute.type).toBe('home');

    const directPlace = resolveInitialRoute('/places/canti');
    expect(directPlace.type).toBe('place');
    expect(directPlace.params.id).toBe('canti');
  });
});
