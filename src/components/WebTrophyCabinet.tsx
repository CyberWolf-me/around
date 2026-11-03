import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebMasteryTier = 'grandMaster' | 'legend' | 'pioneer' | 'scout';

export interface WebAccoladeTrophy {
  id: string;
  seasonId: string;
  seasonTitle: string;
  tier: 'gold' | 'silver' | 'bronze';
  completedChallengesCount: number;
  xpBonus: number;
  earnedAt: string;
}

export interface WebAccoladeLaurel {
  seasonId: string;
  district: string;
  rank: number;
  laurel: 'champion' | 'podium' | 'topTen' | 'explorer';
}

export interface WebCuratorAccolades {
  userId: string;
  username: string;
  crownsCount: number;
  trophies: WebAccoladeTrophy[];
  laurels: WebAccoladeLaurel[];
  totalCuratorXp: number;
}

export function calculateWebMasteryTier(
  crownsCount: number,
  trophies: WebAccoladeTrophy[],
): WebMasteryTier {
  const goldCount = trophies.filter((t) => t.tier === 'gold').length;
  const silverCount = trophies.filter((t) => t.tier === 'silver').length;
  const totalCount = trophies.length;

  if (crownsCount >= 3 || (crownsCount >= 1 && goldCount >= 2)) {
    return 'grandMaster';
  }
  if (crownsCount >= 1 || goldCount >= 1 || silverCount >= 2) {
    return 'legend';
  }
  if (silverCount >= 1 || totalCount >= 1) {
    return 'pioneer';
  }
  return 'scout';
}

export function formatWebMasteryTitle(tier: WebMasteryTier, locale = 'en'): string {
  const lang = locale.toLowerCase();
  switch (tier) {
    case 'grandMaster':
      if (lang.startsWith('uz')) return 'Katta Kurator Ustasi';
      if (lang.startsWith('ru')) return 'Гранд-Мастер Куратор';
      return 'Grand Master Curator';
    case 'legend':
      if (lang.startsWith('uz')) return 'Toshkent Afsonasi';
      if (lang.startsWith('ru')) return 'Легенда Ташкента';
      return 'Tashkent Legend';
    case 'pioneer':
      if (lang.startsWith('uz')) return 'Tuman Kashfiyotchisi';
      if (lang.startsWith('ru')) return 'Районный Первопроходец';
      return 'District Pioneer';
    case 'scout':
      if (lang.startsWith('uz')) return 'Mahalla Qidiruvchisi';
      if (lang.startsWith('ru')) return 'Разведчик Махалли';
      return 'Neighborhood Scout';
  }
}

export function calculateWebHonorScore(accolades: WebCuratorAccolades): number {
  const goldCount = accolades.trophies.filter((t) => t.tier === 'gold').length;
  const silverCount = accolades.trophies.filter((t) => t.tier === 'silver').length;
  const bronzeCount = accolades.trophies.filter((t) => t.tier === 'bronze').length;

  return (
    accolades.crownsCount * 1000 +
    goldCount * 500 +
    silverCount * 250 +
    bronzeCount * 100 +
    accolades.laurels.length * 150 +
    Math.floor(accolades.totalCuratorXp / 10)
  );
}

export function generateWebShareCopy(accolades: WebCuratorAccolades, locale = 'en'): string {
  const tier = calculateWebMasteryTier(accolades.crownsCount, accolades.trophies);
  const title = formatWebMasteryTitle(tier, locale);
  const lang = locale.toLowerCase();

  const lines = [
    `👑 ${title} — @${accolades.username}`,
    `${accolades.crownsCount} District Crowns • ${accolades.trophies.length} Trophies`,
    lang.startsWith('uz')
      ? `Toshkent ta'm pasporti: https://around.tashkent.app/passport/${accolades.username}`
      : lang.startsWith('ru')
      ? `Паспорт вкуса Ташкента: https://around.tashkent.app/passport/${accolades.username}`
      : `Tashkent Taste Passport: https://around.tashkent.app/passport/${accolades.username}`,
  ];

  return lines.join('\n');
}

export interface WebTrophyCabinetProps {
  accolades: WebCuratorAccolades;
  locale?: 'en' | 'uz' | 'ru';
  onTrophyClick?: (trophy: WebAccoladeTrophy) => void;
}

export const WebTrophyCabinet: React.FC<WebTrophyCabinetProps> = ({
  accolades,
  locale = 'en',
  onTrophyClick,
}) => {
  const [selectedTrophy, setSelectedTrophy] = useState<WebAccoladeTrophy | null>(null);
  const [copied, setCopied] = useState(false);

  const tier = calculateWebMasteryTier(accolades.crownsCount, accolades.trophies);
  const title = formatWebMasteryTitle(tier, locale);
  const honorScore = calculateWebHonorScore(accolades);

  const handleTrophySelect = (trophy: WebAccoladeTrophy) => {
    playSoundWithHaptic('select');
    setSelectedTrophy(trophy);
    if (onTrophyClick) {
      onTrophyClick(trophy);
    }
  };

  const handleCopyShare = () => {
    playSoundWithHaptic('trophy');
    const text = generateWebShareCopy(accolades, locale);
    if (typeof navigator !== 'undefined' && navigator.clipboard) {
      navigator.clipboard.writeText(text);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const getTierEmoji = (t: 'gold' | 'silver' | 'bronze') => {
    if (t === 'gold') return '🥇';
    if (t === 'silver') return '🥈';
    return '🥉';
  };

  const getTierColor = (t: 'gold' | 'silver' | 'bronze') => {
    if (t === 'gold') return '#FFD666';
    if (t === 'silver') return '#C0C0C0';
    return '#CD7F32';
  };

  return (
    <div
      data-testid="web-trophy-cabinet"
      style={{
        backgroundColor: '#FFFDF9',
        border: '1.5px solid rgba(22, 20, 18, 0.16)',
        borderRadius: 20,
        padding: 20,
        fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif",
        boxShadow: '0 4px 16px -2px rgba(22, 20, 18, 0.05)',
      }}
    >
      {/* Header with Mastery Tier and Crowns */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 16,
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: 18 }}>👑</span>
            <span
              data-testid="mastery-title"
              style={{
                fontSize: 18,
                fontWeight: 800,
                color: '#161412',
              }}
            >
              {title}
            </span>
          </div>
          <div
            data-testid="honor-score"
            style={{ fontSize: 12, fontWeight: 600, color: '#8F887F', marginTop: 2 }}
          >
            Accolades Honor: {honorScore} pts
          </div>
        </div>

        <div
          data-testid="crown-pill"
          style={{
            backgroundColor: 'rgba(255, 214, 102, 0.2)',
            border: '1.5px solid #FFD666',
            borderRadius: 12,
            padding: '6px 12px',
            display: 'flex',
            alignItems: 'center',
            gap: 6,
            fontWeight: 800,
            fontSize: 14,
            color: '#161412',
          }}
        >
          <span>👑</span>
          <span>{accolades.crownsCount}</span>
        </div>
      </div>

      <hr style={{ border: 'none', borderTop: '1px solid rgba(22, 20, 18, 0.09)', margin: '12px 0' }} />

      {/* Seasonal Trophies Showcase */}
      <div style={{ marginBottom: 16 }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 10,
          }}
        >
          <span style={{ fontSize: 13, fontWeight: 700, color: '#5A544C' }}>
            {locale.startsWith('uz')
              ? 'Mavsumiy Kuboklar'
              : locale.startsWith('ru')
              ? 'Сезонные Трофеи'
              : 'Seasonal Trophies'}
          </span>
          <span style={{ fontSize: 12, fontWeight: 700, color: '#8F887F' }}>
            {accolades.trophies.length}
          </span>
        </div>

        {accolades.trophies.length === 0 ? (
          <div
            data-testid="empty-trophies-state"
            style={{
              backgroundColor: '#F3ECE0',
              borderRadius: 14,
              padding: 16,
              textAlign: 'center',
              fontSize: 12,
              color: '#8F887F',
            }}
          >
            {locale.startsWith('uz')
              ? "Hozircha mavsumiy kuboklar yo'q."
              : locale.startsWith('ru')
              ? 'Пока нет сезонных трофеев.'
              : 'No seasonal trophies yet.'}
          </div>
        ) : (
          <div
            data-testid="trophies-grid"
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))',
              gap: 10,
            }}
          >
            {accolades.trophies.map((trophy) => (
              <div
                key={trophy.id}
                data-testid={`trophy-card-${trophy.id}`}
                onClick={() => handleTrophySelect(trophy)}
                style={{
                  backgroundColor: '#FAF7F2',
                  border: `1.5px solid ${getTierColor(trophy.tier)}`,
                  borderRadius: 14,
                  padding: 10,
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'transform 0.15s ease',
                }}
              >
                <div style={{ fontSize: 24, marginBottom: 4 }}>{getTierEmoji(trophy.tier)}</div>
                <div
                  style={{
                    fontSize: 11,
                    fontWeight: 700,
                    color: '#161412',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                >
                  {trophy.seasonTitle}
                </div>
                <div style={{ fontSize: 10, color: '#8F887F', marginTop: 2 }}>
                  {trophy.seasonId}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Laurels section if any */}
      {accolades.laurels.length > 0 && (
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#5A544C', marginBottom: 8 }}>
            {locale.startsWith('uz')
              ? 'Tuman Shon-Sharaflari'
              : locale.startsWith('ru')
              ? 'Лавры Районов'
              : 'District Laurels'}
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {accolades.laurels.map((l, i) => (
              <div
                key={i}
                data-testid="laurel-chip"
                style={{
                  backgroundColor: '#F3ECE0',
                  border: '1px solid rgba(22, 20, 18, 0.16)',
                  borderRadius: 10,
                  padding: '4px 8px',
                  fontSize: 11,
                  fontWeight: 700,
                  color: '#161412',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 4,
                }}
              >
                <span>{l.laurel === 'champion' ? '👑' : '🥈'}</span>
                <span>
                  {l.district} #{l.rank}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Trophy Detail Inspection Banner if selected */}
      {selectedTrophy && (
        <div
          data-testid="trophy-detail-banner"
          style={{
            backgroundColor: '#F7F2EA',
            border: `1.5px solid ${getTierColor(selectedTrophy.tier)}`,
            borderRadius: 14,
            padding: 12,
            marginBottom: 14,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div>
            <div style={{ fontWeight: 800, fontSize: 13, color: '#161412' }}>
              {selectedTrophy.seasonTitle} ({selectedTrophy.tier.toUpperCase()})
            </div>
            <div style={{ fontSize: 11, color: '#5A544C', marginTop: 2 }}>
              {selectedTrophy.completedChallengesCount} challenges completed • +
              {selectedTrophy.xpBonus} XP Bonus
            </div>
          </div>
          <button
            onClick={() => setSelectedTrophy(null)}
            style={{
              background: 'none',
              border: 'none',
              fontSize: 12,
              fontWeight: 700,
              cursor: 'pointer',
              color: '#8F887F',
            }}
          >
            ✕
          </button>
        </div>
      )}

      {/* Share Button */}
      <button
        data-testid="share-accolades-button"
        onClick={handleCopyShare}
        style={{
          width: '100%',
          backgroundColor: '#161412',
          color: '#FAF7F2',
          border: 'none',
          borderRadius: 12,
          padding: '12px 16px',
          fontWeight: 700,
          fontSize: 13,
          cursor: 'pointer',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          gap: 6,
        }}
      >
        <span>🔗</span>
        <span>
          {copied
            ? locale.startsWith('uz')
              ? 'Nusxalandi!'
              : locale.startsWith('ru')
              ? 'Скопировано!'
              : 'Copied!'
            : locale.startsWith('uz')
            ? 'Yutuqlarni Ulashish'
            : locale.startsWith('ru')
            ? 'Поделиться Достижениями'
            : 'Share Accolades'}
        </span>
      </button>
    </div>
  );
};
