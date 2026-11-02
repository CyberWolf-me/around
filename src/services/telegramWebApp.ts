/**
 * Telegram WebApp (TWA) Mini App Bridge & Theme Synchronization
 * Implements P13-03: extracts start_param invite tokens and syncs Telegram theme colors.
 */

export interface TelegramUser {
  id: number;
  first_name: string;
  last_name?: string;
  username?: string;
  language_code?: string;
  is_premium?: boolean;
}

export interface TelegramThemeParams {
  bg_color?: string;
  text_color?: string;
  hint_color?: string;
  link_color?: string;
  button_color?: string;
  button_text_color?: string;
  secondary_bg_color?: string;
}

export interface TelegramHapticFeedback {
  impactOccurred: (style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft') => void;
  notificationOccurred: (type: 'error' | 'success' | 'warning') => void;
  selectionChanged: () => void;
}

export interface TelegramMainButton {
  text: string;
  color: string;
  textColor: string;
  isVisible: boolean;
  isActive: boolean;
  isProgressVisible: boolean;
  setText: (text: string) => TelegramMainButton;
  onClick: (callback: () => void) => TelegramMainButton;
  offClick: (callback: () => void) => TelegramMainButton;
  show: () => TelegramMainButton;
  hide: () => TelegramMainButton;
  enable: () => TelegramMainButton;
  disable: () => TelegramMainButton;
  showProgress: (leaveActive?: boolean) => TelegramMainButton;
  hideProgress: () => TelegramMainButton;
  setParams: (params: {
    text?: string;
    color?: string;
    text_color?: string;
    is_active?: boolean;
    is_visible?: boolean;
  }) => TelegramMainButton;
}

export interface TelegramWebAppObject {
  initData?: string;
  initDataUnsafe?: {
    query_id?: string;
    user?: TelegramUser;
    receiver?: TelegramUser;
    start_param?: string;
    auth_date?: number;
    hash?: string;
  };
  version?: string;
  platform?: string;
  colorScheme?: 'light' | 'dark';
  themeParams?: TelegramThemeParams;
  isExpanded?: boolean;
  viewportHeight?: number;
  viewportStableHeight?: number;
  headerColor?: string;
  backgroundColor?: string;
  ready: () => void;
  expand: () => void;
  close: () => void;
  onEvent?: (eventType: string, eventHandler: () => void) => void;
  offEvent?: (eventType: string, eventHandler: () => void) => void;
  sendData?: (data: string) => void;
  HapticFeedback?: TelegramHapticFeedback;
  MainButton?: TelegramMainButton;
}

declare global {
  interface Window {
    Telegram?: {
      WebApp?: TelegramWebAppObject;
    };
  }
}

export function isTelegramWebAppAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.Telegram?.WebApp);
}

export function getTelegramWebApp(): TelegramWebAppObject | null {
  if (isTelegramWebAppAvailable()) {
    return window.Telegram!.WebApp!;
  }
  return null;
}

/**
 * Extracts start_param from window.Telegram.WebApp.initDataUnsafe or fallback URL search parameters.
 * Supports:
 * 1. window.Telegram.WebApp.initDataUnsafe.start_param
 * 2. URL ?startapp=TOKEN
 * 3. URL ?tgWebAppStartParam=TOKEN
 * 4. URL ?start_param=TOKEN
 */
export function getTelegramStartParam(): string | null {
  const webApp = getTelegramWebApp();
  if (webApp?.initDataUnsafe?.start_param) {
    const val = webApp.initDataUnsafe.start_param.trim();
    if (val.length > 0) return val;
  }

  if (typeof window !== 'undefined' && window.location?.search) {
    const params = new URLSearchParams(window.location.search);
    const candidate =
      params.get('startapp') ||
      params.get('tgWebAppStartParam') ||
      params.get('start_param') ||
      params.get('invite');
    if (candidate && candidate.trim().length > 0) {
      return candidate.trim();
    }
  }

  return null;
}

export function getTelegramUser(): TelegramUser | null {
  const webApp = getTelegramWebApp();
  return webApp?.initDataUnsafe?.user ?? null;
}

/**
 * Applies Telegram themeParams to CSS custom properties on document.documentElement.
 */
export function applyTelegramTheme(targetDocument: Document = document): void {
  const webApp = getTelegramWebApp();
  if (!webApp || !targetDocument?.documentElement) return;

  const theme = webApp.themeParams || {};
  const rootStyle = targetDocument.documentElement.style;

  if (theme.bg_color) {
    rootStyle.setProperty('--tg-theme-bg-color', theme.bg_color);
  }
  if (theme.text_color) {
    rootStyle.setProperty('--tg-theme-text-color', theme.text_color);
  }
  if (theme.hint_color) {
    rootStyle.setProperty('--tg-theme-hint-color', theme.hint_color);
  }
  if (theme.link_color) {
    rootStyle.setProperty('--tg-theme-link-color', theme.link_color);
  }
  if (theme.button_color) {
    rootStyle.setProperty('--tg-theme-button-color', theme.button_color);
  }
  if (theme.button_text_color) {
    rootStyle.setProperty('--tg-theme-button-text-color', theme.button_text_color);
  }
  if (theme.secondary_bg_color) {
    rootStyle.setProperty('--tg-theme-secondary-bg-color', theme.secondary_bg_color);
  }

  if (webApp.colorScheme) {
    targetDocument.documentElement.setAttribute('data-theme', webApp.colorScheme);
  }
}

/**
 * Parses a Telegram start_param into an application route target.
 */
export function parseTelegramStartParam(rawParam: string): {
  type: 'invite' | 'place' | 'passport';
  value: string;
} {
  const clean = rawParam.trim();
  if (clean.startsWith('place_') || clean.startsWith('p_')) {
    const id = clean.replace(/^(place_|p_)/, '');
    return { type: 'place', value: id };
  }
  if (clean.startsWith('pass_') || clean.startsWith('u_')) {
    const username = clean.replace(/^(pass_|u_)/, '');
    return { type: 'passport', value: username };
  }
  if (clean.startsWith('inv_')) {
    return { type: 'invite', value: clean };
  }
  return { type: 'invite', value: clean };
}

/**
 * Triggers safe haptic impact on Telegram Mobile client if available.
 */
export function triggerTelegramHaptic(
  type: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft' | 'selection' | 'success' | 'warning' | 'error' = 'medium'
): boolean {
  const webApp = getTelegramWebApp();
  if (!webApp?.HapticFeedback) return false;

  try {
    if (type === 'selection') {
      webApp.HapticFeedback.selectionChanged();
    } else if (type === 'success' || type === 'warning' || type === 'error') {
      webApp.HapticFeedback.notificationOccurred(type);
    } else {
      webApp.HapticFeedback.impactOccurred(type);
    }
    return true;
  } catch {
    return false;
  }
}

let activeMainButtonCallback: (() => void) | null = null;

export function isTelegramMainButtonAvailable(): boolean {
  const webApp = getTelegramWebApp();
  return Boolean(webApp?.MainButton);
}

/**
 * Configures the native Telegram MainButton at the bottom of the Mini App screen.
 */
export function setTelegramMainButton(params: {
  text: string;
  color?: string;
  textColor?: string;
  onClick: () => void;
  isVisible?: boolean;
}): boolean {
  const webApp = getTelegramWebApp();
  if (!webApp?.MainButton) return false;

  try {
    const mb = webApp.MainButton;

    if (activeMainButtonCallback && typeof mb.offClick === 'function') {
      mb.offClick(activeMainButtonCallback);
    }

    activeMainButtonCallback = () => {
      triggerTelegramHaptic('selection');
      params.onClick();
    };

    if (typeof mb.setParams === 'function') {
      mb.setParams({
        text: params.text,
        color: params.color || '#ff4800',
        text_color: params.textColor || '#ffffff',
        is_active: true,
        is_visible: params.isVisible !== false,
      });
    } else {
      if (typeof mb.setText === 'function') mb.setText(params.text);
      if (params.isVisible !== false && typeof mb.show === 'function') mb.show();
      if (typeof mb.enable === 'function') mb.enable();
    }

    if (typeof mb.onClick === 'function') {
      mb.onClick(activeMainButtonCallback);
    }

    return true;
  } catch {
    return false;
  }
}

/**
 * Hides and cleans up click listeners on the native Telegram MainButton.
 */
export function hideTelegramMainButton(): boolean {
  const webApp = getTelegramWebApp();
  if (!webApp?.MainButton) return false;

  try {
    const mb = webApp.MainButton;
    if (activeMainButtonCallback && typeof mb.offClick === 'function') {
      mb.offClick(activeMainButtonCallback);
      activeMainButtonCallback = null;
    }
    if (typeof mb.hide === 'function') mb.hide();
    if (typeof mb.disable === 'function') mb.disable();
    return true;
  } catch {
    return false;
  }
}

/**
 * Initializes the Telegram WebApp lifecycle: expands window, marks ready, and hooks theme changes.
 */
export function initTelegramWebApp(): {
  isAvailable: boolean;
  startParam: string | null;
  user: TelegramUser | null;
} {
  const webApp = getTelegramWebApp();
  if (!webApp) {
    return {
      isAvailable: false,
      startParam: getTelegramStartParam(),
      user: null,
    };
  }

  try {
    webApp.ready();
    webApp.expand();
  } catch {
    // Non-fatal if platform restricts expansion
  }

  applyTelegramTheme();

  if (typeof webApp.onEvent === 'function') {
    try {
      webApp.onEvent('themeChanged', () => {
        applyTelegramTheme();
      });
    } catch {
      // Ignore listener error
    }
  }

  return {
    isAvailable: true,
    startParam: getTelegramStartParam(),
    user: getTelegramUser(),
  };
}
