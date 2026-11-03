import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebHallOfFameEntry {
  userId: string;
  username: string;
  displayName: string;
  district: string;
  seasonId: string; // e.g. "2026-10"
  rank: number;
  seasonXp: number;
  placesCount: number;
  laurel: 'champion' | 'podium' | 'topTen';
}

export function filterHallOfFameEntries(
  entries: WebHallOfFameEntry[],
  seasonId?: string,
  district?: string
): WebHallOfFameEntry[] {
  return entries
    .filter((entry) => {
      const matchSeason = !seasonId || entry.seasonId === seasonId;
      const matchDistrict = !district || district === 'all' || entry.district.toLowerCase() === district.toLowerCase();
      return matchSeason && matchDistrict;
    })
    .sort((a, b) => a.rank - b.rank);
}

export interface SeasonHallOfFameProps {
  entries: WebHallOfFameEntry[];
  availableSeasons?: string[];
  availableDistricts?: string[];
  language?: 'en' | 'uz' | 'ru';
  onSelectEntry?: (entry: WebHallOfFameEntry) => void;
}

export const SeasonHallOfFame: React.FC<SeasonHallOfFameProps> = ({
  entries,
  availableSeasons = ['2026-10', '2026-09'],
  availableDistricts = ['all', 'Mirabad', 'Yakkasaray', 'Chilanzar', 'Yunusabad'],
  language = 'en',
  onSelectEntry,
}) => {
  const [selectedSeason, setSelectedSeason] = React.useState<string>(availableSeasons[0] || '2026-10');
  const [selectedDistrict, setSelectedDistrict] = React.useState<string>('all');

  const filteredEntries = React.useMemo(
    () => filterHallOfFameEntries(entries, selectedSeason, selectedDistrict),
    [entries, selectedSeason, selectedDistrict]
  );

  const topPodium = filteredEntries.slice(0, 3);
  const runnerUps = filteredEntries.slice(3, 10);

  const t = {
    title:
      language === 'uz'
        ? 'Toshkent Shon-Sharaf Zali'
        : language === 'ru'
        ? 'Зал Славы Ташкента'
        : 'Tashkent Hall of Fame',
    subtitle:
      language === 'uz'
        ? 'Tarixiy oylik mavsumlar g‘oliblari va chempionlari'
        : language === 'ru'
        ? 'Победители и чемпионы исторических сезонов'
        : 'Historical season champions & neighborhood legends',
    allDistricts: language === 'uz' ? 'Barcha Tumanlar' : language === 'ru' ? 'Все Районы' : 'All Districts',
    noEntries:
      language === 'uz'
        ? 'Tanlangan filtr bo‘yicha yozuvlar topilmadi'
        : language === 'ru'
        ? 'Записей по выбранному фильтру не найдено'
        : 'No entries found for selected filter',
  };

  const handleEntryClick = (entry: WebHallOfFameEntry) => {
    playSoundWithHaptic(entry.rank === 1 ? 'trophy' : 'select');
    onSelectEntry?.(entry);
  };

  return (
    <div
      data-testid="season-hall-of-fame"
      style={{
        background: '#161412',
        borderRadius: 20,
        padding: 24,
        color: '#FAF7F2',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        border: '1px solid #2B2621',
      }}
    >
      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
          <span style={{ fontSize: 24 }}>🏛️</span>
          <h2 style={{ margin: 0, fontSize: 20, fontWeight: 800, color: '#FAF7F2' }}>{t.title}</h2>
        </div>
        <div style={{ fontSize: 12, color: '#8F887F' }}>{t.subtitle}</div>
      </div>

      {/* Filter Bars */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, marginBottom: 20 }}>
        {/* Season Selector */}
        <div style={{ display: 'flex', gap: 6 }}>
          {availableSeasons.map((s) => (
            <button
              key={s}
              data-testid={`season-tab-${s}`}
              onClick={() => {
                playSoundWithHaptic('select');
                setSelectedSeason(s);
              }}
              style={{
                background: selectedSeason === s ? '#FF4800' : '#221E1A',
                color: selectedSeason === s ? '#FFFFFF' : '#8F887F',
                border: '1px solid #332D26',
                borderRadius: 8,
                padding: '6px 12px',
                fontSize: 11,
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              🗓️ {s}
            </button>
          ))}
        </div>

        {/* District Selector */}
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }}>
          {availableDistricts.map((d) => (
            <button
              key={d}
              data-testid={`district-tab-${d.toLowerCase()}`}
              onClick={() => {
                playSoundWithHaptic('select');
                setSelectedDistrict(d);
              }}
              style={{
                background: selectedDistrict.toLowerCase() === d.toLowerCase() ? '#FFD666' : '#221E1A',
                color: selectedDistrict.toLowerCase() === d.toLowerCase() ? '#161412' : '#8F887F',
                border: '1px solid #332D26',
                borderRadius: 8,
                padding: '6px 10px',
                fontSize: 11,
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              {d === 'all' ? t.allDistricts : d}
            </button>
          ))}
        </div>
      </div>

      {/* Empty State */}
      {filteredEntries.length === 0 && (
        <div
          data-testid="hall-of-fame-empty"
          style={{
            padding: 30,
            textAlign: 'center',
            color: '#8F887F',
            fontSize: 13,
            background: '#1F1A16',
            borderRadius: 14,
          }}
        >
          {t.noEntries}
        </div>
      )}

      {/* Top 3 Podium */}
      {topPodium.length > 0 && (
        <div
          data-testid="hall-of-fame-podium"
          style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${topPodium.length}, 1fr)`,
            gap: 12,
            marginBottom: 20,
          }}
        >
          {topPodium.map((entry) => {
            const isFirst = entry.rank === 1;
            const rankEmoji = entry.rank === 1 ? '🥇' : entry.rank === 2 ? '🥈' : '🥉';
            const accentBorder = isFirst ? '#FFD666' : '#3D362E';
            const accentBg = isFirst ? 'rgba(255, 214, 102, 0.08)' : '#221E1A';

            return (
              <div
                key={entry.userId}
                data-testid={`podium-card-rank-${entry.rank}`}
                onClick={() => handleEntryClick(entry)}
                style={{
                  background: accentBg,
                  border: `1.5px solid ${accentBorder}`,
                  borderRadius: 16,
                  padding: 16,
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
              >
                <div style={{ fontSize: 24, marginBottom: 4 }}>{rankEmoji}</div>
                <div style={{ fontSize: 13, fontWeight: 800, color: '#FAF7F2' }}>
                  {entry.displayName}
                </div>
                <div style={{ fontSize: 11, color: '#FF4800', fontWeight: 700, marginTop: 2 }}>
                  @{entry.username}
                </div>
                <div style={{ fontSize: 10, color: '#8F887F', marginTop: 4 }}>
                  {entry.district} · {entry.placesCount} spots
                </div>
                <div
                  style={{
                    display: 'inline-block',
                    marginTop: 8,
                    padding: '2px 8px',
                    borderRadius: 6,
                    background: 'rgba(255, 72, 0, 0.15)',
                    color: '#FF4800',
                    fontSize: 11,
                    fontWeight: 800,
                  }}
                >
                  {entry.seasonXp} XP
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Runner-ups (4-10) */}
      {runnerUps.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {runnerUps.map((entry) => (
            <div
              key={entry.userId}
              data-testid={`runner-up-row-${entry.rank}`}
              onClick={() => handleEntryClick(entry)}
              style={{
                background: '#1F1B17',
                border: '1px solid #2B2621',
                borderRadius: 12,
                padding: '10px 14px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                cursor: 'pointer',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 12, fontWeight: 800, color: '#8F887F', width: 20 }}>
                  #{entry.rank}
                </span>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#FAF7F2' }}>
                    {entry.displayName} <span style={{ color: '#8F887F' }}>@{entry.username}</span>
                  </div>
                  <div style={{ fontSize: 10, color: '#8F887F' }}>{entry.district}</div>
                </div>
              </div>
              <div style={{ fontSize: 11, fontWeight: 800, color: '#66E5B4' }}>
                {entry.seasonXp} XP
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
