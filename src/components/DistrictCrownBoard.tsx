import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebDistrictCurator {
  userId: string;
  username: string;
  fullName: string;
  avatarUrl?: string;
  rank: number;
  district: string;
  seasonXp: number;
  placesCount: number;
  crownsCount: number;
  gapToLeaderXp?: number;
}

export interface WebDistrictPodium {
  district: string;
  seasonId: string;
  champion?: WebDistrictCurator;
  silver?: WebDistrictCurator;
  bronze?: WebDistrictCurator;
  runnersUp: WebDistrictCurator[];
  totalCuratorsCount: number;
}

export const TASHKENT_DISTRICTS = [
  'Mirabad',
  'Yakkasaray',
  'Chilanzar',
  'Yunusabad',
  'Mirzo Ulugbek',
  'Shaikhontokhur',
  'Almazar',
  'Yashnabad',
  'Bektemir',
  'Sergeli',
  'Uchtepa',
] as const;

export function formatWebDistrictTitle(district: string, locale = 'en'): string {
  const lang = locale.toLowerCase();
  const cleanDistrict = district.trim();
  if (lang.startsWith('uz')) {
    return `${cleanDistrict} tumani`;
  } else if (lang.startsWith('ru')) {
    return `${cleanDistrict} район`;
  }
  return `${cleanDistrict} District`;
}

export function formatWebCuratorRankLabel(rank: number, locale = 'en'): string {
  const lang = locale.toLowerCase();
  switch (rank) {
    case 1:
      if (lang.startsWith('uz')) return '👑 Chempion Toji';
      if (lang.startsWith('ru')) return '👑 Корона Чемпиона';
      return '👑 Champion Crown';
    case 2:
      if (lang.startsWith('uz')) return '🥈 Kumush Shon-Sharaf';
      if (lang.startsWith('ru')) return '🥈 Серебряный Лавр';
      return '🥈 Silver Laurel';
    case 3:
      if (lang.startsWith('uz')) return '🥉 Bronza Shon-Sharaf';
      if (lang.startsWith('ru')) return '🥉 Бронзовый Лавр';
      return '🥉 Bronze Laurel';
    default:
      return `#${rank}`;
  }
}

export function computeWebDistrictPodium(
  rawStandings: WebDistrictCurator[],
  district: string,
  seasonId: string,
): WebDistrictPodium {
  if (!rawStandings || rawStandings.length === 0) {
    return {
      district,
      seasonId,
      runnersUp: [],
      totalCuratorsCount: 0,
    };
  }

  // Sort by crownsCount DESC, seasonXp DESC, placesCount DESC
  const sorted = [...rawStandings].sort((a, b) => {
    if (b.crownsCount !== a.crownsCount) return b.crownsCount - a.crownsCount;
    if (b.seasonXp !== a.seasonXp) return b.seasonXp - a.seasonXp;
    return b.placesCount - a.placesCount;
  });

  const leaderXp = sorted[0].seasonXp;
  const ranked: WebDistrictCurator[] = sorted.map((curator, idx) => ({
    ...curator,
    rank: idx + 1,
    gapToLeaderXp: Math.max(0, leaderXp - curator.seasonXp),
  }));

  return {
    district,
    seasonId,
    champion: ranked[0],
    silver: ranked[1],
    bronze: ranked[2],
    runnersUp: ranked.slice(3),
    totalCuratorsCount: ranked.length,
  };
}

export interface DistrictCrownBoardProps {
  initialDistrict?: string;
  standingsByDistrict?: Record<string, WebDistrictCurator[]>;
  seasonId?: string;
  locale?: string;
  onCuratorClick?: (curator: WebDistrictCurator) => void;
}

export const DistrictCrownBoard: React.FC<DistrictCrownBoardProps> = ({
  initialDistrict = 'Mirabad',
  standingsByDistrict = {},
  seasonId = '2026-11',
  locale = 'en',
  onCuratorClick,
}) => {
  const [selectedDistrict, setSelectedDistrict] = useState<string>(initialDistrict);

  const districtList = standingsByDistrict[selectedDistrict] || [];
  const podium = computeWebDistrictPodium(districtList, selectedDistrict, seasonId);

  const handleDistrictChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const nextDistrict = e.target.value;
    setSelectedDistrict(nextDistrict);
    playSoundWithHaptic('select');
  };

  const handleCuratorClick = (curator?: WebDistrictCurator, isChamp = false) => {
    if (!curator) return;
    if (isChamp) {
      playSoundWithHaptic('trophy');
    } else {
      playSoundWithHaptic('pop');
    }
    if (onCuratorClick) {
      onCuratorClick(curator);
    }
  };

  const renderPillar = (
    curator: WebDistrictCurator | undefined,
    rank: number,
    pillarHeight: string,
    accentColor: string,
    medal: string,
  ) => {
    const isFirst = rank === 1;
    const initials = curator
      ? curator.fullName
          .trim()
          .split(/\s+/)
          .map((n) => n[0])
          .slice(0, 2)
          .join('')
          .toUpperCase()
      : '?';

    const openLabel = locale.startsWith('uz')
      ? "Bo'sh"
      : locale.startsWith('ru')
      ? 'Свободно'
      : 'Open';

    return (
      <div
        data-testid={`podium-pillar-rank-${rank}`}
        className="flex-1 flex flex-col items-center cursor-pointer transition-transform hover:scale-[1.02] active:scale-[0.98]"
        onClick={() => handleCuratorClick(curator, isFirst)}
      >
        {/* Avatar & Medal */}
        <div className="relative mb-2 flex flex-col items-center">
          <div
            className={`flex items-center justify-center rounded-full bg-white dark:bg-stone-800 shadow-md ${
              isFirst ? 'w-14 h-14 border-2' : 'w-11 h-11 border'
            }`}
            style={{ borderColor: accentColor }}
          >
            <span
              className={`font-black ${
                isFirst ? 'text-base' : 'text-xs'
              } text-stone-800 dark:text-stone-100`}
            >
              {initials}
            </span>
          </div>
          <span className="absolute -top-3 text-base">{medal}</span>
        </div>

        {/* Username */}
        <div className="text-xs font-bold text-stone-800 dark:text-stone-200 truncate max-w-[90px] text-center">
          {curator ? curator.username : openLabel}
        </div>

        {/* XP */}
        {curator && (
          <div
            className={`text-[10px] font-bold ${
              isFirst ? 'text-amber-500' : 'text-stone-500 dark:text-stone-400'
            }`}
          >
            {curator.seasonXp} XP
          </div>
        )}

        {/* Pillar Block */}
        <div
          className="w-full mt-2 rounded-t-xl flex items-center justify-center border-t border-x border-stone-200 dark:border-stone-700 bg-stone-100 dark:bg-stone-800/80"
          style={{ height: pillarHeight }}
        >
          <span className="font-black text-sm" style={{ color: accentColor }}>
            #{rank}
          </span>
        </div>
      </div>
    );
  };

  return (
    <div className="w-full max-w-xl mx-auto p-5 rounded-2xl bg-white dark:bg-stone-900 border border-stone-200 dark:border-stone-800 shadow-sm">
      {/* Header with district dropdown */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-stone-100 dark:border-stone-800">
        <div>
          <div className="flex items-center gap-1.5">
            <span className="text-xl">👑</span>
            <h2 className="text-lg font-black text-stone-900 dark:text-stone-100">
              {formatWebDistrictTitle(selectedDistrict, locale)}
            </h2>
          </div>
          <p className="text-xs text-stone-500 dark:text-stone-400 font-medium">
            {seasonId} Season • {podium.totalCuratorsCount} Curators
          </p>
        </div>

        {/* District selector dropdown */}
        <div className="flex items-center gap-2">
          <select
            data-testid="district-selector"
            value={selectedDistrict}
            onChange={handleDistrictChange}
            className="text-xs font-bold py-1.5 px-3 rounded-lg border border-stone-300 dark:border-stone-700 bg-stone-50 dark:bg-stone-800 text-stone-800 dark:text-stone-200 outline-none focus:ring-2 focus:ring-amber-500/20"
          >
            {TASHKENT_DISTRICTS.map((d) => (
              <option key={d} value={d}>
                {formatWebDistrictTitle(d, locale)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Top 3 Podium */}
      <div className="flex items-end justify-center gap-2 pt-6 px-2">
        {/* 2nd Place Silver */}
        {renderPillar(podium.silver, 2, '70px', '#94a3b8', '🥈')}

        {/* 1st Place Champion Gold */}
        {renderPillar(podium.champion, 1, '96px', '#f59e0b', '👑')}

        {/* 3rd Place Bronze */}
        {renderPillar(podium.bronze, 3, '52px', '#d97706', '🥉')}
      </div>

      {/* Runners Up List */}
      {podium.runnersUp.length > 0 && (
        <div className="mt-5 pt-4 border-t border-stone-100 dark:border-stone-800">
          <h3 className="text-xs font-bold text-stone-500 dark:text-stone-400 mb-2 uppercase tracking-wider">
            {locale.startsWith('uz')
              ? "Keyingi O'rinlar"
              : locale.startsWith('ru')
              ? 'Претенденты'
              : 'Contenders & Runners-up'}
          </h3>
          <div className="space-y-1.5">
            {podium.runnersUp.slice(0, 5).map((runner) => (
              <div
                key={runner.userId}
                data-testid={`runner-up-item-${runner.userId}`}
                onClick={() => handleCuratorClick(runner, false)}
                className="flex items-center justify-between p-2.5 rounded-xl bg-stone-50 dark:bg-stone-800/60 border border-stone-100 dark:border-stone-800 hover:bg-stone-100 dark:hover:bg-stone-800 cursor-pointer transition-colors"
              >
                <div className="flex items-center gap-2.5">
                  <span className="text-xs font-black text-stone-400 w-5">#{runner.rank}</span>
                  <div className="w-7 h-7 rounded-full bg-stone-200 dark:bg-stone-700 flex items-center justify-center font-bold text-xs text-stone-700 dark:text-stone-300">
                    {runner.fullName.substring(0, 2).toUpperCase()}
                  </div>
                  <div>
                    <div className="text-xs font-bold text-stone-800 dark:text-stone-200">
                      {runner.fullName}
                    </div>
                    <div className="text-[10px] text-stone-500 dark:text-stone-400">
                      {runner.username}
                    </div>
                  </div>
                </div>

                <div className="text-right">
                  <div className="text-xs font-black text-stone-800 dark:text-stone-200">
                    {runner.seasonXp} XP
                  </div>
                  {runner.gapToLeaderXp !== undefined && runner.gapToLeaderXp > 0 && (
                    <div className="text-[9px] text-stone-400">
                      -{runner.gapToLeaderXp} XP to #1
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
