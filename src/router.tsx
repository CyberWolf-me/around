import React, { useEffect, useState } from 'react';
import { AppProvider } from './context/AppContext';
import { AppContent } from './App';

export type RouteType = 'home' | 'invite' | 'passport' | 'place';

export interface RouteMatch {
  path: string;
  type: RouteType;
  params: Record<string, string>;
}

export function parseRoute(pathname: string): RouteMatch {
  const cleanPath = pathname.replace(/\/+$/, '') || '/';

  // Match /invite/:code
  const inviteMatch = cleanPath.match(/^\/invite\/([a-zA-Z0-9_-]+)$/);
  if (inviteMatch) {
    return {
      path: cleanPath,
      type: 'invite',
      params: { code: inviteMatch[1] },
    };
  }

  // Match /passport/:username or /u/:username/passport
  const userPassportMatch = cleanPath.match(/^\/u\/([^/]+)\/passport$/);
  if (userPassportMatch) {
    return {
      path: cleanPath,
      type: 'passport',
      params: { username: userPassportMatch[1] },
    };
  }

  const passportMatch = cleanPath.match(/^\/passport\/([a-zA-Z0-9_.-]+)$/);
  if (passportMatch) {
    return {
      path: cleanPath,
      type: 'passport',
      params: { username: passportMatch[1] },
    };
  }

  // Match /places/:id or /p/:id
  const placeMatch = cleanPath.match(/^\/(?:places|p)\/([a-zA-Z0-9_-]+)$/);
  if (placeMatch) {
    return {
      path: cleanPath,
      type: 'place',
      params: { id: placeMatch[1] },
    };
  }

  return {
    path: cleanPath,
    type: 'home',
    params: {},
  };
}

export function buildInviteUrl(code: string, baseUrl: string = 'https://around.tashkent.app'): string {
  return `${baseUrl}/invite/${code}`;
}

export function buildPassportUrl(username: string, baseUrl: string = 'https://around.tashkent.app'): string {
  return `${baseUrl}/u/${username}/passport`;
}

export function buildPlaceUrl(slugOrId: string, baseUrl: string = 'https://around.tashkent.app'): string {
  return `${baseUrl}/places/${slugOrId}`;
}

export function buildTelegramShareUrl(url: string, text: string): string {
  return `https://t.me/share/url?url=${encodeURIComponent(url)}&text=${encodeURIComponent(text)}`;
}

export const WebCompanionRouter: React.FC = () => {
  const [route, setRoute] = useState<RouteMatch>(() =>
    parseRoute(typeof window !== 'undefined' ? window.location.pathname : '/')
  );

  useEffect(() => {
    const handlePopState = () => {
      setRoute(parseRoute(window.location.pathname));
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  return (
    <AppProvider>
      <AppContent currentRoute={route} />
    </AppProvider>
  );
};
