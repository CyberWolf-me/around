import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebActivityType =
  | 'dropCreated'
  | 'routeCompleted'
  | 'crownOvertake'
  | 'badgeUnlocked'
  | 'placeVisited';

export interface WebActivityEvent {
  id: string;
  type: WebActivityType;
  userId: string;
  username: string;
  userFullName: string;
  district: string;
  placeName?: string;
  placeId?: string;
  routeName?: string;
  badgeName?: string;
  xpAwarded?: number;
  timestamp: string;
}

export function getWebActivityEmoji(type: WebActivityType): string {
  switch (type) {
    case 'dropCreated':
      return '📸';
    case 'routeCompleted':
      return '🚶';
    case 'crownOvertake':
      return '👑';
    case 'badgeUnlocked':
      return '🎖️';
    case 'placeVisited':
      return '📍';
  }
}

export function formatWebRelativeTime(
  timestamp: string,
  locale = 'en',
  now: Date = new Date(),
): string {
  const date = new Date(timestamp);
  const diffMs = Math.max(0, now.getTime() - date.getTime());
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const lang = locale.toLowerCase();

  if (diffSec < 45) {
    if (lang.startsWith('uz')) return 'Hozirgina';
    if (lang.startsWith('ru')) return 'Только что';
    return 'Just now';
  } else if (diffMin < 60) {
    if (lang.startsWith('uz')) return `${diffMin} daq. oldin`;
    if (lang.startsWith('ru')) return `${diffMin} мин. назад`;
    return `${diffMin}m ago`;
  } else if (diffHour < 24) {
    if (lang.startsWith('uz')) return `${diffHour} soat oldin`;
    if (lang.startsWith('ru')) return `${diffHour} ч. назад`;
    return `${diffHour}h ago`;
  } else {
    if (lang.startsWith('uz')) return 'Kecha';
    if (lang.startsWith('ru')) return 'Вчера';
    return 'Yesterday';
  }
}

export function formatWebEventTitle(event: WebActivityEvent, locale = 'en'): string {
  const lang = locale.toLowerCase();
  const targetPlace = event.placeName || 'a local spot';
  const targetRoute = event.routeName || 'curated route';
  const targetBadge = event.badgeName || 'Curator Badge';

  switch (event.type) {
    case 'dropCreated':
      if (lang.startsWith('uz')) {
        return `${event.username} ${targetPlace} da yangi Drop qoldirdi`;
      } else if (lang.startsWith('ru')) {
        return `${event.username} оставил(а) новый Дроп в ${targetPlace}`;
      }
      return `${event.username} shared a new Drop at ${targetPlace}`;

    case 'routeCompleted':
      const xpSuffix = event.xpAwarded ? ` (+${event.xpAwarded} XP)` : '';
      if (lang.startsWith('uz')) {
        return `${event.username} "${targetRoute}" marshrutini tugatdi${xpSuffix}`;
      } else if (lang.startsWith('ru')) {
        return `${event.username} завершил(а) маршрут "${targetRoute}"${xpSuffix}`;
      }
      return `${event.username} completed "${targetRoute}"${xpSuffix}`;

    case 'crownOvertake':
      if (lang.startsWith('uz')) {
        return `${event.username} ${event.district} tumanida #1 Tojni egalladi!`;
      } else if (lang.startsWith('ru')) {
        return `${event.username} занял(а) #1 Корону в районе ${event.district}!`;
      }
      return `${event.username} took the #1 Crown in ${event.district}!`;

    case 'badgeUnlocked':
      if (lang.startsWith('uz')) {
        return `${event.username} "${targetBadge}" nishonini qo'lga kiritdi`;
      } else if (lang.startsWith('ru')) {
        return `${event.username} получил(а) бейдж "${targetBadge}"`;
      }
      return `${event.username} earned the "${targetBadge}" badge`;

    case 'placeVisited':
      if (lang.startsWith('uz')) {
        return `${event.username} ${targetPlace} ga tashrif buyurdi`;
      } else if (lang.startsWith('ru')) {
        return `${event.username} посетил(а) ${targetPlace}`;
      }
      return `${event.username} checked in at ${targetPlace}`;
  }
}

export interface WebActivityTickerProps {
  events?: WebActivityEvent[];
  districtFilter?: string;
  locale?: string;
  onEventClick?: (event: WebActivityEvent) => void;
}

export const WebActivityTicker: React.FC<WebActivityTickerProps> = ({
  events = [],
  districtFilter,
  locale = 'en',
  onEventClick,
}) => {
  const [isPaused, setIsPaused] = useState(false);

  const filteredEvents = districtFilter && districtFilter !== 'all'
    ? events.filter(
        (e) => e.district.toLowerCase() === districtFilter.trim().toLowerCase(),
      )
    : events;

  const handleEventClick = (event: WebActivityEvent) => {
    playSoundWithHaptic('pop');
    if (onEventClick) {
      onEventClick(event);
    }
  };

  const getLiveText = () => {
    const lang = locale.toLowerCase();
    if (lang.startsWith('uz')) return 'JONLI';
    if (lang.startsWith('ru')) return 'ПУЛЬС';
    return 'LIVE';
  };

  const getEmptyText = () => {
    const lang = locale.toLowerCase();
    if (lang.startsWith('uz')) return 'Toshkentda hozircha sokin';
    if (lang.startsWith('ru')) return 'В Ташкенте пока спокойно';
    return 'Quiet across Tashkent';
  };

  return (
    <div
      data-testid="web-activity-ticker-container"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
      className="w-full max-w-4xl mx-auto px-4 py-2.5 rounded-2xl bg-white/95 dark:bg-stone-900/95 border border-stone-200 dark:border-stone-800 shadow-sm flex items-center gap-3 overflow-hidden backdrop-blur-md"
    >
      {/* Live Badge */}
      <div className="flex items-center gap-1.5 shrink-0 px-2 py-1 rounded-full bg-orange-50 dark:bg-orange-950/40 border border-orange-200 dark:border-orange-800/60">
        <span className="relative flex h-2 w-2">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-2 w-2 bg-orange-500" />
        </span>
        <span className="text-[10px] font-black tracking-wider text-orange-600 dark:text-orange-400">
          {getLiveText()}
        </span>
      </div>

      <div className="h-4 w-[1px] bg-stone-200 dark:bg-stone-800 shrink-0" />

      {/* Events Stream / Empty State */}
      {filteredEvents.length === 0 ? (
        <div
          data-testid="ticker-empty-state"
          className="text-xs font-semibold text-stone-500 dark:text-stone-400"
        >
          {getEmptyText()}
        </div>
      ) : (
        <div
          className={`flex items-center gap-6 overflow-x-auto no-scrollbar scroll-smooth whitespace-nowrap py-0.5 ${
            isPaused ? 'opacity-95' : ''
          }`}
        >
          {filteredEvents.map((ev) => (
            <div
              key={ev.id}
              data-testid={`activity-event-item-${ev.id}`}
              onClick={() => handleEventClick(ev)}
              className="inline-flex items-center gap-1.5 text-xs text-stone-700 dark:text-stone-300 hover:text-stone-900 dark:hover:text-white cursor-pointer transition-colors group shrink-0"
            >
              <span className="text-sm group-hover:scale-110 transition-transform">
                {getWebActivityEmoji(ev.type)}
              </span>
              <span className="font-bold group-hover:underline">
                {formatWebEventTitle(ev, locale)}
              </span>
              <span className="text-[10px] font-medium text-stone-400 dark:text-stone-500">
                • {formatWebRelativeTime(ev.timestamp, locale)}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
