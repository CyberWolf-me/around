import React from 'react';
import { Place } from '../types';
import { playSoundWithHaptic } from '../services/soundEffects';

export type MetroLineType = 'chilonzor' | 'ozbekiston' | 'yunusobod' | 'all';

export interface MetroStationOption {
  id: string;
  name: string;
  nameUz: string;
  nameRu: string;
  line: MetroLineType;
  lineColor: string;
  nearbyPlaceIds: string[];
}

export const TASHKENT_METRO_STATIONS: MetroStationOption[] = [
  {
    id: 'all',
    name: 'All Metro Hubs',
    nameUz: 'Barcha Metro Bekatlari',
    nameRu: 'Все станции метро',
    line: 'all',
    lineColor: '#FF5A1F',
    nearbyPlaceIds: [],
  },
  {
    id: 'oybek',
    name: 'Oybek',
    nameUz: 'Oybek',
    nameRu: 'Ойбек',
    line: 'ozbekiston',
    lineColor: '#1E88E5',
    nearbyPlaceIds: ['breadly', 'bnb'],
  },
  {
    id: 'kosmonavtlar',
    name: 'Kosmonavtlar',
    nameUz: 'Kosmonavtlar',
    nameRu: 'Космонавтов',
    line: 'ozbekiston',
    lineColor: '#1E88E5',
    nearbyPlaceIds: ['bnb', 'kitobxon'],
  },
  {
    id: 'amir_temur',
    name: 'Amir Temur',
    nameUz: 'Amir Temur Xiyoboni',
    nameRu: 'Сквер Амира Темура',
    line: 'chilonzor',
    lineColor: '#E53935',
    nearbyPlaceIds: ['centralpark', 'broadway', 'ecorn', 'tims'],
  },
  {
    id: 'chorsu',
    name: 'Chorsu',
    nameUz: 'Chorsu',
    nameRu: 'Чорсу',
    line: 'ozbekiston',
    lineColor: '#1E88E5',
    nearbyPlaceIds: ['chorsu'],
  },
  {
    id: 'minor',
    name: 'Minor',
    nameUz: 'Minor',
    nameRu: 'Минор',
    line: 'yunusobod',
    lineColor: '#43A047',
    nearbyPlaceIds: ['steam', 'ecorn'],
  },
];

export interface MetroStationFilterProps {
  selectedStationId: string;
  onSelectStation: (stationId: string) => void;
  stations?: MetroStationOption[];
  lang?: 'en' | 'uz' | 'ru';
  className?: string;
}

/**
 * Filters places by selected metro landmark station.
 */
export function filterPlacesByMetroStation(
  places: Place[],
  stationId: string,
  stations: MetroStationOption[] = TASHKENT_METRO_STATIONS
): Place[] {
  if (stationId === 'all') return places;

  const station = stations.find((s) => s.id === stationId);
  if (!station) return places;

  return places.filter((p) => {
    // Exact match in nearby place list
    if (station.nearbyPlaceIds.includes(p.id)) return true;

    // Fuzzy text match in street or tags
    const searchTarget = `${p.name} ${p.street} ${(p.tags || []).join(' ')}`.toLowerCase();
    const stationName = station.name.toLowerCase();
    const stationRu = station.nameRu.toLowerCase();
    const stationUz = station.nameUz.toLowerCase();

    return (
      searchTarget.includes(stationName) ||
      searchTarget.includes(stationRu) ||
      searchTarget.includes(stationUz)
    );
  });
}

/**
 * Web Companion Metro Landmark Filter & Station Quick-Jump (`P22-03`).
 * Renders horizontal scrolling pills with line badge colors and audio-tactile haptics.
 */
export const MetroStationFilter: React.FC<MetroStationFilterProps> = ({
  selectedStationId,
  onSelectStation,
  stations = TASHKENT_METRO_STATIONS,
  lang = 'en',
  className = '',
}) => {
  const handleSelect = (stationId: string) => {
    playSoundWithHaptic('select', 'selection');
    onSelectStation(stationId);
  };

  const getStationLabel = (s: MetroStationOption) => {
    if (lang === 'uz') return s.nameUz;
    if (lang === 'ru') return s.nameRu;
    return s.name;
  };

  return (
    <div
      className={`metro-station-filter-bar flex items-center gap-2 overflow-x-auto py-2 px-1 scrollbar-none ${className}`}
      role="tablist"
      aria-label="Tashkent Metro Station Filter"
    >
      {stations.map((s) => {
        const isSelected = selectedStationId === s.id;
        const label = getStationLabel(s);

        return (
          <button
            key={s.id}
            role="tab"
            aria-selected={isSelected}
            onClick={() => handleSelect(s.id)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all duration-150 border ${
              isSelected
                ? 'bg-ink text-white border-ink shadow-sm'
                : 'bg-paper text-ink2 border-paper3 hover:border-ink3 hover:text-ink'
            }`}
          >
            {s.id !== 'all' && (
              <span
                className="w-2 h-2 rounded-full flex-shrink-0"
                style={{ backgroundColor: s.lineColor }}
                aria-hidden="true"
              />
            )}
            {s.id === 'all' && <span className="text-[11px]">🚇</span>}
            <span>{label}</span>
          </button>
        );
      })}
    </div>
  );
};

export default MetroStationFilter;
