import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebRouteStop {
  placeId: string;
  name: string;
  district: string;
  atmosphereTag: string;
  nearestSubway: string;
  walkingMinutes: number;
}

export interface WebCuratedRoute {
  id: string;
  title: string;
  subtitle: string;
  district: string;
  emoji: string;
  stops: WebRouteStop[];
  totalMinutes: number;
  distanceMeters: number;
  xpReward: number;
  startSubway: string;
  endSubway: string;
}

export interface WebRouteProgress {
  totalStops: number;
  completedStops: number;
  percentage: number;
  isCompleted: bool;
  nextPendingStop: WebRouteStop | null;
}

type bool = boolean;

export const DEFAULT_WEB_ROUTES: WebCuratedRoute[] = [
  {
    id: 'mirabad_coffee_crawl',
    title: 'Mirabad Specialty Coffee Crawl',
    subtitle: 'The golden triangle of Tashkent morning coffee and pastry craft',
    district: 'Mirabad',
    emoji: '☕',
    totalMinutes: 12,
    distanceMeters: 850,
    xpReward: 150,
    startSubway: 'Oybek',
    endSubway: 'Kosmonavtlar',
    stops: [
      {
        placeId: 'place_breadly',
        name: 'Breadly Bakery & Café',
        district: 'Mirabad',
        atmosphereTag: 'Morning Brew',
        nearestSubway: 'Oybek',
        walkingMinutes: 0,
      },
      {
        placeId: 'place_socials',
        name: 'Socials Coffee Hub',
        district: 'Mirabad',
        atmosphereTag: 'Work Friendly',
        nearestSubway: 'Oybek',
        walkingMinutes: 5,
      },
      {
        placeId: 'place_ekler',
        name: 'Ekler Patisserie',
        district: 'Mirabad',
        atmosphereTag: 'Sweet Bite',
        nearestSubway: 'Kosmonavtlar',
        walkingMinutes: 7,
      },
    ],
  },
  {
    id: 'chorsu_heritage_trail',
    title: 'Old City Heritage & Bazaar Trail',
    subtitle: 'Sensory journey through clay tandoors, spice alleys, and steaming plov',
    district: 'Old City',
    emoji: '🍲',
    totalMinutes: 16,
    distanceMeters: 1100,
    xpReward: 150,
    startSubway: 'Chorsu',
    endSubway: 'Gafur Gulom',
    stops: [
      {
        placeId: 'place_chorsu',
        name: 'Chorsu Bazaar Food Court',
        district: 'Old City',
        atmosphereTag: 'Heritage Food',
        nearestSubway: 'Chorsu',
        walkingMinutes: 0,
      },
      {
        placeId: 'place_samarkand',
        name: 'Samarkand Darvoza Osh',
        district: 'Old City',
        atmosphereTag: 'Master Plov',
        nearestSubway: 'Chorsu',
        walkingMinutes: 8,
      },
    ],
  },
  {
    id: 'central_cultural_promenade',
    title: 'Central Tashkent Cultural Promenade',
    subtitle: 'Modern architectural walk between Broadway, teatime, and Uzbek hospitality',
    district: 'Central Tashkent',
    emoji: '🏛️',
    totalMinutes: 14,
    distanceMeters: 980,
    xpReward: 150,
    startSubway: 'Amir Temur Xiyoboni',
    endSubway: 'Mustaqillik Maydoni',
    stops: [
      {
        placeId: 'place_tims',
        name: 'TIMS Coffee & Roastery',
        district: 'Central Tashkent',
        atmosphereTag: 'Specialty Roast',
        nearestSubway: 'Amir Temur Xiyoboni',
        walkingMinutes: 0,
      },
      {
        placeId: 'place_afsona',
        name: 'Afsona Uzbek Contemporary',
        district: 'Central Tashkent',
        atmosphereTag: 'Authentic Fusion',
        nearestSubway: 'Mustaqillik Maydoni',
        walkingMinutes: 6,
      },
      {
        placeId: 'place_dodo',
        name: 'Dodo Amir Temur',
        district: 'Central Tashkent',
        atmosphereTag: 'Casual Hangout',
        nearestSubway: 'Amir Temur Xiyoboni',
        walkingMinutes: 8,
      },
    ],
  },
];

export function getLocalizedRouteTitle(route: WebCuratedRoute, lang: 'en' | 'uz' | 'ru' = 'en'): string {
  if (lang === 'uz') {
    switch (route.id) {
      case 'mirabad_coffee_crawl':
        return 'Mirobod Qahva Sayri';
      case 'chorsu_heritage_trail':
        return 'Eski Shahar Merosi va Bozor Yo‘li';
      case 'central_cultural_promenade':
        return 'Markaziy Toshkent Madaniy Sayri';
    }
  } else if (lang === 'ru') {
    switch (route.id) {
      case 'mirabad_coffee_crawl':
        return 'Кофейный маршрут по Мирабаду';
      case 'chorsu_heritage_trail':
        return 'Исторический маршрут по Чорсу';
      case 'central_cultural_promenade':
        return 'Культурная прогулка по Центру';
    }
  }
  return route.title;
}

export function calculateWebRouteProgress(
  route: WebCuratedRoute,
  visitedPlaceIds: string[] = []
): WebRouteProgress {
  if (route.stops.length === 0) {
    return {
      totalStops: 0,
      completedStops: 0,
      percentage: 0,
      isCompleted: false,
      nextPendingStop: null,
    };
  }

  const visitedSet = new Set(visitedPlaceIds);
  let completed = 0;
  let nextPending: WebRouteStop | null = null;

  for (const stop of route.stops) {
    if (visitedSet.has(stop.placeId)) {
      completed += 1;
    } else if (!nextPending) {
      nextPending = stop;
    }
  }

  const percentage = Math.round((completed / route.stops.length) * 100);

  return {
    totalStops: route.stops.length,
    completedStops: completed,
    percentage,
    isCompleted: completed === route.stops.length,
    nextPendingStop: nextPending,
  };
}

export interface CuratedRouteNavigatorProps {
  route?: WebCuratedRoute;
  routes?: WebCuratedRoute[];
  selectedRouteId?: string;
  visitedPlaceIds?: string[];
  onSelectRoute?: (routeId: string) => void;
  onSelectStop?: (stop: WebRouteStop) => void;
  onStartRoute?: (route: WebCuratedRoute) => void;
  language?: 'en' | 'uz' | 'ru';
}

export const CuratedRouteNavigator: React.FC<CuratedRouteNavigatorProps> = ({
  route: propRoute,
  routes = DEFAULT_WEB_ROUTES,
  selectedRouteId,
  visitedPlaceIds = [],
  onSelectRoute,
  onSelectStop,
  onStartRoute,
  language = 'en',
}) => {
  const [activeRouteId, setActiveRouteId] = React.useState<string>(
    selectedRouteId || propRoute?.id || routes[0]?.id || 'mirabad_coffee_crawl'
  );

  const activeRoute = React.useMemo(() => {
    if (propRoute) return propRoute;
    return routes.find((r) => r.id === activeRouteId) || routes[0];
  }, [propRoute, routes, activeRouteId]);

  const progress = React.useMemo(() => {
    return calculateWebRouteProgress(activeRoute, visitedPlaceIds);
  }, [activeRoute, visitedPlaceIds]);

  const handleRouteChange = (id: string) => {
    playSoundWithHaptic('select');
    setActiveRouteId(id);
    onSelectRoute?.(id);
  };

  const handleStopClick = (stop: WebRouteStop) => {
    playSoundWithHaptic('select');
    onSelectStop?.(stop);
  };

  const handleStartCrawl = () => {
    playSoundWithHaptic('success');
    onStartRoute?.(activeRoute);
  };

  const t = {
    crawlHeader:
      language === 'uz'
        ? 'TOSHKENTNING SARALANGAN SAYRLARI'
        : language === 'ru'
        ? 'КУРИРОВАННЫЕ МАРШРУТЫ ТАШКЕНТА'
        : 'CURATED TASHKENT WALKING CRAWLS',
    startCrawl:
      language === 'uz' ? 'Sayrni Boshlash' : language === 'ru' ? 'Начать маршрут' : 'Start Crawl',
    completed:
      language === 'uz'
        ? 'Marshrut Tamomlandi 🏆'
        : language === 'ru'
        ? 'Маршрут пройден 🏆'
        : 'Route Completed 🏆',
    visitedLabel:
      language === 'uz' ? 'tashrif buyurildi' : language === 'ru' ? 'посещено' : 'visited',
    nextStop:
      language === 'uz' ? 'Keyingi bekat' : language === 'ru' ? 'Следующая' : 'Next Stop',
    min: language === 'uz' ? 'daq' : language === 'ru' ? 'мин' : 'min',
    stops: language === 'uz' ? 'bekat' : language === 'ru' ? 'остановок' : 'stops',
  };

  return (
    <div
      data-testid="curated-route-navigator"
      style={{
        background: '#1A1A1A',
        borderRadius: 16,
        padding: 20,
        color: '#FFFFFF',
        border: '1px solid #2A2A2A',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
      }}
    >
      {/* Section Tag */}
      <div style={{ fontSize: 10, fontWeight: 800, color: '#FF5A1F', letterSpacing: '0.12em', textTransform: 'uppercase', marginBottom: 12 }}>
        🗺️ {t.crawlHeader}
      </div>

      {/* Route Switcher Tabs */}
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', marginBottom: 16 }}>
        {routes.map((r) => {
          const isSelected = r.id === activeRoute.id;
          return (
            <button
              key={r.id}
              data-testid={`route-tab-${r.id}`}
              onClick={() => handleRouteChange(r.id)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                padding: '8px 12px',
                borderRadius: 10,
                border: isSelected ? '1px solid #FF5A1F' : '1px solid #333333',
                background: isSelected ? 'rgba(255, 90, 31, 0.15)' : '#242424',
                color: isSelected ? '#FFFFFF' : '#A0A0A0',
                cursor: 'pointer',
                fontSize: 12,
                fontWeight: 600,
                whiteSpace: 'nowrap',
              }}
            >
              <span>{r.emoji}</span>
              <span>{r.district}</span>
            </button>
          );
        })}
      </div>

      {/* Active Route Header Card */}
      <div
        style={{
          background: '#222222',
          border: progress.isCompleted ? '1px solid #66E5B4' : '1px solid #333333',
          borderRadius: 12,
          padding: 16,
          marginBottom: 16,
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 20 }}>{activeRoute.emoji}</span>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700 }}>
                {getLocalizedRouteTitle(activeRoute, language)}
              </h3>
            </div>
            <p style={{ margin: '4px 0 0', fontSize: 12, color: '#888888' }}>
              {activeRoute.subtitle}
            </p>
          </div>
          <span
            style={{
              fontSize: 11,
              fontWeight: 700,
              padding: '3px 8px',
              borderRadius: 6,
              background: 'rgba(255, 214, 102, 0.15)',
              color: '#FFD666',
            }}
          >
            +{activeRoute.xpReward} XP
          </span>
        </div>

        {/* Transit & Timing Pill */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 12,
            marginTop: 12,
            padding: '6px 10px',
            background: '#1A1A1A',
            borderRadius: 8,
            fontSize: 11,
            color: '#A0A0A0',
          }}
        >
          <span>🚶 {activeRoute.totalMinutes} {t.min} ({activeRoute.distanceMeters}m)</span>
          <span>📍 {activeRoute.stops.length} {t.stops}</span>
          <span>🚇 {activeRoute.startSubway} → {activeRoute.endSubway}</span>
        </div>

        {/* Progress Bar */}
        <div style={{ marginTop: 14 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, marginBottom: 4 }}>
            <span style={{ color: '#AAAAAA' }}>
              {progress.completedStops}/{progress.totalStops} {t.visitedLabel}
            </span>
            <span style={{ fontWeight: 700, color: progress.isCompleted ? '#66E5B4' : '#FF5A1F' }}>
              {progress.percentage}%
            </span>
          </div>
          <div style={{ width: '100%', height: 6, background: '#1A1A1A', borderRadius: 3, overflow: 'hidden' }}>
            <div
              style={{
                width: `${progress.percentage}%`,
                height: '100%',
                background: progress.isCompleted ? '#66E5B4' : '#FF5A1F',
                transition: 'width 0.3s ease',
              }}
            />
          </div>
        </div>
      </div>

      {/* Stop Timeline */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
        {activeRoute.stops.map((stop, index) => {
          const isDone = visitedPlaceIds.includes(stop.placeId);
          const isNext = progress.nextPendingStop?.placeId === stop.placeId;

          return (
            <div
              key={stop.placeId}
              data-testid={`stop-item-${stop.placeId}`}
              onClick={() => handleStopClick(stop)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: '10px 12px',
                background: '#222222',
                border: isNext ? '1px solid #FF5A1F' : '1px solid #2D2D2D',
                borderRadius: 10,
                cursor: 'pointer',
              }}
            >
              {/* Step Badge */}
              <div
                style={{
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 11,
                  fontWeight: 700,
                  background: isDone ? '#66E5B4' : isNext ? '#FF5A1F' : '#333333',
                  color: isDone ? '#000000' : '#FFFFFF',
                }}
              >
                {isDone ? '✓' : index + 1}
              </div>

              {/* Stop Info */}
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    fontSize: 13,
                    fontWeight: 600,
                    color: isDone ? '#888888' : '#FFFFFF',
                    textDecoration: isDone ? 'line-through' : 'none',
                  }}
                >
                  {stop.name}
                </div>
                <div style={{ display: 'flex', gap: 8, fontSize: 10, color: '#888888', marginTop: 2 }}>
                  <span>{stop.atmosphereTag}</span>
                  <span>🚇 {stop.nearestSubway}</span>
                  {stop.walkingMinutes > 0 && <span>+{stop.walkingMinutes} {t.min} walk</span>}
                </div>
              </div>

              {isNext && (
                <span
                  style={{
                    fontSize: 9,
                    fontWeight: 700,
                    padding: '2px 6px',
                    borderRadius: 4,
                    background: 'rgba(255, 90, 31, 0.2)',
                    color: '#FF5A1F',
                  }}
                >
                  {t.nextStop}
                </span>
              )}
            </div>
          );
        })}
      </div>

      {/* Start Button */}
      <button
        data-testid="start-crawl-button"
        onClick={handleStartCrawl}
        style={{
          width: '100%',
          padding: 12,
          borderRadius: 10,
          border: progress.isCompleted ? '1px solid #66E5B4' : 'none',
          background: progress.isCompleted ? '#222222' : '#FF5A1F',
          color: progress.isCompleted ? '#66E5B4' : '#FFFFFF',
          fontSize: 13,
          fontWeight: 700,
          cursor: 'pointer',
        }}
      >
        {progress.isCompleted ? t.completed : t.startCrawl}
      </button>
    </div>
  );
};
