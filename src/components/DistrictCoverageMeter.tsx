import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type DistrictCoverageStatus = 'unexplored' | 'discovering' | 'mastered';

export interface WebDistrictCoverageItem {
  district: string;
  visitedCount: number;
  totalPlaces: number;
  coverageFraction: number;
  coveragePercent: number;
  statusLevel: DistrictCoverageStatus;
  statusBadge: string;
}

export interface WebCityCoverageSummary {
  totalVisited: number;
  totalPlaces: number;
  overallFraction: number;
  overallPercentage: number;
  districts: WebDistrictCoverageItem[];
  mostExplored: WebDistrictCoverageItem | null;
  leastExplored: WebDistrictCoverageItem | null;
  recommendedSpot: {
    id: string;
    name: string;
    district: string;
  } | null;
}

export interface TashkentCatalogPlace {
  id: string;
  name: string;
  district: string;
}

export const TASHKENT_CATALOG_PLACES: TashkentCatalogPlace[] = [
  { id: 'place_breadly', name: 'Breadly Bakery', district: 'Mirabad' },
  { id: 'place_socials', name: 'Socials Cafe', district: 'Mirabad' },
  { id: 'place_ekler', name: 'Ekler Patisserie', district: 'Mirabad' },
  { id: 'place_tims', name: 'TIMS Coffee & Roastery', district: 'Central Tashkent' },
  { id: 'place_afsona', name: 'Afsona Restaurant', district: 'Central Tashkent' },
  { id: 'place_dodo', name: 'Dodo Pizza Amir Temur', district: 'Central Tashkent' },
  { id: 'place_bnb', name: 'B&B Coffee House', district: 'Yakkasaray' },
  { id: 'place_shashlik', name: 'Sim Sim Teahouse', district: 'Yakkasaray' },
  { id: 'place_chorsu', name: 'Chorsu Bazaar Food Court', district: 'Old City' },
  { id: 'place_samarkand', name: 'Samarkand Darvoza Osh', district: 'Old City' },
  { id: 'place_yunusabad', name: 'Tashkent TV Tower Cafe', district: 'Yunusabad' },
  { id: 'place_megaplanet', name: 'Mega Planet Lounge', district: 'Yunusabad' },
];

export const TASHKENT_DISTRICTS = [
  'Mirabad',
  'Central Tashkent',
  'Yakkasaray',
  'Old City',
  'Yunusabad',
] as const;

export function getStatusBadge(status: DistrictCoverageStatus, lang: 'en' | 'uz' | 'ru' = 'en'): string {
  switch (status) {
    case 'mastered':
      if (lang === 'uz') return '👑 O‘zlashtirilgan';
      if (lang === 'ru') return '👑 Освоено';
      return '👑 Mastered';
    case 'discovering':
      if (lang === 'uz') return '🧭 O‘rganilmoqda';
      if (lang === 'ru') return '🧭 Исследуется';
      return '🧭 Exploring';
    case 'unexplored':
      if (lang === 'uz') return '🌱 O‘rganilmagan';
      if (lang === 'ru') return '🌱 Не исследовано';
      return '🌱 Unexplored';
  }
}

export function calculateWebDistrictCoverage(
  visitedPlaceIds: string[],
  catalog: TashkentCatalogPlace[] = TASHKENT_CATALOG_PLACES,
  lang: 'en' | 'uz' | 'ru' = 'en'
): WebCityCoverageSummary {
  const visitedSet = new Set(visitedPlaceIds);
  const districtMap = new Map<string, { total: number; visited: number; unvisitedPlaces: TashkentCatalogPlace[] }>();

  for (const d of TASHKENT_DISTRICTS) {
    districtMap.set(d, { total: 0, visited: 0, unvisitedPlaces: [] });
  }

  for (const place of catalog) {
    let entry = districtMap.get(place.district);
    if (!entry) {
      entry = { total: 0, visited: 0, unvisitedPlaces: [] };
      districtMap.set(place.district, entry);
    }
    entry.total += 1;
    if (visitedSet.has(place.id)) {
      entry.visited += 1;
    } else {
      entry.unvisitedPlaces.push(place);
    }
  }

  const items: WebDistrictCoverageItem[] = [];
  let totalPlacesCount = 0;
  let totalVisitedCount = 0;

  for (const [district, stats] of districtMap.entries()) {
    const total = stats.total;
    const visited = Math.min(stats.visited, total);
    totalPlacesCount += total;
    totalVisitedCount += visited;

    const fraction = total > 0 ? visited / total : 0;
    const percent = Math.round(fraction * 100);

    let statusLevel: DistrictCoverageStatus = 'unexplored';
    if (fraction >= 0.6) {
      statusLevel = 'mastered';
    } else if (fraction > 0.0) {
      statusLevel = 'discovering';
    }

    items.push({
      district,
      visitedCount: visited,
      totalPlaces: total,
      coverageFraction: Number(fraction.toFixed(2)),
      coveragePercent: percent,
      statusLevel,
      statusBadge: getStatusBadge(statusLevel, lang),
    });
  }

  const overallFraction = totalPlacesCount > 0 ? totalVisitedCount / totalPlacesCount : 0;
  const overallPercentage = Math.round(overallFraction * 100);

  const districtsWithVenues = items.filter((i) => i.totalPlaces > 0);
  let leastExplored: WebDistrictCoverageItem | null = null;
  let mostExplored: WebDistrictCoverageItem | null = null;

  if (districtsWithVenues.length > 0) {
    leastExplored = [...districtsWithVenues].sort((a, b) => a.coverageFraction - b.coverageFraction)[0];
    mostExplored = [...districtsWithVenues].sort((a, b) => b.coverageFraction - a.coverageFraction)[0];
  }

  let recommendedSpot: WebCityCoverageSummary['recommendedSpot'] = null;
  if (leastExplored) {
    const unvisited = districtMap.get(leastExplored.district)?.unvisitedPlaces || [];
    if (unvisited.length > 0) {
      recommendedSpot = {
        id: unvisited[0].id,
        name: unvisited[0].name,
        district: unvisited[0].district,
      };
    }
  }

  return {
    totalVisited: totalVisitedCount,
    totalPlaces: totalPlacesCount,
    overallFraction: Number(overallFraction.toFixed(2)),
    overallPercentage,
    districts: items,
    mostExplored,
    leastExplored,
    recommendedSpot,
  };
}

export interface DistrictCoverageMeterProps {
  summary?: WebCityCoverageSummary;
  visitedPlaceIds?: string[];
  selectedDistrict?: string | null;
  onSelectDistrict?: (district: string) => void;
  onExplorePlace?: (placeId: string) => void;
  language?: 'en' | 'uz' | 'ru';
}

export const DistrictCoverageMeter: React.FC<DistrictCoverageMeterProps> = ({
  summary: propSummary,
  visitedPlaceIds = [],
  selectedDistrict,
  onSelectDistrict,
  onExplorePlace,
  language = 'en',
}) => {
  const summary = React.useMemo(() => {
    return propSummary || calculateWebDistrictCoverage(visitedPlaceIds, TASHKENT_CATALOG_PLACES, language);
  }, [propSummary, visitedPlaceIds, language]);

  const handleDistrictClick = (district: string) => {
    playSoundWithHaptic('click');
    onSelectDistrict?.(district);
  };

  const handleRecommendationClick = (placeId: string) => {
    playSoundWithHaptic('select');
    onExplorePlace?.(placeId);
  };

  const titleText =
    language === 'uz'
      ? 'TOSHKENT KASHFIYOT XARITASI'
      : language === 'ru'
      ? 'ТЕПЛОВАЯ КАРТА ТАШКЕНТА'
      : 'TASHKENT EXPLORATION HEAT';

  const subtitleText =
    language === 'uz'
      ? `Toshkentning ${summary.overallPercentage}% qismi kashf etildi`
      : language === 'ru'
      ? `Исследовано ${summary.overallPercentage}% Ташкента`
      : `${summary.overallPercentage}% of Tashkent Explored`;

  const recommendationHeader =
    language === 'uz'
      ? 'Tavsiya etilgan keyingi manzil'
      : language === 'ru'
      ? 'Следующее рекомендуемое место'
      : 'Next Recommended Discovery';

  return (
    <div
      data-testid="district-coverage-meter"
      style={{
        background: '#1A1A1A',
        borderRadius: 16,
        padding: 20,
        color: '#FFFFFF',
        border: '1px solid #2A2A2A',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
      }}
    >
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div>
          <span
            style={{
              fontSize: 10,
              fontWeight: 800,
              letterSpacing: '0.12em',
              color: '#FF5A1F',
              textTransform: 'uppercase',
            }}
          >
            {titleText}
          </span>
          <h3 style={{ margin: '4px 0 0', fontSize: 18, fontWeight: 700 }}>
            {subtitleText}
          </h3>
        </div>
        <div
          style={{
            background: 'rgba(255, 90, 31, 0.15)',
            border: '1px solid rgba(255, 90, 31, 0.35)',
            borderRadius: 12,
            padding: '6px 12px',
            textAlign: 'center',
          }}
        >
          <span style={{ fontSize: 18, fontWeight: 800, color: '#FF5A1F' }}>
            {summary.overallPercentage}%
          </span>
        </div>
      </div>

      {/* Overall Progress Bar */}
      <div
        style={{
          width: '100%',
          height: 8,
          background: '#2A2A2A',
          borderRadius: 4,
          overflow: 'hidden',
          marginBottom: 20,
        }}
      >
        <div
          data-testid="overall-progress-bar"
          style={{
            width: `${summary.overallPercentage}%`,
            height: '100%',
            background: 'linear-gradient(90deg, #FF5A1F 0%, #FFB020 100%)',
            transition: 'width 0.4s ease',
          }}
        />
      </div>

      {/* Districts List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {summary.districts.map((item) => {
          const isSelected = selectedDistrict === item.district;
          const barColor =
            item.statusLevel === 'mastered'
              ? '#FFD666'
              : item.statusLevel === 'discovering'
              ? '#FF5A1F'
              : '#444444';

          return (
            <div
              key={item.district}
              data-testid={`district-row-${item.district.toLowerCase().replace(/\s+/g, '-')}`}
              onClick={() => handleDistrictClick(item.district)}
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: 6,
                padding: '10px 12px',
                background: isSelected ? 'rgba(255, 90, 31, 0.1)' : '#222222',
                border: isSelected ? '1px solid #FF5A1F' : '1px solid #2D2D2D',
                borderRadius: 10,
                cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 600, fontSize: 13, color: '#FFFFFF' }}>{item.district}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: 11, color: '#A0A0A0' }}>
                    {item.visitedCount}/{item.totalPlaces} ({item.coveragePercent}%)
                  </span>
                  <span
                    style={{
                      fontSize: 10,
                      fontWeight: 700,
                      padding: '2px 6px',
                      borderRadius: 6,
                      background: 'rgba(255,255,255,0.08)',
                      color: barColor,
                    }}
                  >
                    {item.statusBadge}
                  </span>
                </div>
              </div>

              {/* District Track */}
              <div
                style={{
                  width: '100%',
                  height: 4,
                  background: '#1A1A1A',
                  borderRadius: 2,
                  overflow: 'hidden',
                }}
              >
                <div
                  style={{
                    width: `${item.coveragePercent}%`,
                    height: '100%',
                    background: barColor,
                    transition: 'width 0.3s ease',
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {/* Recommendation Card */}
      {summary.recommendedSpot && (
        <div
          data-testid="recommendation-card"
          style={{
            marginTop: 18,
            padding: 14,
            background: 'linear-gradient(135deg, rgba(255, 90, 31, 0.1) 0%, rgba(30, 30, 30, 0.8) 100%)',
            border: '1px solid rgba(255, 90, 31, 0.3)',
            borderRadius: 12,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, color: '#FF5A1F', textTransform: 'uppercase' }}>
              📍 {recommendationHeader}
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, marginTop: 2 }}>{summary.recommendedSpot.name}</div>
            <div style={{ fontSize: 11, color: '#888888' }}>{summary.recommendedSpot.district}</div>
          </div>
          <button
            data-testid="explore-button"
            onClick={(e) => {
              e.stopPropagation();
              if (summary.recommendedSpot) {
                handleRecommendationClick(summary.recommendedSpot.id);
              }
            }}
            style={{
              background: '#FF5A1F',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: 8,
              padding: '8px 14px',
              fontSize: 12,
              fontWeight: 700,
              cursor: 'pointer',
              whiteSpace: 'nowrap',
            }}
          >
            {language === 'uz' ? 'Joyni Ko‘rish' : language === 'ru' ? 'Посмотреть' : 'Explore Spot'}
          </button>
        </div>
      )}
    </div>
  );
};
