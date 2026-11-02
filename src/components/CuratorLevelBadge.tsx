import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebCuratorTier = 'neighborhoodScout' | 'districtCurator' | 'cityPioneer' | 'tashkentLegend';

export interface WebCuratorProgression {
  totalXp: number;
  level: number;
  tier: WebCuratorTier;
  title: string;
  emoji: string;
  color: string;
  progressFraction: number;
  xpToNextTier: number;
  progressLabel: string;
}

export function calculateWebCuratorProgression(
  dropsCount: number,
  streakWeeks: number = 0,
  crowns: number = 0,
  lang: 'en' | 'uz' | 'ru' = 'en'
): WebCuratorProgression {
  const safeDrops = Math.max(0, dropsCount);
  const safeStreaks = Math.max(0, streakWeeks);
  const safeCrowns = Math.max(0, crowns);

  const totalXp = safeDrops * 50 + safeStreaks * 100 + safeCrowns * 250;

  let tier: WebCuratorTier;
  let level: number;
  let emoji: string;
  let color: string;
  let currentBase: number;
  let nextBase: number | null;

  if (totalXp >= 2000) {
    tier = 'tashkentLegend';
    level = 4;
    emoji = '👑';
    color = '#FFD666'; // Golden Crown
    currentBase = 2000;
    nextBase = null;
  } else if (totalXp >= 750) {
    tier = 'cityPioneer';
    level = 3;
    emoji = '⚡';
    color = '#FF5A1F'; // Brand Orange
    currentBase = 750;
    nextBase = 2000;
  } else if (totalXp >= 250) {
    tier = 'districtCurator';
    level = 2;
    emoji = '🧭';
    color = '#2B4CFF'; // Cobalt Blue
    currentBase = 250;
    nextBase = 750;
  } else {
    tier = 'neighborhoodScout';
    level = 1;
    emoji = '🌱';
    color = '#8E8877'; // Muted Ink
    currentBase = 0;
    nextBase = 250;
  }

  let progressFraction: number;
  let xpToNextTier: number;

  if (nextBase === null) {
    progressFraction = 1.0;
    xpToNextTier = 0;
  } else {
    const range = nextBase - currentBase;
    progressFraction = Math.min(1.0, Math.max(0.0, (totalXp - currentBase) / range));
    xpToNextTier = nextBase - totalXp;
  }

  let title: string;
  switch (tier) {
    case 'neighborhoodScout':
      title = lang === 'uz' ? 'Mahalla Izquvari' : lang === 'ru' ? 'Разведчик района' : 'Neighborhood Scout';
      break;
    case 'districtCurator':
      title = lang === 'uz' ? 'Tuman Kuratori' : lang === 'ru' ? 'Куратор района' : 'District Curator';
      break;
    case 'cityPioneer':
      title = lang === 'uz' ? 'Shahar Keshfiyotchisi' : lang === 'ru' ? 'Городской пионер' : 'City Pioneer';
      break;
    case 'tashkentLegend':
      title = lang === 'uz' ? 'Toshkent Afsonasi' : lang === 'ru' ? 'Легенда Ташкента' : 'Tashkent Legend';
      break;
  }

  let progressLabel: string;
  if (nextBase === null) {
    progressLabel = lang === 'uz' ? 'Eng yuqori cho‘qqi!' : lang === 'ru' ? 'Максимальный уровень!' : 'Max Level Reached!';
  } else {
    progressLabel =
      lang === 'uz'
        ? `Keyingi darajagacha ${xpToNextTier} XP`
        : lang === 'ru'
        ? `До след. уровня: ${xpToNextTier} XP`
        : `${xpToNextTier} XP to next level`;
  }

  return {
    totalXp,
    level,
    tier,
    title,
    emoji,
    color,
    progressFraction,
    xpToNextTier,
    progressLabel,
  };
}

export interface CuratorLevelBadgeProps {
  dropsCount: number;
  streakWeeks?: number;
  crowns?: number;
  lang?: 'en' | 'uz' | 'ru';
  onTap?: () => void;
  className?: string;
}

/**
 * Web Companion Curator Level & Tier Showcase Component (`P23-03`).
 * Renders level badge, XP progress bar, and plays tactile web audio on click.
 */
export const CuratorLevelBadge: React.FC<CuratorLevelBadgeProps> = ({
  dropsCount,
  streakWeeks = 0,
  crowns = 0,
  lang = 'en',
  onTap,
  className = '',
}) => {
  const p = calculateWebCuratorProgression(dropsCount, streakWeeks, crowns, lang);

  const handleClick = () => {
    playSoundWithHaptic('select', 'selection');
    onTap?.call(undefined);
  };

  const percentage = Math.round(p.progressFraction * 100);

  return (
    <div
      onClick={handleClick}
      role="button"
      tabIndex={0}
      aria-label={`${p.title} - Level ${p.level} with ${p.totalXp} XP`}
      className={`curator-level-badge-card cursor-pointer p-4 rounded-2xl bg-paper border border-paper3 hover:border-ink3 transition-all duration-150 shadow-sm ${className}`}
    >
      <div className="flex items-center justify-between gap-3 mb-3">
        <div className="flex items-center gap-3">
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center text-xl flex-shrink-0"
            style={{ backgroundColor: `${p.color}22`, border: `1px solid ${p.color}44` }}
          >
            {p.emoji}
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-ink text-sm leading-tight">{p.title}</span>
              <span
                className="text-[10px] font-mono font-bold px-1.5 py-0.5 rounded"
                style={{ backgroundColor: `${p.color}22`, color: p.color }}
              >
                LVL {p.level}
              </span>
            </div>
            <p className="text-xs text-ink3 font-medium mt-0.5">{p.progressLabel}</p>
          </div>
        </div>

        <div className="bg-paper2 border border-paper3 px-2.5 py-1 rounded-lg text-xs font-mono font-bold text-ink flex-shrink-0">
          {p.totalXp} XP
        </div>
      </div>

      {/* Progress Track */}
      <div className="w-full bg-paper3 h-2 rounded-full overflow-hidden mb-2">
        <div
          className="h-full rounded-full transition-all duration-300"
          style={{
            width: `${percentage}%`,
            backgroundColor: p.color,
          }}
        />
      </div>

      <div className="flex justify-between items-center text-[11px] font-medium text-inkLight">
        <span>
          {dropsCount} drops • {streakWeeks}w streak {crowns > 0 ? `• 👑 ${crowns}` : ''}
        </span>
        <span className="font-mono text-ink2 font-bold">{percentage}%</span>
      </div>
    </div>
  );
};

export default CuratorLevelBadge;
