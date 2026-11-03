import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebClusterIntensity = 'serene' | 'lively' | 'buzzing' | 'peak';

export interface WebNeighborhoodCluster {
  id: string;
  district: string;
  centroidLat: number;
  centroidLng: number;
  dropsCount: number;
  intensity: WebClusterIntensity;
  primaryVenueName: string;
  venueNames: string[];
}

export function getWebClusterIntensity(count: number): WebClusterIntensity {
  if (count >= 11) return 'peak';
  if (count >= 6) return 'buzzing';
  if (count >= 3) return 'lively';
  return 'serene';
}

export function getWebClusterColor(intensity: WebClusterIntensity): string {
  switch (intensity) {
    case 'serene':
      return '#10b981'; // Emerald/Mint
    case 'lively':
      return '#f59e0b'; // Amber
    case 'buzzing':
      return '#f97316'; // Orange
    case 'peak':
      return '#ef4444'; // Red/Coral
  }
}

export function getWebClusterEmoji(intensity: WebClusterIntensity): string {
  switch (intensity) {
    case 'serene':
      return '🍃';
    case 'lively':
      return '✨';
    case 'buzzing':
      return '🔥';
    case 'peak':
      return '⚡';
  }
}

export function formatWebClusterSummary(
  cluster: WebNeighborhoodCluster,
  locale = 'en',
): string {
  const lang = locale.toLowerCase();
  if (lang.startsWith('uz')) {
    return `${cluster.primaryVenueName} va yaqinida ${cluster.dropsCount} ta drop`;
  } else if (lang.startsWith('ru')) {
    return `${cluster.dropsCount} дроп(ов) в районе ${cluster.primaryVenueName} и рядом`;
  }
  return `${cluster.dropsCount} drops across ${cluster.primaryVenueName} & nearby`;
}

export interface WebNeighborhoodHeatmapProps {
  clusters?: WebNeighborhoodCluster[];
  selectedDistrict?: string;
  locale?: string;
  onClusterClick?: (cluster: WebNeighborhoodCluster) => void;
}

export const WebNeighborhoodHeatmap: React.FC<WebNeighborhoodHeatmapProps> = ({
  clusters = [],
  selectedDistrict = 'all',
  locale = 'en',
  onClusterClick,
}) => {
  const [activeCluster, setActiveCluster] = useState<WebNeighborhoodCluster | null>(
    null,
  );

  const filteredClusters =
    selectedDistrict && selectedDistrict !== 'all'
      ? clusters.filter(
          (c) => c.district.toLowerCase() === selectedDistrict.trim().toLowerCase(),
        )
      : clusters;

  const handleClusterSelect = (c: WebNeighborhoodCluster) => {
    setActiveCluster(c);
    playSoundWithHaptic('select');
    if (onClusterClick) {
      onClusterClick(c);
    }
  };

  const getIntensityLabel = (intensity: WebClusterIntensity) => {
    const lang = locale.toLowerCase();
    switch (intensity) {
      case 'serene':
        return lang.startsWith('uz')
          ? 'Sokin Hudud'
          : lang.startsWith('ru')
          ? 'Спокойный уголок'
          : 'Serene Spot';
      case 'lively':
        return lang.startsWith('uz')
          ? 'Jonli Muhit'
          : lang.startsWith('ru')
          ? 'Оживленное место'
          : 'Lively Spot';
      case 'buzzing':
        return lang.startsWith('uz')
          ? 'Qaynoq Nuqta'
          : lang.startsWith('ru')
          ? 'Бурлящая точка'
          : 'Buzzing Hotspot';
      case 'peak':
        return lang.startsWith('uz')
          ? 'Eng Ommabop Markaz'
          : lang.startsWith('ru')
          ? 'Пик активности'
          : 'Peak Activity Center';
    }
  };

  return (
    <div className="w-full max-w-xl mx-auto p-5 rounded-2xl bg-white dark:bg-stone-900 border border-stone-200 dark:border-stone-800 shadow-md">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-stone-100 dark:border-stone-800">
        <div>
          <div className="flex items-center gap-1.5">
            <span className="text-lg">🗺️</span>
            <h2 className="text-base font-black text-stone-900 dark:text-stone-100">
              {locale.startsWith('uz')
                ? 'Mahalla Qaynoq Nuqtalari'
                : locale.startsWith('ru')
                ? 'Тепловая Карта Районов'
                : 'Neighborhood Heatmap'}
            </h2>
          </div>
          <p className="text-xs font-semibold text-stone-500 dark:text-stone-400 mt-0.5">
            {filteredClusters.length}{' '}
            {locale.startsWith('uz')
              ? 'faol klaster'
              : locale.startsWith('ru')
              ? 'активных точек'
              : 'active clusters'}
          </p>
        </div>

        {/* Legend */}
        <div className="flex items-center gap-1.5">
          {(['serene', 'lively', 'buzzing', 'peak'] as WebClusterIntensity[]).map(
            (lvl) => (
              <span
                key={lvl}
                className="w-2.5 h-2.5 rounded-full"
                style={{ backgroundColor: getWebClusterColor(lvl) }}
                title={getIntensityLabel(lvl)}
              />
            ),
          )}
        </div>
      </div>

      {/* Cluster Grid Cards */}
      <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 gap-2.5">
        {filteredClusters.length === 0 ? (
          <div
            data-testid="heatmap-empty-state"
            className="col-span-full py-8 text-center text-xs font-semibold text-stone-400"
          >
            {locale.startsWith('uz')
              ? 'Ushbu tumanda klasterlar topilmadi'
              : locale.startsWith('ru')
              ? 'В этом районе нет активных точек'
              : 'No activity clusters in this district'}
          </div>
        ) : (
          filteredClusters.map((cluster) => {
            const color = getWebClusterColor(cluster.intensity);
            const isSelected = activeCluster?.id === cluster.id;

            return (
              <div
                key={cluster.id}
                data-testid={`heatmap-cluster-card-${cluster.id}`}
                onClick={() => handleClusterSelect(cluster)}
                className={`p-3 rounded-xl border cursor-pointer transition-all ${
                  isSelected
                    ? 'bg-stone-50 dark:bg-stone-800/80 border-orange-500 ring-2 ring-orange-500/20'
                    : 'bg-stone-50/60 dark:bg-stone-800/40 border-stone-200 dark:border-stone-800 hover:border-stone-300'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-base">
                      {getWebClusterEmoji(cluster.intensity)}
                    </span>
                    <span className="text-xs font-black text-stone-900 dark:text-stone-100 truncate max-w-[140px]">
                      {cluster.primaryVenueName}
                    </span>
                  </div>

                  <span
                    className="text-[10px] font-black px-1.5 py-0.5 rounded-md text-white"
                    style={{ backgroundColor: color }}
                  >
                    {cluster.dropsCount}
                  </span>
                </div>

                <div className="mt-1.5 flex items-center justify-between text-[11px] text-stone-500 dark:text-stone-400">
                  <span>{cluster.district}</span>
                  <span className="font-bold">{getIntensityLabel(cluster.intensity)}</span>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Inspection Details Footer */}
      {activeCluster && (
        <div
          data-testid="heatmap-inspection-footer"
          className="mt-4 p-3 rounded-xl bg-orange-50 dark:bg-orange-950/30 border border-orange-200 dark:border-orange-800/60 flex items-center justify-between"
        >
          <div>
            <div className="text-xs font-black text-stone-900 dark:text-stone-100">
              {activeCluster.primaryVenueName}
            </div>
            <div className="text-[11px] text-stone-600 dark:text-stone-400">
              {formatWebClusterSummary(activeCluster, locale)}
            </div>
          </div>
          <div className="text-right">
            <span className="text-xs font-black text-orange-600 dark:text-orange-400">
              {getIntensityLabel(activeCluster.intensity)}
            </span>
          </div>
        </div>
      )}
    </div>
  );
};
