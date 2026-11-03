import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface PlaceRhythmHeatmapProps {
  placeName: string;
  category: string;
  tags?: string[];
  currentHour?: number;
  initialSelectedHour?: number;
  onSelectHour?: (hour: number) => void;
  className?: string;
}

export function computeHourlyDistribution(category: string, tags: string[] = []): number[] {
  const distribution = new Array(24).fill(0.15);
  const lowerCat = category.toLowerCase();
  const lowerTags = tags.map((t) => t.toLowerCase());

  const isCoffee =
    lowerCat.includes('coffee') ||
    lowerCat.includes('café') ||
    lowerCat.includes('cafe') ||
    lowerCat.includes('bakery') ||
    lowerTags.includes('coffee') ||
    lowerTags.includes('breakfast');

  const isNightlife =
    lowerCat.includes('bar') ||
    lowerCat.includes('night') ||
    lowerTags.includes('cocktails') ||
    lowerTags.includes('nightlife') ||
    lowerTags.includes('evening');

  const isCulture =
    lowerCat.includes('museum') ||
    lowerCat.includes('park') ||
    lowerTags.includes('culture') ||
    lowerTags.includes('heritage');

  for (let h = 0; h < 24; h++) {
    if (h < 7) {
      distribution[h] = 0.08;
    } else if (h >= 8 && h <= 11) {
      distribution[h] = isCoffee ? 0.95 : 0.45;
    } else if (h >= 12 && h <= 15) {
      distribution[h] = isCulture ? 0.85 : 0.60;
    } else if (h >= 16 && h <= 18) {
      distribution[h] = 0.65;
    } else if (h >= 19 && h <= 22) {
      distribution[h] = isNightlife ? 0.95 : 0.70;
    } else {
      distribution[h] = isNightlife ? 0.40 : 0.20;
    }
  }

  return distribution;
}

export function getVibeTag(hour: number, category: string, tags: string[] = []): string {
  const lowerCat = category.toLowerCase();
  const lowerTags = tags.map((t) => t.toLowerCase());

  if (hour >= 7 && hour <= 11) {
    if (lowerCat.includes('coffee') || lowerTags.includes('coffee') || lowerCat.includes('bakery')) {
      return '#MorningBrew';
    }
    return '#FreshStart';
  }

  if (hour >= 12 && hour <= 16) {
    if (lowerTags.includes('workfriendly') || lowerTags.includes('wifi')) {
      return '#WorkFriendly';
    }
    return '#LunchVibe';
  }

  if (hour >= 17 && hour <= 20) {
    return '#GoldenHour';
  }

  if (hour >= 21 || hour < 4) {
    return '#EveningBuzz';
  }

  return '#QuietHours';
}

export function computePeakWindow(distribution: number[]): { label: string; peakHour: number } {
  let bestStart = 8;
  let maxSum = 0;

  for (let h = 7; h <= 21; h++) {
    const sum = distribution[h] + distribution[(h + 1) % 24] + distribution[(h + 2) % 24];
    if (sum > maxSum) {
      maxSum = sum;
      bestStart = h;
    }
  }

  const endHour = (bestStart + 3) % 24;
  const startStr = `${bestStart.toString().padStart(2, '0')}:00`;
  const endStr = `${endHour.toString().padStart(2, '0')}:00`;

  return {
    label: `${startStr} – ${endStr}`,
    peakHour: bestStart + 1,
  };
}

export const PlaceRhythmHeatmap: React.FC<PlaceRhythmHeatmapProps> = ({
  placeName,
  category,
  tags = [],
  currentHour = 10,
  initialSelectedHour,
  onSelectHour,
  className = '',
}) => {
  const [selectedHour, setSelectedHour] = useState<number>(initialSelectedHour ?? currentHour);

  const distribution = computeHourlyDistribution(category, tags);
  const peak = computePeakWindow(distribution);
  const activeHour = selectedHour;
  const activeDensity = Math.round(distribution[activeHour] * 100);
  const vibeTag = getVibeTag(activeHour, category, tags);

  const handleHourClick = (h: number) => {
    playSoundWithHaptic('select');
    setSelectedHour(h);
    onSelectHour?.(h);
  };

  return (
    <div
      className={`place-rhythm-heatmap ${className}`}
      data-testid="place-rhythm-heatmap"
      style={{
        background: 'var(--paper, #FBFAF6)',
        borderRadius: '18px',
        border: '1.2px solid var(--paper3, #E6E1D3)',
        padding: '16px',
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.04)',
      }}
    >
      {/* Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '10px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span style={{ fontSize: '15px' }}>🌊</span>
          <span
            style={{
              fontFamily: 'var(--mono, "Space Mono", monospace)',
              fontSize: '10px',
              fontWeight: 700,
              letterSpacing: '1px',
              color: 'var(--orange, #FF5A1F)',
              textTransform: 'uppercase',
            }}
          >
            VENUE RHYTHM
          </span>
        </div>

        <div
          data-testid="peak-window-badge"
          style={{
            fontFamily: 'var(--mono, "Space Mono", monospace)',
            fontSize: '9.5px',
            fontWeight: 700,
            color: 'var(--orange, #FF5A1F)',
            background: 'rgba(255, 90, 31, 0.1)',
            padding: '3px 8px',
            borderRadius: '6px',
          }}
        >
          {`PEAK ${peak.label}`}
        </div>
      </div>

      <div
        style={{
          fontFamily: 'var(--display, "Bricolage Grotesque", sans-serif)',
          fontSize: '13.5px',
          fontWeight: 700,
          color: 'var(--ink, #15130F)',
          marginBottom: '12px',
        }}
      >
        {`Atmosphere rhythm for ${placeName}`}
      </div>

      {/* 24-Hour Sparkline Bars */}
      <div
        style={{
          display: 'flex',
          alignItems: 'flex-end',
          height: '64px',
          gap: '2px',
          paddingBottom: '4px',
          borderBottom: '1px solid var(--paper3, #E6E1D3)',
          marginBottom: '10px',
        }}
      >
        {distribution.map((val, h) => {
          const isSelected = h === activeHour;
          const isCurrent = h === currentHour;
          const heightPx = Math.max(6, Math.round(val * 58));

          let barBg = 'var(--paper2, #F1EEE4)';
          if (isSelected) {
            barBg = 'var(--orange, #FF5A1F)';
          } else if (val >= 0.8) {
            barBg = 'rgba(255, 90, 31, 0.45)';
          } else if (val >= 0.5) {
            barBg = 'var(--paper3, #E6E1D3)';
          }

          return (
            <div
              key={h}
              data-testid={`hour-bar-${h}`}
              onClick={() => handleHourClick(h)}
              title={`${h.toString().padStart(2, '0')}:00 · ${Math.round(val * 100)}% vibe`}
              style={{
                flex: 1,
                height: `${heightPx}px`,
                background: barBg,
                borderRadius: '3px 3px 1px 1px',
                cursor: 'pointer',
                position: 'relative',
                transition: 'all 0.15s ease',
              }}
            >
              {isCurrent && !isSelected && (
                <div
                  style={{
                    position: 'absolute',
                    top: '-6px',
                    left: '50%',
                    transform: 'translateX(-50%)',
                    width: '3px',
                    height: '3px',
                    borderRadius: '50%',
                    background: 'var(--orange, #FF5A1F)',
                  }}
                />
              )}
            </div>
          );
        })}
      </div>

      {/* Timeline Hour Scale Labels */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          fontFamily: 'var(--mono, "Space Mono", monospace)',
          fontSize: '9px',
          color: 'var(--ink3, #8E8877)',
          marginBottom: '12px',
        }}
      >
        <span>00:00</span>
        <span>06:00</span>
        <span>12:00</span>
        <span>18:00</span>
        <span>23:00</span>
      </div>

      {/* Selected Hour Details & Vibe Pill */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          background: 'var(--paper2, #F1EEE4)',
          borderRadius: '10px',
          padding: '8px 12px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span
            style={{
              fontFamily: 'var(--mono, "Space Mono", monospace)',
              fontSize: '11px',
              fontWeight: 700,
              color: 'var(--ink, #15130F)',
            }}
          >
            {`${activeHour.toString().padStart(2, '0')}:00`}
          </span>
          <span
            data-testid="active-vibe-tag"
            style={{
              fontFamily: 'var(--mono, "Space Mono", monospace)',
              fontSize: '10px',
              fontWeight: 700,
              color: 'var(--orange, #FF5A1F)',
            }}
          >
            {vibeTag}
          </span>
        </div>

        <div
          style={{
            fontFamily: 'var(--mono, "Space Mono", monospace)',
            fontSize: '11px',
            fontWeight: 700,
            color: 'var(--ink2, #575247)',
          }}
        >
          {`${activeDensity}% Active Vibe`}
        </div>
      </div>
    </div>
  );
};
